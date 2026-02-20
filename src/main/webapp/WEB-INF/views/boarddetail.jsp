<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%-- ✅ FINAL: boardDetail.jsp (동기/비동기 정책 최종본) --%>

<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<c:set var="isLogin" value="${not empty sessionScope.memberId}" />
<c:set var="sessionMemberId" value="${sessionScope.memberId}" />
<c:set var="sessionMemberRole" value="${sessionScope.memberRole}" />

<c:set var="writerDisplay"
       value="${empty boardData.writerNickname ? boardData.memberId : boardData.writerNickname}" />

<c:set var="createdAt" value="${boardData.boardCreatedAt}" />
<c:set var="updatedAt" value="${boardData.boardUpdatedAt}" />

<%-- ✅ CHANGED: board.jsp와 동일하게 memberStatus 기준으로 제재 플래그 통일 --%>
<c:set var="memberStatus" value="${sessionScope.memberStatus}" />

<c:set var="isBannedFlag"
       value="${memberStatus eq 'SUSPEND_7D'
               or memberStatus eq 'SUSPEND_30D'
               or memberStatus eq 'BAN'}" />

<c:set var="canManagePost"
       value="${isLogin and (sessionMemberId eq boardData.memberId or sessionMemberRole eq 'ADMIN')}" />

<c:set var="canManagePostUi"
       value="${canManagePost and (not isBannedFlag)}" />

<c:set var="isReportedFlag"
       value="${isReported == 1}" />

<%-- ✅ CHANGED: 작성자 권한이 ADMIN이면 신고 버튼 숨김 --%>
<c:set var="writerIsAdmin"
       value="${boardData.writerRole eq 'ADMIN'}" />

<%-- ✅ CHANGED: 신고 가능 조건에서 ADMIN 작성 글 제외 --%>
<c:set var="canReportPost"
       value="${isLogin
               and (sessionMemberId ne boardData.memberId)
               and (not isReportedFlag)
               and (not writerIsAdmin)}" />

<c:set var="isEdited" value="${boardData.isEdited == 1}" />

