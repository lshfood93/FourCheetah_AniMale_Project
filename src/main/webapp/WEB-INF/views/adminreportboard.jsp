<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

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
     data-sidebartype="full" data-sidebar-position="fixed" data-header-position="fixed">

  <aside class="left-sidebar">
    <div>
      <div class="brand-logo d-flex align-items-center justify-content-center">
        <a href="${ctx}/admindashboard" class="text-nowrap logo-img">
          <img src="${ctx}/images/logos/animale-logo.svg" width="150" alt="AniMale Logo">
        </a>
      </div>

      <nav class="sidebar-nav scroll-sidebar" data-simplebar="">
        <ul id="sidebarnav">
          <li class="sidebar-item ${fn:contains(uri, '/admindashboard') ? 'selected' : ''}">
            <a class="sidebar-link ${fn:contains(uri, '/admindashboard') ? 'active' : ''}"
               href="${ctx}/admindashboard">
              <span class="hide-menu">관리자 대시보드</span>
            </a>
          </li>

						<li
							class="sidebar-item ${fn:contains(uri, '/admin/reports') ? 'selected' : ''}">
							<a
							class="sidebar-link ${fn:contains(uri, '/adminreportboard') ? 'active' : ''}"
							href="${ctx}/adminreportboard"> <span class="hide-menu">신고
									게시글 관리</span>
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

            <!-- ✅ 정렬: URL 이동 X (비동기) -->
            <select id="sortSelect" class="form-select" style="max-width: 180px;"
                    onchange="changeSort(this.value)">
              <option value="desc" ${sortOrder == 'desc' ? 'selected' : ''}>최신순</option>
              <option value="asc"  ${sortOrder == 'asc'  ? 'selected' : ''}>오래된순</option>
            </select>
          </div>

          <p class="text-muted mb-3">제목 / 내용 클릭 시 게시글 상세로 이동합니다.</p>

          <!-- ✅ 테이블 교체 대상 -->
          <div class="table-responsive" id="reportTableWrap">
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

          <!-- ✅ 페이지네이션 교체 대상 -->
          <div id="reportPagingWrap">
            <c:if test="${not empty totalPages and totalPages > 0}">
              <nav class="d-flex justify-content-center mt-4">
                <ul class="pagination mb-0">

                  <li class="page-item ${(currentPage <= 1) ? 'disabled' : ''}">
                    <a class="page-link" href="#"
                       data-page="${currentPage-1}">
                      이전
                    </a>
                  </li>

                  <c:forEach var="p" begin="${startPage}" end="${endPage}">
                    <li class="page-item ${(p == currentPage) ? 'active' : ''}">
                      <a class="page-link" href="#"
                         data-page="${p}">
                        ${p}
                      </a>
                    </li>
                  </c:forEach>

                  <li class="page-item ${(currentPage >= totalPages) ? 'disabled' : ''}">
                    <a class="page-link" href="#"
                       data-page="${currentPage+1}">
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
</div>

<script src="${ctx}/libs/jquery/dist/jquery.min.js"></script>
<script src="${ctx}/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
<script src="${ctx}/js/sidebarmenu.js"></script>
<script src="${ctx}/js/app.min.js"></script>
<script src="${ctx}/libs/simplebar/dist/simplebar.js"></script>

<script>
  const ctx = '${ctx}';
  let currentPage = ${empty currentPage ? 1 : currentPage};
  let currentSort = '${empty sortOrder ? "desc" : sortOrder}';

  // ✅ 승인/반려 POST
  async function postAction(url, boardId) {
    const res = await fetch(url, {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      body: new URLSearchParams({ boardId })
    });
    return res.json();
  }

  // ✅ 목록 GET (URL 이동 X)
  async function reloadReportList(page, sortOrder) {
    const url = `${ctx}/admin/reports?page=${page}&sortOrder=${sortOrder}`;

    const res = await fetch(url, {
      method: 'GET',
      headers: { 'X-Requested-With': 'XMLHttpRequest' }
    });

    const html = await res.text();
    const doc = new DOMParser().parseFromString(html, 'text/html');

    const newTableWrap = doc.querySelector('#reportTableWrap');
    const newPagingWrap = doc.querySelector('#reportPagingWrap');

    if (newTableWrap) {
      document.querySelector('#reportTableWrap').innerHTML = newTableWrap.innerHTML;
    }
    if (newPagingWrap) {
      document.querySelector('#reportPagingWrap').innerHTML = newPagingWrap.innerHTML;
    }

    currentPage = page;
    currentSort = sortOrder;

    // ✅ select UI 동기화
    const sel = document.querySelector('#sortSelect');
    if (sel) sel.value = sortOrder;
  }

  // ✅ 정렬 변경
  function changeSort(sortOrder) {
    reloadReportList(1, sortOrder);
  }

  // ✅ 클릭 이벤트 (페이지네이션 + 승인/반려)
  document.addEventListener('click', async (e) => {
    // 1) 페이지네이션 (비동기)
    const pageA = e.target.closest('a[data-page]');
    if (pageA) {
      e.preventDefault();

      // disabled면 무시
      if (pageA.closest('.page-item')?.classList.contains('disabled')) return;

      const page = parseInt(pageA.dataset.page, 10);
      if (!Number.isFinite(page) || page < 1) return;

      reloadReportList(page, currentSort);
      return;
    }

    // 2) 승인/반려 (비동기)
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
        // 행 삭제 후, 페이지가 비어버리면 현재 페이지 재로딩
        tr.remove();

        const tbody = document.querySelector('#reportTableWrap tbody');
        const hasRow = tbody && tbody.querySelectorAll('tr[id^="row-"]').length > 0;

        if (!hasRow) {
          // 현재 페이지가 비었으면 같은 페이지 다시 불러오되, 최소 1페이지 유지
          const nextPage = Math.max(1, currentPage);
          reloadReportList(nextPage, currentSort);
        }
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