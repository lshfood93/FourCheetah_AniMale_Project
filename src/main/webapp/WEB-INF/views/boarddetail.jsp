<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%-- =========================================================
   Board Detail (boardDetail.jsp) - 주석 강화 최종본
   ---------------------------------------------------------
   1) 게시글 본문 렌더
      - boardData.boardContent는 CKEditor HTML이라 escapeXml=false로 출력

   2) 권한/정책 분기(서버/프론트 2중)
      - canManagePost: 작성자 or ADMIN 이면 수정/삭제 가능
      - isBannedFlag: 제재회원이면 수정/삭제 + 댓글 작성/수정/삭제 제한
      - boarddetail.js: data-ban-lock 클릭/submit capture 차단(2중)

   3) 신고 정책
      - canReportPost: 로그인 + 내 글 아님 + 아직 신고 안 함
      - 제재회원도 신고는 가능

   4) 좋아요 정책
      - 로그인하면 좋아요 토글 가능
      - 좋아요 누른 사람 목록 조회 가능
   ========================================================= --%>

<%-- ctx는 header.jsp에서도 쓰기 때문에 request scope로 내려 include 내부에서도 사용 가능 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<%-- ✅ CHANGED: 내부 라우팅은 c:url로 생성 (ctx 중복/인코딩/파라미터 안전) --%>
<c:url var="boardListUrl" value="/boardList">
  <c:param name="boardCategory" value="${boardData.boardCategory}" />
</c:url>
<c:url var="boardEditUrl" value="/boardEditPage">
  <c:param name="boardId" value="${boardData.boardId}" />
</c:url>
<c:url var="boardDeleteUrl" value="/boardDelete" />
<c:url var="loginUrl" value="/login" />

<%-- 로그인/세션 기본값들 --%>
<c:set var="isLogin" value="${not empty sessionScope.memberId}" />
<c:set var="sessionMemberId" value="${sessionScope.memberId}" />
<c:set var="sessionMemberRole" value="${sessionScope.memberRole}" />

<%-- 작성자 표시용: 닉네임이 없으면 memberId로 대체(폴백) --%>
<c:set var="writerDisplay"
       value="${empty boardData.writerNickname ? boardData.memberId : boardData.writerNickname}" />

<%-- 작성/수정일 --%>
<c:set var="createdAt" value="${boardData.boardCreatedAt}" />
<c:set var="updatedAt" value="${boardData.boardUpdatedAt}" />

<%-- ✅ 제재회원 여부(isBannedFlag): 어떤 타입으로 내려와도 true 판정 가능하게 --%>
<c:set var="isBannedFlag"
       value="${(sessionScope.isBanned == true) or (sessionScope.isBanned == 1) or (sessionScope.isBanned == '1')
               or (isBanned == true) or (isBanned == 1) or (isBanned == '1')}" />

<%-- ✅ CHANGED: ADMIN 판정은 contains로도 허용(ROLE_ADMIN/ADMIN 모두 대응) --%>
<c:set var="isAdmin"
       value="${fn:contains(fn:toUpperCase(sessionMemberRole), 'ADMIN')}" />

<%-- 게시글 관리 권한(canManagePost): 로그인 + (내 글 or ADMIN) --%>
<c:set var="canManagePost"
       value="${isLogin and (sessionMemberId eq boardData.memberId or isAdmin)}" />

<%-- UI 노출 권한(canManagePostUi): 실제 권한 + 제재 아님 --%>
<c:set var="canManagePostUi"
       value="${canManagePost and (not isBannedFlag)}" />

<%-- 신고 여부(isReportedFlag) --%>
<c:set var="isReportedFlag"
       value="${isReported == true or isReported == 1 or isReported == '1'}" />

<%-- 신고 버튼 노출(canReportPost): 로그인 + 내 글 아님 + 아직 신고 안 함 --%>
<c:set var="canReportPost"
       value="${isLogin and (sessionMemberId ne boardData.memberId) and (not isReportedFlag)}" />

<%-- 게시글 수정 여부(boardIsEdited): isEdited 우선, 없으면 updatedAt != createdAt 폴백 --%>
<c:set var="boardIsEdited"
       value="${boardData.isEdited == 1 or boardData.isEdited == true or boardData.isEdited == '1'
               or (not empty updatedAt and updatedAt ne createdAt)}" />

<%-- ✅ CHANGED: 좋아요 초기값은 '값이 존재하냐(not empty)'로 판단하면 0도 true 되는 문제가 있어
   -> true/1/'1'만 true로 처리 --%>
