<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%-- =========================================================
   Board List (board.jsp)
   ---------------------------------------------------------
   이 페이지의 핵심 목적:
   1) 카테고리별 게시글 목록 출력
   2) 공지(noticeList)와 일반글(boardList) 표시
   3) 검색(condition + keyword) 처리
   4) 글쓰기 버튼 정책(로그인/제재 상태 반영)
   5) 카드 전체 클릭 이동 UX 제공

   복습 포인트:
   - ctx를 request scope로 둬서 include된 header/footer에서도 안정적으로 사용
   - 내부 링크/액션은 c:url로 생성해서 경로/파라미터 안전하게 관리
   - 화면단에서도 제재 상태를 반영해 글쓰기 버튼 UX 제어
   - 검색어 trim + 빈값 제출 방지로 불필요 요청 차단
   ========================================================= --%>

<%-- 
  공통 contextPath를 request scope에 저장.
  이유:
  - 이 페이지는 <jsp:include>로 header.jsp를 포함하고 있음
  - include 내부에서도 같은 ctx를 참조할 수 있게 request scope로 맞춰두면
    경로가 엇갈리거나 page scope 범위 문제를 줄일 수 있음
--%>
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
   컨트롤러에서 내려주는 주요 모델 값 (이 페이지가 기대하는 입력값)
   ---------------------------------------------------------
   - boardCategory : 현재 게시판 카테고리 (ANIME / FREE / QNA / INFO ...)
   - condition     : 검색 조건 (제목/작성자/내용)
   - keyword       : 검색어
   - noticeList    : 공지글 목록
   - boardList     : 일반 게시글 목록 (또는 검색 결과 목록)
   ========================================================= --%>
<c:set var="boardCategory" value="${requestScope.boardCategory}" />
<c:set var="condition" value="${requestScope.condition}" />
<c:set var="keyword" value="${requestScope.keyword}" />

<%-- 
  검색어 앞뒤 공백 제거.
  이유:
  - 사용자가 '  나루토  '처럼 입력해도 의미 있는 검색어만 남기기 위함
  - 전체보기 버튼 노출 조건 / 빈값 판별 기준을 통일하기 위함
--%>
<c:set var="keywordTrim" value="${fn:trim(keyword)}" />

<%-- 
  카테고리 키 표준화.
  boardCategory가 소문자/공백 섞여 들어와도 비교를 안정적으로 하기 위해
  trim + 대문자 변환 후 categoryKey 하나를 기준값으로 사용한다.
--%>
<c:set var="categoryKey" value="${fn:toUpperCase(fn:trim(boardCategory))}" />

<%-- 
  기본 카테고리 제목.
  아래 c:choose에서 알려진 카테고리(ANIME/FREE/QNA/INFO)는 한글 제목으로 치환하고,
  그 외 값은 기본값("${categoryKey} 게시판")으로 표시되도록 구성.
--%>
<c:set var="categoryTitle" value="${categoryKey} 게시판" />

<%-- 
  로그인/제재 상태 계산용 플래그.
  화면 정책(글쓰기 버튼 노출/비활성)에 사용됨.
--%>
<c:set var="isLogin" value="${not empty sessionScope.memberId}" />
<c:set var="memberStatus" value="${sessionScope.memberStatus}" />

<%-- 
  애니 게시판 여부 / 제재 상태 여부 계산.
  현재 정책:
  - 애니 게시판(ANIME)에서만 제재 사용자 글쓰기 제한 UI 적용
  - 제재 상태는 SUSPEND_7D, SUSPEND_30D를 제한 대상으로 판단
--%>
<c:set var="isAnimeBoard" value="${categoryKey eq 'ANIME'}" />
<c:set var="isSuspended" value="${memberStatus eq 'SUSPEND_7D' or memberStatus eq 'SUSPEND_30D'}" />

<%-- 
  카테고리 코드 -> 화면 제목 매핑.
  categoryKey는 비교 기준값, categoryTitle은 최종 출력용 문구.
