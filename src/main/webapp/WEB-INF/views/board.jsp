<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%-- =========================================================
   Board List (board.jsp) - 경로/ctx/정책 보강 최종본
   ---------------------------------------------------------
   ✅ 이번 페이지에서 정리한 포인트

   1) ctx는 request scope로 내려 header.jsp/include에서도 동일하게 사용
   2) 내부 라우팅(링크/폼 action)은 c:url로 생성
      - ctx 중복 방지, 파라미터 인코딩 안전
   3) 글작성 버튼 정책
      - 애니게시판(ANIME) + 제재(SUSPEND_7D/30D)면 UI에서 비활성 처리
      - 클릭은 JS에서 차단(UX 안전장치)
   4) 검색 정책
      - keyword trim + 빈 값 제출 방지
      - 전체보기 링크는 keyword 있을 때만 노출
   ========================================================= --%>

<%-- ✅ CHANGED: ctx를 request scope로 (include 내부에서도 안정적으로 사용) --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 게시판</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">
<link rel="stylesheet" href="${ctx}/css/style.css">
<link rel="stylesheet" href="${ctx}/css/board.css">
</head>

<body>

<jsp:include page="/WEB-INF/common/header.jsp" />

<%-- =========================================================
   컨트롤러 모델 값(가정)
   - boardCategory, condition, keyword, noticeList, boardList
   ========================================================= --%>
<c:set var="boardCategory" value="${requestScope.boardCategory}" />
<c:set var="condition" value="${requestScope.condition}" />
<c:set var="keyword" value="${requestScope.keyword}" />

<%-- keyword trim --%>
<c:set var="keywordTrim" value="${fn:trim(keyword)}" />

<%-- 카테고리 키 표준화 --%>
<c:set var="categoryKey" value="${fn:toUpperCase(fn:trim(boardCategory))}" />
<c:set var="categoryTitle" value="${categoryKey} 게시판" />

<%-- 로그인/제재 상태 --%>
<c:set var="isLogin" value="${not empty sessionScope.memberId}" />
<c:set var="memberStatus" value="${sessionScope.memberStatus}" />

<c:set var="isAnimeBoard" value="${categoryKey eq 'ANIME'}" />
<c:set var="isSuspended" value="${memberStatus eq 'SUSPEND_7D' or memberStatus eq 'SUSPEND_30D'}" />

<%-- 카테고리 타이틀 매핑 --%>
<c:choose>
  <c:when test="${categoryKey eq 'ANIME'}"><c:set var="categoryTitle" value="애니 게시판" /></c:when>
  <c:when test="${categoryKey eq 'FREE'}"><c:set var="categoryTitle" value="자유 게시판" /></c:when>
  <c:when test="${categoryKey eq 'QNA'}"><c:set var="categoryTitle" value="Q&A 게시판" /></c:when>
  <c:when test="${categoryKey eq 'INFO'}"><c:set var="categoryTitle" value="정보 게시판" /></c:when>
</c:choose>

<%-- 검색 조건 기본값/보정 --%>
<c:set var="selectedCondition" value="BOARD_SEARCH_TITLE" />
<c:choose>
  <c:when test="${condition eq 'BOARD_SEARCH_TITLE'}"><c:set var="selectedCondition" value="BOARD_SEARCH_TITLE" /></c:when>
  <c:when test="${condition eq 'BOARD_SEARCH_WRITER'}"><c:set var="selectedCondition" value="BOARD_SEARCH_WRITER" /></c:when>
  <c:when test="${condition eq 'BOARD_SEARCH_CONTENT'}"><c:set var="selectedCondition" value="BOARD_SEARCH_CONTENT" /></c:when>
</c:choose>

<%-- =========================================================
   ✅ CHANGED: 주요 URL은 c:url로 생성 (경로/파라미터 안전)
   ========================================================= --%>
<c:url var="boardListUrl" value="/boardList">
  <c:param name="boardCategory" value="${categoryKey}" />
</c:url>

<c:url var="boardWriteUrl" value="/boardWritePage">
  <c:param name="type" value="BOARD" />
  <c:param name="boardCategory" value="${categoryKey}" />
</c:url>

