<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%-- JSTL: 현재는 core만 사용 중 (fn/fmt는 추후 확장용이면 유지해도 됨) --%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>

<%-- 컨텍스트 경로: /assets 같은 정적 리소스 및 내부 링크에 공통으로 사용 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!doctype html>
<html lang="ko">
<head>
  <%-- 기본 메타 --%>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Admin | Cash Dashboard</title>

  <%-- 파비콘 + 템플릿 기본 CSS --%>
  <link rel="icon" type="image/png" href="${ctx}/assets/images/logos/favicon.png" />
  <link rel="stylesheet" href="${ctx}/assets/css/styles.min.css" />

  <%--
    관리자 페이지 전용 커스텀 CSS
    - admin-dashboard 범위 선택자로 감싸서 다른 JSP 페이지에는 영향 없게 설계
  --%>
  <link rel="stylesheet" href="${ctx}/assets/css/admincustom.css" />
</head>

<%--
  body에 admin-dashboard 클래스를 주는 이유
  - admincustom.css에서 .admin-dashboard 하위만 스타일을 적용해 '관리자 페이지 전용'으로 제한하기 위함
--%>
<body class="admin-dashboard">

  <%--
    MaterialM 템플릿 기본 레이아웃 컨테이너
    - left-sidebar: 좌측 메뉴 영역
    - body-wrapper : 본문 컨텐츠 영역
  --%>
  <div class="page-wrapper"
       id="main-wrapper"
       data-layout="vertical"
       data-navbarbg="skin6"
       data-sidebartype="full"
       data-sidebar-position="fixed"
       data-header-position="fixed">

    <%-- =========================
         좌측 사이드바(관리자 메뉴)
         ========================= --%>
    <aside class="left-sidebar">
      <div>

        <%--
          로고 영역
          - 로고 클릭 시 관리자 대시보드(현재 페이지)로 이동
          - 로고 파일은 /assets/images/logos/ 아래에 위치
        --%>
        <div class="brand-logo d-flex align-items-center justify-content-between">
          <a href="${ctx}/admindashboard" class="text-nowrap logo-img">
            <img src="${ctx}/assets/images/logos/animale-logo.svg"
                 width="150"
                 alt="AniMale Logo">
          </a>
        </div>

        <%--
          메뉴 영역
          - sidebarmenu.js가 이 구조(ul#sidebarnav)를 기준으로 동작하는 경우가 많아서 템플릿 구조 유지
          - 메뉴 '활성화(active 표시)'는 추후 현재 URL과 비교해서 class를 추가하면 됨
        --%>
        <nav class="sidebar-nav scroll-sidebar" data-simplebar="">
          <ul id="sidebarnav">

            <%-- (1) 관리자 대시보드(캐시) --%>
            <li class="sidebar-item">
              <a class="sidebar-link" href="${ctx}/admindashboard">
                <span class="hide-menu">관리자 대시보드</span>
              </a>
            </li>

            <%-- (2) 신고 게시글 관리(추후 페이지/컨트롤러 연결 예정) --%>
            <li class="sidebar-item">
              <a class="sidebar-link" href="${ctx}/adminreportboard">
                <span class="hide-menu">신고 게시글 관리</span>
              </a>
            </li>

          </ul>
        </nav>

      </div>
    </aside>

    <%-- =========================
         본문 영역
         ========================= --%>
    <div class="body-wrapper">
      <div class="container-fluid">

        <%-- =========================
             상단 카드 2개
             1) 이번 달 충전 금액 + 전월 대비(원형)
             2) 충전 수단 비교(막대)
             ========================= --%>
        <div class="row">

          <%-- (1) 이번 달 충전 금액 카드 --%>
          <div class="col-lg-8 d-flex align-items-stretch">

            <%--
              kpi-card / kpi-card--soft
              - admincustom.css에서 카드 라운드/톤을 레퍼런스처럼 조정할 때 쓰는 확장 클래스(없어도 동작은 함)
              cash-summary
              - 원형 차트 영역(radal-wrap) 정렬/고정을 위한 레이아웃 훅
            --%>
            <div class="card w-100 overflow-hidden kpi-card kpi-card--soft">
              <div class="card-body cash-summary">

                <div class="d-flex align-items-center justify-content-between">

                  <%-- 왼쪽 텍스트 영역: JS가 값을 주입하는 영역(id로 접근) --%>
                  <div>
                    <h5 class="card-title mb-1">이번 달 충전 금액</h5>

                    <%-- JS에서 #text-this-month에 이번달 금액을 렌더링 --%>
                    <h2 class="mb-2" id="text-this-month">₩ 0</h2>

                    <%--
                      전월 대비 뱃지
                      - JS에서 #text-mom 텍스트/클래스를 변경
                      - 상승이면 badge-up, 하락이면 badge-down으로 토글됨
                    --%>
                    <span class="badge-pill badge-up" id="text-mom">전월 대비 +0%</span>
                  </div>

                  <%--
                    오른쪽 원형 그래프 영역
                    - JS에서 #chart-mom-radial에 ApexCharts radialBar 렌더링
                    - radial-wrap은 크기 고정/중앙 정렬용 래퍼
                  --%>
                  <div class="radial-wrap">
                    <div id="chart-mom-radial"></div>
                  </div>

                </div>
              </div>
            </div>
          </div>

          <%-- (2) 충전 수단 비교 카드 --%>
          <div class="col-lg-4 d-flex align-items-stretch">
            <div class="card w-100 overflow-hidden kpi-card">
              <div class="card-body">

                <div class="d-flex align-items-center justify-content-between mb-2">
                  <h5 class="card-title mb-0">충전 수단 비교</h5>
                </div>

                <%-- JS에서 #chart-method-bar에 stacked bar 차트를 렌더링 --%>
                <div id="chart-method-bar"></div>

                <%--
                  수단별 라벨/퍼센트 표시
                  - JS에서 #text-kakao, #text-toss 값을 주입
                  - 점(색상)은 현재 inline style, 추후 css 클래스로 빼도 됨
                --%>
                <div class="mt-3">
                  <div class="d-flex align-items-center justify-content-between py-1">
                    <div class="d-flex align-items-center gap-2">
                      <span class="rounded-circle d-inline-block"
                            style="width: 10px; height: 10px; background: #1e88ff;"></span>
                      <span class="text-muted">카카오페이</span>
                    </div>
                    <div class="fw-semibold" id="text-kakao">0%</div>
                  </div>

                  <div class="d-flex align-items-center justify-content-between py-1">
                    <div class="d-flex align-items-center gap-2">
                      <span class="rounded-circle d-inline-block"
                            style="width: 10px; height: 10px; background: #e9eef5;"></span>
                      <span class="text-muted">토스페이</span>
                    </div>
                    <div class="fw-semibold" id="text-toss">0%</div>
                  </div>
                </div>

              </div>
            </div>
          </div>

        </div>

        <%-- =========================
             하단: 올해 월별 충전 금액(Area chart)
             ========================= --%>
        <div class="row">
          <div class="col-lg-12">
            <div class="card w-100 overflow-hidden kpi-card">
              <div class="card-body">

                <div class="d-flex align-items-center justify-content-between">
                  <h5 class="card-title mb-0">올해 월별 충전 금액</h5>

                  <%--
                    연도 선택 드롭다운
                    - 현재는 더미
                    - 다음 단계에서:
                      1) 서버 렌더링이면 location.href로 year 파라미터 전달
                      2) 비동기면 fetch로 데이터 받고 차트 updateSeries
                  --%>
                  <select id="yearSelect" class="form-select">
                    <option value="2026" selected>2026년</option>
                    <option value="2025">2025년</option>
                    <option value="2024">2024년</option>
                  </select>
                </div>

                <%-- JS에서 #chart-monthly-area에 area chart 렌더링 --%>
                <div class="mt-3" id="chart-monthly-area"></div>

              </div>
            </div>
          </div>
        </div>

      </div>
    </div>

  </div>

  <%-- =========================
       JS 로딩 순서
       1) 템플릿 필수(jQuery/Bootstrap/sidebarmenu/app)
       2) ApexCharts
       3) 우리 대시보드 전용 JS
       ========================= --%>
  <script src="${ctx}/assets/libs/jquery/dist/jquery.min.js"></script>
  <script src="${ctx}/assets/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
  <script src="${ctx}/assets/js/sidebarmenu.js"></script>
  <script src="${ctx}/assets/js/app.min.js"></script>
  <script src="${ctx}/assets/libs/apexcharts/dist/apexcharts.min.js"></script>
  <script src="${ctx}/assets/libs/simplebar/dist/simplebar.js"></script>

  <%-- 선택: JS에서 컨텍스트 경로가 필요할 때 사용 가능 (현재 파일에서는 직접 쓰진 않음) --%>
  <script>
    window.APP_CTX = '${ctx}';
  </script>

  <%-- 대시보드 차트/더미 데이터 렌더링 JS --%>
  <script src="${ctx}/assets/js/admindashboardcash.js"></script>

</body>
</html>
