<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%-- JSTL: 현재는 core만 사용 중 (fn/fmt는 추후 확장용이면 유지해도 됨) --%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>

<%-- 컨텍스트 경로: /assets 같은 정적 리소스 및 내부 링크에 공통으로 사용 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

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

<%--
    관리자 페이지 전용 커스텀 CSS
    - admin-dashboard 범위 선택자로 감싸서 다른 JSP 페이지에는 영향 없게 설계
  --%>
<link rel="stylesheet" href="${ctx}/assets/css/admincustom.css" />
</head>

<body class="admin-dashboard">

	  <!-- 우상단 버튼(너가 만든 플로팅 include 쓰는 걸 추천) -->
      <jsp:include page="dashboardheader.jsp" />

	<div class="page-wrapper" id="main-wrapper" data-layout="vertical"
		data-navbarbg="skin6" data-sidebartype="full"
		data-sidebar-position="fixed" data-header-position="fixed">

		<%-- =========================
         좌측 사이드바(관리자 메뉴)
         ========================= --%>
		<aside class="left-sidebar">
			<div>

				<div class="brand-logo d-flex align-items-center justify-content-center">
					<a href="${ctx}/admindashboard" class="text-nowrap logo-img"> <img
						src="${ctx}/assets/images/logos/animale-logo.svg" width="150"
						alt="AniMale Logo">
					</a>
				</div>

				<nav class="sidebar-nav scroll-sidebar" data-simplebar="">
					<ul id="sidebarnav">

						<li class="sidebar-item"><a class="sidebar-link"
							href="${ctx}/admindashboard"> <span class="hide-menu">관리자
									대시보드</span>
						</a></li>

						<li class="sidebar-item"><a class="sidebar-link"
							href="${ctx}/adminreportboard"> <span class="hide-menu">신고
									게시글 관리</span>
						</a></li>

					</ul>
				</nav>

			</div>
		</aside>

		<%-- =========================
         본문 영역
         ========================= --%>
		<div class="body-wrapper">

			<%-- <jsp:include page="dashboardheader.jsp" /> --%>

			<div class="container-fluid">

				<%-- =========================
             상단 카드 2개
             ========================= --%>
				<div class="row kpi-top-row">

					<%-- (1) 이번 달 충전 금액 카드 --%>
					<div class="col-lg-7 d-flex align-items-stretch">
						<div class="card w-100 h-100 kpi-card kpi-card--soft cash-kpi-card">
							<div class="card-body cash-summary">

								<div class="cash-summary__inner">

									<div class="cash-summary__text">

										<div class="cash-summary__titleRow">
											<div class="cash-summary__titleLeft">
												<span class="kpi-icon" aria-hidden="true"> <i
													class="ti ti-wallet"></i>
												</span>
												<h5 class="cash-summary__title mb-0">이번 달 충전 금액</h5>
											</div>
										</div>

										<h2 class="cash-summary__amount" id="text-this-month">₩ 0</h2>

										<span class="badge-pill badge-up cash-summary__badge"
											id="text-mom">전월 대비 +0%</span>

										<p class="cash-summary__sub">그래프에 마우스를 올리면 상세 데이터를 볼 수 있어요</p>
									</div>

									<div class="radial-wrap">
										<div id="chart-mom-radial"></div>

										<div class="radial-meta">
											<div class="radial-meta__row">
												<span class="radial-meta__label">이번달 승인 건수</span> <span
													class="radial-meta__value" id="text-charge-count">0건</span>
											</div>
											<div class="radial-meta__row">
												<span class="radial-meta__label">일 평균 충전 금액</span> <span
													class="radial-meta__value" id="text-daily-avg">0</span>
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

								<div class="method-head">
									<h5 class="card-title method-title">충전 수단 비교</h5>
									<div class="method-sub">이번달 기준</div>
								</div>

								<div id="chart-method-bar"></div>

								<%-- 범례: bootstrap mt/py/d-flex 제거하고 전용 클래스만 사용(간격 통제용) --%>
								<div class="method-legend">
									<div class="method-legend__row">
										<div class="method-legend__left">
											<span class="dot" style="background: #1e88ff;"></span> <span
												class="name">카카오페이</span>
										</div>
										<div class="pct" id="text-kakao">0%</div>
									</div>

									<div class="method-legend__row">
										<div class="method-legend__left">
											<span class="dot" style="background: #d0d5dd;"></span> <span
												class="name">토스페이</span>
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

								<div class="monthly-head">
									<h5 class="card-title mb-0">월별 충전 금액</h5>

									<select id="yearSelect" class="form-select">
										<option value="2026" selected>2026년</option>
										<option value="2025">2025년</option>
									</select>									
	<%--<select id="yearSelect" class="form-select"></select> 데이터 추가 시 이렇게 빈 셀렉트로 변경--%>
								</div>

								<%-- 여기 오타 수정: method-legend 쓰면 안 됨. 기존처럼 mt-3 유지 --%>
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
	<script
		src="${ctx}/assets/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
	<script src="${ctx}/assets/js/sidebarmenu.js"></script>
	<script src="${ctx}/assets/js/app.min.js"></script>
	<script src="${ctx}/assets/libs/apexcharts/dist/apexcharts.min.js"></script>
	<script src="${ctx}/assets/libs/simplebar/dist/simplebar.js"></script>

	<script>
 	 // 프로젝트 컨텍스트 경로
 	 // 예) /animale
 	 window.APP_CTX = '${ctx}';

     // 대시보드 초기 조회 기준값(연/월)
 	 // 지금은 서버에서 값을 안 내려주니까, 브라우저 기준 날짜로 잡는다.
 	 // (서버 작업 완료되면 여기 값을 EL로 바꿔서 서버 기준으로 통일하면 됨)
	 window.DASH_INIT = {
      year: new Date().getFullYear(),
      month: new Date().getMonth() + 1 // JS의 month는 0~11이라 +1 필요
 	 };
</script>

	<script src="${ctx}/assets/js/admindashboardcash.js"></script>

</body>
</html>