<section class="product-page spad">
  <div class="container">

    <div class="board-toolbar">
      <div class="board-title-wrap">
        <h3><c:out value="${categoryTitle}" /></h3>
        <p class="board-sub">인기글/공지 확인하고 자유롭게 소통해보세요</p>
      </div>

      <div class="board-actions">

        <%-- ✅ CHANGED: action도 c:url 사용 (기본 카테고리 유지) --%>
        <form id="boardSearchForm" action="${boardListUrl}" method="get" class="board-search-box">
          <input type="hidden" name="boardCategory" value="${categoryKey}" />

          <select name="condition" id="boardSearchType">
            <option value="BOARD_SEARCH_TITLE"  <c:if test="${selectedCondition eq 'BOARD_SEARCH_TITLE'}">selected</c:if>>제목</option>
            <option value="BOARD_SEARCH_WRITER" <c:if test="${selectedCondition eq 'BOARD_SEARCH_WRITER'}">selected</c:if>>작성자</option>
            <option value="BOARD_SEARCH_CONTENT" <c:if test="${selectedCondition eq 'BOARD_SEARCH_CONTENT'}">selected</c:if>>내용</option>
          </select>

          <input type="text" name="keyword" id="boardSearchInput"
                 placeholder="검색어를 입력하세요" value="<c:out value='${keywordTrim}'/>" />

          <button type="submit" title="검색">
            <i class="fa fa-search"></i>
          </button>
        </form>

        <%-- ✅ CHANGED: 전체보기 링크도 c:url 사용 --%>
        <c:if test="${not empty keywordTrim}">
          <a href="${boardListUrl}" class="board-reset-btn">전체보기</a>
        </c:if>

        <%-- 글 작성 버튼: 애니게시판 + 제재면 UI 비활성 + JS로 클릭 차단 --%>
        <c:choose>
          <c:when test="${isLogin and isAnimeBoard and isSuspended}">
            <a href="${boardWriteUrl}"
               class="board-write-btn is-disabled"
               aria-disabled="true"
               data-ban-lock="1">
              글 작성
            </a>
          </c:when>

          <c:otherwise>
            <a href="${boardWriteUrl}" class="board-write-btn">
              글 작성
            </a>
          </c:otherwise>
        </c:choose>

      </div>
    </div>

    <div class="board-list">

      <c:if test="${not empty noticeList}">
        <div class="board-notice">
          <c:forEach var="n" items="${noticeList}">
            <%-- ✅ CHANGED: 상세 링크 c:url --%>
            <c:url var="noticeDetailUrl" value="/boardDetail">
              <c:param name="boardId" value="${n.boardId}" />
            </c:url>

            <div class="board-item notice-item" data-href="${noticeDetailUrl}">
              <div class="board-title">
                <span class="notice-badge">공지</span>
                <a href="${noticeDetailUrl}">
                  <c:out value="${n.boardTitle}" />
                </a>
              </div>
              <div class="board-meta">
                <span><c:out value="${n.writerNickname}" /></span>
                <span>· <i class="fa fa-eye"></i> <c:out value="${empty n.boardViews ? 0 : n.boardViews}" /></span>
                <span>· <i class="fa fa-heart"></i> <c:out value="${empty n.likeCnt ? 0 : n.likeCnt}" /></span>
              </div>
            </div>
          </c:forEach>
        </div>
      </c:if>

      <div class="board-posts">

        <c:if test="${empty boardList}">
          <div class="search-empty board-search-empty">
            <c:choose>
              <c:when test="${not empty keywordTrim}">검색 결과가 없습니다.</c:when>
              <c:otherwise>해당 글이 없습니다.</c:otherwise>
            </c:choose>
          </div>
        </c:if>

        <c:choose>
          <%-- 검색 모드: 그냥 리스트 출력 --%>
          <c:when test="${not empty keywordTrim}">
            <c:forEach var="b" items="${boardList}">
              <c:url var="detailUrl" value="/boardDetail">
                <c:param name="boardId" value="${b.boardId}" />
              </c:url>

              <div class="board-item post-item" data-href="${detailUrl}">
                <div class="board-title">
                  <a href="${detailUrl}">
                    <c:out value="${b.boardTitle}" />
                  </a>
                </div>
                <div class="board-meta">
                  <span><c:out value="${b.writerNickname}" /></span>
                  <span>· <i class="fa fa-eye"></i> <c:out value="${empty b.boardViews ? 0 : b.boardViews}" /></span>
                  <span>· <i class="fa fa-heart"></i> <c:out value="${empty b.likeCnt ? 0 : b.likeCnt}" /></span>
                </div>
              </div>
            </c:forEach>
          </c:when>

          <%-- 일반 모드: 인기글(좋아요 10+) 분리 + 나머지 출력 --%>
          <c:otherwise>

            <c:set var="hasPopular" value="false" />
            <c:forEach var="t" items="${boardList}">
              <c:if test="${not empty t.likeCnt and t.likeCnt ge 10}">
                <c:set var="hasPopular" value="true" />
              </c:if>
            </c:forEach>

            <c:if test="${not empty boardList and hasPopular}">
              <div class="board-popular" style="margin-top:6px; margin-bottom:12px;">
                <div style="margin:6px 0 10px;">
                  <h5 style="margin:0;">🔥 인기글</h5>
                </div>

                <c:forEach var="b" items="${boardList}">
                  <c:if test="${not empty b.likeCnt and b.likeCnt ge 10}">
                    <c:url var="detailUrl" value="/boardDetail">
                      <c:param name="boardId" value="${b.boardId}" />
                    </c:url>

                    <div class="board-item post-item popular-item" data-href="${detailUrl}">
                      <div class="board-title">
                        <a href="${detailUrl}">
                          <c:out value="${b.boardTitle}" />
                        </a>
                      </div>
                      <div class="board-meta">
                        <span><c:out value="${b.writerNickname}" /></span>
                        <span>· <i class="fa fa-eye"></i> <c:out value="${empty b.boardViews ? 0 : b.boardViews}" /></span>
                        <span>· <i class="fa fa-heart"></i> <c:out value="${empty b.likeCnt ? 0 : b.likeCnt}" /></span>
                      </div>
                    </div>
                  </c:if>
                </c:forEach>
              </div>

              <div style="height:1px; background:rgba(255,255,255,0.08); margin:14px 0;"></div>
            </c:if>

            <c:forEach var="b" items="${boardList}">
              <c:if test="${empty b.likeCnt or b.likeCnt lt 10}">
                <c:url var="detailUrl" value="/boardDetail">
                  <c:param name="boardId" value="${b.boardId}" />
                </c:url>

                <div class="board-item post-item" data-href="${detailUrl}">
                  <div class="board-title">
                    <a href="${detailUrl}">
                      <c:out value="${b.boardTitle}" />
                    </a>
                  </div>
                  <div class="board-meta">
                    <span><c:out value="${b.writerNickname}" /></span>
                    <span>· <i class="fa fa-eye"></i> <c:out value="${empty b.boardViews ? 0 : b.boardViews}" /></span>
                    <span>· <i class="fa fa-heart"></i> <c:out value="${empty b.likeCnt ? 0 : b.likeCnt}" /></span>
                  </div>
                </div>
              </c:if>
            </c:forEach>

          </c:otherwise>
        </c:choose>

      </div>

    </div>

  </div>
