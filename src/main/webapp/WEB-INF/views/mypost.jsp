<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 내 글 보기</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<!-- 공통 폰트 로드: 기존 메인/게시판 페이지와 동일한 타이포 톤 유지 -->
<link
  href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap"
  rel="stylesheet">
<link
  href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap"
  rel="stylesheet">

<!-- 공통 CSS + board 리스트 스타일 재사용 (카드/툴바 룩앤필 통일 목적) -->
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">

<link rel="stylesheet" href="${ctx}/css/board.css">

<style>
/* 이 페이지에서는 검색 기능보다 '내 글/좋아요글 확인'이 목적이라 헤더 검색 아이콘 숨김 */
.header__right .icon_search {
  display: none !important;
}

/* board.css 기본 툴바 서브텍스트 여백을 이 페이지 비율에 맞게 미세 조정 */
.mypost-toolbar .board-sub {
  margin: 6px 0 0;
}

/* 상단 토글 버튼 묶음 레이아웃 (가로 정렬 + 간격 유지) */
.mypost-toggle {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* 토글 버튼 공통 pill 스타일
   - 버튼처럼 보이지만 페이지 내 모드 전환 역할이라 시각적으로 탭 느낌 강조 */
.mypost-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 900;
  cursor: pointer;
  user-select: none;
  text-decoration: none !important;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.14);
  color: rgba(255, 255, 255, 0.88);
  transition: transform .15s ease, box-shadow .15s ease, background .15s
    ease, border-color .15s ease;
}

/* hover 시 살짝 상승 + 그림자 강화로 클릭 가능 요소임을 명확히 보여줌 */
.mypost-pill:hover {
  transform: translateY(-1px);
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.28);
  background: rgba(255, 255, 255, 0.10);
  border-color: rgba(255, 255, 255, 0.22);
}

/* 활성 탭 상태 표시 (현재 보고 있는 목록을 색으로 구분) */
.mypost-pill.is-active {
  background: rgba(229, 54, 55, 0.16);
  border-color: rgba(229, 54, 55, 0.35);
  color: #fff;
}

/* 각 탭의 글 개수 표시용 카운트 배지 */
.mypost-count {
  font-size: 12px;
  font-weight: 900;
  padding: 3px 10px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.10);
  border: 1px solid rgba(255, 255, 255, 0.10);
  color: rgba(255, 255, 255, 0.9);
}

/* 활성 탭일 때 카운트 배지도 같은 강조색 계열로 맞춰 시각적 일체감 유지 */
.mypost-pill.is-active .mypost-count {
  background: rgba(229, 54, 55, 0.22);
  border-color: rgba(229, 54, 55, 0.28);
}

/* 리스트 영역 최대 폭 제한
   - 한 줄이 너무 길어지지 않게 해서 제목 가독성 유지 */
.mypost-wrap {
  max-width: 980px;
  margin: 0 auto;
}

/* board-item 전체 클릭 UX를 쓰기 위해 커서를 포인터로 지정 */
.mypost-list .board-item {
  cursor: pointer;
}

/* 게시판 종류(ANIME/FREE/QNA/INFO)를 보여주는 카테고리 뱃지 */
.mypost-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 900;
  padding: 4px 10px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.12);
  color: rgba(255, 255, 255, 0.88);
}

/* 빈 상태 문구가 카드 리스트와 너무 붙지 않도록 여백 확보 */
.mypost-empty {
  margin-top: 8px;
}

/* 모바일 대응
   - 토글 버튼을 세로로 쌓아 터치 영역 확보
   - 텍스트/카운트를 양끝 정렬해서 좁은 화면에서도 보기 좋게 */
@media ( max-width : 991px) {
  .mypost-toggle {
    width: 100%;
    flex-wrap: wrap;
  }
  .mypost-pill {
    width: 100%;
    justify-content: space-between;
  }
}
</style>
</head>

