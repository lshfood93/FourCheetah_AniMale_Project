<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

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
  <link rel="stylesheet" href="${ctx}/css/styles.min.css" />
  <link rel="stylesheet" href="${ctx}/css/admincustom.css" />

  <style>
    .truncate-2{
      display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical;
      overflow:hidden; max-width:560px;
    }
  </style>
</head>

<body class="admin-dashboard">
<div class="page-wrapper" id="main-wrapper"
     data-layout="vertical" data-navbarbg="skin6"
     data-sidebartype="full" data-sidebar-position="fixed"     data-header-position="fixed">

  <aside class="left-sidebar">
    <div>
      <div class="brand-logo d-flex align-items-center justify-content-center">
        <a href="${ctx}/admindashboard" class="text-nowrap logo-img">
          <img src="${ctx}/images/logos/animale-logo.svg" width="150" alt="AniMale Logo">
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
            <!-- ✅ 무조건 컨트롤러 타는 URL로 통일 -->
            <a class="sidebar-link" href="${ctx}/admin/reports?page=1&sortOrder=desc">
              <span class="hide-menu">신고 게시글 관리</span>
            </a>
          </li>
        </ul>
      </nav>
    </div>
  </aside>

  <div class="body-wrapper">
    <jsp:include page="dashboardheader.jsp" />

    <div class="container-fluid">
      <div class="card w-100">
        <div class="card-body">

          <div class="d-flex align-items-center justify-content-between mb-3">
            <h5 class="card-title mb-0">신고 게시글 관리</h5>

            <!-- ✅ 정렬도 컨트롤러 URL로 통일 -->
            <select class="form-select" style="max-width: 180px;"
                    onchange="location.href='${ctx}/admin/reports?page=1&sortOrder=' + this.value;">
              <option value="desc" ${sortOrder == 'desc' ? 'selected' : ''}>최신순</option>
              <option value="asc"  ${sortOrder == 'asc'  ? 'selected' : ''}>오래된순</option>
            </select>
          </div>

          <p class="text-muted mb-3">제목 / 내용 클릭 시 게시글 상세로 이동합니다.</p>

          <div class="table-responsive">
            <table class="table align-middle">
              <thead>
                <tr>
                  <th style="width:140px;">작성자</th>
                  <th style="width:220px;">제목</th>
                  <th style="width:120px;" class="text-center">신고횟수</th>
                  <th>내용</th>
                  <th style="width:160px;" class="text-center">Action</th>
                </tr>
              </thead>

              <tbody>
                <c:choose>
                  <c:when test="${not empty reports}">
                    <c:forEach var="r" items="${reports}">
                      <!-- ✅ 상세 URL: 프로젝트에 맞게 여기만 유지 -->
                      <c:url var="detailUrl" value="${ctx}/boardDetail">
                        <c:param name="boardId" value="${r.boardId}" />
                      </c:url>

                      <tr id="row-${r.boardId}">
                        <td><c:out value="${r.boardWriterNickname}" /></td>

                        <td>
                          <a href="${detailUrl}" class="fw-semibold text-decoration-none">
                            <c:out value="${r.boardTitle}" />
                          </a>
                        </td>

                        <td class="text-center">
                          <span class="badge rounded-pill text-bg-light">
                            <c:out value="${r.reportCount}" />
                          </span>
                        </td>

                        <td>
                          <a href="${detailUrl}" class="text-muted text-decoration-none truncate-2">
                            <c:out value="${r.boardContent}" />
                          </a>
                        </td>

                        <td class="text-center">
                          <div class="d-inline-flex gap-2">
                            <button class="btn btn-sm btn-outline-primary"
                                    type="button" title="반려(패스)"
                                    data-action="reject" data-board-id="${r.boardId}">
                              <i class="ti ti-x"></i>
                            </button>

                            <button class="btn btn-sm btn-outline-dark"
                                    type="button" title="신고 처리"
                                    data-action="approve" data-board-id="${r.boardId}">
                              <i class="ti ti-check"></i>
                            </button>
                          </div>
                        </td>
                      </tr>
                    </c:forEach>
                  </c:when>

                  <c:otherwise>
                    <tr>
                      <td colspan="5" class="text-center text-muted py-4">
                        표시할 신고 데이터가 없습니다.
                      </td>
                    </tr>
                  </c:otherwise>
                </c:choose>
              </tbody>
            </table>
          </div>

          <!-- ✅ 페이지네이션 URL도 통일 -->
          <c:if test="${not empty totalPages and totalPages > 0}">
            <nav class="d-flex justify-content-center mt-4">
              <ul class="pagination mb-0">

                <li class="page-item ${(currentPage <= 1) ? 'disabled' : ''}">
                  <a class="page-link"
                     href="${ctx}/admin/reports?page=${currentPage-1}&sortOrder=${sortOrder}">
                    이전
                  </a>
                </li>

                <c:forEach var="p" begin="${startPage}" end="${endPage}">
                  <li class="page-item ${(p == currentPage) ? 'active' : ''}">
                    <a class="page-link"
                       href="${ctx}/admin/reports?page=${p}&sortOrder=${sortOrder}">
                      ${p}
                    </a>
                  </li>
                </c:forEach>

                <li class="page-item ${(currentPage >= totalPages) ? 'disabled' : ''}">
                  <a class="page-link"
                     href="${ctx}/admin/reports?page=${currentPage+1}&sortOrder=${sortOrder}">
                    다음
                  </a>
                </li>

              </ul>
            </nav>
          </c:if>

        </div>
      </div>
    </div>
  </div>
</div>

<script src="${ctx}/libs/jquery/dist/jquery.min.js"></script>
<script src="${ctx}/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
<script src="${ctx}/js/sidebarmenu.js"></script>
<script src="${ctx}/js/app.min.js"></script>
<script src="${ctx}/libs/simplebar/dist/simplebar.js"></script>

<!-- ✅ JS는 이것 “하나만” 남기기 -->
<script>
  const ctx = '${ctx}';

  async function postAction(url, boardId) {
    const res = await fetch(url, {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      body: new URLSearchParams({ boardId })
    });
    return res.json();
  }

  document.addEventListener('click', async (e) => {
    const btn = e.target.closest('[data-action]');
    if(!btn) return;

    const action = btn.dataset.action;     // reject | approve
    const boardId = btn.dataset.boardId;
    const tr = btn.closest('tr');

    const msg = (action === 'reject')
      ? '신고를 반려하시겠습니까?'
      : '신고를 승인(제재)하시겠습니까?';

    if(!confirm(msg)) return;

    try {
      const url = (action === 'reject')
        ? `${ctx}/admin/reports/reject`
        : `${ctx}/admin/reports/approve`;

      const data = await postAction(url, boardId);

      if(data.ok){
        tr.remove();
      } else {
        alert(data.fail || '처리 실패');
      }
    } catch (err) {
      console.error(err);
      alert('서버 통신 오류');
    }
  });
</script>

</body>
</html>