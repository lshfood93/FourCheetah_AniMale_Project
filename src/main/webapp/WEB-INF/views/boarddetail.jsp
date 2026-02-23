<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%-- 
  boardDetail.jsp (게시글 상세 화면)

  이 페이지는 단순 조회 화면이 아니라,
  - 게시글 조회(동기 렌더)
  - 좋아요 토글 / 좋아요 누른 사람 조회(비동기)
  - 댓글 목록/정렬(비동기)
  - 댓글 작성/수정/삭제(동기 submit)
  - 게시글 신고(모달 + 비동기)
  를 함께 다루는 화면이다.

  그래서 JSP에서 먼저 '권한/상태/초기 UI 플래그'를 계산해두고,
  JS(boarddetail.js)에는 최소한의 전역 상태만 넘겨서 동작하게 만드는 구조다.
--%>

<%-- 
  컨텍스트 경로를 request scope에 저장.
  header/footer include 포함해서 이 페이지 전체에서 ${ctx}를 공통으로 쓰기 쉽게 맞춘다.

  scope="request"를 준 이유:
  - 현재 요청 범위에서 include된 JSP(header/footer)까지 동일하게 참조 가능하게 하려는 의도
  - 상대경로/절대경로 실수 줄이고 정적 리소스/내부 링크를 일관되게 관리
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<%-- =========================================================
   1) 세션 기반 로그인 사용자 정보 / 기본 상태값 준비
   ========================================================= --%>

<%-- 로그인 여부: 세션에 memberId가 있으면 로그인 상태로 본다 --%>
<c:set var="isLogin" value="${not empty sessionScope.memberId}" />

<%-- 
  JS에서 댓글/좋아요/권한 처리에 사용할 수 있도록
  세션 사용자 식별자/권한을 JSP 변수로 미리 꺼내둔다.
--%>
<c:set var="sessionMemberId" value="${sessionScope.memberId}" />
<c:set var="sessionMemberRole" value="${sessionScope.memberRole}" />

<%-- 
  작성자 표시명 결정 로직
  - 작성자 닉네임(writerNickname)이 있으면 닉네임 표시
  - 없으면 memberId 표시
  즉, UI에서는 '보여줄 이름' 하나만 신경 쓰도록 writerDisplay로 정리
--%>
<c:set var="writerDisplay"
       value="${empty boardData.writerNickname ? boardData.memberId : boardData.writerNickname}" />

<%-- 
  작성일/수정일도 변수로 분리해두면 아래 메타 정보 렌더링(c:choose)에서
  EL 식이 길어지지 않아 읽기 쉬워진다.
--%>
<c:set var="createdAt" value="${boardData.boardCreatedAt}" />
<c:set var="updatedAt" value="${boardData.boardUpdatedAt}" />

<%-- =========================================================
   2) 제재 상태(기능 제한) 플래그 계산
   ========================================================= --%>

<%-- 
  현재 로그인 사용자의 상태값을 세션에서 가져온다.
  (board.jsp와 같은 기준을 사용해서 제재 여부 판단 기준을 화면 간 통일)
--%>
<c:set var="memberStatus" value="${sessionScope.memberStatus}" />

<%-- 
  제재 회원 여부 플래그
  아래 상태값이면 이 상세 페이지에서 '조회만 가능'에 가깝게 제한한다.
  - SUSPEND_7D
  - SUSPEND_30D
  - BAN

  이 플래그는
  - 댓글 작성/수정/삭제 제한
  - 게시글 수정/삭제 UI 제한
  - 특정 액션 버튼 클릭 차단 안내
  등에 공통으로 사용된다.
--%>
<c:set var="isBannedFlag"
       value="${memberStatus eq 'SUSPEND_7D'
               or memberStatus eq 'SUSPEND_30D'
               or memberStatus eq 'BAN'}" />

<%-- =========================================================
   3) 게시글 관리 권한 플래그 계산 (작성자/관리자)
   ========================================================= --%>

<%-- 
  게시글 관리 가능 조건(원본 권한 기준)
  - 로그인 상태이고
  - 내가 작성자이거나
  - 관리자(ADMIN)인 경우
--%>
<c:set var="canManagePost"
       value="${isLogin and (sessionMemberId eq boardData.memberId or sessionMemberRole eq 'ADMIN')}" />

<%-- 
  실제 UI에서 수정/삭제 버튼을 보여줄지 여부
  = 권한이 있어도 제재회원이면 숨김

  즉,
  - canManagePost : '원래 권한이 있는가'
  - canManagePostUi : '현재 이 화면에서 버튼 노출까지 허용되는가'
  로 역할을 분리한 것
--%>
<c:set var="canManagePostUi"
       value="${canManagePost and (not isBannedFlag)}" />

