<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!-- ✅ 관리자만 접근 -->
<c:if test="${empty sessionScope.memberRole or sessionScope.memberRole ne 'ADMIN'}">
  <c:redirect url="${ctx}/mainPage" />
</c:if>

<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Admin | Report Board</title>

  <link rel="icon" type="image/png" href="${ctx}/favicon.png" />
  <link rel="stylesheet" href="${ctx}/assets/css/styles.min.css" />
  <link rel="stylesheet" href="${ctx}/assets/css/admincustom.css" />
</head>

<body class="admin-dashboard">

  <div class="page-wrapper"
       id="main-wrapper"
       data-layout="vertical"
       data-navbarbg="skin6"
       data-sidebartype="full"
       data-sidebar-position="fixed"
       data-header-position="fixed">

    <!-- 사이드바 -->
    <aside class="left-sidebar">
      <div>
        <div class="brand-logo d-flex align-items-center justify-content-center">
          <a href="${ctx}/admindashboard" class="text-nowrap logo-img">
            <img src="${ctx}/assets/images/logos/animale-logo.svg" width="150" alt="AniMale Logo">
          </a>
        </div>

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

    <!-- 본문 -->
    <div class="body-wrapper">

      <!-- ✅ 우상단 플로팅(공용 include) -->
      <jsp:include page="dashboardheader.jsp" />

      <div class="container-fluid">

        <!-- 신고 게시글 관리(UI) -->
        <div class="card w-100">
          <div class="card-body">

            <div class="d-flex align-items-center justify-content-between mb-3">
              <h5 class="card-title mb-0">신고 게시글 관리</h5>

              <!-- 정렬(select) - 서버 연동 시 name/value 넣어서 submit 또는 JS fetch로 연결 -->
              <select class="form-select" style="max-width: 180px;">
                <option selected>최신순</option>
                <option>오래된순</option>
              </select>
            </div>

            <p class="text-muted mb-3">제목 / 내용 클릭 시 게시글 이동</p>

            <div class="table-responsive">
              <table class="table align-middle">
                <thead>
                  <tr>
                    <th style="width:140px;">작성자ID</th>
                    <th style="width:220px;">제목</th>
                    <th style="width:120px;" class="text-center">신고횟수</th>
                    <th>내용</th>
                    <th style="width:140px;" class="text-center">Action</th>
                  </tr>
                </thead>

                <tbody>
                  <!-- ✅ 서버 연동 전 샘플(더미) -->
                  <tr>
                    <td>이현빈</td>
                    <td><a href="javascript:void(0);" class="fw-semibold text-decoration-none">마린조아</a></td>
                    <td class="text-center"><span class="badge rounded-pill text-bg-light">36</span></td>
                    <td><a href="javascript:void(0);" class="text-muted text-decoration-none">마린우히히</a></td>
                    <td class="text-center">
                      <div class="d-inline-flex gap-2">
                        <button class="btn btn-sm btn-outline-primary" type="button" title="반려(패스)">
                          <i class="ti ti-x"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-dark" type="button" title="신고 처리">
                          <i class="ti ti-check"></i>
                        </button>
                      </div>
                    </td>
                  </tr>

                  <tr>
                    <td>최준혁</td>
                    <td><a href="javascript:void(0);" class="fw-semibold text-decoration-none">술줘</a></td>
                    <td class="text-center"><span class="badge rounded-pill text-bg-light">5</span></td>
                    <td><a href="javascript:void(0);" class="text-muted text-decoration-none">부어라마셔라</a></td>
                    <td class="text-center">
                      <div class="d-inline-flex gap-2">
                        <button class="btn btn-sm btn-outline-primary" type="button" title="반려(패스)">
                          <i class="ti ti-x"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-dark" type="button" title="신고 처리">
                          <i class="ti ti-check"></i>
                        </button>
                      </div>
                    </td>
                  </tr>

                  <tr>
                    <td>김영인</td>
                    <td><a href="javascript:void(0);" class="fw-semibold text-decoration-none">치킨공주</a></td>
                    <td class="text-center"><span class="badge rounded-pill text-bg-light">99</span></td>
                    <td><a href="javascript:void(0);" class="text-muted text-decoration-none">난피자보다치킨이좋아</a></td>
                    <td class="text-center">
                      <div class="d-inline-flex gap-2">
                        <button class="btn btn-sm btn-outline-primary" type="button" title="반려(패스)">
                          <i class="ti ti-x"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-dark" type="button" title="신고 처리">
                          <i class="ti ti-check"></i>
                        </button>
                      </div>
                    </td>
                  </tr>

                  <tr>
                    <td>이승환</td>
                    <td><a href="javascript:void(0);" class="fw-semibold text-decoration-none">닭목살킬러</a></td>
                    <td class="text-center"><span class="badge rounded-pill text-bg-light">999</span></td>
                    <td><a href="javascript:void(0);" class="text-muted text-decoration-none">에다가 오이라면까지</a></td>
                    <td class="text-center">
                      <div class="d-inline-flex gap-2">
                        <button class="btn btn-sm btn-outline-primary" type="button" title="반려(패스)">
                          <i class="ti ti-x"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-dark" type="button" title="신고 처리">
                          <i class="ti ti-check"></i>
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- 페이징(UI) -->
            <nav class="d-flex justify-content-center mt-4">
              <ul class="pagination mb-0">
                <li class="page-item"><a class="page-link" href="javascript:void(0);">이전</a></li>
                <li class="page-item active"><a class="page-link" href="javascript:void(0);">1</a></li>
                <li class="page-item"><a class="page-link" href="javascript:void(0);">2</a></li>
                <li class="page-item"><a class="page-link" href="javascript:void(0);">3</a></li>
                <li class="page-item"><a class="page-link" href="javascript:void(0);">다음</a></li>
              </ul>
            </nav>

          </div>
        </div>

      </div>
    </div>
  </div>

  <!-- 템플릿 JS -->
  <script src="${ctx}/assets/libs/jquery/dist/jquery.min.js"></script>
  <script src="${ctx}/assets/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
  <script src="${ctx}/assets/js/sidebarmenu.js"></script>
  <script src="${ctx}/assets/js/app.min.js"></script>
  <script src="${ctx}/assets/libs/simplebar/dist/simplebar.js"></script>
</body>
</html>
