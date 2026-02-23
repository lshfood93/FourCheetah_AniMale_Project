<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%-- 컨텍스트 경로: 리소스/CSS/JS/링크에 공통으로 붙여서 절대경로 꼬임 방지 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 내 글 보기</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<%-- 파비콘도 컨텍스트 기준으로 로드 --%>
<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<%-- 폰트: 메인/게시판과 동일한 타이포 톤 유지(페이지 간 이질감 방지) --%>
<link
  href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap"
  rel="stylesheet">
<link
  href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap"
  rel="stylesheet">

<%-- 공통 CSS + 게시판 카드 스타일(board.css) 재사용
     - 새로 UI를 또 만들지 않고, board 리스트의 툴바/카드 룩앤필을 그대로 가져오는 목적 --%>
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">
<link rel="stylesheet" href="${ctx}/css/board.css">

<style>
/* 이 페이지는 검색보다 "내 글/좋아요 글" 확인이 핵심이라 헤더 검색 아이콘 숨김 */
.header__right .icon_search {
  display: none !important;
}

/* board.css의 툴바 서브텍스트 여백을 이 페이지 비율에 맞게 미세 조정 */
.mypost-toolbar .board-sub {
  margin: 6px 0 0;
}

/* 상단 토글(내가 작성 / 내가 좋아요) 버튼 영역: 가로 정렬 + 간격 */
.mypost-toggle {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* 토글 버튼 pill 스타일
   - 버튼처럼 보이지만 "페이지 내 모드 전환" 역할이라 탭 느낌으로 설계 */
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

/* hover 시 살짝 떠오르게 + 그림자 강화(클릭 가능한 요소임을 시각적으로 강조) */
.mypost-pill:hover {
  transform: translateY(-1px);
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.28);
  background: rgba(255, 255, 255, 0.10);
  border-color: rgba(255, 255, 255, 0.22);
}

/* 현재 선택된 탭(활성 상태): 강조색 계열로 구분 */
.mypost-pill.is-active {
  background: rgba(229, 54, 55, 0.16);
  border-color: rgba(229, 54, 55, 0.35);
  color: #fff;
}

/* 탭에 표시하는 글 개수 배지 */
.mypost-count {
  font-size: 12px;
  font-weight: 900;
  padding: 3px 10px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.10);
  border: 1px solid rgba(255, 255, 255, 0.10);
  color: rgba(255, 255, 255, 0.9);
}

/* 활성 탭일 때 배지도 같은 강조색 느낌으로 통일 */
.mypost-pill.is-active .mypost-count {
  background: rgba(229, 54, 55, 0.22);
  border-color: rgba(229, 54, 55, 0.28);
}

/* 리스트 영역 최대 폭 제한: 제목이 너무 길게 늘어지지 않게 가독성 확보 */
.mypost-wrap {
  max-width: 980px;
  margin: 0 auto;
}

/* board-item 전체 클릭 UX를 쓰기 위해 커서를 포인터로 지정 */
.mypost-list .board-item {
  cursor: pointer;
}

/* 게시판 카테고리 뱃지(ANIME/FREE/QNA/INFO 표시용) */
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

/* "삭제된 게시글" 안내 모달
   - display:flex로 켰을 때 중앙 정렬되는 구조
   - 배경은 dim 처리로 포커스 이동 */
#deletedBoardModal {
  display: none;
  position: fixed;
  top: 0; left: 0;
  width: 100%; height: 100%;
  background: rgba(0, 0, 0, 0.55);
  z-index: 9999;
  justify-content: center;
  align-items: center;
}
.deleted-modal-box {
  background: #fff;
  border-radius: 14px;
  padding: 44px 36px 36px;
  text-align: center;
  max-width: 380px;
  width: 90%;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
}
.deleted-modal-icon {
  width: 60px; height: 60px;
  border-radius: 50%;
  border: 3px solid #e89c3f;
  display: flex; align-items: center; justify-content: center;
  margin: 0 auto 20px;
  font-size: 28px;
  color: #e89c3f;
  font-weight: 700;
}
.deleted-modal-title {
  font-size: 18px;
  font-weight: 800;
  color: #1a1a1a;
  margin-bottom: 10px;
}
.deleted-modal-desc {
  font-size: 14px;
  color: #777;
  margin-bottom: 28px;
  line-height: 1.5;
}
.deleted-modal-btn {
  background: #6c5ce7;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 12px 40px;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: background .15s ease;
}
.deleted-modal-btn:hover {
  background: #5a4bd1;
}
</style>
</head>