<%-- 
  이미 신고한 게시글인지 여부 (조회 결과에서 1/0으로 내려온 값을 boolean처럼 사용)
  이 값은 신고 버튼 노출 여부/JS 동작에서 중복 신고 방지에 사용된다.
--%>
<c:set var="isReportedFlag" value="${boardData.isReported == 1}" />

<%-- =========================================================
   4) 신고 가능 조건 플래그 계산
   ========================================================= --%>

<%-- 
  작성자 권한이 ADMIN이면 신고 버튼을 숨기기 위한 플래그.
  (운영 정책상 관리자 작성 공지/글은 신고 대상에서 제외하는 의도)
--%>
<c:set var="writerIsAdmin"
       value="${boardData.writerRole eq 'ADMIN'}" />

<%-- 
  신고 가능 조건
  - 로그인 상태여야 함
  - 내 글은 신고 불가
  - 이미 신고한 글은 중복 신고 불가
  - 관리자 작성 글은 신고 UI 미노출
--%>
<c:set var="canReportPost"
       value="${isLogin
               and (sessionMemberId ne boardData.memberId)
               and (not isReportedFlag)
               and (not writerIsAdmin)}" />

<%-- 
  게시글 수정 여부 플래그
  - 메타 정보 표시에서 '작성일' 대신 '수정일'을 보여줄지 결정할 때 사용
--%>
<c:set var="isEdited" value="${boardData.isEdited == 1}" />

<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AniMale | Board Detail</title>

  <link rel="icon" type="image/png" href="${ctx}/favicon.png" />

  <%-- 
    상세 페이지에서 사용하는 공통 스타일/플러그인 스타일 로드
    - 기본 테마(style.css)
    - 아이콘/컴포넌트용 css
    - 페이지 전용 boarddetail.css
  --%>
  <link rel="stylesheet" href="${ctx}/css/bootstrap.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/font-awesome.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/elegant-icons.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/slicknav.min.css" type="text/css" />
  <link rel="stylesheet" href="${ctx}/css/style.css" />

  <%-- 게시글 상세 전용 스타일 (댓글/좋아요/모달 버튼 등 포함) --%>
  <link rel="stylesheet" href="${ctx}/css/boarddetail.css" />
</head>

