<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%-- =========================================================
   Board Detail (boardDetail.jsp) - 주석 강화 최종본
   ---------------------------------------------------------
   이 페이지에서 하는 일(정책 중심으로 이해하면 편함)

   1) 게시글 본문 렌더
      - boardData.boardContent는 CKEditor HTML이라 escapeXml=false로 출력한다.
      - 대신 CSS/JS에서 오버플로/경로 보정을 한다.

   2) 권한/정책 분기(서버/프론트 2중)
      - canManagePost: 작성자 or ADMIN 이면 게시글 수정/삭제 가능
      - isBannedFlag: 제재회원이면 게시글 수정/삭제 + 댓글 작성/수정/삭제 제한
      - canManagePostUi: UI 단에서 수정/삭제 버튼 노출 여부
      - boarddetail.js: data-ban-lock 요소 클릭/submit을 capture 단계에서 차단(2중 안전장치)

   3) 신고 정책
      - canReportPost: 로그인 + 내 글 아님 + 아직 신고 안 함
      - 제재회원도 신고는 가능하게 유지(별도 제한 없음)

   4) 좋아요 정책
      - 로그인하면 좋아요 토글 가능
      - 좋아요 누른 사람 목록 조회 가능
   ========================================================= --%>

<%-- ctx는 header.jsp에서도 쓰기 때문에 request scope로 내려야 include 내부에서도 사용 가능 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<%-- 로그인/세션 기본값들 --%>
<c:set var="isLogin" value="${not empty sessionScope.memberId}" />
<c:set var="sessionMemberId" value="${sessionScope.memberId}" />
<c:set var="sessionMemberRole" value="${sessionScope.memberRole}" />

<%-- 작성자 표시용: 닉네임이 없으면 memberId로 대체(데이터 폴백 정책) --%>
<c:set var="writerDisplay"
       value="${empty boardData.writerNickname ? boardData.memberId : boardData.writerNickname}" />

<%-- 작성/수정일: '수정됨' 라벨 표시 판단에 사용 --%>
<c:set var="createdAt" value="${boardData.boardCreatedAt}" />
<c:set var="updatedAt" value="${boardData.boardUpdatedAt}" />

<%-- =========================================================
   ✅ 제재회원 여부(isBannedFlag)
   ---------------------------------------------------------
   이 값은 '어디서 내려오든' true로 판정되게 만든다.

   가능 케이스:
   - sessionScope.isBanned가 true/1/'1'로 들어오는 경우
   - 컨트롤러 모델로 isBanned가 true/1/'1'로 들어오는 경우

   결과는 JSTL boolean으로 떨어지고,
   마지막에 JS 전역 변수 isBanned로 그대로 넘긴다.
   ========================================================= --%>
<c:set var="isBannedFlag"
       value="${sessionScope.isBanned == 1 or isBanned == 1}" />

<%-- =========================================================
   게시글 관리 권한(canManagePost)
   - 로그인 상태여야 하고
   - (내 글) or (ADMIN) 이어야 함
   ========================================================= --%>
<c:set var="canManagePost"
       value="${isLogin and (sessionMemberId eq boardData.memberId or sessionMemberRole eq 'ADMIN')}" />

<%-- =========================================================
   ✅ UI 노출 권한(canManagePostUi)
   - 실제 권한(canManagePost) + 제재 아님(not isBannedFlag)
   - 제재회원은 버튼 자체를 안 보여주거나(현재 방식)
     disabled로 남겨두는 방식도 가능
   ========================================================= --%>
<c:set var="canManagePostUi"
       value="${canManagePost and (not isBannedFlag)}" />

<%-- =========================================================
   신고 여부(isReportedFlag)
   - 컨트롤러가 isReported를 내려주면 그걸 기준으로
   - 없으면 기본 false로 남는다
   ========================================================= --%>
<c:set var="isReportedFlag"
       value="${isReported == 1}" />

