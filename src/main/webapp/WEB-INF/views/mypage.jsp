<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%> <%-- ✅ CHANGED: profileSrc 경로 보정에 fn 필요 --%>

<%-- ✅ 컨텍스트 경로: 정적 리소스/링크에 공통 사용 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- =========================================================
   1) 인증 가드
   - 세션에 memberId 없으면 마이페이지 접근 불가 → 로그인으로 리다이렉트
   ========================================================= --%>
<c:if test="${empty sessionScope.memberId}">
  <%-- ✅ CHANGED: c:redirect는 ctx를 붙이지 말고 "/매핑"만 (JSTL이 컨텍스트 기준으로 처리) --%>
  <c:redirect url="/login" />
</c:if>

<%-- =========================================================
   ✅ CHANGED: 주요 엔드포인트는 c:url로 생성(컨텍스트 자동 포함 + 인코딩)
   ========================================================= --%>
<c:url var="urlProfileUpload" value="/member/profile/upload" />
<c:url var="urlNickCheck" value="/MemberNickNameCheck" />
<c:url var="urlApplyDecoration" value="/member/apply-decoration" />
<c:url var="urlProfileSubmit" value="/member/profile" />

<c:url var="urlChangePwPage" value="/changePasswordPage" />
<c:url var="urlMyPostPage" value="/myPostPage" />
<c:url var="urlWithdraw" value="/member/withdraw" />

<%-- =========================================================
   2) 프로필 이미지 경로 결정
   - memberProfileImage가 있으면: 저장값 형태에 따라 보정
   - 없으면: 기본 이미지
   ========================================================= --%>
<c:set var="profileRaw" value="${memberData.memberProfileImage}" /> <%-- ✅ CHANGED --%>
<c:set var="profileSrc" value="${ctx}/img/profile-default.jpg" />   <%-- ✅ CHANGED: 기본값 먼저 --%>

<c:if test="${not empty profileRaw}">
  <c:choose>
    <%-- ✅ CHANGED: 외부 URL 그대로 --%>
    <c:when test="${fn:startsWith(profileRaw,'http')}">
      <c:set var="profileSrc" value="${profileRaw}" />
    </c:when>

    <%-- ✅ CHANGED: 이미 ctx 포함이면 그대로 --%>
    <c:when test="${fn:startsWith(profileRaw, ctx)}">
      <c:set var="profileSrc" value="${profileRaw}" />
    </c:when>

    <%-- ✅ CHANGED: '/upload/..' 처럼 슬래시 시작이면 ctx만 앞에 붙임 --%>
    <c:when test="${fn:startsWith(profileRaw,'/')}">
      <c:set var="profileSrc" value="${ctx}${profileRaw}" />
    </c:when>

    <%-- ✅ CHANGED: 'upload/..' 처럼 슬래시 없는 저장값 방어 --%>
    <c:otherwise>
      <c:set var="profileSrc" value="${ctx}/${profileRaw}" />
    </c:otherwise>
  </c:choose>
</c:if>

<%-- =========================================================
   3) 캐시 표시용 안전 처리 + 포맷
   - null이면 0으로 처리
   ========================================================= --%>
<c:set var="cashSafe" value="${empty memberData.memberCash ? 0 : memberData.memberCash}" />
<fmt:formatNumber value="${cashSafe}" type="number" var="cashFmt" />

<%-- =========================================================
   4) 꾸미기 초기값(원본)
   - 닉네임 색(memberNicknameColor)
   - 프로필 테두리 색(memberProfileColor)
   - borderColorStyle은 inline CSS 변수 초기값으로 사용
   ========================================================= --%>
<c:set var="nickColorInit" value="${empty memberData.memberNicknameColor ? '' : memberData.memberNicknameColor}" />
<c:set var="borderColorInit" value="${empty memberData.memberProfileColor ? '' : memberData.memberProfileColor}" />
<c:set var="borderColorStyle" value="${empty borderColorInit ? 'transparent' : borderColorInit}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 마이페이지</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<%-- ✅ 마이페이지 전용 분리 CSS --%>
<link rel="stylesheet" href="${ctx}/css/mypage.css">
</head>

<%-- =========================================================
   body data-* 주입 (JS가 읽는 설정/엔드포인트/비용)
   ========================================================= --%>