<body>

  <%-- 공통 헤더 include: 로그인/메뉴/공통 UI 유지 --%>
  <%@ include file="/WEB-INF/common/header.jsp"%>

  <section class="product-page spad">
    <div class="container">
      <div class="mypost-wrap">

        <%-- board.jsp 툴바 구조 재사용
             - 제목 영역(좌) + 액션 영역(우) 레이아웃을 그대로 가져와서 페이지 일관성 유지 --%>
        <div class="board-toolbar mypost-toolbar">
          <div class="board-title-wrap">

            <%-- 관리자면 타이틀만 "관리자 내 글 보기"로 바꿔서 구분 --%>
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

          <%-- board-actions 영역: 기존 페이지의 글쓰기/정렬 대신 "목록 전환 토글" 배치 --%>
          <div class="board-actions mypost-toggle">

            <%-- 탭 버튼 1: 내가 작성한 글
                 - 처음 진입은 작성글을 기본 탭으로 잡아서 is-active를 먼저 줌 --%>
            <button type="button" class="mypost-pill is-active" id="btnMy">
              <i class="fa fa-pencil"></i> 내가 작성한 글

              <%-- 리스트가 비어있으면 0, 있으면 length로 건수 표시 --%>
              <span class="mypost-count">
                <c:out value="${empty myBoardWriteList ? 0 : fn:length(myBoardWriteList)}" />건
              </span>
            </button>

            <%-- 탭 버튼 2: 내가 좋아요한 글 --%>
            <button type="button" class="mypost-pill" id="btnLike">
              <i class="fa fa-heart"></i> 내가 좋아요한 글
              <span class="mypost-count">
                <c:out value="${empty myBoardLikeList ? 0 : fn:length(myBoardLikeList)}" />건
              </span>
            </button>
          </div>
        </div>

        <%-- 리스트 마크업도 board.jsp의 board-list/board-posts 구조를 그대로 사용
             - board.css의 카드 스타일을 추가 작업 없이 재사용하기 위함 --%>
        <div class="board-list mypost-list">

          <%-- [탭 1] 내가 작성한 글 목록
               - 초기 진입은 이 영역을 기본 노출(숨김 처리 없음) --%>
          <div id="myPostBox" class="board-posts">

            <%-- 작성 글이 없으면 빈 상태 문구 출력 --%>
            <c:if test="${empty myBoardWriteList}">
              <div class="search-empty board-search-empty mypost-empty">작성한 글이 없습니다.</div>
            </c:if>

            <%-- 작성 글 리스트 출력 --%>
            <c:forEach var="post" items="${myBoardWriteList}">

              <%-- 카테고리 코드를 정규화(공백 제거 + 대문자)
                   - DB 값이 'free', ' FREE ' 같이 들어와도 화면 변환이 안정적으로 되게 처리 --%>
              <c:set var="categoryKey" value="${fn:toUpperCase(fn:trim(post.boardCategory))}" />

              <%-- 기본 카테고리 타이틀(미등록 코드 대비) --%>
              <c:set var="categoryTitle" value="${categoryKey} 게시판" />

              <%-- 알려진 카테고리 코드만 한글 표기로 치환
                   - 기본값이 있으니 매핑이 누락되어도 화면이 깨지지 않음 --%>
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

              <%-- 상세 페이지 URL 생성
                   - c:url + c:param으로 파라미터 결합을 JSTL에 맡기면
                     ctx 결합 실수/인코딩 실수를 줄일 수 있음 --%>
              <c:url var="detailUrl" value="/boardDetail">
                <c:param name="boardId" value="${post.boardId}" />
              </c:url>

              <%-- 카드 하나 = 게시글 1개
                   - data-href: 카드 전체 클릭 이동용
                   - data-status: "내용삭제" 같은 상태를 JS에서 검사해서 이동 차단/모달 표시 --%>
              <div class="board-item post-item" data-href="${detailUrl}" data-status="${post.boardStatus}">
                <div class="board-title">

                  <%-- 카테고리 뱃지 --%>
                  <span class="mypost-badge">${categoryTitle}</span>

                  <%-- 제목 링크
                       - a 클릭은 checkDeleted()에서 상태 체크 후 true/false로 이동 제어 --%>
                  <a href="${detailUrl}" onclick="return checkDeleted(this)">
                    <c:out value="${post.boardTitle}" />
                  </a>
                </div>
              </div>
            </c:forEach>
          </div>

          <%-- [탭 2] 내가 좋아요한 글 목록
               - 초기에는 숨김, 토글 버튼으로 display 전환만 수행(서버 재요청 없음) --%>
          <div id="likePostBox" class="board-posts" style="display: none;">

            <%-- 좋아요한 글이 없으면 빈 상태 문구 출력 --%>
            <c:if test="${empty myBoardLikeList}">
              <div class="search-empty board-search-empty mypost-empty">좋아요한 글이 없습니다.</div>
            </c:if>

            <%-- 좋아요 글 리스트 출력 --%>
            <c:forEach var="post" items="${myBoardLikeList}">
              <%-- 작성글 탭과 동일하게 카테고리 정규화/표기 규칙 통일 --%>
              <c:set var="categoryKey" value="${fn:toUpperCase(fn:trim(post.boardCategory))}" />
              <c:set var="categoryTitle" value="${categoryKey} 게시판" />

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

              <%-- URL 생성 규칙도 두 탭에서 동일하게 유지(유지보수 시 한쪽만 깨지는 사고 방지) --%>
              <c:url var="detailUrl" value="/boardDetail">
                <c:param name="boardId" value="${post.boardId}" />
              </c:url>

              <%-- 좋아요 탭도 동일: data-href / data-status로 카드 클릭과 삭제 상태 제어 --%>
              <div class="board-item post-item" data-href="${detailUrl}" data-status="${post.boardStatus}">
                <div class="board-title">
                  <span class="mypost-badge">${categoryTitle}</span>

                  <%-- 링크 클릭 시에도 동일하게 삭제 여부 체크 --%>
                  <a href="${detailUrl}" onclick="return checkDeleted(this)">
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

  <%-- 삭제된 게시글 안내 모달
       - JS에서 display를 flex로 바꿔서 보여주고, 버튼 클릭 시 display:none으로 닫음 --%>
  <div id="deletedBoardModal">
    <div class="deleted-modal-box">
      <div class="deleted-modal-icon">!</div>
      <p class="deleted-modal-title">삭제된 게시글입니다</p>
      <p class="deleted-modal-desc">신고 처리가 완료된 게시글은<br>조회할 수 없습니다.</p>
      <button class="deleted-modal-btn" onclick="document.getElementById('deletedBoardModal').style.display='none'">확인</button>
    </div>
  </div>

  <%-- 공통 푸터 include --%>
  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <%-- 공통 JS 로드: 기존 템플릿 스크립트 흐름 유지 --%>
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <script>
(function(){
  // 토글 버튼/목록 영역 DOM 참조
  // - 서버에서 두 목록을 모두 렌더링해두고, 화면에서는 display만 바꿔서 전환한다.
  // - 탭 클릭마다 재조회(AJAX)가 없어서 빠르고 단순하다.
  const btnMy = document.getElementById("btnMy");
  const btnLike = document.getElementById("btnLike");
  const myBox = document.getElementById("myPostBox");
  const likeBox = document.getElementById("likePostBox");

  // 화면 모드 전환 함수
  // mode === "MY"   : 내가 작성한 글
  // mode === "LIKE" : 내가 좋아요한 글
  function setMode(mode){
    if(mode === "MY"){
      // 작성글 노출 / 좋아요글 숨김
      myBox.style.display = "";
      likeBox.style.display = "none";

      // 활성 탭 표시
      btnMy.classList.add("is-active");
      btnLike.classList.remove("is-active");
    }else{
      // 좋아요글 노출 / 작성글 숨김
      myBox.style.display = "none";
      likeBox.style.display = "";

      // 활성 탭 표시
      btnMy.classList.remove("is-active");
      btnLike.classList.add("is-active");
    }
  }

  // 토글 버튼 이벤트 연결
  btnMy.addEventListener("click", () => setMode("MY"));
  btnLike.addEventListener("click", () => setMode("LIKE"));

  // 카드 전체 클릭 이동 처리
  // - 카드 내부의 a를 클릭한 경우는 a의 onclick(checkDeleted)이 처리하므로 여기서는 빠진다.
  // - 카드 클릭은 data-href로 이동한다.
  // - 단, data-status가 "내용삭제"면 상세 이동을 막고 모달을 보여준다.
  document.querySelectorAll(".board-item[data-href]").forEach(function(item){
    item.addEventListener("click", function(e){
      // 링크 직접 클릭이면 여기서 이동 처리하지 않는다(중복 이동 방지)
      if(e.target.closest("a")) return;

      // 삭제 상태면 이동 차단 + 모달 표시
      if(item.getAttribute("data-status") === "내용삭제"){
        document.getElementById("deletedBoardModal").style.display = "flex";
        return;
      }

      // 정상 게시글이면 상세로 이동
      location.href = item.getAttribute("data-href");
    });
  });

  // 초기 진입은 작성글 탭으로 고정
  setMode("MY");
})();

// 제목 링크(a) 클릭 시 삭제 여부 체크
// - 삭제된 글이면 이동을 막고 모달만 띄운다.
// - 정상 글이면 true 반환해서 기본 링크 이동을 그대로 진행한다.
function checkDeleted(el) {
  const item = el.closest(".board-item");
  if(item && item.getAttribute("data-status") === "내용삭제"){
    document.getElementById("deletedBoardModal").style.display = "flex";
    return false;
  }
  return true;
}
</script>

</body>
</html>