<body class="board-detail-page">

  <%-- 공통 헤더 include --%>
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <section class="product spad board-detail-wrap">
    <div class="container">

      <%-- =====================================================
           게시글 본문 카드 영역
           - 제목 / 메타정보 / 본문 / 액션 버튼(목록/수정/삭제/신고/좋아요)
           ===================================================== --%>
      <div class="bd-card">
        <header class="bd-head">
          <%-- 제목은 사용자 입력값이므로 c:out으로 이스케이프 출력 --%>
          <h3 class="bd-title"><c:out value="${boardData.boardTitle}" /></h3>

          <div class="bd-meta">
            <%-- 작성자 표시: 닉네임 우선, 없으면 아이디(writerDisplay) --%>
            <span class="meta-chip">
              <i class="fa fa-user"></i>
              <c:out value="${writerDisplay}" />
            </span>

            <%-- 
              수정된 글이면 작성일 대신 수정일만 보여준다.
              (UI 정책상 둘 다 노출하지 않고, 현재 상태를 더 잘 보여주는 날짜 하나만 강조)
            --%>
            <c:choose>
              <c:when test="${isEdited and not empty updatedAt}">
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

            <%-- 조회수 --%>
            <span class="meta-chip">
              <i class="fa fa-eye"></i>
              조회 <c:out value="${boardData.boardViews}" />
            </span>

            <%-- 카테고리 값이 있을 때만 표시 (null/빈값이면 칩 자체 미노출) --%>
            <c:if test="${not empty boardData.boardCategory}">
              <span class="meta-chip">
                <i class="fa fa-tag"></i>
                <c:out value="${boardData.boardCategory}" />
              </span>
            </c:if>

            <%-- 
              로그인 + 제재 상태일 때 경고 칩 노출
              사용자가 왜 버튼/기능이 제한되는지 화면에서 바로 이해하게 하기 위한 안내
            --%>
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
            <%-- 
              본문은 에디터 HTML(서식 포함)을 렌더링해야 하므로 escapeXml="false"
              전제:
              - 서버단(HtmlSanitizer 등)에서 저장/출력 시점에 안전한 HTML만 허용되도록 처리되어 있어야 함
            --%>
            <c:out value="${boardData.boardContent}" escapeXml="false" />
          </div>
        </div>

        <div class="bd-actions">
          <div class="left">
            <%-- 
              목록 복귀 버튼
              현재 글의 카테고리를 쿼리파라미터로 넘겨 같은 카테고리 목록으로 돌아가게 함
            --%>
            <a class="bd-btn"
               href="${ctx}/boardList?boardCategory=${boardData.boardCategory}">
              목록
            </a>

            <%-- 
              게시글 수정/삭제 버튼 노출 조건
              - 작성자 또는 관리자(canManagePost)
              - 동시에 제재회원이 아님(canManagePostUi)
            --%>
            <c:if test="${canManagePostUi}">
              <a class="bd-btn"
                 data-ban-lock="1"
                 href="${ctx}/boardEditPage?boardId=${boardData.boardId}">
                수정
              </a>

              <%-- 
                게시글 삭제는 동기 form submit
                이유:
                - 서버 message 페이지/redirect 흐름 유지
                - 기존 컨트롤러 정책과 맞추기 쉬움
              --%>
              <form action="${ctx}/boardDelete" method="post" style="display:inline;">
                <input type="hidden" name="boardId" value="${boardData.boardId}" />
                <button type="submit" class="bd-btn"
                        data-ban-lock="1"
                        onclick="return confirm('정말 삭제하시겠습니까?');">
                  삭제
                </button>
              </form>
            </c:if>

            <%-- 
              신고 버튼 노출 조건은 canReportPost에 통합해둠
              (로그인/본인글 제외/중복신고 제외/관리자 작성글 제외)
            --%>
            <c:if test="${canReportPost}">
              <button id="btnReport" type="button" class="bd-btn danger">
                신고
              </button>
            </c:if>
          </div>

          <div class="right">
            <%-- 
              좋아요 초기 상태 계산
              컨트롤러에서 likedByMe / likeCount를 별도로 내려준 경우 우선 사용,
              없으면 boardData 내 값으로 fallback.
              
              이렇게 해두면 컨트롤러 구현이 일부 달라도 JSP가 유연하게 초기 렌더 가능.
            --%>
            <c:set var="initLiked"
                   value="${not empty likedByMe ? likedByMe : (boardData.isLiked eq 1)}" />
            <c:set var="initLikeCount"
                   value="${not empty likeCount ? likeCount : boardData.likeCnt}" />

            <%-- 
              좋아요 상태 pill(표시용)
              initLiked=true이면 is-liked 클래스를 붙여 초기 스타일 상태를 맞춤
            --%>
            <span id="likePill" class="like-pill <c:if test='${initLiked}'>is-liked</c:if>">
              좋아요 <span id="likeCount" class="like-count"><c:out value="${initLikeCount}" /></span>
            </span>

            <%-- 
              좋아요 토글 버튼
              data-liked에 초기 좋아요 상태를 1/0으로 담아 JS가 즉시 참조할 수 있게 함
            --%>
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

            <%-- 좋아요 누른 사용자 목록 모달 열기 버튼 --%>
            <button id="btnLikeUsers"
                    type="button"
                    class="bd-btn"
                    data-board-id="${boardData.boardId}">
              좋아요 누른 사람
            </button>
          </div>
        </div>
      </div>

      <%-- =====================================================
           댓글 카드 영역
           - 정렬 선택 / 총 개수
           - 로그인/제재 상태별 작성 UI 분기
           - 댓글 리스트 렌더 영역
           - 수정/삭제용 hidden form
           ===================================================== --%>
      <div class="reply-card">
        <div class="reply-head">
          <h4>댓글</h4>

          <%-- 
            우측 도구 그룹
            - replySort: 댓글 정렬 기준 선택 (최신순/작성순)
            - replyCount: JS가 댓글 목록 로딩 후 총 개수를 갱신
          --%>
          <div class="reply-head-tools">
            <select id="replySort">
              <option value="REPLY_LIST_RECENT" selected>최신순</option>
              <option value="REPLY_LIST_OLDEST">작성순</option>
            </select>

            <div class="reply-count">총 <span id="replyCount">0</span>개</div>
          </div>
        </div>

        <c:choose>
          <%-- 비로그인 상태: 댓글 작성 폼 대신 로그인 유도 문구 노출 --%>
          <c:when test="${not isLogin}">
            <div class="reply-login-hint">
              댓글 작성은 로그인 후 가능합니다.
              <a href="${ctx}/login">로그인하기</a>
            </div>
          </c:when>

          <%-- 
            로그인했지만 제재회원인 경우:
            - 작성 폼 모양은 보여주되 disabled 처리
            - 왜 안 되는지 안내 문구를 함께 보여줌
          --%>
          <c:when test="${isLogin and isBannedFlag}">
            <div class="ban-hint">
              제재회원은 댓글 작성/수정/삭제 및 게시글 작성/수정/삭제가 제한됩니다.
            </div>

            <form id="replyForm" class="reply-form is-banned" onsubmit="return false;">
              <input type="hidden" name="boardId" value="${boardData.boardId}" />
              <textarea id="replyContent" name="replyContent" placeholder="제재회원은 댓글을 작성할 수 없습니다." disabled></textarea>
              <button type="submit" class="bd-btn accent" disabled>등록</button>
            </form>
          </c:when>

          <%-- 
            일반 로그인 사용자: 댓글 작성은 동기 submit
            (댓글 작성 컨트롤러의 redirect/message 흐름과 맞추기 위한 정책)
          --%>
          <c:otherwise>
            <form id="replyForm" class="reply-form" action="${ctx}/replyWrite" method="post">
              <input type="hidden" name="boardId" value="${boardData.boardId}" />
              <textarea id="replyContent" name="replyContent" placeholder="댓글을 입력하세요"></textarea>
              <button type="submit" class="bd-btn accent">등록</button>
            </form>
          </c:otherwise>
        </c:choose>

        <%-- 
          댓글 리스트 렌더 영역
          실제 댓글 카드들은 JS(boarddetail.js)가 비동기로 받아와서 그려 넣는다.
          replyEmpty는 댓글이 없을 때만 JS가 표시한다.
        --%>
        <div id="replyList" class="reply-list">
          <div class="reply-empty" id="replyEmpty" style="display:none;">등록된 댓글이 없습니다.</div>
        </div>

        <%-- 
          댓글 수정/삭제는 UI 상에서는 버튼 클릭처럼 보이지만,
          실제 전송은 동기 submit(hidden form)으로 처리한다.
          
          이유:
          - 기존 ReplyController의 POST 처리 흐름 유지
          - 서버 리다이렉트/메시지 처리 정책 일관성 유지
          - 프론트에서 fetch로 전환할 때보다 기존 구조와 충돌이 적음
        --%>
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

  <%-- =========================================================
       신고 모달
       - 신고 사유(select)
       - 상세 사유(textarea, 선택)
       - 신고 접수 버튼(btnReportSubmit)
       실제 신고 요청은 JS에서 비동기로 처리
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
            <%-- 신고 분류(코드값)는 서버에 그대로 전달되는 값이므로 option value가 중요 --%>
            <select id="reportReason" style="flex:1; min-width:200px;">
              <option value="SPAM">스팸/도배</option>
              <option value="ABUSE">욕설/비방</option>
              <option value="ILLEGAL">불법/유해</option>
              <option value="ETC">기타</option>
            </select>
            <%-- 상세 신고 사유는 선택 입력(비어도 접수 가능) --%>
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
       제재회원 액션 차단 안내 모달
       - 제재회원이 제한된 기능(신고/수정/삭제 등)을 시도할 때 안내용
       - 안내 문구는 JS에서 상황에 맞게 바꿔 쓸 수 있도록 id=banActionText 부여
       ========================================================= --%>
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

  <%-- =========================================================
       좋아요 누른 사람 목록 모달
       - JS가 목록 데이터를 비동기로 가져와 likeUsersList에 렌더링
       - 목록이 비어 있으면 likeUsersEmpty 표시
       ========================================================= --%>
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

  <%-- =========================================================
       JS 전역 변수 브리지 (JSP -> boarddetail.js)

       boarddetail.js가 화면 동작을 할 때 필요한 최소 정보만 내려준다.
       - ctx: 내부 API/페이지 경로 조합용
       - boardId: 현재 게시글 식별자
       - isLogin: 로그인 여부
       - sessionMemberId / sessionMemberRole: 권한/본인 여부 판단
       - isReported: 신고 버튼/중복신고 처리 관련 초기 상태
       - isBanned: 제재회원 기능 제한 처리용
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

  <%-- 
    공통 JS 라이브러리 및 테마 스크립트 로드
    (순서 중요: jQuery -> bootstrap -> 플러그인 -> main.js -> 페이지 전용 js)
  --%>
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/player.js"></script>
  <script src="${ctx}/js/jquery.nice-select.min.js"></script>
  <script src="${ctx}/js/mixitup.min.js"></script>
  <script src="${ctx}/js/jquery.slicknav.js"></script>
  <script src="${ctx}/js/owl.carousel.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <%-- 
    게시글 상세 페이지 전용 스크립트
    담당 기능:
    - 좋아요 토글 / 좋아요 사용자 목록 모달
    - 댓글 목록 로딩/정렬/렌더링
    - 댓글 인라인 수정 후 hidden form submit
    - 댓글 삭제 hidden form submit
    - 신고 모달/신고 접수(fetch)
    - 제재회원 액션 차단 모달 처리
  --%>
  <script src="${ctx}/js/boarddetail.js"></script>

  <%-- 공통 푸터 include --%>
  <%@ include file="/WEB-INF/common/footer.jsp"%>
</body>
</html>