<%-- ✅ NEW: 삭제된 게시글 여부 --%>
<c:set var="boardIsDeleted" value="${boardData.boardStatus ne '정상'}" />

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

            <%-- ✅ CHANGED: 수정된 글이면 작성일 대신 수정일만 표시 --%>
            <c:choose>
              <c:when test="${boardIsEdited and not empty updatedAt}">
                <span class="meta-chip">
                  <i class="fa fa-pencil"></i>
                  수정일 <c:out value="${updatedAt}" />
                </span>
              </c:when>
              <c:otherwise>
                <span class="meta-chip">
                  <i class="fa fa-clock-o"></i>
                  작성일 <c:out value="${createdAt}" />
                </span>
              </c:otherwise>
            </c:choose>

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
            <a class="bd-btn"
               href="${ctx}/boardList?boardCategory=${boardData.boardCategory}">
              목록
            </a>

            <c:if test="${canManagePostUi}">
              <%-- ✅ CHANGED: 삭제된 게시글이면 수정 링크도 차단 --%>
              <c:choose>
                <c:when test="${boardIsDeleted}">
                  <a class="bd-btn" data-deleted-lock="1" href="#">수정</a>
                </c:when>
                <c:otherwise>
                  <a class="bd-btn"
                     data-ban-lock="1"
                     href="${ctx}/boardEditPage?boardId=${boardData.boardId}">
                    수정
                  </a>
                </c:otherwise>
              </c:choose>

              <%-- ✅ CHANGED: 삭제된 게시글이면 data-deleted-lock 추가, confirm 제거 --%>
              <c:choose>
                <c:when test="${boardIsDeleted}">
                  <button type="button" class="bd-btn" data-deleted-lock="1">
                    삭제
                  </button>
                </c:when>
                <c:otherwise>
                  <form action="${ctx}/boardDelete" method="post" style="display:inline;">
                    <input type="hidden" name="boardId" value="${boardData.boardId}" />
                    <button type="submit" class="bd-btn"
                            data-ban-lock="1"
                            onclick="return confirm('정말 삭제하시겠습니까?');">
                      삭제
                    </button>
                  </form>
                </c:otherwise>
              </c:choose>
            </c:if>

            <c:if test="${canReportPost}">
              <button id="btnReport" type="button" class="bd-btn danger">
                신고
              </button>
            </c:if>
          </div>

          <div class="right">
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

      <%-- 댓글 카드 --%>
      <div class="reply-card">
        <div class="reply-head">
          <h4>댓글</h4>

          <%-- ✅ CHANGED: 우측 도구 그룹(정렬 + 총개수) --%>
          <div class="reply-head-tools">
            <select id="replySort">
              <option value="REPLY_LIST_RECENT" selected>최신순</option>
              <option value="REPLY_LIST_OLDEST">작성순</option>
            </select>

            <div class="reply-count">총 <span id="replyCount">0</span>개</div>
          </div>
        </div>

        <c:choose>
          <c:when test="${not isLogin}">
            <div class="reply-login-hint">
              댓글 작성은 로그인 후 가능합니다.
              <a href="${ctx}/login">로그인하기</a>
            </div>
          </c:when>

          <c:when test="${isLogin and isBannedFlag}">
            <div class="ban-hint">
              제재회원은 댓글 작성/수정/삭제 및 게시글 수정/삭제가 제한됩니다.
            </div>

            <form id="replyForm" class="reply-form is-banned" onsubmit="return false;">
              <input type="hidden" name="boardId" value="${boardData.boardId}" />
              <textarea id="replyContent" name="replyContent" placeholder="제재회원은 댓글을 작성할 수 없습니다." disabled></textarea>
              <button type="submit" class="bd-btn accent" disabled>등록</button>
            </form>
          </c:when>

          <c:otherwise>
            <%-- ✅ CHANGED: 댓글 작성은 동기 submit --%>
            <form id="replyForm" class="reply-form" action="${ctx}/replyWrite" method="post">
              <input type="hidden" name="boardId" value="${boardData.boardId}" />
              <textarea id="replyContent" name="replyContent" placeholder="댓글을 입력하세요"></textarea>
              <button type="submit" class="bd-btn accent">등록</button>
            </form>
          </c:otherwise>
        </c:choose>

        <div id="replyList" class="reply-list">
          <div class="reply-empty" id="replyEmpty" style="display:none;">등록된 댓글이 없습니다.</div>
        </div>

        <%-- ✅ CHANGED: 댓글 수정/삭제 동기 submit용 hidden form 2개 --%>
        <form id="replyEditForm" action="${ctx}/replyEdit" method="post" style="display:none;">
          <input type="hidden" name="boardId" id="editBoardId" value="${boardData.boardId}" />
          <input type="hidden" name="replyId" id="editReplyId" value="" />
          <input type="hidden" name="replyContent" id="editReplyContent" value="" />
        </form>

        <form id="replyDeleteForm" action="${ctx}/replyDelete" method="post" style="display:none;">
          <input type="hidden" name="boardId" id="delBoardId" value="${boardData.boardId}" />
          <input type="hidden" name="replyId" id="delReplyId" value="" />
        </form>
      </div>

    </div>
  </section>

  <%-- 신고 모달 --%>
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
            <%-- ✅ CHANGED: reasonCode 백엔드 validReasonCodes와 일치(OBSCENE 추가) --%>
            <select id="reportReason" style="flex:1; min-width:200px;">
              <option value="SPAM">스팸/도배</option>
              <option value="ABUSE">욕설/비방</option>
              <option value="OBSCENE">음란/선정성</option>
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
  
	<%-- ✅ CHANGED: 제재회원 신고 불가 안내 모달 --%>
	<div class="modal fade" id="banReportModal" tabindex="-1" role="dialog" aria-hidden="true">
	  <div class="modal-dialog modal-dialog-centered" role="document">
	    <div class="modal-content">
	      <div class="modal-header">
	        <h5 class="modal-title">이용 불가</h5>
	        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
	          <span aria-hidden="true">&times;</span>
	        </button>
	      </div>
	
			<div class="modal-body" style="line-height:1.6;">
			  <!-- ✅ CHANGED: 텍스트를 JS에서 바꿀 수 있게 id 부여 -->
			  <div id="banActionText">
			    제재회원은 해당 기능을 이용할 수 없습니다.<br/>
			    현재는 조회만 가능합니다.
			  </div>
			</div>
	
	      <div class="modal-footer">
	        <button type="button" class="bd-btn" data-dismiss="modal">확인</button>
	      </div>
	    </div>
	  </div>
	</div>

  <%-- ✅ CHANGED: 좋아요 누른 사람 모달 --%>
  <div class="modal fade" id="likeUsersModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">좋아요 누른 사람</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>

        <div class="modal-body">
          <div class="like-users-wrap">
            <div id="likeUsersEmpty" class="like-users-empty" style="display:none;">
              아직 좋아요를 누른 사용자가 없습니다.
            </div>
            <ul id="likeUsersList" class="like-users-list"></ul>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="bd-btn" data-dismiss="modal">닫기</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ✅ NEW: 삭제된 게시글 안내 모달 --%>
  <div class="modal fade" id="deletedBoardModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">안내</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          이미 삭제된 게시글입니다.
        </div>
        <div class="modal-footer">
          <button type="button" class="bd-btn" data-dismiss="modal">확인</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ✅ NEW: 제재 회원 안내 모달 --%>
  <div class="modal fade" id="bannedModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">안내</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <p id="bannedModalMsg"></p>
        </div>
        <div class="modal-footer">
          <button type="button" class="bd-btn" data-dismiss="modal">확인</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ✅ NEW: 신고 결과 안내 모달 (성공/실패/중복 공통) --%>
  <div class="modal fade" id="reportResultModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">안내</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <p id="reportResultMsg"></p>
        </div>
        <div class="modal-footer">
          <button type="button" class="bd-btn" data-dismiss="modal">확인</button>
        </div>
      </div>
    </div>
  </div>

  <%-- JS 전역 변수 --%>
  <script>
    const ctx = '${ctx}';
    const boardId = ${boardData.boardId};
    const boardStatus = '${boardData.boardStatus}'; <%-- ✅ NEW --%>
    const isLogin = ${isLogin};
    const sessionMemberId = '${sessionMemberId}';
    const sessionMemberRole = '${sessionMemberRole}';
    const isReported = ${isReportedFlag};
    const isBanned = ${isBannedFlag};
  </script>

  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/player.js"></script>
  <script src="${ctx}/js/jquery.nice-select.min.js"></script>
  <script src="${ctx}/js/mixitup.min.js"></script>
  <script src="${ctx}/js/jquery.slicknav.js"></script>
  <script src="${ctx}/js/owl.carousel.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <script src="${ctx}/js/boarddetail.js"></script>

  <%@ include file="/WEB-INF/common/footer.jsp"%>
</body>
</html>