<%-- =========================================================
   신고 버튼 노출(canReportPost)
   - 로그인 필수
   - 내 글은 신고 X
   - 이미 신고한 글은 또 신고 X
   - 제재회원도 신고는 가능하게 유지(정책)
   ========================================================= --%>
<c:set var="canReportPost"
       value="${isLogin and (sessionMemberId ne boardData.memberId) and (not isReportedFlag)}" />

<%-- =========================================================
   게시글 수정 여부(boardIsEdited)
   - boardData.isEdited가 있으면 그걸 우선
   - 없으면 updatedAt != createdAt 으로 추론(폴백)
   ========================================================= --%>
<c:set var="boardIsEdited"
       value="${boardData.isEdited == 1 or boardData.isEdited == true or boardData.isEdited == '1'
               or (not empty updatedAt and updatedAt ne createdAt)}" />

<%-- ✅ CHANGED: 좋아요 초기값은 '값이 존재하냐(not empty)'로 판단하면 0도 true 되는 문제가 있어
   -> true/1/'1'만 true로 처리 --%>
<c:set var="initLikedFlag" value="${isLiked}" />
<c:set var="initLikeCount" value="${likeCount}" />

<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AniMale | Board Detail</title>

  <link rel="icon" type="image/png" href="${ctx}/favicon.png" />

  <%-- 공용 CSS 세트: header/footer 포함 페이지들과 스타일 충돌 최소화 --%>
  <link rel="stylesheet" href="${ctx}/css/bootstrap.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/font-awesome.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/elegant-icons.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/slicknav.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/style.css" />

 <link rel="stylesheet" href="${ctx}/css/boarddetail.css" />
</head>