<body>

  <%@ include file="/WEB-INF/common/header.jsp"%>

  <section class="product-page spad">
    <div class="container">
      <div class="mypost-wrap">

        <%-- board.jsp 툴바 구조를 재사용해 페이지 간 UI 패턴을 통일
             (제목 영역 + 우측 액션 영역 구조 그대로 활용) --%>
        <div class="board-toolbar mypost-toolbar">
          <div class="board-title-wrap">
            <c:choose>
              <c:when test="${sessionScope.memberRole eq 'ADMIN'}">
                <h3>관리자 내 글 보기</h3>
                <p class="board-sub">내가 작성한 글과 좋아요한 글을 한 번에 확인하세요</p>
              </c:when>
              <c:otherwise>
                <h3>내 글 보기</h3>
                <p class="board-sub">내가 작성한 글과 좋아요한 글을 한 번에 확인하세요</p>
              </c:otherwise>
            </c:choose>
          </div>

          <%-- board-actions 영역에는 '글쓰기/정렬' 대신 목록 전환용 토글 버튼 배치 --%>
          <div class="board-actions mypost-toggle">
            <button type="button" class="mypost-pill is-active" id="btnMy">
              <i class="fa fa-pencil"></i> 내가 작성한 글
              <span class="mypost-count">
                <c:out value="${empty myBoardWriteList ? 0 : fn:length(myBoardWriteList)}" />건
              </span>
            </button>

            <button type="button" class="mypost-pill" id="btnLike">
              <i class="fa fa-heart"></i> 내가 좋아요한 글
              <span class="mypost-count">
                <c:out value="${empty myBoardLikeList ? 0 : fn:length(myBoardLikeList)}" />건
              </span>
            </button>
          </div>
        </div>

        <%-- board-list / board-posts 마크업 구조를 그대로 사용
             이유: 기존 board.css 카드 스타일을 추가 CSS 최소화로 재사용 가능 --%>
        <div class="board-list mypost-list">

          <%-- 탭 1: 내가 작성한 글 목록
               초기 진입 시 기본으로 보여주는 영역이라 display:none 없이 렌더링 --%>
          <div id="myPostBox" class="board-posts">
            <c:if test="${empty myBoardWriteList}">
              <div class="search-empty board-search-empty mypost-empty">작성한 글이 없습니다.</div>
            </c:if>

            <c:forEach var="post" items="${myBoardWriteList}">
              <c:set var="categoryKey" value="${fn:toUpperCase(fn:trim(post.boardCategory))}" />
              <c:set var="categoryTitle" value="${categoryKey} 게시판" />

              <%-- DB 저장값(영문 코드)을 화면 표시용 한글 카테고리명으로 변환
                   기본값은 '{코드} 게시판'으로 두고, 알려진 코드만 사용자 친화적 문구로 치환 --%>
              <c:choose>
                <c:when test="${categoryKey eq 'ANIME'}">
                  <c:set var="categoryTitle" value="애니 게시판" />
                </c:when>
                <c:when test="${categoryKey eq 'FREE'}">
                  <c:set var="categoryTitle" value="자유 게시판" />
                </c:when>
                <c:when test="${categoryKey eq 'QNA'}">
                  <c:set var="categoryTitle" value="Q&amp;A 게시판" />
                </c:when>
                <c:when test="${categoryKey eq 'INFO'}">
                  <c:set var="categoryTitle" value="정보 게시판" />
                </c:when>
              </c:choose>

              <%-- 상세 페이지 이동 URL 생성
                   c:url을 쓰는 이유:
                   1) 컨텍스트 경로(ctx) 수동 결합 실수를 줄이고
                   2) 쿼리 파라미터(boardId) 조합을 JSTL에 맡겨 일관성 있게 관리하기 위해서 --%>
              <c:url var="detailUrl" value="/boardDetail">
                <c:param name="boardId" value="${post.boardId}" />
              </c:url>

              <%-- 카드 전체 클릭 이동을 지원하기 위해 data-href에도 동일 URL 저장
                   (제목 링크 클릭 / 카드 빈 영역 클릭 모두 같은 상세 페이지로 이동) --%>
              <div class="board-item post-item" data-href="${detailUrl}">
                <div class="board-title">
                  <span class="mypost-badge">${categoryTitle}</span>

                  <%-- 제목 출력은 c:out 사용
                       사용자가 입력한 제목에 특수문자/태그 문자열이 있어도 화면에 문자로 안전하게 표시됨 --%>
                  <a href="${detailUrl}">
                    <c:out value="${post.boardTitle}" />
                  </a>
                </div>
              </div>
            </c:forEach>
          </div>

          <%-- 탭 2: 내가 좋아요한 글 목록
               초기 로딩 시에는 숨겨두고, 상단 토글 클릭으로 표시 전환 --%>
          <div id="likePostBox" class="board-posts" style="display: none;">
            <c:if test="${empty myBoardLikeList}">
              <div class="search-empty board-search-empty mypost-empty">좋아요한 글이 없습니다.</div>
            </c:if>

            <c:forEach var="post" items="${myBoardLikeList}">
              <c:set var="categoryKey" value="${fn:toUpperCase(fn:trim(post.boardCategory))}" />
              <c:set var="categoryTitle" value="${categoryKey} 게시판" />

              <%-- 작성글 탭과 동일한 카테고리 변환 규칙을 그대로 사용
                   두 탭의 표시 기준이 달라지면 사용자가 같은 글을 다르게 인식할 수 있으므로 통일 유지 --%>
              <c:choose>
                <c:when test="${categoryKey eq 'ANIME'}">
                  <c:set var="categoryTitle" value="애니 게시판" />
                </c:when>
                <c:when test="${categoryKey eq 'FREE'}">
                  <c:set var="categoryTitle" value="자유 게시판" />
                </c:when>
                <c:when test="${categoryKey eq 'QNA'}">
                  <c:set var="categoryTitle" value="Q&amp;A 게시판" />
                </c:when>
                <c:when test="${categoryKey eq 'INFO'}">
                  <c:set var="categoryTitle" value="정보 게시판" />
                </c:when>
              </c:choose>

              <%-- 좋아요 탭도 상세 URL 생성 규칙을 동일하게 유지
                   (탭별로 URL 생성 방식이 달라지면 추후 수정 시 한쪽만 깨질 위험이 커짐) --%>
              <c:url var="detailUrl" value="/boardDetail">
                <c:param name="boardId" value="${post.boardId}" />
              </c:url>

              <%-- 카드 클릭 이동용 목적지 저장 (제목 링크 href와 동일 값 사용) --%>
              <div class="board-item post-item" data-href="${detailUrl}">
                <div class="board-title">
                  <span class="mypost-badge">${categoryTitle}</span>

                  <%-- 제목은 c:out으로 안전 출력 (화면 렌더링 시 HTML로 해석되지 않게 방지) --%>
                  <a href="${detailUrl}">
                    <c:out value="${post.boardTitle}" />
                  </a>
                </div>
              </div>
            </c:forEach>
          </div>

        </div>

      </div>
    </div>
  </section>

  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <script>
