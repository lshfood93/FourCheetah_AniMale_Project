<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- 컨텍스트 경로 공통 변수
     로그인 페이지 내부 링크/정적 리소스 경로를 전부 같은 기준(ctx)으로 맞춘다.
     스크립틀릿 대신 EL로 통일해서 JSP 가독성/유지보수성도 같이 챙김. --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 컨트롤러 매핑 경로 미리 생성
     파라미터 없는 링크라도 c:url로 만들어두면
     1) 컨텍스트 경로 자동 반영
     2) 링크 작성 방식 통일
     3) 추후 경로 변경 시 추적이 쉬움 --%>
<c:url var="loginActionUrl" value="/login" />
<c:url var="findPwUrl" value="/findPasswordPage" />
<c:url var="joinUrl" value="/joinPage" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 로그인</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<%-- favicon도 ctx 기준으로 맞춰서 하위 경로 접속 시 깨지지 않게 처리 --%>
<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<%-- Google Font --%>
<link
  href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap"
  rel="stylesheet">
<link
  href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap"
  rel="stylesheet">

<%-- 공통 CSS (템플릿/아이콘/프로젝트 스타일) --%>
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* ---------------------------------------------------------
   로그인 페이지 전용 보정 스타일
   ---------------------------------------------------------
   공통 style.css를 그대로 쓰되,
   이 페이지에서만 필요한 옵션 UI / 배너 높이만 추가로 덮어쓴다.
--------------------------------------------------------- */

/* 로그인 옵션(자동 로그인) 영역 배치 */
.login-box-clean .login-options {
  margin: 12px 0 18px;
  display: flex;
  align-items: center;
}

/* 자동 로그인 라벨
   체크박스 + 텍스트를 한 덩어리처럼 클릭 가능하게 구성 */
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

/* 체크박스 커스텀 UI
   브라우저 기본 체크박스 대신 프로젝트 톤에 맞게 직접 스타일링 */
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

/* 체크된 상태 배경/테두리 강조 */
.login-box-clean .login-options .auto-login input[type="checkbox"]:checked {
  background: rgba(227, 42, 42, 0.95);
  border-color: rgba(227, 42, 42, 0.95);
}

/* 체크 표시(✓)를 의사요소로 직접 그림 */
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

/* 라벨 hover 시 살짝 강조 */
.login-box-clean .login-options .auto-login:hover {
  opacity: 1;
}

/* ---------------------------------------------------------
   로그인 페이지 배너 높이 강제 보정
   ---------------------------------------------------------
   템플릿 기본값/다른 CSS 영향으로 배너가 너무 낮게 보이거나
   잘리는 경우가 있어서 이 페이지에서만 강하게 고정한다.
--------------------------------------------------------- */
.normal-breadcrumb.set-bg{
  height: 400px !important;
  min-height: 400px !important;

  /* 배경 이미지가 너무 아래쪽만 보이지 않게 위쪽 영역이 조금 더 보이도록 조정 */
  background-position: 50% 15% !important;

  /* 다른 스타일이 개입해도 커버 기준 유지 */
  background-size: cover !important;
  background-repeat: no-repeat !important;
}
</style>
</head>

<body>

  <%-- 공통 헤더 include --%>
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <%-- 로그인 페이지 상단 배너
       set-bg 클래스 + data-setbg는 main.js에서 background-image를 적용하는 템플릿 방식 --%>
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

  <%-- 로그인 입력 영역 --%>
  <section class="login spad">
    <div class="container">
      <div class="row justify-content-center">
        <div class="col-lg-6">

          <div class="login-box-clean">

            <%-- 로그인 폼
                 action도 c:url로 만든 경로를 사용해서 컨텍스트 경로 누락 방지 --%>
            <form action="${loginActionUrl}" method="post">

              <%-- 아이디 입력 --%>
              <div class="login-input">
                <i class="fa fa-user"></i>
                <input type="text" name="memberName" placeholder="아이디" required>
              </div>

              <%-- 비밀번호 입력 --%>
              <div class="login-input">
                <i class="fa fa-lock"></i>
                <input type="password" name="memberPassword" placeholder="비밀번호" required>
              </div>

              <%-- 자동 로그인 옵션
                   체크되면 autoLogin=Y 값이 서버로 전달됨 --%>
              <div class="login-options">
                <label class="auto-login">
                  <input type="checkbox" name="autoLogin" value="Y">
                  자동 로그인
                </label>
              </div>

              <%-- 로그인 제출 버튼 --%>
              <button type="submit" class="login-btn-full">로그인</button>
            </form>

            <%-- 보조 링크 영역 (비밀번호 찾기 / 회원가입) --%>
            <div class="login-links">
              <a href="${findPwUrl}">비밀번호 찾기</a>
              <span>|</span>
              <a href="${joinUrl}">회원가입</a>
            </div>

          </div>

        </div>
      </div>
    </div>
  </section>

  <%-- 공통 푸터 include --%>
  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <%-- 공통 스크립트
       main.js가 set-bg 처리(배경이미지 적용)도 담당하므로 로그인 페이지에서도 필요함 --%>
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

<%-- =========================================================
     로그인 페이지 진입 알림 (SweetAlert2 통합)
     ---------------------------------------------------------
     기존에는 alert()가 2군데로 나뉘어 있었는데,
     여기서 한 번에 처리하면 UI도 통일되고 유지보수도 쉬움.

     처리 대상
     1) joinSuccess=true   -> 회원가입 완료 안내
     2) pwChanged=true     -> 비밀번호 변경 후 재로그인 안내

     둘 다 동시에 있으면 순서대로 하나씩 보여주도록 구성.
   ========================================================= --%>
<script>
  $(function () {
    const params = new URLSearchParams(window.location.search);

    <%-- URL 쿼리스트링 기반 플래그 (회원가입 완료 후 리다이렉트 시 사용) --%>
    const isJoinSuccess = params.get('joinSuccess') === 'true';

    <%-- 서버/파라미터 값을 JS 문자열로 안전하게 받아서 비교
         값이 없으면 빈 문자열이 들어오고, true일 때만 알림 출력 --%>
    const isPwChanged = '<c:out value="${param.pwChanged}" />' === 'true';

    <%-- 표시할 알림 목록을 먼저 모아두고 순차 실행
         (조건이 2개여도 팝업이 겹치지 않게 하기 위함) --%>
    const alertQueue = [];

    if (isJoinSuccess) {
      alertQueue.push({
        icon: 'success',
        title: '회원가입 완료',
        html: '회원가입을 축하합니다!<br>로그인 후 서비스를 이용해주세요.'
      });
    }

    if (isPwChanged) {
      alertQueue.push({
        icon: 'success',
        title: '비밀번호 변경 완료',
        html: '비밀번호가 변경되었습니다.<br>다시 로그인 해주세요.'
      });
    }

    <%-- 알림이 없으면 바로 종료 --%>
    if (!alertQueue.length) return;

    <%-- SweetAlert2 순차 표시
         사용자가 확인을 눌러야 다음 알림으로 넘어감 --%>
    (async function () {
      for (const item of alertQueue) {
        await Swal.fire({
          icon: item.icon,
          title: item.title,
          html: item.html,
          confirmButtonText: '확인',
          allowOutsideClick: false,
          allowEscapeKey: true
        });
      }
    })();
  });
</script>

</body>
</html>