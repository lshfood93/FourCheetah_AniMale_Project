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

  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

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

    /* 로딩 오버레이 */
    .admin-loading-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.45);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 9999;
    }
    .admin-loading-card {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
      padding: 28px 32px;
      border-radius: 16px;
      background: #fff;
      box-shadow: 0 16px 40px rgba(0, 0, 0, 0.18);
      min-width: 160px;
    }
    .admin-spinner {
      width: 32px;
      height: 32px;
      border: 3px solid rgba(13, 110, 253, 0.2);
      border-top-color: #0d6efd;
      border-radius: 50%;
      animation: admin-spin 0.8s linear infinite;
    }
    @keyframes admin-spin {
      from { transform: rotate(0deg); }
      to   { transform: rotate(360deg); }
    }
    .admin-loading-text {
      font-size: 14px;
      font-weight: 700;
      color: #333;
      letter-spacing: -0.2px;
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

            <select id="sortSelect" class="form-select" style="max-width: 180px;"
                    onchange="changeSort(this.value)">
              <option value="desc" ${sortOrder == 'desc' ? 'selected' : ''}>최신순</option>
              <option value="asc"  ${sortOrder == 'asc'  ? 'selected' : ''}>오래된순</option>
            </select>
          </div>

          <p class="text-muted mb-3">제목 / 내용 클릭 시 게시글 상세로 이동합니다.</p>

          <div id="actionAlert" class="alert d-none" role="alert"></div>

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

<div id="loadingOverlay" class="admin-loading-overlay" style="display:none;">
  <div class="admin-loading-card">
    <div class="admin-spinner"></div>
    <div id="loadingText" class="admin-loading-text">처리 중...</div>
  </div>
</div>

<script src="${ctx}/libs/jquery/dist/jquery.min.js"></script>
<script src="${ctx}/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
<script src="${ctx}/js/sidebarmenu.js"></script>
<script src="${ctx}/js/app.min.js"></script>
<script src="${ctx}/libs/simplebar/dist/simplebar.js"></script>

<script>
  var ctx = '${ctx}';
  var currentPage = ${empty currentPage ? 1 : currentPage};
  var currentSort = '${empty sortOrder ? "desc" : sortOrder}';

  /* ===== 로딩 오버레이 ===== */
  function showLoading(text) {
    document.getElementById('loadingText').textContent = text || '처리 중...';
    document.getElementById('loadingOverlay').style.display = 'flex';
  }
  function hideLoading() {
    document.getElementById('loadingOverlay').style.display = 'none';
  }

  /* ===== 알림 (SweetAlert2 우선, fallback은 alert DIV) ===== */
  function showActionAlert(type, message) {
    var icon = (type === 'success') ? 'success'
             : (type === 'warning') ? 'warning'
             : (type === 'info')    ? 'info'
             : 'error';

    if (window.Swal && typeof window.Swal.fire === 'function') {
      window.Swal.fire({
        position: 'top',
        icon: icon,
        title: (icon === 'success') ? '완료' : '알림',
        text: String(message || ''),
        confirmButtonText: '확인',
        allowOutsideClick: false
      });
      return;
    }

    var el = document.getElementById('actionAlert');
    if (!el) return;
    el.className = 'alert alert-' + type;
    el.classList.remove('d-none');
    el.innerHTML =
        '<div class="aa-title">' + (type === 'success' ? '완료' : '실패') + '</div>'
      + '<div>' + escapeHtml(String(message || '')) + '</div>';

    window.clearTimeout(window.__adminReportAlertTimer);
    window.__adminReportAlertTimer = window.setTimeout(function() {
      el.classList.add('d-none');
    }, 5000);
  }

  function escapeHtml(str) {
    return String(str || '').replace(/[&<>"']/g, function(m) {
      return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m];
    });
  }

  /* ===== POST 요청 ===== */
  function postAction(url, boardId) {
    return fetch(url, {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      body: new URLSearchParams({ boardId: boardId })
    }).then(function(res) { return res.json(); });
  }

  /* ===== 목록 새로고침 ===== */
  function reloadReportList(page, sortOrder) {
    var safePage = parseInt(page, 10);
    if (!Number.isFinite(safePage) || safePage < 1) safePage = 1;

    var url = ctx + '/admin/reports?page=' + safePage + '&sortOrder=' + sortOrder;

    return fetch(url, {
      method: 'GET',
      headers: { 'X-Requested-With': 'XMLHttpRequest' }
    })
    .then(function(res) { return res.text(); })
    .then(function(html) {
      var doc = new DOMParser().parseFromString(html, 'text/html');

      var newTableWrap = doc.querySelector('#reportTableWrap');
      var newPagingWrap = doc.querySelector('#reportPagingWrap');

      if (newTableWrap) document.querySelector('#reportTableWrap').innerHTML = newTableWrap.innerHTML;
      if (newPagingWrap) document.querySelector('#reportPagingWrap').innerHTML = newPagingWrap.innerHTML;

      currentPage = safePage;
      currentSort = sortOrder;

      var sel = document.querySelector('#sortSelect');
      if (sel) sel.value = sortOrder;

      stripHtmlTagsFromReportContent();
    })
    .catch(function(err) { console.error('[reloadReportList]', err); });
  }

  function changeSort(sortOrder) {
    reloadReportList(1, sortOrder);
  }

  /* ===== HTML 태그 제거 ===== */
  function stripHtmlTagsFromReportContent() {
    document.querySelectorAll('#reportTableWrap .report-content').forEach(function(el) {
      var t = el.textContent || '';
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

  /* ===== 클릭 이벤트 (페이지네이션 + 승인/반려) ===== */
  document.addEventListener('click', function(e) {
    // 페이지네이션
    var pageA = e.target.closest('a[data-page]');
    if (pageA) {
      e.preventDefault();
      if (pageA.closest('.page-item') && pageA.closest('.page-item').classList.contains('disabled')) return;
      var page = parseInt(pageA.dataset.page, 10);
      if (!Number.isFinite(page) || page < 1) return;
      reloadReportList(page, currentSort);
      return;
    }

    // 승인/반려
    var btn = e.target.closest('[data-action]');
    if (!btn) return;

    var action = btn.dataset.action;
    var boardId = btn.dataset.boardId;
    var tr = btn.closest('tr');

    var confirmMsg = (action === 'reject')
      ? '신고를 반려(패스) 처리하시겠습니까?'
      : '신고를 승인(제재) 처리하시겠습니까?';

    var loadingMsg = (action === 'reject') ? '반려 처리 중...' : '승인 처리 중...';

    // Swal confirm
    if (window.Swal && typeof window.Swal.fire === 'function') {
      window.Swal.fire({
        icon: 'question',
        title: '확인',
        text: confirmMsg,
        showCancelButton: true,
        confirmButtonText: '확인',
        cancelButtonText: '취소',
        allowOutsideClick: false
      }).then(function(result) {
        if (!result.isConfirmed) return;
        doAction(action, boardId, tr, loadingMsg);
      });
    } else {
      if (!confirm(confirmMsg)) return;
      doAction(action, boardId, tr, loadingMsg);
    }
  });

  function doAction(action, boardId, tr, loadingMsg) {
    showLoading(loadingMsg);

    var url = (action === 'reject')
      ? ctx + '/admin/reports/reject'
      : ctx + '/admin/reports/approve';

    postAction(url, boardId)
      .then(function(data) {
        hideLoading();

        if (data && data.ok) {
          showActionAlert('success', data.ok);
          if (tr) tr.remove();

          var tbody = document.querySelector('#reportTableWrap tbody');
          var hasRow = tbody && tbody.querySelectorAll('tr[id^="row-"]').length > 0;
          if (!hasRow) reloadReportList(Math.max(1, currentPage), currentSort);

        } else {
          showActionAlert('danger', (data && data.fail) ? data.fail : '처리 실패');
        }
      })
      .catch(function(err) {
        hideLoading();
        console.error(err);
        showActionAlert('danger', '서버 통신 오류');
      });
  }

  document.addEventListener('DOMContentLoaded', function() {
    stripHtmlTagsFromReportContent();
  });
</script>

</body>
</html>