<c:set var="initLikedFlag"
       value="${(likedByMe == true) or (likedByMe == 1) or (likedByMe == '1')
               or (boardData.isLiked == true) or (boardData.isLiked == 1) or (boardData.isLiked == '1')}" />
<c:set var="initLikeCount"
       value="${not empty likeCount ? likeCount : (not empty boardData.likeCnt ? boardData.likeCnt : 0)}" />

<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AniMale | Board Detail</title>

  <link rel="icon" type="image/png" href="${ctx}/favicon.png" />

  <link rel="stylesheet" href="${ctx}/css/bootstrap.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/font-awesome.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/elegant-icons.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/slicknav.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/style.css" />

  <link rel="stylesheet" href="${ctx}/css/boarddetail.css" />
</head>

<body class="board-detail-page">

  <jsp:include page="/WEB-INF/common/header.jsp" />

  <section class="product spad board-detail-wrap">
    <div class="container">

      <div class="bd-card">
        <header class="bd-head">
          <h3 class="bd-title"><c:out value="${boardData.boardTitle}" /></h3>

          <div class="bd-meta">
            <span class="meta-chip">
              <i class="fa fa-user"></i>
              <c:out value="${writerDisplay}" />
            </span>

            <span class="meta-chip">
              <i class="fa fa-clock-o"></i>
              작성일 <c:out value="${createdAt}" />
            </span>

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
            <c:out value="${boardData.boardContent}" escapeXml="false" />
          </div>
        </div>

        <div class="bd-actions">
          <div class="left">
            <%-- ✅ CHANGED: 목록 이동도 c:url 사용 --%>
            <a class="bd-btn" href="${boardListUrl}">목록</a>

            <c:if test="${canManagePostUi}">
              <a class="bd-btn" data-ban-lock="1" href="${boardEditUrl}">수정</a>

              <form action="${boardDeleteUrl}" method="post" style="display:inline;">
                <input type="hidden" name="boardId" value="${boardData.boardId}" />
                <button type="submit" class="bd-btn" data-ban-lock="1"
                        onclick="return confirm('정말 삭제하시겠습니까?');">
                  삭제
                </button>
              </form>
            </c:if>

            <c:if test="${canReportPost}">
              <button id="btnReport" type="button" class="bd-btn danger">신고</button>
            </c:if>
          </div>

          <div class="right">
            <span id="likePill" class="like-pill <c:if test='${initLikedFlag}'>is-liked</c:if>">
              좋아요 <span id="likeCount" class="like-count"><c:out value="${initLikeCount}" /></span>
            </span>

            <button id="btnLike"
                    type="button"
                    class="bd-btn"
                    data-board-id="${boardData.boardId}"
                    data-liked="<c:out value='${initLikedFlag ? 1 : 0}'/>">
              <c:choose>
                <c:when test="${initLikedFlag}">좋아요 취소</c:when>
                <c:otherwise>좋아요</c:otherwise>
              </c:choose>
            </button>

            <button id="btnLikeUsers" type="button" class="bd-btn" data-board-id="${boardData.boardId}">
              좋아요 누른 사람
            </button>
          </div>
        </div>
      </div>

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
              <%-- ✅ CHANGED: login 링크도 c:url 변수 사용 --%>
              <a href="${loginUrl}">로그인하기</a>
            </div>
          </c:when>

          <c:when test="${isLogin and isBannedFlag}">
            <div class="ban-hint">
              제재회원은 댓글 작성/수정/삭제 및 게시글 수정/삭제가 제한됩니다.
            </div>

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

  <%-- ✅ boarddetail.js가 읽는 전역 변수 --%>
  <script>
    const ctx = '${ctx}';
    const boardId = ${boardData.boardId};
    const isLogin = ${isLogin};
    const sessionMemberId = '${sessionMemberId}';
    const sessionMemberRole = '${sessionMemberRole}';
    const isReported = ${isReportedFlag};
    const isBanned = ${isBannedFlag};
  </script>

  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/player.js"></script>
  <script src="${ctx}/js/jquery.nice-select.min.js"></script>
  <script src="${ctx}/js/mixitup.min.js"></script>
  <script src="${ctx}/js/jquery.slicknav.js"></script>
  <script src="${ctx}/js/owl.carousel.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <script src="${ctx}/js/boarddetail.js"></script>

</body>
</html>
