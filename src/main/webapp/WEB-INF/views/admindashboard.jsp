<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%-- JSTL: core/functions/fmt
     - core(c): if/redirect/set 등 기본 제어용
     - functions(fn): 문자열 처리 등(현재는 많이 안 쓰더라도 유지 가능)
     - fmt: 숫자/날짜 포맷(현재 페이지에서 직접 쓰지 않아도 추후 확장 가능)
--%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>

<%-- 컨텍스트 경로: /assets 같은 정적 리소스 및 내부 링크에 공통으로 사용 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- ✅ 접근 제어(관리자만 접근)
     - sessionScope.memberRole이 ADMIN이 아니면 mainPage로 redirect
     - 실무에선 Filter/Spring Security로 막는 게 더 깔끔하지만
       JSP 레벨에서 1차 방어로도 많이 씀
--%>
<c:if test="${empty sessionScope.memberRole or sessionScope.memberRole ne 'ADMIN'}">
  <c:redirect url="${ctx}/mainPage" />
</c:if>

<!doctype html>
<html lang="ko">
<head>
<%-- 기본 메타 --%>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Admin | Cash Dashboard</title>

<%-- 파비콘 + 템플릿 기본 CSS --%>
<link rel="icon" type="image/png" href="${ctx}/favicon.png" />
<link rel="stylesheet" href="${ctx}/assets/css/styles.min.css" />

<%-- ✅ 관리자 페이지 전용 커스텀 CSS
     - body에 admin-dashboard 클래스를 달아두었기 때문에
       admincustom.css는 .admin-dashboard 하위에만 적용됨
--%>
<link rel="stylesheet" href="${ctx}/assets/css/admincustom.css" />
</head>