<body class="board-detail-page">

  <%-- header.jsp는 request scope ctx를 사용 가능 --%>
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <section class="product spad board-detail-wrap">
    <div class="container">

      <div class="bd-card">
        <header class="bd-head">
          <h3 class="bd-title"><c:out value="${boardData.boardTitle}" /></h3>

          <%-- 메타 정보: 작성자/작성일/수정일/조회수/카테고리 + (선택) 제재 배지 --%>
          <div class="bd-meta">
            <span class="meta-chip">
              <i class="fa fa-user"></i>
              <c:out value="${writerDisplay}" />
            </span>

            <span class="meta-chip">
              <i class="fa fa-clock-o"></i>
              작성일 <c:out value="${createdAt}" />
            </span>

            <%-- 수정된 글이면 수정일 칩 노출 --%>
            <c:if test="${boardIsEdited and not empty updatedAt}">
              <span class="meta-chip">
                <i class="fa fa-pencil"></i>
                수정일 <c:out value="${updatedAt}" />
              </span>
            </c:if>

            <span class="meta-chip">
              <i class="fa fa-eye"></i>
              조회 <c:out value="${boardData.boardViews}" />
            </span>

            <c:if test="${not empty boardData.boardCategory}">
              <span class="meta-chip">
                <i class="fa fa-tag"></i>
                <c:out value="${boardData.boardCategory}" />
              </span>
            </c:if>

            <%-- ✅ 제재회원 안내 배지: '제재 상태'는 사용자에게 알려주는 UX --%>
            <c:if test="${isLogin and isBannedFlag}">
              <span class="meta-chip meta-chip--ban">
                <i class="fa fa-ban"></i>
                제재회원(기능 제한)
              </span>
            </c:if>
          </div>
        </header>

        <div class="bd-body">
          <div class="bd-content">
            <%-- =========================================================
               CKEditor HTML 렌더링
               ---------------------------------------------------------
               escapeXml=false:
               - 태그가 실제 HTML로 렌더링됨(의도된 동작)
               - 대신 CSS에서 white-space, table overflow,
                 JS에서 src 경로 보정을 해준다.
               ========================================================= --%>
            <c:out value="${boardData.boardContent}" escapeXml="false" />
          </div>
        </div>

        <%-- =========================================================
           액션 영역(좌/우)
           좌: 목록/수정/삭제/신고
           우: 좋아요/좋아요 토글/좋아요 누른 사람
           ========================================================= --%>
        <div class="bd-actions">
          <div class="left">
            <%-- 목록: boardCategory가 필수인 라우트 정책이므로 쿼리로 붙여서 이동 --%>
            <a class="bd-btn"
               href="${ctx}/boardList?boardCategory=${boardData.boardCategory}">
              목록
            </a>

            <%-- ✅ 수정/삭제: 제재회원이면 UI에서 숨김(canManagePostUi=false) --%>
            <c:if test="${canManagePostUi}">
              <%-- data-ban-lock: JS가 제재 상태일 때 클릭을 capture 단계에서 차단하기 위한 표식 --%>
              <a class="bd-btn"
                 data-ban-lock="1"
                 href="${ctx}/boardEditPage?boardId=${boardData.boardId}">
                수정
              </a>

              <form action="${ctx}/boardDelete" method="post" style="display:inline;">
                <input type="hidden" name="boardId" value="${boardData.boardId}" />
                <button type="submit" class="bd-btn"
                        data-ban-lock="1"
                        onclick="return confirm('정말 삭제하시겠습니까?');">
                  삭제
                </button>
              </form>
            </c:if>

            <%-- 신고: 로그인 + 내 글 아님 + 아직 신고 안 함 --%>
            <c:if test="${canReportPost}">
              <button id="btnReport" type="button" class="bd-btn danger">
                신고
              </button>
            </c:if>
          </div>

          <div class="right">
            <%-- =========================================================
               좋아요 초기값 결정
               ---------------------------------------------------------
               케이스 1) 컨트롤러가 likedByMe / likeCount 내려줌
               케이스 2) boardData.isLiked / boardData.likeCnt 만 있음
               -> 둘 다 대응하도록 폴백 처리
               ========================================================= --%>
            <c:set var="initLiked"
                   value="${not empty likedByMe ? likedByMe : (boardData.isLiked eq 1)}" />
            <c:set var="initLikeCount"
                   value="${not empty likeCount ? likeCount : boardData.likeCnt}" />

            <span id="likePill" class="like-pill <c:if test='${initLiked}'>is-liked</c:if>">
              좋아요 <span id="likeCount" class="like-count"><c:out value="${initLikeCount}" /></span>
            </span>

            <button id="btnLike"
                    type="button"
                    class="bd-btn"
                    data-board-id="${boardData.boardId}"
                    data-liked="<c:out value='${initLiked ? 1 : 0}'/>">
              <c:choose>
                <c:when test="${initLiked}">좋아요 취소</c:when>
                <c:otherwise>좋아요</c:otherwise>
              </c:choose>
            </button>

            <button id="btnLikeUsers"
                    type="button"
                    class="bd-btn"
                    data-board-id="${boardData.boardId}">
              좋아요 누른 사람
            </button>
          </div>
        </div>
      </div>

      <%-- =========================================================
         댓글 카드
         ---------------------------------------------------------
         정책:
         - 비로그인: 작성 불가 안내 + 로그인 링크
         - 로그인 + 제재: 폼은 보여주되 disabled(디자인 유지) + JS에서도 전송 차단
         - 로그인 + 정상: 작성 가능
         ========================================================= --%>
      <div class="reply-card">
        <div class="reply-head">
          <h4>댓글</h4>

          <select id="replySort">
            <option value="REPLY_LIST_RECENT" selected>최신순</option>
            <option value="REPLY_LIST_OLDEST">작성순</option>
          </select>

          <div class="reply-count">총 <span id="replyCount">0</span>개</div>
        </div>

        <c:choose>
          <c:when test="${not isLogin}">
            <div class="reply-login-hint">
              댓글 작성은 로그인 후 가능합니다.
              <a href="${ctx}/login">로그인하기</a>
            </div>
          </c:when>

          <%-- ✅ 제재회원: 댓글 기능 제한 --%>
          <c:when test="${isLogin and isBannedFlag}">
            <div class="ban-hint">
              제재회원은 댓글 작성/수정/삭제 및 게시글 수정/삭제가 제한됩니다.
            </div>

            <%-- 폼은 남기되 disabled(UX 유지) + JS에서도 작성 차단 --%>
            <form id="replyForm" class="reply-form is-banned" onsubmit="return false;">
              <input type="hidden" id="replyBoardId" name="boardId" value="${boardData.boardId}" />
              <textarea id="replyContent" name="replyContent" placeholder="제재회원은 댓글을 작성할 수 없습니다." disabled></textarea>
              <button type="submit" class="bd-btn accent" disabled>등록</button>
            </form>
          </c:when>

          <c:otherwise>
            <form id="replyForm" class="reply-form">
              <input type="hidden" id="replyBoardId" name="boardId" value="${boardData.boardId}" />
              <textarea id="replyContent" name="replyContent" placeholder="댓글을 입력하세요"></textarea>
              <button type="submit" class="bd-btn accent">등록</button>
            </form>
          </c:otherwise>
        </c:choose>

        <div id="replyList" class="reply-list">
          <div class="reply-empty" id="replyEmpty" style="display:none;">등록된 댓글이 없습니다.</div>
        </div>
      </div>

    </div>
  </section>

  <%-- =========================================================
     신고 모달(bootstrap)
     - btnReport 클릭 시 open
     - btnReportSubmit 클릭 시 /boardReport POST
     ========================================================= --%>
  <div class="modal fade" id="reportModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">게시글 신고</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <div style="display:flex; gap:10px; flex-wrap:wrap;">
            <select id="reportReason" style="flex:1; min-width:200px;">
              <option value="SPAM">스팸/도배</option>
              <option value="ABUSE">욕설/비방</option>
              <option value="ILLEGAL">불법/유해</option>
              <option value="ETC">기타</option>
            </select>
            <textarea id="reportContent" rows="4"
                      style="width:100%; margin-top:10px;"
                      placeholder="신고 사유를 자세히 적어주세요(선택)"></textarea>
          </div>
          <div style="margin-top:10px; font-size:12px; opacity:.75;">
            허위 신고는 제재 대상이 될 수 있습니다.
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="bd-btn" data-dismiss="modal">닫기</button>
          <button type="button" class="bd-btn accent" id="btnReportSubmit">신고 접수</button>
        </div>
      </div>
    </div>
  </div>

  <%-- =========================================================
     ✅ boarddetail.js가 읽는 전역 변수
     ---------------------------------------------------------
     - 가능하면 window 전역 오염을 줄이려면 data-*로 옮길 수도 있지만,
       지금 구조는 'JSP에서 주입 → JS에서 즉시 사용'이라 관리가 쉽다.

     주의:
     - isLogin/isReported/isBanned는 boolean으로 내려가야 JS 비교가 깔끔함
     ========================================================= --%>
  <script>
    const ctx = '${ctx}';
    const boardId = ${boardData.boardId};
    const isLogin = ${isLogin};
    const sessionMemberId = '${sessionMemberId}';
    const sessionMemberRole = '${sessionMemberRole}';
    const isReported = ${isReportedFlag};
    const isBanned = ${isBannedFlag};
  </script>

  <%-- 공용 JS 세트 --%>
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/player.js"></script>
  <script src="${ctx}/js/jquery.nice-select.min.js"></script>
  <script src="${ctx}/js/mixitup.min.js"></script>
  <script src="${ctx}/js/jquery.slicknav.js"></script>
  <script src="${ctx}/js/owl.carousel.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <%-- 페이지 전용 JS --%>
  <script src="${ctx}/js/boarddetail.js"></script>

  <%@ include file="/WEB-INF/common/footer.jsp"%>
</body>
</html>
