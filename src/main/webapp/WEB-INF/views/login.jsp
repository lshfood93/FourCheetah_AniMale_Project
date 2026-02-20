<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- ✅ CHANGED: 컨텍스트 경로를 EL로 통일 (스크립틀릿 제거) --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- ✅ CHANGED: 매핑(컨트롤러) 경로는 c:url로 생성 (컨텍스트 자동 + 인코딩 안전) --%>
<c:url var="loginActionUrl" value="/login" />
<c:url var="findPwUrl" value="/findPasswordPage" />
<c:url var="joinUrl" value="/joinPage" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 로그인</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<%-- ✅ CHANGED: favicon도 ctx로 통일 --%>
<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<!-- Google Font -->
<link
  href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap"
  rel="stylesheet">
<link
  href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap"
  rel="stylesheet">

<!-- CSS -->
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* 로그인 옵션 (자동 로그인) */
.login-box-clean .login-options {
  margin: 12px 0 18px;
  display: flex;
  align-items: center;
}

/* 라벨 */
.login-box-clean .login-options .auto-login {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-size: 14px;
  color: #ffffff;
  opacity: 0.9;
  user-select: none;
}

/* 체크박스 커스텀 */
.login-box-clean .login-options .auto-login input[type="checkbox"] {
  appearance: none;
  -webkit-appearance: none;
  width: 18px;
  height: 18px;
  border: 2px solid rgba(255, 255, 255, 0.7);
  border-radius: 4px;
  background: transparent;
  display: inline-block;
  position: relative;
  cursor: pointer;
}

/* 체크 표시 */
.login-box-clean .login-options .auto-login input[type="checkbox"]:checked {
  background: rgba(227, 42, 42, 0.95);
  border-color: rgba(227, 42, 42, 0.95);
}

.login-box-clean .login-options .auto-login input[type="checkbox"]:checked::after {
  content: "";
  position: absolute;
  left: 5px;
  top: 1px;
  width: 5px;
  height: 10px;
  border: solid #fff;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
}

/* 호버 */
.login-box-clean .login-options .auto-login:hover {
  opacity: 1;
}

/* 로그인 페이지 배너 높이 강제 (이 페이지에서만 적용) */
.normal-breadcrumb.set-bg{
  height: 400px !important;
  min-height: 400px !important;

  /* 위쪽이 더 보이게(필요하면 0%~30% 사이로 조절) */
  background-position: 50% 15% !important;

  /* 혹시 다른 CSS가 background-size를 건드리면 같이 고정 */
  background-size: cover !important;
  background-repeat: no-repeat !important;
}

</style>
</head>

<body>

  <!-- Header -->
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <!-- Breadcrumb -->
  <section class="normal-breadcrumb set-bg"
    data-setbg="${ctx}/img/normal-breadcrumb.jpg">
    <div class="container">
      <div class="row">
        <div class="col-lg-12 text-center">
          <div class="normal__breadcrumb__text">
            <h2>로그인</h2>
            <p>AniMale에 오신 것을 환영합니다.</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <section class="login spad">
    <div class="container">
      <div class="row justify-content-center">
        <div class="col-lg-6">

          <div class="login-box-clean">

            <%-- ✅ CHANGED: action도 c:url로 통일 --%>
            <form action="${loginActionUrl}" method="post">

              <div class="login-input">
                <i class="fa fa-user"></i>
                <input type="text" name="memberName" placeholder="아이디" required>
              </div>

              <div class="login-input">
                <i class="fa fa-lock"></i>
                <input type="password" name="memberPassword" placeholder="비밀번호" required>
              </div>

              <div class="login-options">
                <label class="auto-login">
                  <input type="checkbox" name="autoLogin" value="Y">
                  자동 로그인
                </label>
              </div>

              <button type="submit" class="login-btn-full">로그인</button>
            </form>

            <div class="login-links">
              <%-- ✅ CHANGED: 링크도 c:url로 통일 --%>
              <a href="${findPwUrl}">비밀번호 찾기</a>
              <span>|</span>
              <a href="${joinUrl}">회원가입</a>
            </div>

          </div>

        </div>
      </div>
    </div>
  </section>

  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <!-- 회원가입 성공 알림 -->
  <script>
    $(function () {
      const params = new URLSearchParams(window.location.search);
      if (params.get("joinSuccess") === "true") {
        alert("회원가입을 축하합니다!\n로그인 후 서비스를 이용해주세요.");
      }
    });
  </script>

  <!-- 비밀번호 변경 후 알림 -->
  <c:if test="${param.pwChanged eq 'true'}">
    <script>
      alert("비밀번호가 변경되었습니다. 다시 로그인 해주세요.");
    </script>
  </c:if>

</body>
</html>
