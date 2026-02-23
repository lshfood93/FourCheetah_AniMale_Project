/* =========================================================
   AniMale Admin Dashboard (Cash)

   이 스크립트의 역할
   ---------------------------------------------------------
   1) 서버 API(/api/admin/cash/admindashboard)에서 대시보드 데이터를 가져온다.
   2) 가져온 응답(JSON)을 프론트에서 쓰기 쉬운 vm(ViewModel) 형태로 정리한다.
   3) JSP에 미리 준비된 텍스트 영역(#text-*)과 차트 영역(#chart-*)에 렌더링한다.
   4) 월별 Area 차트의 최고/최저 라벨은 ApexCharts 기본 annotation 대신
      HTML 오버레이로 직접 붙여서, 줌/스크롤/리사이즈 시에도 자연스럽게 제어한다.

   설계 포인트
   ---------------------------------------------------------
   - 서버 응답 필드명이 달라도 프론트 전체를 고치지 않도록 toVM()에서 흡수
   - 서버 호출 실패 시에도 화면 전체가 죽지 않도록 fallback vm 사용
   - 월별 차트 데이터는 연도별 캐시(monthlyByYear)로 보관해서 불필요한 재호출 감소
   - 최고/최저 배지는 "전체 12개월이 보일 때만" 노출되도록 제어
   - 줌/스크롤 입력이 들어오면 배지를 먼저 숨기고, 이후 상태를 다시 판정해서 복구
   ========================================================= */

