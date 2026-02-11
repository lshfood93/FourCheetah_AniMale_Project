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
  // - momPercent를 0~100 범위로 clamp하여 radialBar series로 사용
  // =========================================================
  const ringValue = Math.max(0, Math.min(100, Math.abs(vm.momPercent || 0)));

  const radialOptions = {
    series: [ringValue],
    chart: {
      type: 'radialBar',
      height: 140,
      sparkline: { enabled: true } // 축/여백을 최소화해 카드형 위젯 느낌
    },
    colors: ['#1e88ff'], // 포인트 컬러 통일(파랑)

    plotOptions: {
      radialBar: {
        hollow: { size: '65%' },

        // 배경 링(회색 트랙)
        track: {
          background: '#e9eef5',
          strokeWidth: '100%'
        },

        dataLabels: {
          name: { show: false },
          value: {
            show: true,
            fontSize: '16px',
            formatter: function () {
              const v = vm.momPercent ?? 0;
              const sign = v >= 0 ? '+' : '';
              return sign + Math.round(v) + '%';
            }
          }
        }
      }
    }
  };

  const radialEl = document.querySelector('#chart-mom-radial');
  if (radialEl) new ApexCharts(radialEl, radialOptions).render();

  // =========================================================
  // 2) 충전 수단 비교(스택 막대)
  // - 비중(파랑) + 나머지(회색)로 100% 스택처럼 보이게 구성
  // =========================================================
  const kakao = vm.kakaoPercent ?? 0;
  const toss = vm.tossPercent ?? 0;

  const methodBarOptions = {
    series: [
      { name: '비중', data: [kakao, toss] },
      { name: '나머지', data: [100 - kakao, 100 - toss] }
    ],
    chart: {
      type: 'bar',
      height: 120,
      stacked: true,
      sparkline: { enabled: true },
      fontFamily: 'inherit'
    },
    colors: ['#1e88ff', '#e9eef5'],
    fill: { opacity: 1 },

    plotOptions: {
      bar: {
        horizontal: false,
        columnWidth: '35%',
        borderRadius: 8,
        borderRadiusApplication: 'end',
        borderRadiusWhenStacked: 'all'
      }
    },

    dataLabels: { enabled: false },
    xaxis: {
      categories: ['카카오페이', '토스페이'],
      labels: { show: false },
      axisBorder: { show: false },
      axisTicks: { show: false }
    },
    yaxis: { max: 100, labels: { show: false } },
    legend: { show: false },

    // 툴팁은 파랑(비중)만 보여주고 회색(나머지)은 숨김
    tooltip: {
      y: {
        formatter: function (val, opts) {
          const seriesIndex = opts.seriesIndex;
          if (seriesIndex === 0) return Math.round(val) + '%';
          return '';
        }
      }
    }
  };

  const barEl = document.querySelector('#chart-method-bar');
  if (barEl) new ApexCharts(barEl, methodBarOptions).render();

  // =========================================================
  // 3) 올해 월별 충전금액(에어리어 차트)
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
