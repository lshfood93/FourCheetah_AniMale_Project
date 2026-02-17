<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%-- ✅ jsp:include로 들어가는 header.jsp에서도 ctx를 쓰게 하려면 request scope 필수 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<c:set var="isLogin" value="${not empty sessionScope.memberId}" />
<c:set var="sessionMemberId" value="${sessionScope.memberId}" />
<c:set var="sessionMemberRole" value="${sessionScope.memberRole}" />

<c:set var="writerDisplay"
       value="${empty boardData.writerNickname ? boardData.memberId : boardData.writerNickname}" />

<c:set var="createdAt" value="${boardData.boardCreatedAt}" />
<c:set var="updatedAt" value="${boardData.boardUpdatedAt}" />

<%-- ✅ 게시글 관리 권한(작성자 or ADMIN) --%>
<c:set var="canManagePost"
       value="${isLogin and (sessionMemberId eq boardData.memberId or sessionMemberRole eq 'ADMIN')}" />

<%-- ✅ 신고 버튼 노출: 로그인 + (자기 글은 보통 신고 막음) 필요하면 조건 바꿔 --%>
<c:set var="canReportPost"
       value="${isLogin and (sessionMemberId ne boardData.memberId)}" />

<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AniMale | Board Detail</title>

  <link rel="icon" type="image/png" href="${ctx}/favicon.png" />

  <%-- ✅ 공용 페이지들과 동일한 CSS 세트 (헤더/푸터 깨짐 방지) --%>
  <link rel="stylesheet" href="${ctx}/css/bootstrap.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/font-awesome.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/elegant-icons.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/slicknav.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/style.css" />

  <%-- ✅ 보드디테일 전용 CSS --%>
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

            <c:if test="${not empty updatedAt and updatedAt ne createdAt}">
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
          </div>
        </header>

        <div class="bd-body">
          <div class="bd-content">
            <%-- CKEditor HTML 렌더링 --%>
            <c:out value="${boardData.boardContent}" escapeXml="false" />
          </div>
        </div>

        <%-- ✅ 액션 영역: 목록/수정/삭제/신고 + 좋아요 --%>
        <div class="bd-actions">
          <div class="left">
            <%-- BoardController의 /boardList는 boardCategory 필수라서 붙여줌 --%>
            <a class="bd-btn"
               href="${ctx}/boardList?boardCategory=${boardData.boardCategory}">
              목록
            </a>

            <c:if test="${canManagePost}">
              <a class="bd-btn"
                 href="${ctx}/boardEditPage?boardId=${boardData.boardId}">
                수정
              </a>

              <form action="${ctx}/boardDelete" method="post" style="display:inline;">
                <input type="hidden" name="boardId" value="${boardData.boardId}" />
                <button type="submit" class="bd-btn"
                        onclick="return confirm('정말 삭제하시겠습니까?');">
                  삭제
                </button>
              </form>
            </c:if>

            <c:if test="${canReportPost}">
              <button id="btnReport" type="button" class="bd-btn">
                신고
              </button>
            </c:if>
          </div>

          <div class="right">
            <%-- 좋아요: BoardController가 likedByMe/likeCount를 내려주면 그걸 쓰는게 정석.
                 네 현재 JSP는 boardData.isLiked / boardData.likeCnt를 쓰고 있어서
                 모델 구성에 따라 값이 0으로만 보일 수 있음.
                 아래는 "둘 다 대응"하도록 data 초기값만 안전하게 잡았어. --%>

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

          <%-- 정렬 셀렉트(있어야 JS가 change로 갱신함) --%>
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
          <c:otherwise>
            <form id="replyForm" class="reply-form">
              <%-- ✅ 핵심: 댓글 작성 시 boardId가 빠지면 DTO 바인딩이 0이 되어 AOP에서 "존재하지 않는 게시글" 터질 수 있음 --%>
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

  <%-- ✅ 신고 모달(부트스트랩) --%>
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

  <script>
    const ctx = '${ctx}';
    const boardId = ${boardData.boardId};
    const isLogin = ${isLogin};
    const sessionMemberId = '${sessionMemberId}';
    const sessionMemberRole = '${sessionMemberRole}';
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

  <script src="${ctx}/js/boarddetail.js"></script>

  <%@ include file="/WEB-INF/common/footer.jsp"%>
</body>
</html>