--%>
<c:choose>
  <c:when test="${categoryKey eq 'ANIME'}"><c:set var="categoryTitle" value="애니 게시판" /></c:when>
  <c:when test="${categoryKey eq 'FREE'}"><c:set var="categoryTitle" value="자유 게시판" /></c:when>
  <c:when test="${categoryKey eq 'QNA'}"><c:set var="categoryTitle" value="Q&A 게시판" /></c:when>
  <c:when test="${categoryKey eq 'INFO'}"><c:set var="categoryTitle" value="정보 게시판" /></c:when>
</c:choose>

<%-- 
  검색 조건 기본값/보정 로직.
  컨트롤러에서 condition이 비어 있거나 예상 외 값이 와도
  기본값(제목 검색)으로 안전하게 동작하도록 selectedCondition을 먼저 세팅한다.
--%>
<c:set var="selectedCondition" value="BOARD_SEARCH_TITLE" />
<c:choose>
  <c:when test="${condition eq 'BOARD_SEARCH_TITLE'}"><c:set var="selectedCondition" value="BOARD_SEARCH_TITLE" /></c:when>
  <c:when test="${condition eq 'BOARD_SEARCH_WRITER'}"><c:set var="selectedCondition" value="BOARD_SEARCH_WRITER" /></c:when>
  <c:when test="${condition eq 'BOARD_SEARCH_CONTENT'}"><c:set var="selectedCondition" value="BOARD_SEARCH_CONTENT" /></c:when>
</c:choose>

