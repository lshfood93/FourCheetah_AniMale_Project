<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Admin | 신고 게시글 관리</title>

  <link rel="icon" type="image/png" href="${ctx}/assets/images/logos/favicon.png" />
  <link rel="stylesheet" href="${ctx}/assets/css/styles.min.css" />
  <link rel="stylesheet" href="${ctx}/assets/css/admincustom.css" />
</head>

<body class="admin-dashboard">
  <div class="page-wrapper" id="main-wrapper"
       data-layout="vertical" data-navbarbg="skin6" data-sidebartype="full"
       data-sidebar-position="fixed" data-header-position="fixed">

    <!-- 좌측 사이드바 -->
    <aside class="left-sidebar">
      <div>
        <div class="brand-logo d-flex align-items-center justify-content-between">
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
      <jsp:include page="dashboardheader.jsp" />

      <div class="container-fluid">

        <div class="card w-100">
          <div class="card-body">
            <h5 class="card-title mb-3">신고 게시글 목록</h5>

            <!-- 더미 리스트: reportList -->
            <div class="table-responsive">
              <table class="table align-middle text-nowrap mb-0">
                <thead>
                  <tr class="border-0">
                    <th>신고ID</th>
                    <th>게시글ID</th>
                    <th>사유</th>
                    <th>신고자</th>
                    <th>상태</th>
                    <th class="text-end">처리</th>
                  </tr>
                </thead>
                <tbody>
                  <c:forEach var="r" items="${reportList}">
                    <tr>
                      <td>${r.reportId}</td>
                      <td>${r.boardId}</td>
                      <td>${r.reason}</td>
                      <td>${r.reporter}</td>
                      <td>
                        <span class="badge bg-warning">${r.status}</span>
                      </td>
                      <td class="text-end">
                        <a class="btn btn-sm btn-outline-secondary"
                           href="${ctx}/adminreportboard/detail?reportId=${r.reportId}">
                          게시글 상세보기
                        </a>

                        <a class="btn btn-sm btn-outline-primary"
                           href="${ctx}/adminreportboard/action/confirm?reportId=${r.reportId}">
                          조치 확인
                        </a>

                        <a class="btn btn-sm btn-outline-danger"
                           href="${ctx}/adminreportboard/action/delete?reportId=${r.reportId}">
                          게시글 내용 삭제
                        </a>
                      </td>
                    </tr>
                  </c:forEach>

                  <c:if test="${empty reportList}">
                    <tr>
                      <td colspan="6" class="text-center text-muted py-4">
                        신고 내역이 없습니다.
                      </td>
                    </tr>
                  </c:if>
                </tbody>
              </table>
            </div>

          </div>
        </div>

      </div>
    </div>

  </div>

  <script src="${ctx}/assets/libs/jquery/dist/jquery.min.js"></script>
  <script src="${ctx}/assets/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
  <script src="${ctx}/assets/js/sidebarmenu.js"></script>
  <script src="${ctx}/assets/js/app.min.js"></script>
  <script src="${ctx}/assets/libs/simplebar/dist/simplebar.js"></script>

</body>
</html>
