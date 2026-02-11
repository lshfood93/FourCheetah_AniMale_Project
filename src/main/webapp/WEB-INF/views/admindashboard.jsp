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
<link rel="icon" type="image/png"
	href="${ctx}/assets/images/logos/favicon.png" />
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
	<div class="page-wrapper" id="main-wrapper" data-layout="vertical"
		data-navbarbg="skin6" data-sidebartype="full"
		data-sidebar-position="fixed" data-header-position="fixed">

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
				<div
					class="brand-logo d-flex align-items-center justify-content-between">
					<a href="${ctx}/admindashboard" class="text-nowrap logo-img"> <img
						src="${ctx}/assets/images/logos/animale-logo.svg" width="150"
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
						<li class="sidebar-item"><a class="sidebar-link"
							href="${ctx}/admindashboard"> <span class="hide-menu">관리자
									대시보드</span>
						</a></li>

						<%-- (2) 신고 게시글 관리(추후 페이지/컨트롤러 연결 예정) --%>
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

			<%--
        상단 헤더는 다른 사람이 작업한다 했으니 include만 유지
        - 헤더 내부 레이아웃/스타일은 여기서 신경 쓰지 않음

        <jsp:include page="dashboardheader.jsp" />
      --%>

			<div class="container-fluid">

				<%-- =========================
             상단 카드 2개
             1) 이번 달 충전 금액 + 전월 대비(원형)
             2) 충전 수단 비교(100% 가로 스택)
             - 주의: col은 반드시 같은 row 안에 있어야 정렬이 정상 동작함
             ========================= --%>
				<div class="row">

					<%-- (1) 이번 달 충전 금액 카드 --%>
					<div class="col-lg-7 d-flex align-items-stretch">

						<%--
              kpi-card / kpi-card--soft
              - admincustom.css에서 카드 라운드/톤을 레퍼런스처럼 조정할 때 쓰는 확장 클래스(없어도 동작은 함)
              cash-summary
              - 카드1 전용 레이아웃 훅
              cash-kpi-card
              - 카드1에서 tooltip overflow 잘림 방지를 위해 overflow visible을 적용하기 위한 클래스
            --%>
						<div class="card w-100 kpi-card kpi-card--soft cash-kpi-card">
							<div class="card-body cash-summary">

								<%--
                  최종 구조(중요)
                  - grid를 걸어주는 래퍼(.cash-summary__inner)가 반드시 있어야
                    좌(텍스트) / 우(원형) 2컬럼이 유지됨
                  - id(text-this-month / text-mom / chart-mom-radial) 중복이 없어야 JS 렌더링이 정상 동작함
                --%>
								<div class="cash-summary__inner">

									<%-- 왼쪽 텍스트 영역 --%>
									<div class="cash-summary__text">

										<%-- 상단: 아이콘 + 타이틀(레퍼런스 느낌) --%>
										<div class="cash-summary__titleRow">
											<div class="cash-summary__titleLeft">
												<%-- 아이콘(외부 아이콘 라이브러리 없이도 동작) --%>
												<span class="kpi-icon" aria-hidden="true">👛</span>
												<h5 class="cash-summary__title mb-0">이번 달 충전 금액</h5>
											</div>
										</div>

										<%-- 중단: 금액(크게) --%>
										<h2 class="cash-summary__amount" id="text-this-month">₩ 0</h2>

										<%-- 하단: 배지(금액 아래로 내려서 '떨어져 보이게') --%>
										<span class="badge-pill badge-up cash-summary__badge"
											id="text-mom">전월 대비 +0%</span>

										<%-- 안내 문구 --%>
										<p class="cash-summary__sub">그래프에 마우스를 올리면 상세 데이터를 볼 수 있어요</p>
									</div>

									<%--
                    오른쪽 원형 그래프 영역
                    - JS에서 #chart-mom-radial에 ApexCharts radialBar 렌더링
                    - 중앙 텍스트는 제거하고(깔끔)
                    - hover 시 커스텀 툴팁으로 상세 비교 표시
                  --%>
									<div class="radial-wrap">
										<%-- 원형 그래프 렌더링 대상(필수) --%>
										<div id="chart-mom-radial"></div>

										<%-- 오른쪽 보조 KPI(원형 아래) --%>
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
						<div class="card w-100 overflow-hidden kpi-card">
							<div class="card-body">

								<div
									class="d-flex align-items-center justify-content-between mb-2">
									<h5 class="card-title mb-0">충전 수단 비교</h5>
								</div>

								<%--
                  100% 가로 스택 1개
                  - JS에서 #chart-method-bar에 ApexCharts bar 렌더링
                  - 카카오페이/토스페이가 하나의 막대(총합 100%) 안에서 나뉘어 보여서
                    비율 차이가 훨씬 직관적으로 보임
                --%>
								<div id="chart-method-bar"></div>

								<%--
                  수단별 라벨/퍼센트 표시
                  - JS에서 #text-kakao, #text-toss 값을 주입
                  - 점(색상)은 현재 inline style, 추후 css 클래스로 빼도 됨
                --%>
								<div class="mt-3">
									<div
										class="d-flex align-items-center justify-content-between py-1">
										<div class="d-flex align-items-center gap-2">
											<span class="rounded-circle d-inline-block"
												style="width: 10px; height: 10px; background: #1e88ff;"></span>
											<span class="text-muted">카카오페이</span>
										</div>
										<div class="fw-semibold" id="text-kakao">0%</div>
									</div>

									<div
										class="d-flex align-items-center justify-content-between py-1">
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
             하단: 월별 충전 금액(Area chart)
             ========================= --%>
				<div class="row">
					<div class="col-lg-12">
						<div class="card w-100 overflow-hidden kpi-card">
							<div class="card-body">

								<div class="d-flex align-items-center justify-content-between">
									<h5 class="card-title mb-0">월별 충전 금액</h5>

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
	<script
		src="${ctx}/assets/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
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