<%-- =========================================================
   페이지에서 자주 사용하는 내부 URL 미리 생성
   ---------------------------------------------------------
   c:url 사용 이유:
   - contextPath 자동 반영
   - 파라미터 인코딩 안전
   - 링크 생성 규칙을 한 곳에서 관리 가능
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
        <%-- 최종 매핑된 게시판 제목 출력 --%>
        <h3><c:out value="${categoryTitle}" /></h3>
        <p class="board-sub">인기글/공지 확인하고 자유롭게 소통해보세요</p>
      </div>

      <div class="board-actions">

        <%-- 
          검색 폼
          - action은 boardListUrl 사용 (현재 카테고리 유지)
          - hidden boardCategory를 함께 보내서 검색 후에도 같은 게시판 유지
          - condition + keyword 조합으로 검색
        --%>
        <form id="boardSearchForm" action="${boardListUrl}" method="get" class="board-search-box">
          <input type="hidden" name="boardCategory" value="${categoryKey}" />

          <%-- 검색 조건 선택 박스: selectedCondition 기준으로 선택 유지 --%>
          <select name="condition" id="boardSearchType">
            <option value="BOARD_SEARCH_TITLE"  <c:if test="${selectedCondition eq 'BOARD_SEARCH_TITLE'}">selected</c:if>>제목</option>
            <option value="BOARD_SEARCH_WRITER" <c:if test="${selectedCondition eq 'BOARD_SEARCH_WRITER'}">selected</c:if>>작성자</option>
            <option value="BOARD_SEARCH_CONTENT" <c:if test="${selectedCondition eq 'BOARD_SEARCH_CONTENT'}">selected</c:if>>내용</option>
          </select>

          <%-- 
            검색어 입력값은 trim된 값을 다시 보여줌.
            c:out으로 출력해서 특수문자 포함 검색어도 안전하게 렌더링.
          --%>
          <input type="text" name="keyword" id="boardSearchInput"
                 placeholder="검색어를 입력하세요" value="<c:out value='${keywordTrim}'/>" />

          <button type="submit" title="검색">
            <i class="fa fa-search"></i>
          </button>
        </form>

        <%-- 
          전체보기 버튼은 검색 상태일 때만 노출.
          keywordTrim이 존재하면 '검색 결과 화면'으로 판단하고
          카테고리 기본 목록으로 쉽게 돌아갈 수 있는 동선을 제공.
        --%>
        <c:if test="${not empty keywordTrim}">
          <a href="${boardListUrl}" class="board-reset-btn">전체보기</a>
        </c:if>

        <%-- 
          글 작성 버튼 정책
          -----------------------------------------------------
          제한 조건:
          - 로그인 상태
          - 현재 게시판이 애니 게시판(ANIME)
          - 회원 상태가 제재(SUSPEND_7D / SUSPEND_30D)
          
          처리 방식:
          - href는 유지 (UI 구조 일관성)
          - CSS 클래스(is-disabled) + data 속성으로 상태 표시
          - 실제 클릭 차단은 JS에서 추가로 수행 (UX 안전장치)
        --%>
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

      <%-- 
        공지 영역
        noticeList가 있을 때만 상단에 별도 섹션으로 렌더링.
        일반글과 시각적으로 구분해서 중요한 공지를 먼저 보이게 함.
      --%>
      <c:if test="${not empty noticeList}">
        <div class="board-notice">
          <c:forEach var="n" items="${noticeList}">
            <%-- 공지 상세 링크 생성 (boardId 파라미터 포함) --%>
            <c:url var="noticeDetailUrl" value="/boardDetail">
              <c:param name="boardId" value="${n.boardId}" />
            </c:url>

            <%-- 
              data-href를 두는 이유:
              아래 JS에서 카드 전체 클릭 이동 처리에 사용.
              (제목 <a> 클릭은 기본 동작 유지)
            --%>
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

        <%-- 
          목록 비어 있음 처리
          - 검색어가 있으면: '검색 결과가 없습니다.'
          - 검색어가 없으면: '해당 글이 없습니다.'
          같은 empty 상황이어도 사용자 맥락에 맞는 문구를 출력
        --%>
        <c:if test="${empty boardList}">
          <div class="search-empty board-search-empty">
            <c:choose>
              <c:when test="${not empty keywordTrim}">검색 결과가 없습니다.</c:when>
              <c:otherwise>해당 글이 없습니다.</c:otherwise>
            </c:choose>
          </div>
        </c:if>

        <c:choose>
          <%-- =========================================================
               검색 모드
               ---------------------------------------------------------
               keywordTrim이 있으면 인기글 분리 없이 검색 결과를 그대로 출력.
               검색 결과는 사용자가 입력한 조건/키워드에 대한 응답이므로
               추가 분류보다 '결과 그대로' 보여주는 쪽이 UX가 단순함.
               ========================================================= --%>
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

          <%-- =========================================================
               일반 모드 (검색어 없음)
               ---------------------------------------------------------
               정책:
               1) 좋아요 10개 이상 글을 '인기글' 영역으로 먼저 출력
               2) 나머지 글은 아래 일반 목록으로 출력
               
               구현 방식:
               - 먼저 hasPopular 플래그를 계산(1차 순회)
               - 인기글 섹션 렌더링 여부 판단
               - 이후 인기글 / 일반글을 조건으로 나눠 출력(2~3차 순회)
               ========================================================= --%>
          <c:otherwise>

            <%-- 인기글 존재 여부 선계산 (좋아요 10개 이상이 하나라도 있는지 확인) --%>
            <c:set var="hasPopular" value="false" />
            <c:forEach var="t" items="${boardList}">
              <c:if test="${not empty t.likeCnt and t.likeCnt ge 10}">
                <c:set var="hasPopular" value="true" />
              </c:if>
            </c:forEach>

            <%-- 
              인기글 섹션은
              1) boardList가 비어있지 않고
              2) 실제 인기글이 있을 때만 노출
            --%>
            <c:if test="${not empty boardList and hasPopular}">
              <div class="board-popular" style="margin-top:6px; margin-bottom:12px;">
                <div style="margin:6px 0 10px;">
                  <h5 style="margin:0;">🔥 인기글</h5>
                </div>

                <%-- 좋아요 10개 이상 글만 인기글 영역에 출력 --%>
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

              <%-- 인기글 영역과 일반글 영역 시각적 구분선 --%>
              <div style="height:1px; background:rgba(255,255,255,0.08); margin:14px 0;"></div>
            </c:if>

            <%-- 일반글 영역: 인기글 기준(좋아요 10+) 미만 글만 출력 --%>
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
  // =========================================================
  // 검색 폼 제출 시 프론트 검증
  // ---------------------------------------------------------
  // 목적:
  // 1) 공백만 입력한 검색 요청 방지
  // 2) 앞뒤 공백 제거(trim) 후 서버로 전송
  // 3) 가능하면 SweetAlert, 없으면 alert로 폴백
  // =========================================================
  (function(){
    var form = document.getElementById("boardSearchForm");
    if(!form) return;

    form.addEventListener("submit", function(e){
      var input = document.getElementById("boardSearchInput");

      // null/undefined 방어 후 문자열 trim
      var k = (input && input.value ? input.value : "").trim();

      // 빈 문자열이면 요청 막고 사용자에게 안내
      if(!k){
        e.preventDefault();

        // SweetAlert2가 로드된 페이지에서는 모달 안내, 아니면 기본 alert 사용
        if (window.Swal && typeof window.Swal.fire === 'function') {
          Swal.fire({
            icon: 'warning',
            title: '검색',
            text: '검색어를 입력하세요.',
            confirmButtonText: '확인'
          }).then(() => {
            if (input) input.focus();
          });
        } else {
          alert("검색어를 입력하세요.");
          if (input) input.focus();
        }
        return;
      }

      // trim된 값을 다시 입력칸에 반영해서 서버에도 정제된 값이 전송되도록 함
      input.value = k;
    });
  })();

  // =========================================================
  // 제재 상태의 애니 게시판 글쓰기 버튼 클릭 차단
  // ---------------------------------------------------------
  // 서버에서 이미 정책을 적용하더라도, 화면에서도 즉시 안내해 UX를 개선한다.
  // - is-disabled 버튼 클릭 시 이동 막기
  // - 경고 메시지 노출
  // =========================================================
  (function(){
    var banBtn = document.querySelector(".board-write-btn.is-disabled");
    if(!banBtn) return;

    banBtn.addEventListener("click", function(e){
      e.preventDefault();

      if (window.Swal && typeof window.Swal.fire === 'function') {
        Swal.fire({
          icon: 'warning',
          title: '작성 제한',
          text: '제재 기간 동안 애니 게시판 글 작성이 제한됩니다.',
          confirmButtonText: '확인'
        });
      } else {
        alert("제재 기간 동안 애니 게시판 글 작성이 제한됩니다.");
      }
      return false;
    });
  })();

  // =========================================================
  // 카드 전체 클릭 이동
  // ---------------------------------------------------------
  // 목적:
  // - 제목 텍스트 링크만 누르지 않아도 카드 빈 영역 클릭으로 상세 이동 가능
  // - 단, 내부 <a> 클릭은 기본 링크 동작을 그대로 유지
  // =========================================================
  (function(){
    var items = document.querySelectorAll(".board-item[data-href]");

    items.forEach(function(item){
      item.addEventListener("click", function(e){
        // 제목 링크(<a>)를 직접 클릭한 경우에는 카드 이동 로직 중복 실행 방지
        if(e.target.closest("a")) return;

        location.href = item.getAttribute("data-href");
      });
    });
  })();
</script>

<%-- 
  삭제된 게시글 접근 후 목록으로 리다이렉트된 경우 안내 모달 표시
  deletedBoardRedirect 플래그는 컨트롤러에서 설정한다고 가정.
--%>
<c:if test="${deletedBoardRedirect}">
<script>
document.addEventListener('DOMContentLoaded', function () {
  // SweetAlert2가 있으면 모달, 없으면 기본 alert로 폴백
  if (window.Swal && typeof window.Swal.fire === 'function') {
    window.Swal.fire({
      icon: 'warning',
      title: '삭제된 게시글입니다',
      text: '신고 처리가 완료된 게시글은 조회할 수 없습니다.',
      confirmButtonText: '확인'
    });
  } else {
    alert('신고 처리가 완료된 게시글은 조회할 수 없습니다.');
  }
});
</script>
</c:if>

</body>
</html>