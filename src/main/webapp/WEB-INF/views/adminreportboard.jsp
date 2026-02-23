<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%-- 이 페이지에서 정적 리소스/링크 생성에 계속 쓰는 컨텍스트 경로 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<%-- 현재 요청 URI (사이드바 active/selected 표시용) --%>
<c:set var="uri" value="${pageContext.request.requestURI}" />

<%-- 관리자 페이지 방어:
     세션 role이 없거나 ADMIN이 아니면 관리자 화면 렌더링 전에 메인으로 리다이렉트 --%>
<c:if test="${empty sessionScope.memberRole or sessionScope.memberRole ne 'ADMIN'}">
  <c:redirect url="${ctx}/mainPage" />
</c:if>

<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Admin | Report Board</title>

  <%-- 관리자 템플릿/커스텀 스타일 로드 --%>
  <link rel="icon" type="image/png" href="${ctx}/favicon.png" />
  <link rel="stylesheet" href="${ctx}/css/styles.min.css" />
  <link rel="stylesheet" href="${ctx}/css/admincustom.css" />

  <%-- 액션 확인/완료 알림용 SweetAlert2 (없으면 아래 JS에서 fallback 사용) --%>
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

  <style>
    /* 테이블 내용 미리보기 2줄 말줄임
       신고 목록에서 본문이 길어도 행 높이가 과하게 커지지 않게 고정 */
    .truncate-2{
      display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical;
      overflow:hidden; max-width:560px;
    }

    /* SweetAlert2 사용 불가 시 보여줄 fallback alert 박스 스타일 */
    #actionAlert{
      border-radius: 14px;
      padding: 12px 14px;
    }
    #actionAlert .aa-title{
      font-weight: 800;
      margin-bottom: 6px;
    }

    /* 관리자 처리(승인/반려) 중 화면 중복 클릭 방지용 로딩 오버레이 */
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
          <%-- 현재 URI에 admindashboard가 포함되면 대시보드 메뉴 활성화 --%>
          <li class="sidebar-item ${fn:contains(uri, '/admindashboard') ? 'selected' : ''}">
            <a class="sidebar-link ${fn:contains(uri, '/admindashboard') ? 'active' : ''}"
               href="${ctx}/admindashboard">
              <span class="hide-menu">관리자 대시보드</span>
            </a>
          </li>

          <%-- 신고 게시글 관리 메뉴 활성화:
               예전/현재 경로 둘 다 커버하려고 /admin/reports 와 /adminreportboard 모두 체크 --%>
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
    <%-- 관리자 공통 헤더 포함 --%>
    <jsp:include page="dashboardheader.jsp" />

    <div class="container-fluid">
      <div class="card w-100">
        <div class="card-body">

          <div class="d-flex align-items-center justify-content-between mb-3">
            <h5 class="card-title mb-0">신고 게시글 관리</h5>

            <%-- 정렬 변경 시 페이지 전체 새로고침 대신 JS reloadReportList로 부분 갱신 --%>
            <select id="sortSelect" class="form-select" style="max-width: 180px;"
                    onchange="changeSort(this.value)">
              <option value="desc" ${sortOrder == 'desc' ? 'selected' : ''}>최신순</option>
              <option value="asc"  ${sortOrder == 'asc'  ? 'selected' : ''}>오래된순</option>
            </select>
          </div>

          <p class="text-muted mb-3">제목 / 내용 클릭 시 게시글 상세로 이동합니다.</p>

          <%-- SweetAlert2 미사용/실패 시 fallback 알림 영역 (기본 숨김) --%>
          <div id="actionAlert" class="alert d-none" role="alert"></div>

          <%-- 목록 부분만 비동기로 갈아끼우기 쉽게 래퍼를 분리해둠 --%>
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
                      <%-- 상세페이지 링크는 c:url + c:param 조합으로 안전하게 생성 --%>
                      <c:url var="detailUrl" value="${ctx}/boardDetail">
                        <c:param name="boardId" value="${r.boardId}" />
                      </c:url>

                      <%-- 화면 표시용 값 정리:
                           닉네임이 없으면 '-', 내용이 비면 빈 문자열로 통일해서 출력 안정화 --%>
                      <c:set var="writerName" value="${empty r.boardWriterNickname ? '-' : r.boardWriterNickname}" />
                      <c:set var="rawContent" value="${empty r.boardContent ? '' : r.boardContent}" />

                      <%-- 행 id는 JS에서 승인/반려 후 제거 대상 찾을 때 사용 --%>
                      <tr id="row-${r.boardId}">
                        <td><c:out value="${writerName}" /></td>

                        <td>
                          <a href="${detailUrl}" class="fw-semibold text-decoration-none">
                            <%-- 제목은 c:out으로 출력해서 HTML 태그/XSS 해석 방지 --%>
                            <c:out value="${r.boardTitle}" />
                          </a>
                        </td>

                        <td class="text-center">
                          <span class="badge rounded-pill text-bg-light">
                            <c:out value="${r.reportCount}" />
                          </span>
                        </td>

                        <td>
                          <%-- 본문도 c:out으로 1차 안전 출력.
                               이후 JS에서 stripHtmlTagsFromReportContent로 표시용 정리(태그 제거/공백 정리) --%>
                          <a href="${detailUrl}" class="text-muted text-decoration-none truncate-2 report-content">
                            <c:out value="${rawContent}" />
                          </a>
                        </td>

                        <td class="text-center">
                          <div class="d-inline-flex gap-2">
                            <%-- 반려(패스) 액션:
                                 data-action / data-board-id를 JS가 읽어서 공통 처리 --%>
                            <button class="btn btn-sm btn-outline-primary"
                                    type="button" title="반려(패스)"
                                    data-action="reject" data-board-id="${r.boardId}">
                              <i class="ti ti-x"></i>
                            </button>

                            <%-- 승인(제재) 액션 --%>
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
                    <%-- 목록이 없을 때 안내 행 표시 --%>
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

          <%-- 페이징도 부분 갱신 대상이라 별도 래퍼로 분리 --%>
          <div id="reportPagingWrap">
            <c:if test="${not empty totalPages and totalPages > 0}">
              <nav class="d-flex justify-content-center mt-4">
                <ul class="pagination mb-0">

                  <%-- 이전 페이지 버튼 (1페이지면 disabled) --%>
                  <li class="page-item ${(currentPage <= 1) ? 'disabled' : ''}">
                    <a class="page-link" href="#" data-page="${currentPage-1}">이전</a>
                  </li>

                  <%-- 페이지 번호 범위 출력(startPage ~ endPage) --%>
                  <c:forEach var="p" begin="${startPage}" end="${endPage}">
                    <li class="page-item ${(p == currentPage) ? 'active' : ''}">
                      <a class="page-link" href="#" data-page="${p}">${p}</a>
                    </li>
                  </c:forEach>

                  <%-- 다음 페이지 버튼 (마지막 페이지면 disabled) --%>
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