</section>

<%@ include file="/WEB-INF/common/footer.jsp"%>

<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
<script src="${ctx}/js/bootstrap.min.js"></script>

<script>
  // ✅ CHANGED: 공통 알림 함수 (SweetAlert2 우선 사용)
  // - 헤더에 SweetAlert2 CDN이 있다고 했으므로 Swal.fire 사용
  // - 혹시 로딩 이슈가 생길 경우를 대비해 alert fallback 유지(안전장치)
  function showPageAlert(options, fallbackMessage) {
    if (window.Swal && typeof window.Swal.fire === 'function') {
      return window.Swal.fire(options);
    }
    alert(fallbackMessage || (options && options.text) || '알림');
    return Promise.resolve();
  }

  // 검색어 trim + 빈값 방지
  (function(){
    var form = document.getElementById("boardSearchForm");
    if(!form) return;

    form.addEventListener("submit", function(e){
      var input = document.getElementById("boardSearchInput");
      var k = (input && input.value ? input.value : "").trim();

      // ✅ CHANGED: 기본 alert -> SweetAlert2
      if(!k){
        e.preventDefault();

        showPageAlert({
          icon: 'warning',
          title: '검색어를 입력하세요',
          text: '검색어를 입력한 뒤 다시 검색해주세요.',
          confirmButtonText: '확인'
        }, '검색어를 입력하세요.').then(function () {
          // ✅ CHANGED: 모달 닫힌 뒤 포커스 복원 (UX)
          if (input) input.focus();
        });

        return;
      }

      // ✅ 기존 동작 유지: trim 적용 후 제출
      input.value = k;
    });
  })();

  // ✅ CHANGED: 제재 상태 글작성 버튼 클릭 차단(UX 안전장치)
  (function(){
    var banBtn = document.querySelector(".board-write-btn.is-disabled");
    if(!banBtn) return;

    banBtn.addEventListener("click", function(e){
      e.preventDefault();

      // ✅ CHANGED: 기본 alert -> SweetAlert2
      showPageAlert({
        icon: 'warning',
        title: '작성 제한',
        text: '제재 기간 동안 애니 게시판 글 작성이 제한됩니다.',
        confirmButtonText: '확인'
      }, '제재 기간 동안 애니 게시판 글 작성이 제한됩니다.');

      return false;
    });
  })();

  // 카드 전체 클릭 이동 (제목 a 클릭은 유지)
  (function(){
    var items = document.querySelectorAll(".board-item[data-href]");
    items.forEach(function(item){
      item.addEventListener("click", function(e){
        if(e.target.closest("a")) return;
        location.href = item.getAttribute("data-href");
      });
    });
  })();
</script>

<c:if test="${deletedBoardRedirect}">
<script>
document.addEventListener('DOMContentLoaded', function () {
  // ✅ CHANGED: SweetAlert2로 통일 (헤더 CDN 전제)
  if (window.Swal && typeof window.Swal.fire === 'function') {
    window.Swal.fire({
      icon: 'warning',
      title: '삭제된 게시글입니다',
      text: '신고 처리가 완료된 게시글은 조회할 수 없습니다.',
      confirmButtonText: '확인'
    });
  }
});
</script>
</c:if>

</body>
</html>
