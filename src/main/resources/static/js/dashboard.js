$(function () {

  /*
    [전체 흐름]
    - 페이지 DOM 로딩 완료 후 실행
    - ApexCharts로 3개 차트 렌더링
      1) sales-profit : area + line 혼합(연도 비교)
      2) total-followers : stacked bar(스파크라인)
      3) total-income : area 스파크라인(미니 추이)
  */


  // =====================================
  // Sales Profit (area + line, 연도 비교)
  // =====================================

  /*
    ApexCharts 옵션 객체
    - series: 실제 데이터(여러 시리즈 가능)
    - chart: 차트 전체 공통 설정(높이, 폰트, 애니메이션 등)
    - colors/fill/stroke/grid/tooltip: 시각 스타일
  */
  var options = {
    series: [
      {
        /*
          시리즈 1: This Year
          - type: area (면적 그래프)
          - name: 툴팁/라벨에 쓰이는 이름
          - chart: 시리즈 레벨에서 드롭섀도우 등 세부 스타일(템플릿 구조 유지)
          - data: {x: 라벨, y: 값} 형태로 월별 데이터
        */
        type: "area",
        name: "This Year",
        chart: {
          foreColor: "#111c2d99",
          fontSize: 12,
          fontWeight: 500,
          dropShadow: {
            enabled: true,
            enabledOnSeries: undefined, // 특정 시리즈만 적용할 때 쓰는 자리(현재는 전체 적용 형태)
            top: 5,
            left: 0,
            blur: 3,
            color: "#000",
            opacity: 0.1,
          },
        },
        data: [
          { x: "Aug", y: 25 },
          { x: "Sep", y: 25 },
          { x: "Oct", y: 10 },
          { x: "Nov", y: 10 },
          { x: "Dec", y: 45 },
          { x: "Jan", y: 45 },
          { x: "Feb", y: 75 },
          { x: "Mar", y: 70 },
          { x: "Apr", y: 35 },
        ],
      },
      {
        /*
          시리즈 2: Last Year
          - type: line (선 그래프)
          - 작년 데이터 라인으로 비교용
        */
        type: "line",
        name: "Last Year",
        chart: {
          foreColor: "#111c2d99",
        },
        data: [
          { x: "Aug", y: 50 },
          { x: "Sep", y: 50 },
          { x: "Oct", y: 25 },
          { x: "Nov", y: 20 },
          { x: "Dec", y: 20 },
          { x: "Jan", y: 20 },
          { x: "Feb", y: 35 },
          { x: "Mar", y: 35 },
          { x: "Apr", y: 60 },
        ],
      },
    ],

    /*
      chart(공통 설정)
      - height: 차트 높이
      - fontFamily: 상속(inherit)으로 페이지 폰트 그대로 사용
      - foreColor: 기본 글자 색(축/라벨 등)
      - offsetX/Y: 차트를 살짝 이동시켜 레이아웃 맞춤
      - animations: 렌더링 애니메이션 속도
      - toolbar: 우측 상단 메뉴(다운로드 등) 숨김
    */
    chart: {
      height: 300,
      fontFamily: "inherit",
      foreColor: "#adb0bb",
      fontSize: "12px",
      offsetX: -15,
      offsetY: 10,
      animations: {
        speed: 500,
      },
      toolbar: {
        show: false,
      },
    },

    /*
      colors
      - CSS 변수 사용(부트스트랩 계열)
      - 첫 번째: primary(올해)
      - 두 번째: secondary-color(작년)
    */
    colors: ["var(--bs-primary)", "var(--bs-secondary-color)"],

    /*
      dataLabels
      - 각 포인트 값 라벨 표시 여부
      - 여기선 깔끔하게 숨김
    */
    dataLabels: {
      enabled: false,
    },

    /*
      fill (면적 채우기)
      - gradient로 아래쪽 투명하게 사라지는 느낌
      - opacityFrom -> opacityTo: 위에서 아래로 점점 투명
    */
    fill: {
      type: "gradient",
      gradient: {
        shadeIntensity: 0,
        inverseColors: false,
        opacityFrom: 0.1,
        opacityTo: 0,
        stops: [100],
      },
    },

    /*
      grid
      - 배경 격자(가이드 라인)
      - strokeDashArray: 점선 형태
      - borderColor: 라인 색(반투명)
    */
    grid: {
      show: true,
      strokeDashArray: 3,
      borderColor: "#90A4AE50",
    },

    /*
      stroke
      - 라인/면적의 윤곽선 설정
      - curve: smooth면 곡선 형태
      - width: 선 두께
    */
    stroke: {
      curve: "smooth",
      width: 2,
    },

    /*
      xaxis
      - 축 테두리/틱(눈금) 숨김
      - 월 라벨은 data.x를 기반으로 사용
    */
    xaxis: {
      axisBorder: {
        show: false,
      },
      axisTicks: {
        show: false,
      },
    },

    /*
      yaxis
      - tickAmount: y축 눈금 개수(대략적인 가이드)
    */
    yaxis: {
      tickAmount: 3,
    },

    /*
      legend
      - 범례 숨김(카드 UI에서 공간 절약)
    */
    legend: {
      show: false,
    },

    /*
      tooltip
      - hover 시 툴팁 테마
    */
    tooltip: {
      theme: "dark",
    },
  };

  /*
    렌더링 처리
    - 기존 차트가 남아있을 수 있어서 innerHTML 비우고 다시 그림
    - new ApexCharts(대상 엘리먼트, 옵션).render()
  */
  document.getElementById("sales-profit").innerHTML = "";
  var chart = new ApexCharts(document.querySelector("#sales-profit"), options);
  chart.render();


  // =====================================
  // total-followers (stacked bar sparkline)
  // =====================================

  /*
    미니 막대 차트(스파크라인)
    - stacked: true로 두 시리즈를 겹쳐서 채움(현재값/잔여량 같은 표현에 자주 씀)
    - sparkline: true라 축/여백 최소화(카드 안 미니차트용)
  */
  var totalfollowers = {
    series: [
      {
        /*
          시리즈 1
          - 실제 채워진 값(예: 팔로워 증가/현재 수치 느낌)
        */
        name: "",
        data: [29, 52, 38, 47, 56],
      },
      {
        /*
          시리즈 2
          - 기준선/전체값(항상 71로 고정)
          - stacked로 쌓이면서 "총량 대비" 같은 표현이 됨
        */
        name: "",
        data: [71, 71, 71, 71, 71],
      },
    ],

    chart: {
      fontFamily: "inherit",
      type: "bar",
      height: 90,
      stacked: true,
      toolbar: {
        show: false,
      },
      sparkline: {
        enabled: true,
      },
    },

    /*
      grid
      - 스파크라인은 보통 grid 숨김
      - padding도 전부 0으로 꽉 차게 사용
    */
    grid: {
      show: false,
      borderColor: "rgba(0,0,0,0.1)",
      strokeDashArray: 1,
      xaxis: {
        lines: {
          show: false,
        },
      },
      yaxis: {
        lines: {
          show: true,
        },
      },
      padding: {
        top: 0,
        right: 0,
        bottom: 0,
        left: 0,
      },
    },

    /*
      colors
      - 첫 시리즈: danger(강조)
      - 두 번째 시리즈: 옅은 회색(잔여/배경 느낌)
    */
    colors: [
      "var(--bs-danger)",
      "var(--black-black-10, rgba(17, 28, 45, 0.10))",
    ],

    /*
      plotOptions.bar
      - columnWidth: 막대 폭
      - borderRadius: 둥근 모서리
      - stacked일 때 끝부분 둥글게 처리하는 옵션들
    */
    plotOptions: {
      bar: {
        horizontal: false,
        columnWidth: "30%",
        borderRadius: [3],
        borderRadiusApplication: "end",
        borderRadiusWhenStacked: "all",
      },
    },

    /*
      dataLabels: 막대 위 숫자 숨김
    */
    dataLabels: {
      enabled: false,
    },

    /*
      축 라벨/테두리/틱 숨김 (sparkline 느낌 유지)
    */
    xaxis: {
      labels: {
        show: false,
      },
      axisBorder: {
        show: false,
      },
      axisTicks: {
        show: false,
      },
    },
    yaxis: {
      labels: {
        show: false,
      },
    },

    /*
      tooltip: hover 시 어두운 테마
    */
    tooltip: {
      theme: "dark",
    },

    /*
      legend: 범례 숨김
    */
    legend: {
      show: false,
    },
  };

  /*
    total-followers 차트 렌더링
  */
  var chart_column_stacked = new ApexCharts(
    document.querySelector("#total-followers"),
    totalfollowers
  );
  chart_column_stacked.render();


  // =====================================
  // total-income (area sparkline)
  // =====================================

  /*
    미니 area 차트
    - sparkline enabled로 카드 내부 작은 추이 그래프
    - group: "sparklines"로 같은 그룹 애니메이션/동작 묶는 용도(템플릿 구조 유지)
  */
  var options = {
    chart: {
      id: "total-income",
      type: "area",
      height: 70,
      sparkline: {
        enabled: true,
      },
      group: "sparklines",
      fontFamily: "inherit",
      foreColor: "#adb0bb",
    },

    /*
      series
      - monthly earnings 데이터(7포인트)
      - color는 시리즈 단위로 지정(secondary)
    */
    series: [
      {
        name: "monthly earnings",
        color: "var(--bs-secondary)",
        data: [25, 66, 20, 40, 12, 58, 20],
      },
    ],

    /*
      stroke: 곡선 + 두께
    */
    stroke: {
      curve: "smooth",
      width: 2,
    },

    /*
      fill: 아래쪽이 거의 투명한 그라데이션
      - opacityFrom/To를 0으로 둬서 면이 과하게 진해지지 않게 함
      - stops는 템플릿 기본값 유지
    */
    fill: {
      type: "gradient",
      gradient: {
        shadeIntensity: 0,
        inverseColors: false,
        opacityFrom: 0,
        opacityTo: 0,
        stops: [20, 180],
      },
    },

    /*
      markers: 포인트 점 숨김(미니차트에서 깔끔하게)
    */
    markers: {
      size: 0,
    },

    /*
      tooltip
      - fixed.enabled: 툴팁 위치를 고정해서 흔들림 줄임
      - x.show: x값 표시 숨김(미니차트라 간단히)
    */
    tooltip: {
      theme: "dark",
      fixed: {
        enabled: true,
        position: "right",
      },
      x: {
        show: false,
      },
    },
  };

  /*
    total-income 차트 렌더링
  */
  new ApexCharts(document.querySelector("#total-income"), options).render();

});