<%-- ✅ body에 admin-dashboard를 넣어 “관리자 전용 CSS scope”로 사용 --%>
<body class="admin-dashboard">

  <%-- ✅ 우상단 플로팅 버튼 영역
       - dashboardheader.jsp에 (프로필/로그아웃) 같은 아이콘을 include해둔 상태로 보임
       - CSS에서 .admin-float-actions로 position:fixed 처리되어 스크롤에도 고정
  --%>
  <jsp:include page="dashboardheader.jsp" />

  <%-- ✅ 템플릿 레이아웃 wrapper
       - data-* 속성들은 템플릿 JS(sidebarmenu/app.min.js)가 레이아웃을 구성할 때 참조
       - 특히 data-sidebar-position="fixed"면 템플릿이 sidebar top을 72px 등으로 조정하는데
         admincustom.css에서 top:0으로 덮어써서 화면 맨 위까지 채우도록 수정했음
  --%>
  <div class="page-wrapper" id="main-wrapper" data-layout="vertical"
    data-navbarbg="skin6" data-sidebartype="full"
    data-sidebar-position="fixed" data-header-position="fixed">

    <%-- =========================
         좌측 사이드바(관리자 메뉴)
         ========================= --%>
    <aside class="left-sidebar">
      <div>

        <%-- ✅ 로고 영역
             - 템플릿 기본값에서 로고가 잘리는 문제가 있어
               admincustom.css에서 brand-logo padding/height를 안정화
        --%>
        <div class="brand-logo d-flex align-items-center justify-content-center">
          <a href="${ctx}/admindashboard" class="text-nowrap logo-img">
            <img src="${ctx}/assets/images/logos/animale-logo.svg" width="150" alt="AniMale Logo">
          </a>
        </div>

        <%-- ✅ 메뉴 영역
             - scroll-sidebar는 simplebar가 적용되어 내부 스크롤 처리됨
        --%>
        <nav class="sidebar-nav scroll-sidebar" data-simplebar="">
          <ul id="sidebarnav">
            <li class="sidebar-item">
              <a class="sidebar-link" href="${ctx}/admindashboard">
                <span class="hide-menu">관리자 대시보드</span>
              </a>
            </li>

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
             상단 카드 2개 row
             - 왼쪽(이번달 KPI) + 오른쪽(결제수단 비교)
             - 둘 다 col에 d-flex align-items-stretch를 줘서 높이를 동일하게 맞춤
             ========================= --%>
        <div class="row kpi-top-row">

          <%-- (1) 이번 달 충전 금액 카드 --%>
          <div class="col-lg-7 d-flex align-items-stretch">
            <div class="card w-100 h-100 kpi-card kpi-card--soft cash-kpi-card">
              <div class="card-body cash-summary">

                <div class="cash-summary__inner">

                  <%-- ✅ 좌측 텍스트 영역
                       - JS가 #text-this-month, #text-mom 같은 id에 값을 채움
                  --%>
                  <div class="cash-summary__text">

                    <div class="cash-summary__titleRow">
                      <div class="cash-summary__titleLeft">
                        <span class="kpi-icon" aria-hidden="true">
                          <i class="ti ti-wallet"></i>
                        </span>
                        <h5 class="cash-summary__title mb-0">이번 달 충전 금액</h5>
                      </div>
                    </div>

                    <%-- ✅ JS에서 이번달 금액 setText('text-this-month', ...)로 채움 --%>
                    <h2 class="cash-summary__amount" id="text-this-month">₩ 0</h2>

                    <%-- ✅ 전월 대비 배지
                         - JS에서 상태에 따라 badge-up / badge-down / badge-neutral 바뀜
                    --%>
                    <span class="badge-pill badge-up cash-summary__badge" id="text-mom">전월 대비 +0%</span>

                    <p class="cash-summary__sub">그래프에 마우스를 올리면 상세 데이터를 볼 수 있어요</p>
                  </div>

                  <%-- ✅ 우측 차트 영역(라디얼)
                       - JS가 #chart-mom-radial에 ApexCharts render
                       - 아래 radial-meta는 (승인 건수/일 평균) 같은 보조 지표 영역
                       - 현재 JS에는 text-charge-count/text-daily-avg 세팅 로직이 없으니
                         서버 연동 시 그 부분도 setText로 채워주면 됨
                  --%>
                  <div class="radial-wrap">
                    <div id="chart-mom-radial"></div>

                    <div class="radial-meta">
                      <div class="radial-meta__row">
                        <span class="radial-meta__label">이번달 승인 건수</span>
                        <span class="radial-meta__value" id="text-charge-count">0건</span>
                      </div>
                      <div class="radial-meta__row">
                        <span class="radial-meta__label">일 평균 충전 금액</span>
                        <span class="radial-meta__value" id="text-daily-avg">0</span>
                      </div>
                    </div>
                  </div>

                </div>
              </div>
            </div>
          </div>

          <%-- (2) 충전 수단 비교 카드 --%>
          <div class="col-lg-5 d-flex align-items-stretch">
            <div class="card w-100 h-100 kpi-card method-kpi-card">
              <div class="card-body">

                <%-- ✅ 카드2 헤더(제목/서브)
                     - CSS에서 baseline 정렬/간격 튜닝
                --%>
                <div class="method-head">
                  <h5 class="card-title method-title">충전 수단 비교</h5>
                  <div class="method-sub">이번달 기준</div>
                </div>

                <%-- ✅ JS에서 #chart-method-bar에 100% 스택 바 렌더링 --%>
                <div id="chart-method-bar"></div>

                <%-- ✅ 범례
                     - JS에서 text-kakao/text-toss에 %만 채움
                     - 레이아웃은 bootstrap mt/py/d-flex 제거하고 전용 클래스만 사용
                --%>
                <div class="method-legend">
                  <div class="method-legend__row">
                    <div class="method-legend__left">
                      <span class="dot" style="background: #1e88ff;"></span>
                      <span class="name">카카오페이</span>
                    </div>
                    <div class="pct" id="text-kakao">0%</div>
                  </div>

                  <div class="method-legend__row">
                    <div class="method-legend__left">
                      <span class="dot" style="background: #d0d5dd;"></span>
                      <span class="name">토스페이</span>
                    </div>
                    <div class="pct" id="text-toss">0%</div>
                  </div>
                </div>

              </div>
            </div>
          </div>

        </div>

        <%-- =========================
             하단: 월별 충전 금액(Area chart)
             ========================= --%>
        <div class="row">
          <div class="col-lg-12">
            <div class="card w-100 kpi-card monthly-kpi-card">
              <div class="card-body">

                <%-- ✅ 월별 헤더: 제목 + 연도 select를 flex로 한 줄 정렬 --%>
                <div class="monthly-head">
                  <h5 class="card-title mb-0">월별 충전 금액</h5>

                  <%-- ✅ 현재는 더미 연도 2개만 옵션으로 하드코딩
                       - 서버 연도 리스트가 생기면 빈 select로 바꿔서 JS가 option을 채우게 가능
                  --%>
                  <select id="yearSelect" class="form-select">
                    <option value="2026" selected>2026년</option>
                    <option value="2025">2025년</option>
                  </select>
                  <%-- <select id="yearSelect" class="form-select"></select> --%>
                </div>

                <%-- ✅ 월별 차트 렌더링 영역
                     - JS가 #chart-monthly-area에 ApexCharts 렌더링
                     - overlay 배지(monthly-overlay)는 JS가 DOM을 동적으로 생성해서 host 안에 append함
                --%>
                <div class="mt-3" id="chart-monthly-area"></div>

              </div>
            </div>
          </div>
        </div>

      </div>
    </div>

  </div>

  <%-- =========================
       JS 로딩
       ========================= --%>
  <script src="${ctx}/assets/libs/jquery/dist/jquery.min.js"></script>
  <script src="${ctx}/assets/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
  <script src="${ctx}/assets/js/sidebarmenu.js"></script>
  <script src="${ctx}/assets/js/app.min.js"></script>
  <script src="${ctx}/assets/libs/apexcharts/dist/apexcharts.min.js"></script>
  <script src="${ctx}/assets/libs/simplebar/dist/simplebar.js"></script>

  <%-- ✅ JS가 서버 호출할 때 사용할 공통 값(window.APP_CTX, window.DASH_INIT)
       - 현재 네 admindashboardcash.js는 더미 vm을 쓰고 있어서 DASH_INIT을 직접 쓰진 않지만
         서버 연동 버전(fetchDashboard/toVM)을 활성화하면 바로 활용 가능
  --%>
  <script>
    window.APP_CTX = '${ctx}';

    window.DASH_INIT = {
      year: new Date().getFullYear(),
      month: new Date().getMonth() + 1
    };
  </script>

  <%-- ✅ 실제 대시보드 렌더링 스크립트(차트 3개 그리는 파일) --%>
  <script src="${ctx}/assets/js/admindashboardcash.js"></script>

</body>
</html>
