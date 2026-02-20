<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="uri" value="${pageContext.request.requestURI}" />

<c:if test="${empty sessionScope.memberRole or sessionScope.memberRole ne 'ADMIN'}">
  <c:redirect url="${ctx}/mainPage" />
</c:if>

<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Admin | Cash Dashboard</title>

<link rel="icon" type="image/png" href="${ctx}/favicon.png" />
<link rel="stylesheet" href="${ctx}/css/styles.min.css" />
<link rel="stylesheet" href="${ctx}/css/admincustom.css" />
</head>

<body class="admin-dashboard">

  <!-- ✅ 우상단 플로팅 버튼 -->
  <jsp:include page="dashboardheader.jsp" />

  <div class="page-wrapper" id="main-wrapper" data-layout="vertical"
    data-navbarbg="skin6" data-sidebartype="full"
    data-sidebar-position="fixed" data-header-position="fixed">

    <!-- 좌측 사이드바 -->
    <aside class="left-sidebar">
      <div>
        <div class="brand-logo d-flex align-items-center justify-content-center">
          <a href="${ctx}/admindashboard" class="text-nowrap logo-img">
            <img src="${ctx}/images/logos/animale-logo.svg" width="150" alt="AniMale Logo">
          </a>
        </div>

        <%-- ✅ 현재 URI로 active 판별용 --%>
<c:set var="uri" value="${pageContext.request.requestURI}" />

<nav class="sidebar-nav scroll-sidebar" data-simplebar="">
  <ul id="sidebarnav">

    <li class="sidebar-item ${fn:contains(uri, '/admindashboard') ? 'selected' : ''}">
      <a class="sidebar-link ${fn:contains(uri, '/admindashboard') ? 'active' : ''}"
         href="${ctx}/admindashboard">
        <span class="hide-menu">관리자 대시보드</span>
      </a>
    </li>

    <li class="sidebar-item ${fn:contains(uri, '/admin/reports') ? 'selected' : ''}">
      <a class="sidebar-link ${fn:contains(uri, '/admin/reports') ? 'active' : ''}"
         href="${ctx}/admin/reports?page=1&sortOrder=desc">
        <span class="hide-menu">신고 게시글 관리</span>
      </a>
    </li>

  </ul>
</nav>

      </div>
    </aside>

    <!-- 본문 -->
    <div class="body-wrapper">
      <div class="container-fluid">

        <!-- 상단 카드 2개 row -->
        <div class="row kpi-top-row">

          <!-- (1) 이번 달 충전 금액 카드 -->
          <div class="col-lg-7 d-flex align-items-stretch">
            <div class="card w-100 h-100 kpi-card kpi-card--soft cash-kpi-card">
              <div class="card-body cash-summary">
                <div class="cash-summary__inner">

                  <!-- 좌측 텍스트 -->
                  <div class="cash-summary__text">
                    <div class="cash-summary__titleRow">
                      <div class="cash-summary__titleLeft">
                        <span class="kpi-icon" aria-hidden="true">
                          <i class="ti ti-wallet"></i>
                        </span>
                        <h5 class="cash-summary__title mb-0">이번 달 충전 금액</h5>
                      </div>
                    </div>

                    <h2 class="cash-summary__amount" id="text-this-month">₩ 0</h2>
                    <span class="badge-pill badge-up cash-summary__badge" id="text-mom">전월 대비 +0%</span>

                    <p class="cash-summary__sub">그래프에 마우스를 올리면 상세 데이터를 볼 수 있어요</p>
                  </div>

                  <!-- 우측 차트(라디얼) -->
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

          <!-- (2) 충전 수단 비교 카드 -->
          <div class="col-lg-5 d-flex align-items-stretch">
            <div class="card w-100 h-100 kpi-card method-kpi-card">
              <div class="card-body">

                <div class="method-head">
                  <h5 class="card-title method-title">충전 수단 비교</h5>
                  <div class="method-sub">이번달 기준</div>
                </div>

                <div id="chart-method-bar"></div>

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

        <!-- 하단: 월별 충전 금액(Area chart) -->
        <div class="row">
          <div class="col-lg-12">
            <div class="card w-100 kpi-card monthly-kpi-card">
              <div class="card-body">

                <div class="monthly-head">
                  <h5 class="card-title mb-0">월별 충전 금액</h5>

                  <select id="yearSelect" class="form-select">
                    <option value="2026" selected>2026년</option>
                    <option value="2025">2025년</option>
                  </select>
                </div>

                <div class="mt-3" id="chart-monthly-area"></div>

              </div>
            </div>
          </div>
        </div>

      </div>
    </div>

  </div>

  <!-- JS 로딩 -->
  <script src="${ctx}/libs/jquery/dist/jquery.min.js"></script>
  <script src="${ctx}/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
  <script src="${ctx}/js/sidebarmenu.js"></script>
  <script src="${ctx}/js/app.min.js"></script>
  <script src="${ctx}/libs/apexcharts/dist/apexcharts.min.js"></script>
  <script src="${ctx}/libs/simplebar/dist/simplebar.js"></script>

  <script>
    window.APP_CTX = '${ctx}';
    window.DASH_INIT = {
      year: new Date().getFullYear(),
      month: new Date().getMonth() + 1
    };
  </script>

  <script src="${ctx}/js/admindashboardcash.js"></script>
</body>
</html>