(async function () { // 최상위 await(fetch)를 쓰기 위해 async IIFE 형태로 감쌈
  // =========================================================
  // 0) 서버 API 호출 준비 + 응답(JSON) -> vm 변환(toVM)
  // =========================================================
  // 이 파일은 JSP에서 아래 전역값을 먼저 세팅해 둔 상태를 전제로 동작한다.
  //
  // window.APP_CTX
  // - 애플리케이션 컨텍스트 경로
  // - 예: '', '/animale'
  // - 정적/동적 URL 조합 시 하드코딩 경로 꼬임 방지용
  //
  // window.DASH_INIT
  // - 초기 조회 기준 year/month
  // - JSP에서 서버 기준값을 내려줄 수 있고, 없으면 현재 날짜 사용
  const APP_CTX = window.APP_CTX || '';
  const INIT = window.DASH_INIT || {};

  // Number(...)로 강제 숫자화하는 이유
  // - JSP에서 문자열로 내려오는 경우가 많아서 숫자 계산 전에 타입 고정 필요
  // - falsy/null/undefined일 때는 현재 날짜로 fallback
  const initYear = Number(INIT.year || new Date().getFullYear());
  const initMonth = Number(INIT.month || (new Date().getMonth() + 1));

  // ---------------------------------------------------------
  // 서버 대시보드 API 호출 함수
  // ---------------------------------------------------------
  // year/month를 쿼리스트링으로 전달하고 JSON 응답을 기대한다.
  // fetch 실패(res.ok=false)는 throw해서 상위 try/catch에서 fallback vm로 처리한다.
  const fetchDashboard = async (year, month) => {
    const qs = new URLSearchParams({
      year: String(year),
      month: String(month)
    });

    const url = APP_CTX + '/api/admin/cash/admindashboard?' + qs.toString();

    const res = await fetch(url, {
      headers: { Accept: 'application/json' }
    });

    if (!res.ok) {
      // 여기서 명시적으로 throw해 두면 상위에서 "화면은 살리고 값만 0 처리" 흐름 유지 가능
      throw new Error('dashboard api failed: ' + res.status);
    }

    return res.json();
  };

  // ---------------------------------------------------------
  // API 응답(JSON) -> 프론트 표준 vm(ViewModel) 변환
  // ---------------------------------------------------------
  // 목적:
  // - 서버 응답 구조 변화의 영향 범위를 이 함수 내부로 제한
  // - 아래 렌더링 코드(텍스트/차트)는 vm 기준으로만 읽도록 고정
  // - null/undefined/NaN/누락 필드 방어를 한 곳에서 처리
  const toVM = (api, fallbackYear, fallbackMonth) => {
    // year/month는 서버가 내려주면 서버값 우선, 없으면 호출 기준값 사용
    const year = Number(api.year ?? fallbackYear);
    const month = Number(api.month ?? fallbackMonth);

    // 이번 달 / 전월 총액
    // - 이번 달은 없으면 0 처리
    // - 전월은 "없음(null)"과 "0원"을 구분해야 해서 null 유지
    const thisMonthTotal = Number(api.thisMonthTotal ?? 0);
    const lastMonthTotal = (api.lastMonthTotal == null)
      ? null
      : Number(api.lastMonthTotal);

    // 카드 텍스트에 표시할 값들
    // - thisMonthCount, dailyAvg는 값 없으면 0 처리
    // - lastMonthCount는 전월 데이터 유무 판단에 쓰이므로 null 구분 유지
    const thisMonthCount = Number(api.thisMonthCount ?? 0);
    const lastMonthCount = (api.lastMonthCount == null)
      ? null
      : Number(api.lastMonthCount);
    const dailyAvg = Number(api.dailyAvg ?? 0);

    // 전월 대비 퍼센트(momPercent)
    // - 서버가 계산해서 내려줄 수 있으므로 우선 받아두고
    // - 없을 때만 아래 렌더 단계에서 JS 계산으로 보완
    const momPercent = (api.momPercent == null)
      ? null
      : Number(api.momPercent);

    // 충전 수단별 금액 파싱
    // - 현재 UI는 카카오/토스 2종만 쓰므로 두 변수에 모아둔다.
    // - providerList가 누락/비배열이면 빈 배열 처리
    let kakaoAmount = 0;
    let tossAmount = 0;

    const providerList = Array.isArray(api.providerList) ? api.providerList : [];
    for (const row of providerList) {
      const provider = String(row.provider ?? '');
      const amount = Number(row.cashAmount ?? 0);

      if (provider === 'KAKAOPAY') kakaoAmount = amount;
      if (provider === 'TOSSPAY') tossAmount = amount;
    }

    // 수단 비율 계산
    // - 기준은 "이번 달 총액"
    // - 총액이 0이면 둘 다 0%
    // - 현재 UI가 2개 수단만 보여주므로 합이 100이 되도록 토스를 보정
    let kakaoPercent = 0;
    let tossPercent = 0;
    if (thisMonthTotal > 0) {
      kakaoPercent = Math.round((kakaoAmount * 100) / thisMonthTotal);
      tossPercent = Math.max(0, 100 - kakaoPercent);
    }

    // 연간 월별 데이터(yearMonthly)를 12칸 배열로 변환
    // 예시 입력:
    //   [{ month:1, cashAmount:1000 }, { month:2, cashAmount:2000 }]
    // 결과:
    //   [1000, 2000, 0, 0, ..., 0]  // length 12
    const monthlyTotals = new Array(12).fill(0);
    const yearMonthly = Array.isArray(api.yearMonthly) ? api.yearMonthly : [];

    for (const row of yearMonthly) {
      const m = Number(row.month);
      const amount = Number(row.cashAmount ?? 0);

      // month 범위가 1~12일 때만 반영해서 잘못된 데이터 방어
      if (m >= 1 && m <= 12) {
        monthlyTotals[m - 1] = amount;
      }
    }

    // 아래 렌더링 코드에서 공통으로 쓰는 표준 vm 반환
    return {
      year,
      month,

      thisMonthTotal,
      lastMonthTotal,

      thisMonthCount,
      lastMonthCount,
      dailyAvg,
      momPercent,

      kakaoPercent,
      tossPercent,

      // 툴팁에서 퍼센트 말고 실제 금액도 보여주기 위해 보관
      kakaoAmount,
      tossAmount,

      // 월별 Area 차트 데이터
      monthlyTotals
    };
  };

  // ---------------------------------------------------------
  // 초기 데이터 로딩
  // ---------------------------------------------------------
  // 여기서 vm이 확정된 뒤에만 아래 렌더링(텍스트/차트)이 실행된다.
  // 서버 오류가 나더라도 catch에서 fallback vm을 만들기 때문에
  // "화면 전체 JS가 죽는 상황"을 피할 수 있다.
  let vm;
  try {
    const api = await fetchDashboard(initYear, initMonth);
    vm = toVM(api, initYear, initMonth);
  } catch (e) {
    console.error(e);

    // 서버 미구현/에러 상황용 최소 동작 vm
    // - 차트는 0으로 렌더링
    // - 화면은 깨지지 않음
    vm = {
      year: initYear,
      month: initMonth,

      thisMonthTotal: 0,
      lastMonthTotal: null,

      thisMonthCount: 0,
      lastMonthCount: null,
      dailyAvg: 0,
      momPercent: null,

      kakaoPercent: 0,
      tossPercent: 0,
      kakaoAmount: 0,
      tossAmount: 0,

      monthlyTotals: new Array(12).fill(0)
    };
  }

  // =========================================================
  // 공통 유틸 함수
  // =========================================================

  // DOM 텍스트 안전 업데이트
  // - 해당 id가 없는 페이지/부분 렌더에서도 에러 없이 무시되게 함
  const setText = (id, text) => {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
  };

  // 숫자 범위를 min~max 사이로 제한
  // - 차트 퍼센트/ringValue 등에서 과도한 값 방지
  const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

  // 월별 데이터 정규화
  // - 항상 12칸 숫자 배열로 맞춘다.
  // - 입력이 null/undefined/문자열 배열/길이 부족이어도 안전하게 처리
  const normalizeMonthly = (arr) => {
    const out = new Array(12).fill(0);
    if (!Array.isArray(arr)) return out;

    for (let i = 0; i < Math.min(12, arr.length); i++) {
      const n = Number(arr[i]);
      out[i] = Number.isFinite(n) ? n : 0;
    }
    return out;
  };

  // =========================================================
  // 텍스트 영역 렌더링 (수단 퍼센트 / 건수 / 일평균)
  // =========================================================
  setText('text-kakao', String(vm.kakaoPercent) + '%');
  setText('text-toss', String(vm.tossPercent) + '%');

  // null/undefined 방어를 한 번 더 걸고 포맷팅
  setText('text-charge-count', String(Number(vm.thisMonthCount ?? 0)) + '건');
  setText('text-daily-avg', '₩ ' + Number(vm.dailyAvg ?? 0).toLocaleString());

  // =========================================================
  // 1) 전월 대비 라디얼 차트 + 배지 텍스트
  // =========================================================
  // 여기서는 단순 차트 렌더만 하는 게 아니라,
  // "전월 데이터 없음 / 전월 0원 / 비교 불가" 같은 예외 케이스를 함께 처리한다.
  const thisMonthTotal = Number(vm.thisMonthTotal ?? 0);
  const lastMonthTotal = (vm.lastMonthTotal == null) ? null : Number(vm.lastMonthTotal);
  const lastMonthCount = (vm.lastMonthCount == null) ? null : Number(vm.lastMonthCount);

  // ---------------------------------------------------------
  // 전월 데이터 유무 판정
  // ---------------------------------------------------------
  // 서버가 count를 내려주는 경우:
  // - count > 0 이면 전월 데이터 있음
  // count가 아예 없는 경우:
  // - lastMonthTotal null 여부로만 판단
  //
  // 이렇게 분기하는 이유:
  // - total 값이 0인 것과 데이터 자체가 없는 것을 구분하려고
  const hasPrevData = (lastMonthCount != null)
    ? (lastMonthCount > 0)
    : (lastMonthTotal != null);

  const prevIsZero = (lastMonthTotal === 0);

  // ---------------------------------------------------------
  // momPercent 최종 확정
  // ---------------------------------------------------------
  // 우선순위:
  // 1) 서버가 momPercent를 내려주면 사용
  // 2) 서버가 안 내려주면 JS에서 계산
  //
  // 단, 전월 총액이 0 이하/없음이면 나눗셈 비교가 성립하지 않으므로 null 유지
  let momPercent = (vm.momPercent == null) ? null : Number(vm.momPercent);
  if (!Number.isFinite(momPercent)) momPercent = null;

  if (momPercent == null) {
    if (lastMonthTotal != null && Number.isFinite(lastMonthTotal) && lastMonthTotal > 0) {
      momPercent = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
    } else {
      momPercent = null;
    }
  }

  // 전월 대비 배지(text-mom) DOM + 클래스 제어 헬퍼
  const momEl = document.getElementById('text-mom');

  const setMomBadge = (text, state) => {
    setText('text-mom', text);

    if (!momEl) return;

    // 이전 상태 클래스 제거 후 새 상태만 부여
    // (클래스 누적 꼬임 방지)
    momEl.classList.remove('badge-up', 'badge-down', 'badge-neutral');

    if (state === 'up') {
      momEl.classList.add('badge-up');
    } else if (state === 'down') {
      momEl.classList.add('badge-down');
    } else {
      momEl.classList.add('badge-neutral');
    }
  };

  // 라디얼 색상 정의
  // - 증가: 파랑
  // - 감소: 핑크/레드 계열
  // - 중립/비교불가: 회색
  const COLOR_UP = '#1e88ff';
  const COLOR_DOWN = '#d61f69';
  const COLOR_NEUTRAL = '#94a3b8';

  // 아래 분기에서 최종 결정할 값들
  // - radialColor      : 라디얼 막대 색상
  // - ringValue        : 라디얼 채움 비율(0~100)
  // - momTextForTooltip: 툴팁에 보여줄 증감 문구
  let radialColor = COLOR_UP;
  let ringValue = 0;
  let momTextForTooltip = '';

  if (momPercent != null && Number.isFinite(momPercent)) {
    // 정상 비교 가능 케이스
    const sign = momPercent >= 0 ? '+' : '';
    const rounded = Math.round(momPercent);

    setMomBadge(
      '전월 대비 ' + sign + rounded + '%',
      momPercent >= 0 ? 'up' : 'down'
    );

    radialColor = (momPercent >= 0) ? COLOR_UP : COLOR_DOWN;

    // 라디얼은 0~100 범위만 표시하므로 절대값 기준 clamp
    // (예: +180% 같은 값은 꽉 찬 원형으로 표현)
    ringValue = clamp(Math.abs(momPercent), 0, 100);

    momTextForTooltip = sign + rounded + '%';
  } else {
    // 비교 불가/예외 케이스를 문구로 명확히 구분
    if (!hasPrevData) {
      // 전월 기록 자체가 없는 경우
      setMomBadge('전월 데이터 없음', 'neutral');
      momTextForTooltip = '전월 데이터 없음';
      radialColor = COLOR_NEUTRAL;
      ringValue = 0;
    } else if (prevIsZero) {
      // 전월 데이터는 있으나 전월 금액이 0원인 경우
      // - 이번 달이 >0이면 증가처럼 보이지만 퍼센트 비교는 수학적으로 불가
      setMomBadge('전월 0원', thisMonthTotal > 0 ? 'up' : 'neutral');

      momTextForTooltip = (thisMonthTotal > 0)
        ? '전월 0원(비교 불가)'
        : '전월 0원';

      radialColor = (thisMonthTotal > 0) ? COLOR_UP : COLOR_NEUTRAL;

      // 시각적으로 "이번 달 값이 생김"을 강조하고 싶으면 100% 링 표시
      ringValue = (thisMonthTotal > 0) ? 100 : 0;
    } else {
      // 예외적 비정상 상태(값 이상 등)
      setMomBadge('전월 대비 계산 불가', 'neutral');
      momTextForTooltip = '계산 불가';
      radialColor = COLOR_NEUTRAL;
      ringValue = 0;
    }
  }

  // 카드 상단 큰 금액 텍스트
  setText('text-this-month', '₩ ' + thisMonthTotal.toLocaleString());

  // 툴팁에서 전월 금액을 보여줄 때 null이면 0으로 표시
  const lastMonthTotalForTooltip =
    (lastMonthTotal != null && Number.isFinite(lastMonthTotal))
      ? lastMonthTotal
      : 0;

  // 라디얼 차트 옵션
  const radialOptions = {
    series: [ringValue],
    chart: {
      type: 'radialBar',
      height: 260,
      width: 260,

      // sparkline: 축/범례 등 장식을 최대한 제거해 카드형 UI에 맞춤
      sparkline: { enabled: true },

      // 카드 레이아웃에 맞게 미세 위치 조정
      offsetY: -18,
      offsetX: 0
    },
    grid: {
      padding: { top: -22, bottom: -22, left: -10, right: -10 }
    },
    colors: [radialColor],
    plotOptions: {
      radialBar: {
        hollow: { size: '40%' },
        track: {
          background: '#e9eef5',
          strokeWidth: '100%',
          margin: 0
        },
        // 중앙 라벨은 숨기고 커스텀 텍스트(카드 외부 영역)로 표현하는 구조
        dataLabels: {
          name: { show: false },
          value: { show: false }
        }
      }
    },
    tooltip: {
      enabled: true,
      fixed: {
        enabled: true,
        position: 'topLeft',
        offsetX: -6,
        offsetY: 10
      },
      custom: function () {
        return (
          "<div class='dash-tooltip'>" +
            "<div class='tt-row'><span class='label'>지난달</span><span class='value'>₩ " + Number(lastMonthTotalForTooltip).toLocaleString() + '</span></div>' +
            "<div class='tt-row'><span class='label'>이번달</span><span class='value'>₩ " + Number(thisMonthTotal).toLocaleString() + '</span></div>' +
            "<div class='tt-row'><span class='label'>증감</span><span class='value'>" + momTextForTooltip + '</span></div>' +
          '</div>'
        );
      }
    }
  };

  const radialEl = document.querySelector('#chart-mom-radial');
  if (radialEl) {
    // 동일 영역 재렌더 시 이전 DOM 찌꺼기 방지
    radialEl.innerHTML = '';
    new ApexCharts(radialEl, radialOptions).render();
  }

  // =========================================================
  // 2) 충전 수단 비교 차트 (100% 가로 스택 바)
  // =========================================================
  // 현재 UI는 카카오/토스 2개만 노출하는 막대 1줄 구조
  const kakao = clamp(Number(vm.kakaoPercent ?? 0), 0, 100);
  const toss = clamp(Number(vm.tossPercent ?? 0), 0, 100);

  const methodTotal = Number(vm.thisMonthTotal ?? 0);

  // 서버가 수단별 금액을 안 내려주거나 일부 누락된 경우
  // 퍼센트와 총액으로 대략 복원해서 툴팁 값이 비지 않게 함
  const pctToAmount = (total, pct) => Math.round(total * pct / 100);

  let kakaoAmount = Number(vm.kakaoAmount ?? pctToAmount(methodTotal, kakao));
  let tossAmount = Number(vm.tossAmount ?? (methodTotal - kakaoAmount));

  if (!Number.isFinite(kakaoAmount)) kakaoAmount = 0;
  if (!Number.isFinite(tossAmount) || tossAmount < 0) tossAmount = 0;

  // 툴팁 custom 함수에서 참조할 배열
  const methodPercents = [kakao, toss];
  const methodAmounts = [kakaoAmount, tossAmount];

  const methodBarOptions = {
    series: [
      { name: '카카오페이', data: [kakao] },
      { name: '토스페이', data: [toss] }
    ],
    chart: {
      type: 'bar',
      height: 56,

      // 한 줄에서 100% 누적 막대 표현
      stacked: true,
      stackType: '100%',

      // 카드용 compact UI
      sparkline: { enabled: true },
      fontFamily: 'inherit'
    },
    colors: ['#1e88ff', '#d0d5dd'],
    plotOptions: {
      bar: {
        horizontal: true,
        barHeight: '100%',
        borderRadius: 0,
        borderRadiusWhenStacked: 'all'
      }
    },
    grid: {
      show: false,
      padding: { top: 0, bottom: 0, left: 0, right: 0 }
    },
    dataLabels: {
      enabled: true,
      formatter: function (val) {
        return Math.round(val) + '%';
      },
      // 두 수단 대비 가독성 확보용 색상 분리
      style: {
        fontSize: '12px',
        fontWeight: 800,
        colors: ['#ffffff', '#344054']
      }
    },
    xaxis: {
      max: 100,
      labels: { show: false },
      axisBorder: { show: false },
      axisTicks: { show: false }
    },
    yaxis: {
      labels: { show: false }
    },
    legend: { show: false },
    tooltip: {
      shared: false,
      intersect: true,
      custom: function ({ seriesIndex }) {
        const ratio = Math.round(methodPercents[seriesIndex] ?? 0);
        const amount = Number(methodAmounts[seriesIndex] ?? 0);

        return (
          "<div class='dash-tooltip'>" +
            "<div class='tt-row'><span class='label'>이번달 결제금액</span><span class='value'>₩ " + amount.toLocaleString() + '</span></div>' +
            "<div class='tt-row'><span class='label'>비율</span><span class='value'>" + ratio + '%</span></div>' +
          '</div>'
        );
      }
    }
  };

  const barEl = document.querySelector('#chart-method-bar');
  if (barEl) {
    barEl.innerHTML = '';
    new ApexCharts(barEl, methodBarOptions).render();
  }

  // =========================================================
  // 3) 월별 충전금액 Area 차트 + 최고/최저 배지(HTML 오버레이)
  // =========================================================
  // 이 파트가 가장 복잡한 이유:
  // - ApexCharts SVG annotation으로는 줌/스크롤/리사이즈 시 제어가 빡빡할 수 있어
  // - 그래서 차트 위에 HTML 오버레이를 올리고, 실제 마커 위치를 읽어 배지 위치를 맞춘다.
  const months = [
    '1월','2월','3월','4월','5월','6월',
    '7월','8월','9월','10월','11월','12월'
  ];

  // ---------------------------------------------------------
  // 연도별 월 데이터 캐시
  // ---------------------------------------------------------
  // - 최초 로드한 연도 데이터는 vm.monthlyTotals 사용
  // - 사용자가 다른 연도를 선택하면 캐시에 없을 때만 API 재호출
  const monthlyByYear = {};
  monthlyByYear[vm.year] = normalizeMonthly(vm.monthlyTotals);

  // 차트 인스턴스 / 현재 최고최저 정보
  let monthlyAreaChart = null;
  let lastMM = null;

  // 금액(원) -> '만' 단위 텍스트 변환
  // 예: 1230000 -> '123만'
  // y축 라벨/배지 텍스트에서 통일해서 사용
  const toManText = (v) => {
    const n = Number(v);
    if (!Number.isFinite(n)) return '0만';
    return Math.round(n / 10000) + '만';
  };

  // y축 눈금 단위(100만 원)
  // 요청사항 기준으로 통일
  const Y_STEP = 1000000;

  // ---------------------------------------------------------
  // y축 범위 계산
  // ---------------------------------------------------------
  // - min은 항상 0
  // - max는 데이터 최댓값을 100만 단위로 올림
  // - tickAmount는 (max-min)/step 기반
  const calcYAxis = (data) => {
    const vals = normalizeMonthly(data).map((x) => Number(x) || 0);
    const maxVal = Math.max(...vals);

    const max = Math.max(Y_STEP, Math.ceil(maxVal / Y_STEP) * Y_STEP);
    const min = 0;
    const tickAmount = Math.round((max - min) / Y_STEP);

    return { min, max, tickAmount };
  };

  // ---------------------------------------------------------
  // 최고/최저 값 및 인덱스 계산
  // ---------------------------------------------------------
  // 반환값 예시:
  // {
  //   vals:   [..12개..],
  //   maxVal: 3000000, maxIdx: 4,
  //   minVal: 0,       minIdx: 0
  // }
  const computeMinMax = (data) => {
    const vals = normalizeMonthly(data).map((x) => Number(x) || 0);
    const maxVal = Math.max(...vals);
    const minVal = Math.min(...vals);
    const maxIdx = vals.indexOf(maxVal);
    const minIdx = vals.indexOf(minVal);

    return { vals, maxVal, minVal, maxIdx, minIdx };
  };

  // ---------------------------------------------------------
  // 오버레이 DOM 생성/보장
  // ---------------------------------------------------------
  // host(#chart-monthly-area) 안에 아래 구조를 보장한다.
  // .monthly-overlay
  //   .monthly-badge.monthly-badge--max
  //   .monthly-badge.monthly-badge--min
  //
  // host가 position: static이면 absolute 배치 기준이 안 잡히므로 relative로 바꿔준다.
  const ensureMonthlyOverlay = (host) => {
    const pos = getComputedStyle(host).position;
    if (pos === 'static') host.style.position = 'relative';

    let overlay = host.querySelector('.monthly-overlay');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.className = 'monthly-overlay';
      host.appendChild(overlay);
    }

    let maxBadge = overlay.querySelector('.monthly-badge--max');
    if (!maxBadge) {
      maxBadge = document.createElement('div');
      maxBadge.className = 'monthly-badge monthly-badge--max';
      overlay.appendChild(maxBadge);
    }

    let minBadge = overlay.querySelector('.monthly-badge--min');
    if (!minBadge) {
      minBadge = document.createElement('div');
      minBadge.className = 'monthly-badge monthly-badge--min';
      overlay.appendChild(minBadge);
    }

    return { overlay, maxBadge, minBadge };
  };

  // 오버레이 전체 표시/숨김
  // - 개별 배지 display 조작보다 먼저 큰 단위로 토글할 때 사용
  const setMonthlyOverlayVisible = (host, visible) => {
    const overlay = host.querySelector('.monthly-overlay');
    if (!overlay) return;
    overlay.style.display = visible ? 'block' : 'none';
  };

  // ---------------------------------------------------------
  // ApexCharts 마커 노드 탐색
  // ---------------------------------------------------------
  // ApexCharts 버전/렌더 구조에 따라 마커 selector가 조금 달라질 수 있어서
  // 1차 selector 실패 시 더 넓은 selector로 fallback 한다.
  const getMarkerNodes = (host) => {
    let nodes = host.querySelectorAll('.apexcharts-series-markers .apexcharts-marker');

    if (!nodes || nodes.length < 12) {
      nodes = host.querySelectorAll('.apexcharts-marker');
    }

    return nodes;
  };

  // ---------------------------------------------------------
  // 플롯(그래프가 실제 그려지는 영역) rect 조회
  // ---------------------------------------------------------
  // 마커가 host 내부에 있다고 해서 모두 "현재 보이는 plot 범위" 안에 있는 건 아니다.
  // 줌/팬 상태에서는 바깥쪽 마커가 있어도 보이지 않는 경우가 있어
  // plot 영역 rect와 비교해서 실제 가시성 판단에 사용한다.
  const getPlotRect = (host) => {
    const plot =
      host.querySelector('.apexcharts-inner') ||
      host.querySelector('.apexcharts-plot-series') ||
      host.querySelector('.apexcharts-grid') ||
      host;

    return plot.getBoundingClientRect();
  };

  // ---------------------------------------------------------
  // 현재 plot 안에 "보이는" 마커 개수 계산
  // ---------------------------------------------------------
  // 전체 12개월 뷰인지 fallback 판정하는 데 사용
  // (x축 범위를 직접 읽을 수 없는 경우 대비)
  const countVisibleMarkersInPlot = (host) => {
    const markers = getMarkerNodes(host);
    if (!markers || markers.length === 0) return 0;

    const hostRect = host.getBoundingClientRect();
    const plotRect = getPlotRect(host);

    // host 좌표계를 기준으로 plot 영역 계산
    const left = plotRect.left - hostRect.left;
    const right = plotRect.right - hostRect.left;
    const top = plotRect.top - hostRect.top;
    const bottom = plotRect.bottom - hostRect.top;

    const margin = 2; // 좌표 오차/반올림 오차 여유
    let count = 0;

    // 월별 데이터는 최대 12개 포인트만 사용
    const n = Math.min(markers.length, 12);

    for (let i = 0; i < n; i++) {
      const r = markers[i].getBoundingClientRect();

      // 마커 중심점 좌표 계산
      const x = (r.left - hostRect.left) + (r.width / 2);
      const y = (r.top - hostRect.top) + (r.height / 2);

      const inPlot =
        x >= (left - margin) &&
        x <= (right + margin) &&
        y >= (top - margin) &&
        y <= (bottom + margin);

      if (inPlot) count++;
    }

    return count;
  };

  // 마커가 12개 모두 plot 안에 있으면 "전체 뷰"로 간주
  const isMonthlyFullView = (host) => {
    return countVisibleMarkersInPlot(host) >= 12;
  };

  // ---------------------------------------------------------
  // x축 범위 기반 전체뷰 판정 보조 상태
  // ---------------------------------------------------------
  // 전체뷰에서의 minX/maxX를 저장해두고, 현재 범위와 비교해서
  // resetZoom 이후 "정말 전체로 돌아왔는지" 더 정확하게 판정한다.
  let fullXRange = null;
  const X_EPS = 0.0001; // 부동소수점 오차 허용 범위

  // chart 이벤트 콜백(chartContext)에서 x축 범위 읽기
  const readXRangeFromCtx = (ctx) => {
    if (!ctx || !ctx.w || !ctx.w.globals) return null;

    const minX = ctx.w.globals.minX;
    const maxX = ctx.w.globals.maxX;

    if (!Number.isFinite(minX) || !Number.isFinite(maxX)) return null;
    return { minX, maxX };
  };

  // 차트 인스턴스에서 x축 범위 읽기
  const readXRangeFromChart = (chart) => {
    if (!chart || !chart.w || !chart.w.globals) return null;

    const minX = chart.w.globals.minX;
    const maxX = chart.w.globals.maxX;

    if (!Number.isFinite(minX) || !Number.isFinite(maxX)) return null;
    return { minX, maxX };
  };

  // 현재 x축 범위가 "초기 전체 범위"와 같은지 비교
  // - fullXRange가 아직 없거나 읽기에 실패하면 null 반환
  // - null이면 나중에 마커 개수 기반 fallback 사용
  const isFullViewByRange = () => {
    if (!fullXRange) return null;

    const cur = readXRangeFromChart(monthlyAreaChart);
    if (!cur) return null;

    return (
      Math.abs(cur.minX - fullXRange.minX) < X_EPS &&
      Math.abs(cur.maxX - fullXRange.maxX) < X_EPS
    );
  };

  // ---------------------------------------------------------
  // 배지를 즉시 숨기는 함수
  // ---------------------------------------------------------
  // 줌/스크롤 입력 직후 잠깐 위치가 튀는 현상을 막기 위해 먼저 숨기고,
  // 이후 queueMonthlyBadgeSync()에서 다시 전체뷰 여부를 판정해 표시/숨김 결정
  const hideMonthlyBadgesNow = () => {
    const host = document.querySelector('#chart-monthly-area');
    if (!host) return;

    ensureMonthlyOverlay(host);
    setMonthlyOverlayVisible(host, false);
  };

  // ---------------------------------------------------------
  // 배지 정렬 기준(가로/세로) 결정
  // ---------------------------------------------------------
  // x축 기준:
  // - 왼쪽 끝(1~2월 근처): left 정렬
  // - 오른쪽 끝(11~12월 근처): right 정렬
  // - 나머지 중앙: center 정렬
  //
  // 이유:
  // - 끝쪽 포인트에서 center 정렬을 쓰면 화면 밖으로 잘릴 가능성이 커짐
  const decideAnchorX = (idx) => {
    if (idx <= 1) return 'left';
    if (idx >= 10) return 'right';
    return 'center';
  };

  // y축 기준:
  // - 포인트가 너무 위쪽이면 배지를 아래쪽으로 내림
  // - 그렇지 않으면 일반적으로 위쪽에 띄움
  const decideAnchorY = (y) => {
    return (y < 34) ? 'down' : 'up';
  };

  // anchor 결과를 실제 transform으로 적용
  // - left/center/right + up/down 조합을 CSS translate로 매핑
  const applyBadgeTransform = (badgeEl, ax, ay) => {
    let tx = '-50%';    // center 기본값
    if (ax === 'left') tx = '0%';
    if (ax === 'right') tx = '-100%';

    const ty = (ay === 'down') ? '30%' : '-135%';

    badgeEl.style.transform = 'translate(' + tx + ', ' + ty + ')';
  };

  // ---------------------------------------------------------
  // 특정 월 인덱스(idx)의 마커 위치에 배지 배치
  // ---------------------------------------------------------
  // 마커 DOM 좌표를 host 기준 좌표로 변환해서 badgeEl.left/top에 반영한다.
  const placeBadgeAtIndex = (host, badgeEl, idx) => {
    const markers = getMarkerNodes(host);
    const marker = markers && markers[idx] ? markers[idx] : null;

    if (!marker) {
      // 마커를 못 찾는 경우 배지를 숨겨서 잘못된 위치 표시 방지
      badgeEl.style.display = 'none';
      return;
    }

    const hostRect = host.getBoundingClientRect();
    const mRect = marker.getBoundingClientRect();

    // host 기준 좌표계로 변환 (overlay도 host 내부에 absolute 배치되므로 좌표계 통일)
    const x = (mRect.left - hostRect.left) + (mRect.width / 2);
    const y = (mRect.top - hostRect.top) + (mRect.height / 2);

    const ax = decideAnchorX(idx);
    const ay = decideAnchorY(y);

    applyBadgeTransform(badgeEl, ax, ay);

    badgeEl.style.display = 'inline-flex';
    badgeEl.style.left = x + 'px';
    badgeEl.style.top = y + 'px';
  };

  // ---------------------------------------------------------
  // 최고/최저 배지 텍스트 + 위치 동기화
  // ---------------------------------------------------------
  // requestAnimationFrame을 2번 쓰는 이유:
  // - 차트 업데이트 직후 바로 마커 좌표를 읽으면 아직 layout/paint가 안정되지 않은 타이밍이 있음
  // - 두 번 넘겨서 DOM/렌더 완료 이후 좌표를 읽게 하려는 안정화 목적
  const syncMonthlyBadges = (host, mm) => {
    if (!host || !mm) return;

    const parts = ensureMonthlyOverlay(host);
    const maxBadge = parts.maxBadge;
    const minBadge = parts.minBadge;

    maxBadge.textContent = '최고 ' + toManText(mm.maxVal);
    minBadge.textContent = '최저 ' + toManText(mm.minVal);

    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        placeBadgeAtIndex(host, maxBadge, mm.maxIdx);

        // 최고/최저가 같은 포인트면 배지 2개가 겹치므로 최저 배지는 숨김
        if (mm.minIdx !== mm.maxIdx) {
          placeBadgeAtIndex(host, minBadge, mm.minIdx);
        } else {
          minBadge.style.display = 'none';
        }
      });
    });
  };

  // ---------------------------------------------------------
  // 배지 동기화 큐(재시도 포함)
  // ---------------------------------------------------------
  // 역할:
  // - 차트 렌더/업데이트/리사이즈/줌 이후에 "한 번에" 배지 갱신 타이밍 잡기
  // - 마커 DOM이 아직 준비 안 된 경우 몇 번 재시도
  let _badgeSyncRaf = 0;
  let _badgeSyncRetry = 0;
  const BADGE_SYNC_RETRY_MAX = 8;

  const queueMonthlyBadgeSync = () => {
    // 같은 프레임 안에서 여러 번 호출돼도 마지막 요청만 살아남게 함
    cancelAnimationFrame(_badgeSyncRaf);

    _badgeSyncRaf = requestAnimationFrame(() => {
      const host = document.querySelector('#chart-monthly-area');
      if (!host || !lastMM) return;

      ensureMonthlyOverlay(host);

      const markers = getMarkerNodes(host);
      const markerReady = markers && markers.length >= 12;

      // 마커 DOM이 아직 준비되지 않은 경우
      // - 배지는 숨기고
      // - 짧은 간격으로 몇 번 재시도
      if (!markerReady) {
        setMonthlyOverlayVisible(host, false);

        if (_badgeSyncRetry < BADGE_SYNC_RETRY_MAX) {
          _badgeSyncRetry++;
          setTimeout(queueMonthlyBadgeSync, 40);
        }
        return;
      }

      _badgeSyncRetry = 0;

      // 전체 뷰 판정 우선순위
      // 1) x축 범위 비교 (더 정확)
      // 2) 실패 시 마커 가시 개수 기반 fallback
      const fullByRange = isFullViewByRange();
      const isFull = (fullByRange === null)
        ? isMonthlyFullView(host)
        : fullByRange;

      // 전체 12개월 뷰가 아니면 배지는 숨긴다.
      // (줌 상태에서 일부 포인트만 보일 때 배지 위치가 UX상 혼란스럽기 때문)
      if (!isFull) {
        setMonthlyOverlayVisible(host, false);
        return;
      }

      // 전체 뷰일 때만 배지 표시 + 좌표 재배치
      setMonthlyOverlayVisible(host, true);
      syncMonthlyBadges(host, lastMM);
    });
  };

  // ---------------------------------------------------------
  // 월별 Area 차트 옵션 생성
  // ---------------------------------------------------------
  // 연도와 12개월 데이터를 받아 ApexCharts 옵션 객체를 만든다.
  const buildMonthlyAreaOptions = (year, data) => {
    const yAxis = calcYAxis(data);
    const mm = computeMinMax(data);

    // 최고/최저 포인트를 discrete marker로 한 번 더 강조
    // (기본 markers + 특정 포인트 강조)
    const discreteMarkers = [];

    if (mm.maxIdx >= 0) {
      discreteMarkers.push({
        seriesIndex: 0,
        dataPointIndex: mm.maxIdx,
        size: 6,
        fillColor: '#ffffff',
        strokeColor: '#1e88ff',
        strokeWidth: 2
      });
    }

    if (mm.minIdx >= 0 && mm.minIdx !== mm.maxIdx) {
      discreteMarkers.push({
        seriesIndex: 0,
        dataPointIndex: mm.minIdx,
        size: 6,
        fillColor: '#ffffff',
        strokeColor: '#64748b',
        strokeWidth: 2
      });
    }

    return {
      series: [
        { name: year + '년', data: data }
      ],

      chart: {
        type: 'area',
        height: 320,
        fontFamily: 'inherit',
        toolbar: { show: false },

        // 차트 생명주기 이벤트
        // - 배지 표시/숨김/재배치 타이밍을 여기서 제어
        events: {
          mounted: function (chartContext) {
            // 최초 마운트 시점의 x축 범위를 "전체 뷰 기준값"으로 저장
            // 이후 zoom/reset 시 전체 복귀 판정에 사용
            if (!fullXRange) {
              const r = readXRangeFromCtx(chartContext);
              if (r) fullXRange = r;
            }

            queueMonthlyBadgeSync();
          },

          updated: function () {
            // updateSeries / updateOptions 이후
            queueMonthlyBadgeSync();
          },

          zoomed: function () {
            // 줌 직후에는 먼저 숨기고, 다음 틱에서 상태 재판정
            hideMonthlyBadgesNow();
            setTimeout(queueMonthlyBadgeSync, 0);
          },

          scrolled: function () {
            // 드래그/스크롤(팬)도 동일 처리
            hideMonthlyBadgesNow();
            setTimeout(queueMonthlyBadgeSync, 0);
          },

          beforeResetZoom: function () {
            // resetZoom 직전에 잠깐 숨겨서 UI 튐 방지
            hideMonthlyBadgesNow();
          },

          animationEnd: function () {
            // 차트 애니메이션 종료 후 좌표 안정화 타이밍
            queueMonthlyBadgeSync();
          }
        }
      },

      // 배지(오버레이)가 차트 상단에 뜰 공간을 확보하려고 top padding을 크게 둠
      grid: {
        padding: { top: 58, right: 18, left: 52, bottom: 0 }
      },

      colors: ['#1e88ff'],
      dataLabels: { enabled: false },
      stroke: { curve: 'smooth', width: 2 },

      markers: {
        size: 2,
        hover: { size: 5 },
        discrete: discreteMarkers
      },

      xaxis: {
        categories: months,
        axisBorder: { show: false },
        axisTicks: { show: false }
      },

      yaxis: {
        min: yAxis.min,
        max: yAxis.max,
        tickAmount: yAxis.tickAmount,
        labels: {
          offsetX: -8,
          formatter: function (val) {
            return Math.round(val / 10000) + '만';
          }
        }
      },

      tooltip: {
        y: {
          formatter: function (val) {
            return '₩ ' + Number(val).toLocaleString();
          }
        }
      }
    };
  };

  // ---------------------------------------------------------
  // 월별 차트 렌더/업데이트 함수
  // ---------------------------------------------------------
  // - 첫 호출: ApexCharts 인스턴스 생성 + render()
  // - 이후 호출: resetZoom -> updateSeries -> updateOptions 순으로 갱신
  const renderMonthly = (year) => {
    const host = document.querySelector('#chart-monthly-area');
    if (!host) return;

    const data = monthlyByYear[year]
      ? normalizeMonthly(monthlyByYear[year])
      : new Array(12).fill(0);

    const opts = buildMonthlyAreaOptions(year, data);

    // 현재 차트 데이터 기준 최고/최저 정보 저장
    // 이후 배지 sync에서 참조
    lastMM = computeMinMax(data);

    // ---------- 첫 렌더 ----------
    if (!monthlyAreaChart) {
      host.innerHTML = '';

      monthlyAreaChart = new ApexCharts(host, opts);

      monthlyAreaChart.render().then(() => {
        // 최초 render 완료 후 차트 인스턴스에서 전체 x범위 저장 (한 번 더 보강)
        const r = readXRangeFromChart(monthlyAreaChart);
        if (r) fullXRange = r;

        queueMonthlyBadgeSync();
      });

      return;
    }

    // ---------- 업데이트 렌더 ----------
    // 차트 업데이트 중 배지가 기존 위치에 남아 있으면 튀어 보이므로 먼저 숨김
    hideMonthlyBadgesNow();

    try {
      // 이전 줌 상태가 남아 있으면 새 연도 데이터에서도 축 범위가 좁게 보일 수 있어
      // 업데이트 전에 전체뷰로 리셋
      if (typeof monthlyAreaChart.resetZoom === 'function') {
        monthlyAreaChart.resetZoom();
      }
    } catch (e) {
      // resetZoom 지원 여부/시점 문제로 실패해도 전체 동작은 계속 진행
    }

    // series 먼저 갱신
    monthlyAreaChart.updateSeries(opts.series, true);

    // updateOptions에는 series 제외 나머지 옵션만 전달
    // (불필요한 중복 갱신 감소)
    const rest = Object.assign({}, opts);
    delete rest.series;

    const p = monthlyAreaChart.updateOptions(rest, true, true);

    const afterUpdate = () => {
      // 업데이트 후 현재 전체 x범위를 다시 저장
      // (연도 전환/옵션 변경 후 기준 범위가 달라질 수 있음)
      const r = readXRangeFromChart(monthlyAreaChart);
      if (r) fullXRange = r;

      queueMonthlyBadgeSync();
    };

    // ApexCharts 버전에 따라 Promise를 반환할 수도/안 할 수도 있어 둘 다 대응
    if (p && typeof p.then === 'function') {
      p.then(afterUpdate);
    } else {
      setTimeout(afterUpdate, 0);
    }
  };

  // 초기 렌더는 서버에서 받은 vm.year 기준
  renderMonthly(Number(vm.year || initYear));

  // =========================================================
  // 4) 연도 선택(select#yearSelect) 변경 이벤트
  // =========================================================
  // 정책:
  // - 상단 KPI(이번달/전월/수단비율)는 초기 month 컨셉 유지
  // - 연도 select는 월별 그래프 데이터만 바꿔서 보여줌
  const yearSelect = document.getElementById('yearSelect');
  if (yearSelect) {
    // 서버 응답 기준 연도를 select 값에 동기화
    yearSelect.value = String(vm.year);

    yearSelect.addEventListener('change', async function () {
      const year = Number(this.value);

      // 캐시에 없을 때만 서버 요청
      if (!monthlyByYear[year]) {
        try {
          // month는 현재 KPI 컨셉에 맞춰 vm.month 유지
          const apiY = await fetchDashboard(year, vm.month);
          const vmY = toVM(apiY, year, vm.month);

          monthlyByYear[year] = normalizeMonthly(vmY.monthlyTotals);
        } catch (e) {
          console.error(e);

          // 실패해도 그래프 자체는 유지되도록 0값 배열로 fallback
          monthlyByYear[year] = new Array(12).fill(0);
        }
      }

      renderMonthly(year);

      // 현재 선택된 연도 상태만 vm에 반영
      // (상단 KPI 재렌더는 하지 않음)
      vm.year = year;
    });
  }

  // =========================================================
  // 5) 리사이즈 / 뷰포트 변화 / 브라우저 줌 입력 처리
  // =========================================================
  // 목적:
  // - 차트가 다시 레이아웃되면 마커 좌표가 바뀌므로 배지 위치도 재동기화 필요
  let _resizeTimer = null;

  window.addEventListener('resize', () => {
    // resize 연속 발생 시 너무 자주 계산하지 않도록 디바운스
    clearTimeout(_resizeTimer);
    _resizeTimer = setTimeout(() => {
      queueMonthlyBadgeSync();
    }, 80);
  });

  // 모바일/브라우저 확대축소 환경에서 visualViewport 변화도 감지
  // - 일반 resize만으로는 잡히지 않는 케이스 보완
  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', queueMonthlyBadgeSync);
    window.visualViewport.addEventListener('scroll', queueMonthlyBadgeSync);
  }

  // Ctrl(Windows) / Cmd(Mac) + Wheel 브라우저 줌 감지
  // - 사용자가 브라우저 확대/축소를 하면 차트와 overlay 좌표가 순간적으로 어긋날 수 있음
  // - 먼저 숨기고, 다음 틱에 다시 전체뷰 여부를 판단해서 복구
  window.addEventListener(
    'wheel',
    (e) => {
      if (e.ctrlKey || e.metaKey) {
        hideMonthlyBadgesNow();
        setTimeout(queueMonthlyBadgeSync, 0);
      }
    },
    { passive: true }
  );
})();