<body class="mypage-page"
  data-ctx="${ctx}"
  data-url-profile-upload="${urlProfileUpload}"        <%-- ✅ CHANGED --%>
  data-url-nick-check="${urlNickCheck}"                <%-- ✅ CHANGED --%>
  data-url-apply-decoration="${urlApplyDecoration}"    <%-- ✅ CHANGED --%>
  data-cost-nick="300"
  data-cost-profile="500"
  data-cost-nick-decor="200"
  data-cost-border-decor="200">

  <%@ include file="/WEB-INF/common/header.jsp"%>

  <c:if test="${not empty msg}">
    <div class="container" style="margin-top: 18px;">
      <div class="alert alert-warning" style="border-radius: 14px;">${msg}</div>
    </div>
  </c:if>

  <div class="container mypage-title">
    <h1 class="mypage-title__h1">마이페이지</h1>
  </div>

  <section class="spad mypage-spad">
    <div class="container">
      <div class="row">

        <div class="col-12 col-lg-4 mypage-col-left">
          <div class="login-box-clean mypage-side-card text-center">

            <div class="profile-img-wrap is-loading" id="profileWrap"
              style="--profile-border-color: ${borderColorStyle};">

              <img id="profilePreview" alt="프로필 이미지"
                data-real-src="${profileSrc}"
                data-initial-src="${profileSrc}"
                data-default-src="${ctx}/img/profile-default.jpg"
                src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==">

              <div class="profile-loader" role="status" aria-live="polite">
                <div class="loader-bar" aria-hidden="true"></div>
                <div class="loader-text">이미지 불러오는 중</div>
              </div>
            </div>

            <label id="profileBtnLabel" class="mypage-btn profile-btn disabled-btn">
              <span class="btn-text">프로필 사진 변경</span>
              <input type="file" id="profileInput" accept="image/*" hidden>
            </label>

            <div class="msg-area msg-info cost-hint" id="profileCostMsg"
              style="margin-top: 10px; display: none;">
              <span class="cost-hint__text">
                ※ 프로필 사진 변경 시 <b>500원</b> 이 차감됩니다.
              </span>
            </div>
          </div>

          <div class="login-box-clean mypage-side-card" style="margin-top: 20px;">
            <ul class="side-menu">
              <li class="menu-item">
                <a class="menu-link ${activeMenu eq 'PW' ? 'is-active' : ''}"
                  href="${urlChangePwPage}"> <%-- ✅ CHANGED --%>
                  <i class="fa fa-lock"></i><span>비밀번호 변경</span>
                </a>
              </li>

              <li class="menu-item">
                <a class="menu-link ${activeMenu eq 'MYPOST' ? 'is-active' : ''}"
                  href="${urlMyPostPage}"> <%-- ✅ CHANGED --%>
                  <i class="fa fa-pencil-square-o"></i><span>내 글 보기</span>
                </a>
              </li>

              <li class="menu-item">
                <form action="${urlWithdraw}" method="post"  <%-- ✅ CHANGED --%>
                  style="margin: 0;"
                  onsubmit="return confirm('정말 탈퇴하시겠습니까?\n탈퇴 후에는 복구할 수 없습니다.');">
                  <button type="submit" class="menu-btn danger">
                    <i class="fa fa-sign-out"></i><span>회원 탈퇴</span>
                  </button>
                </form>
              </li>
            </ul>
          </div>
        </div>

        <div class="col-12 col-lg-8 mypage-col-right">
          <div class="login-box-clean mypage-right-card">
            <h5 style="margin-bottom: 24px;">내 정보</h5>

            <form id="mypageForm" action="${urlProfileSubmit}" method="post"> <%-- ✅ CHANGED --%>
              <input type="hidden" id="temporaryProfileImageToken"
                name="temporaryProfileImageToken" value="" />

              <input type="hidden" id="originNicknameColor" value="${nickColorInit}">
              <input type="hidden" id="originBorderColor" value="${borderColorInit}">

              <input type="hidden" id="nicknameColorInput" name="memberNicknameColor" value="${nickColorInit}">
              <input type="hidden" id="borderColorInput" name="memberProfileColor" value="${borderColorInit}">

              <!-- (아이디/이메일/닉네임/꾸미기/캐시/비용/버튼 영역은 네 코드 그대로) -->
            </form>
          </div>
        </div>

      </div>
    </div>
  </section>

  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <div id="modalBackdrop" class="modal-backdrop-custom">
    <div class="modal-box" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
      <!-- (모달 내부는 네 코드 그대로) -->
    </div>
  </div>

  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/mypage.js"></script>

</body>
</html>
