(function () {
  // =========================================================
  // 더미 데이터(ViewModel)
  // - 추후 서버에서 Model로 내려주거나, fetch로 받아서 교체하면 됨
  // =========================================================
  const vm = {
    year: 2026,

    thisMonthTotal: 5600000, // 이번달 충전금액(원)
    momPercent: 36,          // 전월 대비 증감률(%)  +면 상승 / -면 하락

    kakaoPercent: 58,        // 결제수단 비중(%)
    tossPercent: 42,

    // (선택) 지난달 금액을 서버에서 내려줄 수 있으면 가장 정확함
    // lastMonthTotal: 4120000,

    // 1~12월 월별 충전금액(원)
    monthlyTotals: [
      1200000, 1800000, 2400000, 2100000, 2700000, 3100000,
      2900000, 3300000, 2800000, 3600000, 4100000, 4500000
    ]
  };

  // =========================================================
  // 텍스트 영역 렌더링(금액/퍼센트)
  // - JSP의 id(#text-this-month, #text-mom...)에 주입
  // =========================================================
  const setText = (id, text) => {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
  };

  // 이번달 금액 표시
  setText('text-this-month', '₩ ' + Number(vm.thisMonthTotal).toLocaleString());

  // 전월 대비 표시(+/- 기호 포함)
  const momSign = vm.momPercent >= 0 ? '+' : '';
  setText('text-mom', '전월 대비 ' + momSign + Math.round(vm.momPercent) + '%');

  // 전월 대비 배지 색상 토글(상승: 초록 / 하락: 핑크)
  const momEl = document.getElementById('text-mom');
  if (momEl) {
    momEl.classList.remove('badge-up', 'badge-down');
    momEl.classList.add(vm.momPercent >= 0 ? 'badge-up' : 'badge-down');
  }

  // 수단별 퍼센트 텍스트
  setText('text-kakao', String(vm.kakaoPercent) + '%');
  setText('text-toss', String(vm.tossPercent) + '%');

  // =========================================================
  // 1) 전월 대비 원형(라디얼) 차트
  // - 중앙 텍스트 제거(깔끔)
  // - hover 시 커스텀 툴팁으로 지난달/이번달/증감 표시
  // =========================================================

  // 안전한 증감률(숫자 보정)
  const safeMom = Number(vm.momPercent ?? 0);

  // 지난달 금액(선택)
  // - 서버에서 lastMonthTotal을 내려주면 그대로 사용
  // - 없으면 momPercent 기반으로 역산(0/음수 극단값 방어)
  let lastMonthTotal = vm.lastMonthTotal;

  if (lastMonthTotal == null) {
    const denom = 1 + (safeMom / 100);
    lastMonthTotal = (denom <= 0) ? 0 : Math.round(vm.thisMonthTotal / denom);
  }

  // 링에 표시할 값(0~100)
  // - momPercent가 100을 넘거나 음수여도 안전하게 clamp
  const ringValue = Math.max(0, Math.min(100, Math.abs(safeMom)));

  const radialOptions = {
    series: [ringValue],
    chart: {
      type: 'radialBar',
      height: 260,
	  width: 260,
      sparkline: { enabled: true }, // 축/여백 최소화(위젯 느낌)
    },
    colors: ['#1e88ff'], // 포인트 컬러(파랑)
    plotOptions: {
      radialBar: {
        // hollow size가 작아질수록 링이 두꺼워짐
        hollow: { size: '40%' },

        // 배경 링(회색 트랙)
        track: {
          background: '#e9eef5',
          strokeWidth: '100%',
          margin: 0
        },

        // 중앙 텍스트는 제거(깔끔하게)
        dataLabels: {
          name: { show: false },
          value: { show: false }
        }
      }
    },

    // 커스텀 tooltip: hover 시 상세 비교 제공
    tooltip: {
      enabled: true,
	  fixed: {
	    enabled: true,
	    position: 'topLeft',
	    offsetX: -6,
	    offsetY: 10
	  },
      custom: function () {
        const sign = safeMom >= 0 ? '+' : '';
        const momText = sign + Math.round(safeMom) + '%';

        // 주의: bootstrap .row 충돌 방지 → tt-row 사용
        return `
          <div class="dash-tooltip">
            <div class="tt-row"><span class="label">지난달</span><span class="value">₩ ${Number(lastMonthTotal).toLocaleString()}</span></div>
            <div class="tt-row"><span class="label">이번달</span><span class="value">₩ ${Number(vm.thisMonthTotal).toLocaleString()}</span></div>
            <div class="tt-row"><span class="label">증감</span><span class="value">${momText}</span></div>
          </div>
        `;
      }
    }
  };

  // 원형 차트 렌더링(중요)
  const radialEl = document.querySelector('#chart-mom-radial');
  if (radialEl) new ApexCharts(radialEl, radialOptions).render();

  // =========================================================
  // 2) 충전 수단 비교(100% 가로 스택 1개)
  // - 하나의 막대(총합 100%) 안에서 카카오/토스 비율이 나뉘어 보이도록
  // - 퍼센트 차이가 직관적으로 보이게 개선
  // =========================================================
  const kakao = Math.max(0, Math.min(100, Number(vm.kakaoPercent ?? 0)));
  const toss = Math.max(0, Math.min(100, Number(vm.tossPercent ?? 0)));

  const methodBarOptions = {
    series: [
      { name: '카카오페이', data: [kakao] },
      { name: '토스페이', data: [toss] }
    ],
    chart: {
      type: 'bar',
      height: 120,
      stacked: true,
      stackType: '100%',
      sparkline: { enabled: true },
      fontFamily: 'inherit'
    },
    colors: ['#1e88ff', '#e9eef5'],
    plotOptions: {
      bar: {
        horizontal: true,
        barHeight: '44%',
        borderRadius: 12,
        borderRadiusWhenStacked: 'all'
      }
    },
    dataLabels: {
      enabled: true,
      formatter: function (val) {
        return Math.round(val) + '%';
      },
      style: {
        fontSize: '12px',
        fontWeight: 700
      }
    },
    xaxis: {
      max: 100,
      labels: { show: false },
      axisBorder: { show: false },
      axisTicks: { show: false }
    },
    yaxis: { labels: { show: false } },
    legend: { show: false },
    tooltip: {
      y: {
        formatter: function (val, opts) {
          const name = opts.seriesIndex === 0 ? '카카오페이' : '토스페이';
          return name + ' ' + Math.round(val) + '%';
        }
      }
    },
    grid: { show: false }
  };

  const barEl = document.querySelector('#chart-method-bar');
  if (barEl) new ApexCharts(barEl, methodBarOptions).render();

  // =========================================================
  // 3) 월별 충전금액(에어리어 차트)
  // - 금액은 원 단위, y축 라벨만 '만' 단위로 표시
  // =========================================================
  const months = ['1월','2월','3월','4월','5월','6월','7월','8월','9월','10월','11월','12월'];
  const monthly = Array.isArray(vm.monthlyTotals) ? vm.monthlyTotals : new Array(12).fill(0);

  const monthlyAreaOptions = {
    series: [{ name: vm.year + '년', data: monthly }],
    chart: {
      type: 'area',
      height: 320,
      fontFamily: 'inherit',
      toolbar: { show: false }
    },
    colors: ['#1e88ff'],
    dataLabels: { enabled: false },
    stroke: { curve: 'smooth', width: 2 },

    xaxis: {
      categories: months,
      axisBorder: { show: false },
      axisTicks: { show: false }
    },

    // y축 라벨은 만 단위로 간단히 표시
    yaxis: {
      labels: {
        formatter: function (val) {
          return Math.round(val / 10000) + '만';
        }
      }
    },

    // 툴팁에서는 원 단위(콤마 포함)로 보여줌
    tooltip: {
      y: {
        formatter: function (val) {
          return '₩ ' + Number(val).toLocaleString();
        }
      }
    }
  };

  const areaEl = document.querySelector('#chart-monthly-area');
  if (areaEl) new ApexCharts(areaEl, monthlyAreaOptions).render();

  // =========================================================
  // 연도 선택(현재는 더미)
  // - 다음 단계에서 실제 연도별 데이터로 바꾸려면:
  //   1) 서버 렌더링: location.href로 year 전달 후 페이지 리로드
  //   2) 비동기: fetch로 데이터 받아서 차트 updateSeries / updateOptions 적용
  // =========================================================
  const yearSelect = document.getElementById('yearSelect');
  if (yearSelect) {
    yearSelect.addEventListener('change', function () {
      console.log('year changed:', this.value);
    });
  }
})();
