/* =========================================================
   AniMale Admin Dashboard (Cash)
   - JSP: #text-*, #chart-* 아이디에 렌더링
   - ApexCharts 사용
   - ✅ 변경: 더미 vm 제거 + 서버 API 연동
   - ✅ 변경: vm을 fetch로 받은 뒤에만 렌더링(텍스트/차트) 실행
   - 월별 그래프: 최고/최저 라벨을 SVG annotation 대신 HTML 오버레이로 표시
   - [요구 반영] 줌/스크롤(휠 확대 포함) 입력이 발생하면 라벨 즉시 숨김
               최대치로 축소(=전체 12개월 뷰)로 돌아오면 다시 표시
   - y축: 100만 단위 통일
   ========================================================= */

(async function () { // ✅ 변경: async IIFE (await fetch 필요)
  // =========================================================
  // 0) 서버 API 호출 + 응답을 vm 형태로 변환(toVM)
  // =========================================================
  // JSP에서 아래 2개를 세팅해둔 상태를 전제로 함:
  // - window.APP_CTX  : 컨텍스트 경로 (예: /animale)
  // - window.DASH_INIT: 초기 조회 기준값 (year/month)
  const APP_CTX = window.APP_CTX || '';
  const INIT = window.DASH_INIT || {};

  const initYear = Number(INIT.year || new Date().getFullYear());
  const initMonth = Number(INIT.month || (new Date().getMonth() + 1));

  // ✅ 변경: 서버 API 호출 함수
  // - year/month 파라미터를 쿼리스트링으로 전달
  // - 응답은 JSON
  const fetchDashboard = async (year, month) => {
    const qs = new URLSearchParams({ year: String(year), month: String(month) });
    const url = APP_CTX + '/api/admin/cash/admindashboard?' + qs.toString();

    const res = await fetch(url, { headers: { Accept: 'application/json' } });
    if (!res.ok) throw new Error('dashboard api failed: ' + res.status);

    return res.json();
  };

  // ✅ 변경: API 응답(JSON) -> 기존 프론트 렌더링이 기대하는 vm 형태로 통일
  // - 서버가 어떤 필드명을 쓰든, 여기서 "프론트 표준(vm)"으로 변환해두면
  //   아래 렌더링/차트 코드는 거의 수정 없이 유지할 수 있음.
  const toVM = (api, fallbackYear, fallbackMonth) => {
    const year = Number(api.year ?? fallbackYear);
    const month = Number(api.month ?? fallbackMonth);

    const thisMonthTotal = Number(api.thisMonthTotal ?? 0);
    const lastMonthTotal = (api.lastMonthTotal == null) ? null : Number(api.lastMonthTotal);

    // JSP에 표시 영역이 있는 값들(없으면 0으로 방어)
    const thisMonthCount = Number(api.thisMonthCount ?? 0);
    const lastMonthCount = (api.lastMonthCount == null) ? null : Number(api.lastMonthCount);
    const dailyAvg = Number(api.dailyAvg ?? 0);

    // momPercent: 서버가 내려주면 우선 사용, 없으면 아래 로직에서 JS 계산 가능
    const momPercent = (api.momPercent == null) ? null : Number(api.momPercent);

    // providerList 예시:
    // [{ provider:'KAKAOPAY', cashAmount:합계 }, { provider:'TOSSPAY', cashAmount:합계 }]
    let kakaoAmount = 0;
    let tossAmount = 0;

    const providerList = Array.isArray(api.providerList) ? api.providerList : [];
    for (const row of providerList) {
      const provider = String(row.provider ?? '');
      const amount = Number(row.cashAmount ?? 0);

      if (provider === 'KAKAOPAY') kakaoAmount = amount;
      if (provider === 'TOSSPAY') tossAmount = amount;
    }

    // 퍼센트는 "이번달 총액(thisMonthTotal)" 기준
    // - 둘만 쓰는 UI라서 합 100이 되도록 토스는 보정(100 - 카카오)
    let kakaoPercent = 0;
    let tossPercent = 0;
    if (thisMonthTotal > 0) {
      kakaoPercent = Math.round((kakaoAmount * 100) / thisMonthTotal);
      tossPercent = Math.max(0, 100 - kakaoPercent);
    }

    // yearMonthly 예시:
    // [{ month:1, cashAmount:합계 }, ...]
    // -> 12칸 배열(monthlyTotals)로 변환
    const monthlyTotals = new Array(12).fill(0);
    const yearMonthly = Array.isArray(api.yearMonthly) ? api.yearMonthly : [];

    for (const row of yearMonthly) {
      const m = Number(row.month);
      const amount = Number(row.cashAmount ?? 0);
      if (m >= 1 && m <= 12) monthlyTotals[m - 1] = amount;
    }

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

      // 수단별 금액(툴팁에서 사용)
      kakaoAmount,
      tossAmount,

      // 월별 합계(Area chart에서 사용)
      monthlyTotals
    };
  };

  // ✅ 변경: vm을 서버에서 받아온 뒤에만 아래 렌더링 로직이 실행되도록 구성
  let vm;
  try {
    const api = await fetchDashboard(initYear, initMonth);
    vm = toVM(api, initYear, initMonth);
  } catch (e) {
    console.error(e);
    // 서버가 아직 준비 안 됐거나 에러가 나도 화면이 완전히 죽지 않게 최소 fallback
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
  // 공통 유틸
  // =========================================================
  const setText = (id, text) => {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
  };

  const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

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
  // 텍스트 영역 렌더링(금액/퍼센트)
  // =========================================================
  setText('text-kakao', String(vm.kakaoPercent) + '%');
  setText('text-toss', String(vm.tossPercent) + '%');

  // JSP에 이미 존재하는 영역도 서버값으로 채움(없으면 0)
  setText('text-charge-count', String(Number(vm.thisMonthCount ?? 0)) + '건');
  setText('text-daily-avg', '₩ ' + Number(vm.dailyAvg ?? 0).toLocaleString());

  // =========================================================
  // 1) 전월 대비 원형(라디얼) 차트
  // - 감소면 라디얼 색 down으로 변경
  // - 전월 0원/전월 데이터 없음이면 퍼센트 계산 대신 상태 문구 표시
  // =========================================================
  const thisMonthTotal = Number(vm.thisMonthTotal ?? 0);
  const lastMonthTotal = (vm.lastMonthTotal == null) ? null : Number(vm.lastMonthTotal);
  const lastMonthCount = (vm.lastMonthCount == null) ? null : Number(vm.lastMonthCount);

  // 전월 상태 판정
  // - count가 있으면 count 기준으로 "전월 데이터 유무"를 판정
  // - count가 없으면 total이 null인지 여부로 판정
  const hasPrevData = (lastMonthCount != null) ? (lastMonthCount > 0) : (lastMonthTotal != null);
  const prevIsZero = (lastMonthTotal === 0);

  // momPercent 최종 결정
  // 1) 서버가 momPercent를 내려주면 우선 사용
  // 2) 없으면 lastMonthTotal > 0일 때만 JS로 계산
  let momPercent = (vm.momPercent == null) ? null : Number(vm.momPercent);
  if (!Number.isFinite(momPercent)) momPercent = null;

  if (momPercent == null) {
    if (lastMonthTotal != null && Number.isFinite(lastMonthTotal) && lastMonthTotal > 0) {
      momPercent = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
    } else {
      momPercent = null;
    }
  }

  // 배지/색상 상태값
  const momEl = document.getElementById('text-mom');

  const setMomBadge = (text, state) => {
    setText('text-mom', text);

    if (!momEl) return;
    momEl.classList.remove('badge-up', 'badge-down', 'badge-neutral');

    if (state === 'up') momEl.classList.add('badge-up');
    else if (state === 'down') momEl.classList.add('badge-down');
    else momEl.classList.add('badge-neutral');
  };

  // 라디얼 색상
  const COLOR_UP = '#1e88ff';
  const COLOR_DOWN = '#d61f69';
  const COLOR_NEUTRAL = '#94a3b8';

  // 배지 텍스트/상태 결정
  let radialColor = COLOR_UP;
  let ringValue = 0;
  let momTextForTooltip = '';

  if (momPercent != null && Number.isFinite(momPercent)) {
    const sign = momPercent >= 0 ? '+' : '';
    const rounded = Math.round(momPercent);

    setMomBadge('전월 대비 ' + sign + rounded + '%', momPercent >= 0 ? 'up' : 'down');

    radialColor = (momPercent >= 0) ? COLOR_UP : COLOR_DOWN;
    ringValue = clamp(Math.abs(momPercent), 0, 100);
    momTextForTooltip = sign + rounded + '%';
  } else {
    if (!hasPrevData) {
      setMomBadge('전월 데이터 없음', 'neutral');
      momTextForTooltip = '전월 데이터 없음';
      radialColor = COLOR_NEUTRAL;
      ringValue = 0;
    } else if (prevIsZero) {
      setMomBadge('전월 0원', thisMonthTotal > 0 ? 'up' : 'neutral');

      momTextForTooltip = (thisMonthTotal > 0)
        ? '전월 0원(비교 불가)'
        : '전월 0원';

      radialColor = (thisMonthTotal > 0) ? COLOR_UP : COLOR_NEUTRAL;
      ringValue = (thisMonthTotal > 0) ? 100 : 0;
    } else {
      setMomBadge('전월 대비 계산 불가', 'neutral');
      momTextForTooltip = '계산 불가';
      radialColor = COLOR_NEUTRAL;
      ringValue = 0;
    }
  }

  // 카드 상단 큰 금액 텍스트
  setText('text-this-month', '₩ ' + thisMonthTotal.toLocaleString());

  // tooltip에 표시할 지난달 금액(없으면 0)
  const lastMonthTotalForTooltip =
    (lastMonthTotal != null && Number.isFinite(lastMonthTotal)) ? lastMonthTotal : 0;

  const radialOptions = {
    series: [ringValue],
    chart: {
      type: 'radialBar',
      height: 260,
      width: 260,
      sparkline: { enabled: true },
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
        track: { background: '#e9eef5', strokeWidth: '100%', margin: 0 },
        dataLabels: { name: { show: false }, value: { show: false } }
      }
    },
    tooltip: {
      enabled: true,
      fixed: { enabled: true, position: 'topLeft', offsetX: -6, offsetY: 10 },
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
    radialEl.innerHTML = '';
    new ApexCharts(radialEl, radialOptions).render();
  }

  // =========================================================
  // 2) 충전 수단 비교(100% 가로 스택 1개)
  // =========================================================
  const kakao = clamp(Number(vm.kakaoPercent ?? 0), 0, 100);
  const toss = clamp(Number(vm.tossPercent ?? 0), 0, 100);

  // 수단별 금액은 서버에서 내려준 금액이 있으면 그걸 우선 사용
  // 없으면 퍼센트와 총액을 기반으로 근사 계산
  const methodTotal = Number(vm.thisMonthTotal ?? 0);

  const pctToAmount = (total, pct) => Math.round(total * pct / 100);

  let kakaoAmount = Number(vm.kakaoAmount ?? pctToAmount(methodTotal, kakao));
  let tossAmount = Number(vm.tossAmount ?? (methodTotal - kakaoAmount));
  if (!Number.isFinite(kakaoAmount)) kakaoAmount = 0;
  if (!Number.isFinite(tossAmount) || tossAmount < 0) tossAmount = 0;

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
      stacked: true,
      stackType: '100%',
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
    grid: { show: false, padding: { top: 0, bottom: 0, left: 0, right: 0 } },
    dataLabels: {
      enabled: true,
      formatter: function (val) { return Math.round(val) + '%'; },
      style: { fontSize: '12px', fontWeight: 800, colors: ['#ffffff', '#344054'] }
    },
    xaxis: { max: 100, labels: { show: false }, axisBorder: { show: false }, axisTicks: { show: false } },
    yaxis: { labels: { show: false } },
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
  // 3) 월별 충전금액(에어리어 차트)
  // - 최고/최저 라벨: HTML 오버레이(.monthly-overlay)로 표시
  // - 줌/스크롤 입력이 한번이라도 들어오면 즉시 숨김
  //   최대치로 축소(=전체 12개월 뷰)로 돌아오면 다시 표시
  // - y축: 100만 단위 통일
  // =========================================================
  const months = ['1월','2월','3월','4월','5월','6월','7월','8월','9월','10월','11월','12월'];

  // ✅ 변경: 더미 monthlyByYear 제거 -> 서버 기반 캐시로 전환
  // - 최초 로딩한 연도는 vm.monthlyTotals로 캐시에 넣음
  // - 다른 연도를 선택하면 캐시에 없을 때만 서버에서 받아서 캐시에 저장
  const monthlyByYear = {};
  monthlyByYear[vm.year] = normalizeMonthly(vm.monthlyTotals);

  let monthlyAreaChart = null;
  let lastMM = null;

  const toManText = (v) => {
    const n = Number(v);
    if (!Number.isFinite(n)) return '0만';
    return Math.round(n / 10000) + '만';
  };

  const Y_STEP = 1000000;

  const calcYAxis = (data) => {
    const vals = normalizeMonthly(data).map((x) => Number(x) || 0);
    const maxVal = Math.max(...vals);

    const max = Math.max(Y_STEP, Math.ceil(maxVal / Y_STEP) * Y_STEP);
    const min = 0;
    const tickAmount = Math.round((max - min) / Y_STEP);

    return { min, max, tickAmount };
  };

  const computeMinMax = (data) => {
    const vals = normalizeMonthly(data).map((x) => Number(x) || 0);
    const maxVal = Math.max(...vals);
    const minVal = Math.min(...vals);
    const maxIdx = vals.indexOf(maxVal);
    const minIdx = vals.indexOf(minVal);
    return { vals, maxVal, minVal, maxIdx, minIdx };
  };

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

  const setMonthlyOverlayVisible = (host, visible) => {
    const overlay = host.querySelector('.monthly-overlay');
    if (!overlay) return;
    overlay.style.display = visible ? 'block' : 'none';
  };

  const getMarkerNodes = (host) => {
    let nodes = host.querySelectorAll('.apexcharts-series-markers .apexcharts-marker');
    if (!nodes || nodes.length < 12) {
      nodes = host.querySelectorAll('.apexcharts-marker');
    }
    return nodes;
  };

  const getPlotRect = (host) => {
    const plot =
      host.querySelector('.apexcharts-inner') ||
      host.querySelector('.apexcharts-plot-series') ||
      host.querySelector('.apexcharts-grid') ||
      host;

    return plot.getBoundingClientRect();
  };

  const countVisibleMarkersInPlot = (host) => {
    const markers = getMarkerNodes(host);
    if (!markers || markers.length === 0) return 0;

    const hostRect = host.getBoundingClientRect();
    const plotRect = getPlotRect(host);

    const left = plotRect.left - hostRect.left;
    const right = plotRect.right - hostRect.left;
    const top = plotRect.top - hostRect.top;
    const bottom = plotRect.bottom - hostRect.top;

    const margin = 2;
    let count = 0;

    const n = Math.min(markers.length, 12);
    for (let i = 0; i < n; i++) {
      const r = markers[i].getBoundingClientRect();
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

  const isMonthlyFullView = (host) => {
    return countVisibleMarkersInPlot(host) >= 12;
  };

  let fullXRange = null;
  const X_EPS = 0.0001;

  const readXRangeFromCtx = (ctx) => {
    if (!ctx || !ctx.w || !ctx.w.globals) return null;
    const minX = ctx.w.globals.minX;
    const maxX = ctx.w.globals.maxX;
    if (!Number.isFinite(minX) || !Number.isFinite(maxX)) return null;
    return { minX, maxX };
  };

  const readXRangeFromChart = (chart) => {
    if (!chart || !chart.w || !chart.w.globals) return null;
    const minX = chart.w.globals.minX;
    const maxX = chart.w.globals.maxX;
    if (!Number.isFinite(minX) || !Number.isFinite(maxX)) return null;
    return { minX, maxX };
  };

  const isFullViewByRange = () => {
    if (!fullXRange) return null;
    const cur = readXRangeFromChart(monthlyAreaChart);
    if (!cur) return null;

    return (
      Math.abs(cur.minX - fullXRange.minX) < X_EPS &&
      Math.abs(cur.maxX - fullXRange.maxX) < X_EPS
    );
  };

  const hideMonthlyBadgesNow = () => {
    const host = document.querySelector('#chart-monthly-area');
    if (!host) return;

    ensureMonthlyOverlay(host);
    setMonthlyOverlayVisible(host, false);
  };

  const decideAnchorX = (idx) => {
    if (idx <= 1) return 'left';
    if (idx >= 10) return 'right';
    return 'center';
  };

  const decideAnchorY = (y) => {
    return (y < 34) ? 'down' : 'up';
  };

  const applyBadgeTransform = (badgeEl, ax, ay) => {
    let tx = '-50%';
    if (ax === 'left') tx = '0%';
    if (ax === 'right') tx = '-100%';

    const ty = (ay === 'down') ? '30%' : '-135%';
    badgeEl.style.transform = 'translate(' + tx + ', ' + ty + ')';
  };

  const placeBadgeAtIndex = (host, badgeEl, idx) => {
    const markers = getMarkerNodes(host);
    const marker = markers && markers[idx] ? markers[idx] : null;

    if (!marker) {
      badgeEl.style.display = 'none';
      return;
    }

    const hostRect = host.getBoundingClientRect();
    const mRect = marker.getBoundingClientRect();

    const x = (mRect.left - hostRect.left) + (mRect.width / 2);
    const y = (mRect.top - hostRect.top) + (mRect.height / 2);

    const ax = decideAnchorX(idx);
    const ay = decideAnchorY(y);
    applyBadgeTransform(badgeEl, ax, ay);

    badgeEl.style.display = 'inline-flex';
    badgeEl.style.left = x + 'px';
    badgeEl.style.top = y + 'px';
  };

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

        if (mm.minIdx !== mm.maxIdx) {
          placeBadgeAtIndex(host, minBadge, mm.minIdx);
        } else {
          minBadge.style.display = 'none';
        }
      });
    });
  };

  let _badgeSyncRaf = 0;
  let _badgeSyncRetry = 0;
  const BADGE_SYNC_RETRY_MAX = 8;

  const queueMonthlyBadgeSync = () => {
    cancelAnimationFrame(_badgeSyncRaf);

    _badgeSyncRaf = requestAnimationFrame(() => {
      const host = document.querySelector('#chart-monthly-area');
      if (!host || !lastMM) return;

      ensureMonthlyOverlay(host);

      const markers = getMarkerNodes(host);
      const markerReady = markers && markers.length >= 12;

      if (!markerReady) {
        setMonthlyOverlayVisible(host, false);
        if (_badgeSyncRetry < BADGE_SYNC_RETRY_MAX) {
          _badgeSyncRetry++;
          setTimeout(queueMonthlyBadgeSync, 40);
        }
        return;
      }

      _badgeSyncRetry = 0;

      const fullByRange = isFullViewByRange();
      const isFull =
        (fullByRange === null)
          ? isMonthlyFullView(host)
          : fullByRange;

      if (!isFull) {
        setMonthlyOverlayVisible(host, false);
        return;
      }

      setMonthlyOverlayVisible(host, true);
      syncMonthlyBadges(host, lastMM);
    });
  };

  const buildMonthlyAreaOptions = (year, data) => {
    const yAxis = calcYAxis(data);
    const mm = computeMinMax(data);

    // 최대/최저 마커 강조(원형 포인트)
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
      series: [{ name: year + '년', data: data }],
      chart: {
        type: 'area',
        height: 320,
        fontFamily: 'inherit',
        toolbar: { show: false },
        events: {
          mounted: function (chartContext) {
            if (!fullXRange) {
              const r = readXRangeFromCtx(chartContext);
              if (r) fullXRange = r;
            }
            queueMonthlyBadgeSync();
          },

          updated: function () {
            queueMonthlyBadgeSync();
          },

          zoomed: function () {
            hideMonthlyBadgesNow();
            setTimeout(queueMonthlyBadgeSync, 0);
          },

          scrolled: function () {
            hideMonthlyBadgesNow();
            setTimeout(queueMonthlyBadgeSync, 0);
          },

          beforeResetZoom: function () {
            hideMonthlyBadgesNow();
          },

          animationEnd: function () {
            queueMonthlyBadgeSync();
          }
        }
      },

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
          formatter: function (val) { return Math.round(val / 10000) + '만'; }
        }
      },

      tooltip: {
        y: {
          formatter: function (val) { return '₩ ' + Number(val).toLocaleString(); }
        }
      }
    };
  };

  const renderMonthly = (year) => {
    const host = document.querySelector('#chart-monthly-area');
    if (!host) return;

    const data = monthlyByYear[year]
      ? normalizeMonthly(monthlyByYear[year])
      : new Array(12).fill(0);

    const opts = buildMonthlyAreaOptions(year, data);

    lastMM = computeMinMax(data);

    if (!monthlyAreaChart) {
      host.innerHTML = '';
      monthlyAreaChart = new ApexCharts(host, opts);

      monthlyAreaChart.render().then(() => {
        const r = readXRangeFromChart(monthlyAreaChart);
        if (r) fullXRange = r;

        queueMonthlyBadgeSync();
      });

      return;
    }

    hideMonthlyBadgesNow();

    try {
      if (typeof monthlyAreaChart.resetZoom === 'function') {
        monthlyAreaChart.resetZoom();
      }
    } catch (e) {}

    monthlyAreaChart.updateSeries(opts.series, true);

    const rest = Object.assign({}, opts);
    delete rest.series;

    const p = monthlyAreaChart.updateOptions(rest, true, true);

    const afterUpdate = () => {
      const r = readXRangeFromChart(monthlyAreaChart);
      if (r) fullXRange = r;

      queueMonthlyBadgeSync();
    };

    if (p && typeof p.then === 'function') {
      p.then(afterUpdate);
    } else {
      setTimeout(afterUpdate, 0);
    }
  };

  // 최초 렌더: 서버에서 받은 vm.year 기준
  renderMonthly(Number(vm.year || initYear));

  // =========================================================
  // 4) 연도 선택 변경 이벤트
  // - ✅ 변경: 캐시에 없으면 서버에서 해당 연도 월별 데이터만 받아서 monthlyByYear에 저장
  // - 상단 KPI(이번달/전월대비/수단비율)는 "초기 month 기준"으로 유지(기존 컨셉)
  // =========================================================
  const yearSelect = document.getElementById('yearSelect');
  if (yearSelect) {
    yearSelect.value = String(vm.year);

    yearSelect.addEventListener('change', async function () { // ✅ 변경: async
      const year = Number(this.value);

      // 캐시에 없으면: 해당 연도 데이터만 서버에서 받아서 월별 그래프용으로 저장
      if (!monthlyByYear[year]) {
        try {
          // month는 기존 컨셉대로 '초기 month' 유지 (월별 그래프만 교체)
          const apiY = await fetchDashboard(year, vm.month);
          const vmY = toVM(apiY, year, vm.month);

          monthlyByYear[year] = normalizeMonthly(vmY.monthlyTotals);
        } catch (e) {
          console.error(e);
          // API 실패 시 0으로라도 그래프는 그리게 처리
          monthlyByYear[year] = new Array(12).fill(0);
        }
      }

      renderMonthly(year);
      vm.year = year; // 현재 선택 연도 상태만 갱신
    });
  }

  // =========================================================
  // 5) 리사이즈/줌 이벤트 처리(배지 위치 동기화)
  // =========================================================
  let _resizeTimer = null;
  window.addEventListener('resize', () => {
    clearTimeout(_resizeTimer);
    _resizeTimer = setTimeout(() => {
      queueMonthlyBadgeSync();
    }, 80);
  });

  // 모바일/줌 환경에서 viewport 변화 감지
  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', queueMonthlyBadgeSync);
    window.visualViewport.addEventListener('scroll', queueMonthlyBadgeSync);
  }

  // Ctrl(Win)/Cmd(Mac) + Wheel 확대/축소 시 즉시 숨김 -> 전체뷰로 돌아오면 다시 표시
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
