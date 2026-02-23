<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>

<%-- 
  컨텍스트 경로 / 현재 요청 URI 저장.
  - ctx: 정적 리소스, 링크, script 경로를 전부 일관되게 맞추기 위한 기준값
  - uri: 좌측 사이드바에서 현재 메뉴 active/selected 판별할 때 사용
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="uri" value="${pageContext.request.requestURI}" />

<%-- 
  관리자 전용 페이지 1차 가드.
  세션 role이 비어있거나 ADMIN이 아니면 메인으로 돌려보낸다.
  (컨트롤러에서 막는 게 우선이지만 JSP에서도 화면 직접 접근 대비용으로 한 번 더 체크)
--%>
<c:if test="${empty sessionScope.memberRole or sessionScope.memberRole ne 'ADMIN'}">
  <c:redirect url="${ctx}/mainPage" />
</c:if>

<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Admin | Cash Dashboard</title>

<%-- 정적 리소스 경로는 ctx 기준으로 통일해서 context path가 바뀌어도 깨지지 않게 유지 --%>
<link rel="icon" type="image/png" href="${ctx}/favicon.png" />
<link rel="stylesheet" href="${ctx}/css/styles.min.css" />
<link rel="stylesheet" href="${ctx}/css/admincustom.css" />
</head>

<body class="admin-dashboard">

  <!-- 대시보드 공통 헤더(우상단 플로팅 버튼 포함) -->
  <jsp:include page="dashboardheader.jsp" />

  <div class="page-wrapper" id="main-wrapper" data-layout="vertical"
    data-navbarbg="skin6" data-sidebartype="full"
    data-sidebar-position="fixed" data-header-position="fixed">

    <!-- 좌측 사이드바 영역 -->
    <aside class="left-sidebar">
      <div>
        <div class="brand-logo d-flex align-items-center justify-content-center">
          <a href="${ctx}/admindashboard" class="text-nowrap logo-img">
            <img src="${ctx}/images/logos/animale-logo.svg" width="150" alt="AniMale Logo">
          </a>
        </div>

        <%-- 
          현재 URI를 기준으로 사이드바 active/selected 상태를 계산할 때 사용.
          상단에서 이미 한 번 세팅했지만, 이 블록을 부분 복사/재사용할 때도 동작하게
          여기서 다시 선언해 둔 형태로 보임(중복 선언이어도 값은 동일하므로 문제 없음).
        --%>
<c:set var="uri" value="${pageContext.request.requestURI}" />