<%-- 승인/반려 처리 중 중복 클릭 방지 + 처리중 피드백용 오버레이 --%>
<div id="loadingOverlay" class="admin-loading-overlay" style="display:none;">
  <div class="admin-loading-card">
    <div class="admin-spinner"></div>
    <div id="loadingText" class="admin-loading-text">처리 중...</div>
  </div>
</div>

<%-- 관리자 템플릿 JS --%>
<script src="${ctx}/libs/jquery/dist/jquery.min.js"></script>
<script src="${ctx}/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
<script src="${ctx}/js/sidebarmenu.js"></script>
<script src="${ctx}/js/app.min.js"></script>
<script src="${ctx}/libs/simplebar/dist/simplebar.js"></script>

<script>
  /* =========================================================
     이 페이지 JS 흐름
     ---------------------------------------------------------
     1) 페이지네이션/정렬 변경 -> reloadReportList()
        - /admin/reports를 다시 요청
        - 받은 HTML에서 테이블/페이징 부분만 교체(부분 렌더)
     2) 승인/반려 버튼 클릭 -> doAction()
        - confirm -> POST 요청 -> 성공 시 행 제거 or 목록 재조회
     3) 본문 표시 텍스트 정리
        - report-content에 들어간 문자열에서 태그/공백 정리
   ========================================================= */

  /* JSP에서 내려준 서버 값들을 JS 전역 상태로 보관 */
  var ctx = '${ctx}';
  var currentPage = ${empty currentPage ? 1 : currentPage};
  var currentSort = '${empty sortOrder ? "desc" : sortOrder}';

  /* ===== 로딩 오버레이 =====
     승인/반려 처리 중에는 중복 클릭 방지 + 사용자에게 진행중 상태 표시 */
  function showLoading(text) {
    document.getElementById('loadingText').textContent = text || '처리 중...';
    document.getElementById('loadingOverlay').style.display = 'flex';
  }
  function hideLoading() {
    document.getElementById('loadingOverlay').style.display = 'none';
  }

  /* ===== 알림 표시 =====
     우선순위:
     1) SweetAlert2가 있으면 Swal.fire 사용
     2) 없으면 페이지 내 alert DIV(fallback) 사용

     fallback에서도 innerHTML을 쓰기 때문에 message는 escapeHtml 처리해서 넣음 */
  function showActionAlert(type, message) {
    var icon = (type === 'success') ? 'success'
             : (type === 'warning') ? 'warning'
             : (type === 'info')    ? 'info'
             : 'error';

    if (window.Swal && typeof window.Swal.fire === 'function') {
      window.Swal.fire({
    	position: 'center',
    	heightAuto: false,
    	target: document.body,
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

    /* 같은 페이지에서 액션 연속 수행할 수 있으므로
       기존 타이머가 있으면 지우고 새 타이머로 교체 */
    window.clearTimeout(window.__adminReportAlertTimer);
    window.__adminReportAlertTimer = window.setTimeout(function() {
      el.classList.add('d-none');
    }, 5000);
  }

  /* HTML 문자열 삽입 전 최소 이스케이프 유틸 (fallback alert용) */
  function escapeHtml(str) {
    return String(str || '').replace(/[&<>"']/g, function(m) {
      return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m];
    });
  }

  /* ===== POST 요청 공통 함수 =====
     승인/반려 둘 다 boardId만 보내는 구조라 공통화 */
  function postAction(url, boardId) {
    return fetch(url, {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      body: new URLSearchParams({ boardId: boardId })
    }).then(function(res) { return res.json(); });
  }

  /* ===== 목록 새로고침(부분 갱신) =====
     전체 페이지 이동 대신 서버에서 같은 목록 페이지 HTML을 다시 받아서
     #reportTableWrap / #reportPagingWrap만 교체하는 방식

     장점:
     - 서버 JSP 렌더 결과를 그대로 재사용 가능
     - 페이징/정렬 상태 반영이 쉬움
     - 프론트 템플릿 문자열을 따로 만들 필요가 없음 */
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
      /* 서버 응답 HTML을 문서로 파싱해서 필요한 영역만 추출 */
      var doc = new DOMParser().parseFromString(html, 'text/html');

      var newTableWrap = doc.querySelector('#reportTableWrap');
      var newPagingWrap = doc.querySelector('#reportPagingWrap');

      if (newTableWrap) document.querySelector('#reportTableWrap').innerHTML = newTableWrap.innerHTML;
      if (newPagingWrap) document.querySelector('#reportPagingWrap').innerHTML = newPagingWrap.innerHTML;

      /* 부분 갱신 후 현재 상태값도 JS 변수에 맞춰 갱신 */
      currentPage = safePage;
      currentSort = sortOrder;

      /* 정렬 select UI 값도 동기화 */
      var sel = document.querySelector('#sortSelect');
      if (sel) sel.value = sortOrder;

      /* 새로 교체된 목록 본문 텍스트 정리 다시 적용 */
      stripHtmlTagsFromReportContent();
    })
    .catch(function(err) { console.error('[reloadReportList]', err); });
  }

  /* 정렬 select onchange에서 호출 */
  function changeSort(sortOrder) {
    reloadReportList(1, sortOrder);
  }

  /* ===== 본문 표시용 텍스트 정리 =====
     신고 대상 게시글 본문이 HTML/에디터 형식일 수 있어서 목록에서는 태그 없이 짧게 보여주기 용도.
     여기서는 "표시용 텍스트"만 정리하는 함수이고, 원본 데이터/DB를 수정하는 건 아님.

     순서 포인트:
     - br/p 종료/시작 태그를 먼저 공백으로 치환해서 문장 붙는 현상 완화
     - &nbsp; 정리
     - 나머지 태그 제거
     - 공백 압축 + trim */
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

  /* ===== 문서 전체 클릭 이벤트 위임 =====
     동적으로 갈아끼우는 요소(페이징 링크, 승인/반려 버튼)도 계속 동작하게
     개별 바인딩 대신 document 위임 방식 사용 */
  document.addEventListener('click', function(e) {
    // 페이지네이션 클릭 처리
    var pageA = e.target.closest('a[data-page]');
    if (pageA) {
      e.preventDefault();

      /* disabled 버튼이면 무시 (이전/다음 비활성 상태) */
      if (pageA.closest('.page-item') && pageA.closest('.page-item').classList.contains('disabled')) return;

      var page = parseInt(pageA.dataset.page, 10);
      if (!Number.isFinite(page) || page < 1) return;

      reloadReportList(page, currentSort);
      return;
    }

    // 승인/반려 버튼 클릭 처리
    var btn = e.target.closest('[data-action]');
    if (!btn) return;

    var action = btn.dataset.action;
    var boardId = btn.dataset.boardId;
    var tr = btn.closest('tr');

    /* 액션 종류에 따라 확인 문구/로딩 문구 분기 */
    var confirmMsg = (action === 'reject')
      ? '신고를 반려(패스) 처리하시겠습니까?'
      : '신고를 승인(제재) 처리하시겠습니까?';

    var loadingMsg = (action === 'reject') ? '반려 처리 중...' : '승인 처리 중...';

    // 확인창: SweetAlert2 우선, 없으면 기본 confirm fallback
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

  /* ===== 승인/반려 실제 처리 =====
     1) 로딩 오버레이 표시
     2) 액션별 POST 요청
     3) 성공 시 알림 + 현재 행 제거
     4) 현재 화면에서 행이 다 없어졌으면 목록 재조회(빈 상태/다음 데이터 반영) */
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

          /* 처리 완료된 행은 화면에서 즉시 제거해서 반응성 높임 */
          if (tr) tr.remove();

          /* 현재 tbody에 실제 데이터 행(row-*)이 남아있는지 확인
             없으면 같은 페이지 기준으로 다시 조회해서 빈 행/페이징 상태를 서버 기준으로 맞춤 */
          var tbody = document.querySelector('#reportTableWrap tbody');
          var hasRow = tbody && tbody.querySelectorAll('tr[id^="row-"]').length > 0;
          if (!hasRow) reloadReportList(Math.max(1, currentPage), currentSort);

        } else {
          /* 서버가 실패 응답(JSON fail) 준 경우 */
          showActionAlert('danger', (data && data.fail) ? data.fail : '처리 실패');
        }
      })
      .catch(function(err) {
        hideLoading();
        console.error(err);
        showActionAlert('danger', '서버 통신 오류');
      });
  }

  /* 초기 렌더 시점에도 본문 표시 텍스트 정리 1회 적용 */
  document.addEventListener('DOMContentLoaded', function() {
    stripHtmlTagsFromReportContent();
  });
</script>

</body>
</html>