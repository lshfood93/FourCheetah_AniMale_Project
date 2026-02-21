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

    #actionAlert{
      border-radius: 14px;
      padding: 12px 14px;
    }
    #actionAlert .aa-title{
      font-weight: 800;
      margin-bottom: 6px;
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

          <li class="sidebar-item ${fn:contains(uri, '/admin/reports') or fn:contains(uri, '/adminreportboard') ? 'selected' : ''}">
            <a class="sidebar-link ${fn:contains(uri, '/admin/reports') or fn:contains(uri, '/adminreportboard') ? 'active' : ''}"
               href="${ctx}/admin/reports">
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

            <!-- ✅ 정렬: URL 이동 X (비동기) -->
            <select id="sortSelect" class="form-select" style="max-width: 180px;"
                    onchange="changeSort(this.value)">
              <option value="desc" ${sortOrder == 'desc' ? 'selected' : ''}>최신순</option>
              <option value="asc"  ${sortOrder == 'asc'  ? 'selected' : ''}>오래된순</option>
            </select>
          </div>

          <p class="text-muted mb-3">제목 / 내용 클릭 시 게시글 상세로 이동합니다.</p>

          <!-- ✅ 처리 결과 메시지 -->
          <div id="actionAlert" class="alert d-none" role="alert"></div>

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

                      <!-- ✅ DTO에 값이 없을 수 있으니 안전 처리 -->
                      <c:set var="writerName" value="${empty r.boardWriterNickname ? '-' : r.boardWriterNickname}" />
                      <c:set var="rawContent" value="${empty r.boardContent ? '' : r.boardContent}" />

                      <tr id="row-${r.boardId}">
                        <td><c:out value="${writerName}" /></td>

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
                          <a href="${detailUrl}" class="text-muted text-decoration-none truncate-2 report-content">
                            <c:out value="${rawContent}" />
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
                    <a class="page-link" href="#" data-page="${currentPage-1}">이전</a>
                  </li>

                  <c:forEach var="p" begin="${startPage}" end="${endPage}">
                    <li class="page-item ${(p == currentPage) ? 'active' : ''}">
                      <a class="page-link" href="#" data-page="${p}">${p}</a>
                    </li>
                  </c:forEach>

                  <li class="page-item ${(currentPage >= totalPages) ? 'disabled' : ''}">
                    <a class="page-link" href="#" data-page="${currentPage+1}">다음</a>
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

  async function postAction(url, boardId) {
    const res = await fetch(url, {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      body: new URLSearchParams({ boardId: boardId })
    });
    return res.json();
  }

  function showActionAlert(type, message) {
    const el = document.getElementById('actionAlert');
    if (!el) return;

    el.className = 'alert alert-' + type;
    el.classList.remove('d-none');
    el.innerHTML = '<div class="aa-title">' + (type === 'success' ? '완료' : '실패') + '</div>'
                 + '<div>' + escapeHtml(String(message || '')) + '</div>';

    window.clearTimeout(window.__adminReportAlertTimer);
    window.__adminReportAlertTimer = window.setTimeout(() => {
      el.classList.add('d-none');
    }, 5000);
  }

  function escapeHtml(str) {
    return str.replace(/[&<>"']/g, (m) => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[m]));
  }

  function stripHtmlTagsFromReportContent(){
    document.querySelectorAll('#reportTableWrap .report-content').forEach(el => {
      const t = el.textContent || '';
      el.textContent = t
        .replace(/<\s*br\s*\/?\s*>/gi, ' ')
        .replace(/<\s*\/\s*p\s*>/gi, ' ')
        .replace(/<\s*p\b[^>]*>/gi, ' ')
        .replace(/&nbsp;/gi, ' ')
        .replace(/<[^>]*>/g, '')
        .replace(/\s+/g, ' ')
        .trim();
    });
  }

  async function reloadReportList(page, sortOrder) {
    const url = ctx + '/admin/reports?page=' + page + '&sortOrder=' + sortOrder;

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

    const sel = document.querySelector('#sortSelect');
    if (sel) sel.value = sortOrder;

    stripHtmlTagsFromReportContent();
  }

  function changeSort(sortOrder) {
    reloadReportList(1, sortOrder);
  }

  document.addEventListener('click', async (e) => {
    // 페이지네이션
    const pageA = e.target.closest('a[data-page]');
    if (pageA) {
      e.preventDefault();
      if (pageA.closest('.page-item') && pageA.closest('.page-item').classList.contains('disabled')) return;

      const page = parseInt(pageA.dataset.page, 10);
      if (!Number.isFinite(page) || page < 1) return;

      reloadReportList(page, currentSort);
      return;
    }

    // 승인/반려
    const btn = e.target.closest('[data-action]');
    if(!btn) return;

    const action = btn.dataset.action;     // reject | approve
    const boardId = btn.dataset.boardId;
    const tr = btn.closest('tr');

    const confirmMsg = (action === 'reject')
      ? '신고를 반려(패스) 처리하시겠습니까?'
      : '신고를 승인(제재) 처리하시겠습니까?';

    if(!confirm(confirmMsg)) return;

    try {
      const url = (action === 'reject')
        ? (ctx + '/admin/reports/reject')
        : (ctx + '/admin/reports/approve');

      const data = await postAction(url, boardId);

      // ✅ 컨트롤러 응답 포맷에 맞춘 성공/실패 판정
      // 성공: data.ok 존재(문자열)
      // 실패: data.fail 존재(문자열)
      if (data && data.ok) {
        showActionAlert('success', data.ok);

        // 성공이면 행 제거
        if (tr) tr.remove();

        // 행이 다 사라지면 현재 페이지 재로딩
        const tbody = document.querySelector('#reportTableWrap tbody');
        const hasRow = tbody && tbody.querySelectorAll('tr[id^="row-"]').length > 0;
        if (!hasRow) reloadReportList(Math.max(1, currentPage), currentSort);

      } else {
        showActionAlert('danger', (data && data.fail) ? data.fail : '처리 실패');
      }

    } catch (err) {
      console.error(err);
      showActionAlert('danger', '서버 통신 오류');
    }
  });

  document.addEventListener('DOMContentLoaded', () => {
    stripHtmlTagsFromReportContent();
  });
</script>

</body>
</html>