(function(){
  // 토글 버튼/목록 영역 DOM 참조
  // - 이 페이지는 서버에서 두 목록을 모두 렌더링해두고,
  //   JS에서는 display 전환만 담당한다(재조회 없음).
  // - 그래서 탭 전환이 빠르고 구현도 단순해진다.
  const btnMy = document.getElementById("btnMy");
  const btnLike = document.getElementById("btnLike");
  const myBox = document.getElementById("myPostBox");
  const likeBox = document.getElementById("likePostBox");

  // 화면 모드 전환 함수
  // mode === "MY"   -> 내가 작성한 글 표시
  // mode === "LIKE" -> 내가 좋아요한 글 표시
  // 표시 영역(display) + 버튼 활성 클래스(is-active)를 같이 바꿔
  // 화면에 보이는 상태와 버튼 강조 상태가 항상 일치하도록 유지한다.
  function setMode(mode){
    if(mode === "MY"){
      myBox.style.display = "";
      likeBox.style.display = "none";
      btnMy.classList.add("is-active");
      btnLike.classList.remove("is-active");
    }else{
      myBox.style.display = "none";
      likeBox.style.display = "";
      btnMy.classList.remove("is-active");
      btnLike.classList.add("is-active");
    }
  }

  // 상단 토글 버튼 이벤트 연결
  // - 클릭 시 서버 요청 없이 즉시 목록만 전환
  btnMy.addEventListener("click", () => setMode("MY"));
  btnLike.addEventListener("click", () => setMode("LIKE"));

  // 카드 전체 클릭 이동 처리
  // - board.jsp와 동일 UX: 카드 아무 곳이나 누르면 상세로 이동
  // - 단, 내부 <a>를 직접 클릭한 경우에는 a의 기본 동작을 그대로 사용하고
  //   카드 클릭 핸들러는 중복 실행하지 않도록 바로 종료
  document.querySelectorAll(".board-item[data-href]").forEach(function(item){
    item.addEventListener("click", function(e){
      if(e.target.closest("a")) return;
      location.href = item.getAttribute("data-href");
    });
  });

  // 초기 진입 상태를 JS로 한 번 더 명시
  // - HTML의 초기 class/style 상태와 JS 상태를 맞춰두면
  //   나중에 탭 기본값 변경/조건 분기 추가 시 실수를 줄이기 좋다.
  setMode("MY");
})();
</script>

</body>
</html>