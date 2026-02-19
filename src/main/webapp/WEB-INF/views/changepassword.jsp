<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- =========================================================
   ✅ 1) 접근 가드 (JSTL)
   - 로그인 변경: sessionScope.memberId 존재
   - 비번 재설정: findPasswordVerified=true && findPasswordMemberId 존재
   ========================================================= --%>
<c:set var="isLoginFlow" value="${not empty sessionScope.memberId}" />
<c:set var="isResetFlow" value="${sessionScope.findPasswordVerified eq true and not empty sessionScope.findPasswordMemberId}" />

<%-- ✅ CHANGED: 내부 URL은 c:url로 통일 --%>
<c:url var="loginUrl" value="/login" />
<c:url var="adminPageUrl" value="/adminPage" />
<c:url var="mypageUrl" value="/member/mypage" />
<c:url var="changePwActionUrl" value="/member/change-password" />

<%-- ✅ CHANGED: 접근 불가면 로그인으로 리다이렉트 --%>
<c:if test="${not isLoginFlow and not isResetFlow}">
  <c:redirect url="${loginUrl}" />
</c:if>

<%-- =========================================================
   ✅ 2) role 기반 뒤로가기 링크 결정
   ========================================================= --%>
<c:set var="role" value="${sessionScope.memberRole}" />
<c:set var="isAdmin" value="${not empty role and fn:contains(fn:toUpperCase(role), 'ADMIN')}" />

<c:choose>
  <c:when test="${isResetFlow}">
    <c:set var="backUrl" value="${loginUrl}" />
    <c:set var="backText" value="← 로그인 화면으로" />
  </c:when>
  <c:otherwise>
    <c:choose>
      <c:when test="${isAdmin}">
        <c:set var="backUrl" value="${adminPageUrl}" />
        <c:set var="backText" value="← 관리자 페이지로" />
      </c:when>
      <c:otherwise>
        <c:set var="backUrl" value="${mypageUrl}" />
        <c:set var="backText" value="← 마이페이지로" />
      </c:otherwise>
    </c:choose>
  </c:otherwise>
</c:choose>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 비밀번호 변경</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

<style>
.icon_profile, .icon_search, .search-switch { display: none !important; }
.change-wrap { max-width: 520px; margin: 0 auto; background: #fff; padding: 40px 30px; border-radius: 16px; }
.change-box h4 { text-align: center; font-weight: 700; margin-bottom: 30px; color: #000; }
.msg { font-size: 12px; margin-top: 6px; min-height: 16px; }
.msg.error { color: #ff4c4c; }
.msg.success { color: #4caf50; }
.btn-main { width: 100%; height: 52px; border-radius: 30px; background: #e53637 !important; border: none; color: #fff !important; font-weight: 600; margin-top: 20px; }
.btn-main:disabled { background: #bdbdbd !important; }
.cancel-link { display: block; margin-top: 16px; text-align: center; color: #2f80ed; font-size: 14px; }
.login-input input { border: 1.5px solid rgba(0, 0, 0, 0.35) !important; border-radius: 30px !important; height: 50px; padding-left: 48px; background: #fff !important; }
.login-input input:focus { outline: none; border-color: #000 !important; }
</style>

<script>
$(function() {
  // ✅ CHANGED: JSP 스크립틀릿 대신 JSTL boolean 출력으로 통일
  const requireCurrent = ${isLoginFlow}; // 로그인 변경이면 true, 재설정이면 false
  const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+=-]).{8,16}$/;

  let currentPasswordValid = !requireCurrent; // 재설정이면 현재비번 불필요
  let newPasswordValid = false;

  function toggleButton() {
    $(".btn-main").prop("disabled", !(currentPasswordValid && newPasswordValid));
  }

  if (requireCurrent) {
    $("#currentPassword").on("input", function() {
      if ($(this).val().length >= 4) {
        $("#currentPasswordMsg").text("현재 비밀번호 입력이 확인되었습니다.").removeClass("error").addClass("success");
        currentPasswordValid = true;
      } else {
        $("#currentPasswordMsg").text("현재 비밀번호를 입력해주세요.").removeClass("success").addClass("error");
        currentPasswordValid = false;
      }
      $("#newPassword").trigger("input");
      toggleButton();
    });
  }

  $("#newPassword, #newPasswordConfirm").on("input", function() {
    const currentPassword = requireCurrent ? $("#currentPassword").val() : "";
    const newPassword = $("#newPassword").val();
    const newPasswordConfirm = $("#newPasswordConfirm").val();

    if (!passwordRegex.test(newPassword)) {
      $("#newPasswordMsg").text("8~16자, 영문/숫자/특수문자 포함").removeClass("success").addClass("error");
      newPasswordValid = false;
      toggleButton();
      return;
    }

    if (requireCurrent && currentPassword.length > 0 && currentPassword === newPassword) {
      $("#newPasswordMsg").text("현재 비밀번호와 다른 비밀번호를 입력해주세요.").removeClass("success").addClass("error");
      newPasswordValid = false;
      toggleButton();
      return;
    }

    if (newPassword === newPasswordConfirm) {
      $("#newPasswordMsg").text("새 비밀번호가 일치합니다.").removeClass("error").addClass("success");
      newPasswordValid = true;
    } else {
      $("#newPasswordMsg").text("새 비밀번호가 일치하지 않습니다.").removeClass("success").addClass("error");
      newPasswordValid = false;
    }

    toggleButton();
  });

  $("form").on("submit", function(e) {
    if (requireCurrent) {
      const currentPassword = $("#currentPassword").val();
      const newPassword = $("#newPassword").val();
      if (currentPassword === newPassword) {
        e.preventDefault();
        return false;
      }
    }

    if (!(currentPasswordValid && newPasswordValid)) {
      e.preventDefault();
      return false;
    }
  });

  toggleButton();
});
</script>
</head>

<body>

<%@ include file="/WEB-INF/common/header.jsp" %>

<section class="spad">
  <div class="container">
    <div class="change-wrap">
      <div class="login-box-clean change-box">

        <h4>
          <c:choose>
            <c:when test="${isResetFlow}">비밀번호 재설정</c:when>
            <c:otherwise>비밀번호 변경</c:otherwise>
          </c:choose>
        </h4>

        <%-- ✅ CHANGED: action도 c:url 변수 사용 --%>
        <form action="${changePwActionUrl}" method="post">

          <c:if test="${isLoginFlow}">
            <div class="login-input">
              <i class="fa fa-lock"></i>
              <input type="password" id="currentPassword" name="currentPassword" placeholder="현재 비밀번호">
            </div>
            <div id="currentPasswordMsg" class="msg"></div>
          </c:if>

          <div class="login-input" style="margin-top: 18px;">
            <i class="fa fa-key"></i>
            <input type="password" id="newPassword" name="newPassword" placeholder="새 비밀번호">
          </div>

          <div class="login-input">
            <i class="fa fa-key"></i>
            <input type="password" id="newPasswordConfirm" placeholder="새 비밀번호 확인">
          </div>
          <div id="newPasswordMsg" class="msg"></div>

          <button type="submit" class="btn-main" disabled>
            <c:choose>
              <c:when test="${isResetFlow}">비밀번호 재설정</c:when>
              <c:otherwise>비밀번호 변경</c:otherwise>
            </c:choose>
          </button>

          <a href="${backUrl}" class="cancel-link">${backText}</a>

        </form>

      </div>
    </div>
  </div>
</section>

<%@ include file="/WEB-INF/common/footer.jsp" %>

<script src="${ctx}/js/bootstrap.min.js"></script>
</body>
</html>