<nav class="sidebar-nav scroll-sidebar" data-simplebar="">
  <ul id="sidebarnav">

    <%-- 관리자 메인 대시보드 메뉴: 현재 URI에 /admindashboard가 포함되면 활성화 --%>
    <li class="sidebar-item ${fn:contains(uri, '/admindashboard') ? 'selected' : ''}">
      <a class="sidebar-link ${fn:contains(uri, '/admindashboard') ? 'active' : ''}"
         href="${ctx}/admindashboard">
        <span class="hide-menu">관리자 대시보드</span>
      </a>
    </li>

    <%-- 신고 게시글 관리 메뉴: /admin/reports 경로일 때 활성화 --%>
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

    <!-- 본문 영역 -->
    <div class="body-wrapper">
      <div class="container-fluid">

        <!-- 상단 KPI 카드 2개 영역 -->
        <div class="row kpi-top-row">

          <!-- 이번 달 충전 금액 요약 카드 -->
          <div class="col-lg-7 d-flex align-items-stretch">
            <div class="card w-100 h-100 kpi-card kpi-card--soft cash-kpi-card">
              <div class="card-body cash-summary">
                <div class="cash-summary__inner">

                  <!-- 좌측 텍스트 요약 영역 (금액/전월대비/설명 문구) -->
                  <div class="cash-summary__text">
                    <div class="cash-summary__titleRow">
                      <div class="cash-summary__titleLeft">
                        <span class="kpi-icon" aria-hidden="true">
                          <i class="ti ti-wallet"></i>
                        </span>
                        <h5 class="cash-summary__title mb-0">이번 달 충전 금액</h5>
                      </div>
                    </div>

                    <%-- JS가 API 응답값으로 채워 넣는 텍스트 노드들 (초기값은 0으로 렌더) --%>
                    <h2 class="cash-summary__amount" id="text-this-month">₩ 0</h2>
                    <span class="badge-pill badge-up cash-summary__badge" id="text-mom">전월 대비 +0%</span>

                    <p class="cash-summary__sub">그래프에 마우스를 올리면 상세 데이터를 볼 수 있어요</p>
                  </div>

                  <!-- 우측 라디얼 차트 + 보조 지표 영역 -->
                  <div class="radial-wrap">
                    <%-- 전월 대비/진행률 성격의 라디얼 차트가 렌더링될 컨테이너 --%>
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

          <!-- 충전 수단 비교 카드 (이번달 기준 막대 차트 + 범례/비율) -->
          <div class="col-lg-5 d-flex align-items-stretch">
            <div class="card w-100 h-100 kpi-card method-kpi-card">
              <div class="card-body">

                <div class="method-head">
                  <h5 class="card-title method-title">충전 수단 비교</h5>
                  <div class="method-sub">이번달 기준</div>
                </div>

                <%-- 카카오페이/토스페이 비중 비교용 차트 컨테이너 --%>
                <div id="chart-method-bar"></div>

                <div class="method-legend">
                  <div class="method-legend__row">
                    <div class="method-legend__left">
                      <span class="dot" style="background: #1e88ff;"></span>
                      <span class="name">카카오페이</span>
                    </div>
                    <%-- JS가 퍼센트 값을 주입 --%>
                    <div class="pct" id="text-kakao">0%</div>
                  </div>

                  <div class="method-legend__row">
                    <div class="method-legend__left">
                      <span class="dot" style="background: #d0d5dd;"></span>
                      <span class="name">토스페이</span>
                    </div>
                    <%-- JS가 퍼센트 값을 주입 --%>
                    <div class="pct" id="text-toss">0%</div>
                  </div>
                </div>

              </div>
            </div>
          </div>

        </div>

        <!-- 하단 영역: 연도 선택 + 월별 충전 금액(Area Chart) -->
        <div class="row">
          <div class="col-lg-12">
            <div class="card w-100 kpi-card monthly-kpi-card">
              <div class="card-body">

                <div class="monthly-head">
                  <h5 class="card-title mb-0">월별 충전 금액</h5>

                  <%-- 
                    연도 선택 셀렉트.
                    JS에서 change 이벤트를 받아 해당 연도 기준 월별 데이터 재조회/재렌더링할 때 사용.
                  --%>
                  <select id="yearSelect" class="form-select">
                    <option value="2026" selected>2026년</option>
                    <option value="2025">2025년</option>
                  </select>
                </div>

                <%-- 월별 충전 금액 area chart 렌더링 컨테이너 --%>
                <div class="mt-3" id="chart-monthly-area"></div>

              </div>
            </div>
          </div>
        </div>

      </div>
    </div>

  </div>

  <!-- 대시보드 공통/서드파티 JS 로딩 -->
  <script src="${ctx}/libs/jquery/dist/jquery.min.js"></script>
  <script src="${ctx}/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
  <script src="${ctx}/js/sidebarmenu.js"></script>
  <script src="${ctx}/js/app.min.js"></script>
  <script src="${ctx}/libs/apexcharts/dist/apexcharts.min.js"></script>
  <script src="${ctx}/libs/simplebar/dist/simplebar.js"></script>

  <script>
    /*
      대시보드 전용 JS(admindashboardcash.js)에서 사용하는 전역 초기값.
      - APP_CTX: API 호출/리소스 경로 생성 시 context path 기준점
      - DASH_INIT: 초기 조회 기준 년/월 (브라우저 현재 시간 기준)
        ※ yearSelect 기본 옵션은 현재 코드상 2026으로 고정되어 있으므로,
           JS 내부에서 이 값과 select 값 중 무엇을 우선할지 확인하면서 쓰면 됨.
    */
    window.APP_CTX = '${ctx}';
    window.DASH_INIT = {
      year: new Date().getFullYear(),
      month: new Date().getMonth() + 1
    };
  </script>

  <%-- 
    현금/충전 대시보드 전용 스크립트.
    이 파일에서 KPI 텍스트 업데이트, ApexCharts 렌더링, 연도 변경 이벤트 처리 등을 담당.
  --%>
  <script src="${ctx}/js/admindashboardcash.js"></script>
</body>
</html>