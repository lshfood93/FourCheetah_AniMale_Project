<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<%-- 
  현재 애플리케이션의 contextPath를 꺼내서 ctx 변수로 보관한다.

  왜 필요한가?
  - 정적 리소스(css/js/favicon) 경로를 환경별(로컬/배포)로 안전하게 맞추기 위해서
  - /animale 같은 컨텍스트 경로가 붙는 환경에서도 ${ctx}/... 형태로 일관되게 사용 가능
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- =========================================================
   1) 접근 가드용 상태값 계산 (JSTL)

   이 페이지는 두 가지 흐름에서만 접근 가능하다.

   [A] 로그인 상태에서 '비밀번호 변경'
       - sessionScope.memberId 가 존재해야 함

   [B] 비밀번호 찾기 인증 완료 후 '비밀번호 재설정'
       - sessionScope.findPasswordVerified == true
       - sessionScope.findPasswordMemberId 존재

   아래 boolean 값을 먼저 계산해두면,
   이후 분기(c:if / c:choose)에서 조건식을 반복하지 않아도 되어
   JSP 가독성과 유지보수성이 좋아진다.
   ========================================================= --%>
<c:set var="isLoginFlow" value="${not empty sessionScope.memberId}" />
<c:set var="isResetFlow" value="${sessionScope.findPasswordVerified eq true and not empty sessionScope.findPasswordMemberId}" />

<%-- 
  이 페이지에서 사용하는 내부 URL(페이지 이동 / form action)을 c:url로 미리 정의한다.

  이렇게 분리하는 이유:
  - JSP 본문 곳곳에 경로 문자열을 하드코딩하지 않기 위해
  - contextPath 포함 경로를 안전하게 만들기 위해
  - 나중에 매핑이 바뀌면 상단 변수 정의만 수정하면 되게 하려고
--%>
<c:url var="loginUrl" value="/login" />
<c:url var="adminPageUrl" value="/adminPage" />
<c:url var="mypageUrl" value="/member/mypage" />
<c:url var="changePwActionUrl" value="/member/change-password" />

<%-- 
  접근 허용 조건이 둘 다 아니면(로그인 변경도 아니고, 재설정 흐름도 아니면)
  이 페이지를 직접 접근한 것으로 보고 로그인 페이지로 즉시 리다이렉트한다.

  목적:
  - 비정상 진입 차단
  - 세션 상태 없는 사용자의 직접 URL 접근 방지
--%>
<c:if test="${not isLoginFlow and not isResetFlow}">
  <c:redirect url="${loginUrl}" />
</c:if>

<%-- =========================================================
   2) 뒤로가기 링크(backUrl / backText) 결정

   이 페이지 하단의 '취소/뒤로가기' 링크는 진입 흐름에 따라 목적지가 달라진다.

   - 비밀번호 재설정 흐름(isResetFlow): 로그인 화면으로
   - 일반 로그인 변경 흐름:
       * 관리자면 관리자 페이지로
       * 일반 사용자면 마이페이지로

   먼저 role과 admin 여부를 계산한 뒤, c:choose로 최종 링크/문구를 정한다.
   ========================================================= --%>
<c:set var="role" value="${sessionScope.memberRole}" />
<c:set var="isAdmin" value="${not empty role and fn:contains(fn:toUpperCase(role), 'ADMIN')}" />

<c:choose>
  <%-- 비밀번호 찾기 이후 재설정 흐름이면, 완료/취소 후 다시 로그인으로 보내는 UX가 자연스럽다 --%>
  <c:when test="${isResetFlow}">
    <c:set var="backUrl" value="${loginUrl}" />
    <c:set var="backText" value="← 로그인 화면으로" />
  </c:when>
  <c:otherwise>
    <%-- 일반 로그인 상태에서의 비밀번호 변경 흐름: 권한(role)에 따라 복귀 목적지 분기 --%>
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
/* 헤더의 프로필/검색 UI는 이 페이지에서는 필요 없어서 숨김 처리 (비밀번호 변경 화면 집중도 확보) */
.icon_profile, .icon_search, .search-switch { display: none !important; }

/* 변경 폼 카드 영역 (가운데 배치 + 흰 배경) */
.change-wrap { max-width: 520px; margin: 0 auto; background: #fff; padding: 40px 30px; border-radius: 16px; }

/* 제목 스타일 */
.change-box h4 { text-align: center; font-weight: 700; margin-bottom: 30px; color: #000; }

/* 유효성 검사 메시지 영역 (높이를 고정해 레이아웃 흔들림 최소화) */
.msg { font-size: 12px; margin-top: 6px; min-height: 16px; }
.msg.error { color: #ff4c4c; }
.msg.success { color: #4caf50; }

/* 메인 제출 버튼 */
.btn-main { width: 100%; height: 52px; border-radius: 30px; background: #e53637 !important; border: none; color: #fff !important; font-weight: 600; margin-top: 20px; }

/* 비활성 상태 버튼 (검증 완료 전) */
.btn-main:disabled { background: #bdbdbd !important; }

/* 뒤로가기 링크 */
.cancel-link { display: block; margin-top: 16px; text-align: center; color: #2f80ed; font-size: 14px; }

/* 입력칸 스타일 (기존 로그인 템플릿 계열 클래스 재사용) */
.login-input input { border: 1.5px solid rgba(0, 0, 0, 0.35) !important; border-radius: 30px !important; height: 50px; padding-left: 48px; background: #fff !important; }

/* 포커스 시 테두리 강조 */
.login-input input:focus { outline: none; border-color: #000 !important; }
</style>

<script>
$(function() {
  /* =========================================================
     [현재 화면 흐름 구분값]
     
     JSP에서 계산한 isLoginFlow(boolean)를 그대로 JS 상수로 내려받는다.
     - true  : 로그인 상태에서 '비밀번호 변경' (현재 비밀번호 입력 필요)
     - false : 비밀번호 찾기 인증 후 '비밀번호 재설정' (현재 비밀번호 입력 불필요)

     즉, requireCurrent는 '현재 비밀번호 필드가 필수인지'를 결정하는 핵심 플래그다.
     ========================================================= */
  const requireCurrent = ${isLoginFlow};

  /* 
     새 비밀번호 형식 검사용 정규식
     조건:
     - 8~16자
     - 영문 최소 1개
     - 숫자 최소 1개
     - 특수문자 최소 1개
  */
  const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+=-]).{8,16}$/;

  /* =========================================================
     [상태값]
     
     버튼 활성화는 입력값 그 자체가 아니라 '검증 통과 여부' 상태값으로 제어한다.
     
     currentPasswordValid:
     - 로그인 변경(requireCurrent=true)일 때는 사용자가 현재 비번을 입력해야 true 가능
     - 재설정(requireCurrent=false)일 때는 현재 비번이 필요 없으므로 시작값을 true로 둔다.
     
     newPasswordValid:
     - 새 비밀번호 규칙 검사 + 확인 일치까지 끝나야 true
     ========================================================= */
  let currentPasswordValid = !requireCurrent; // 재설정 흐름이면 현재비번 체크를 자동 통과 처리
  let newPasswordValid = false;

  /* 
     제출 버튼 활성/비활성 제어
     - 현재 비밀번호 조건(필요한 경우만)
     - 새 비밀번호 조건
     두 상태가 모두 통과했을 때만 버튼 활성화
  */
  function toggleButton() {
    $(".btn-main").prop("disabled", !(currentPasswordValid && newPasswordValid));
  }

  /* =========================================================
     [현재 비밀번호 입력 검사 - 로그인 변경 흐름에서만]
     
     재설정 흐름에서는 currentPassword input 자체가 렌더링되지 않으므로
     requireCurrent가 true일 때만 이벤트를 등록한다.
     
     여기서는 '입력 여부 확인' 수준의 클라이언트 검증만 수행하고,
     실제 현재 비밀번호 일치 여부 검증은 서버에서 해야 한다.
     ========================================================= */
  if (requireCurrent) {
    $("#currentPassword").on("input", function() {
      if ($(this).val().length >= 4) {
        /* 
           현재 비밀번호는 여기서 진짜 일치 검증을 하는 것이 아니라
           '입력이 되었는지'에 대한 1차 확인만 한다.
           (서버 제출 시 실제 검증)
        */
        $("#currentPasswordMsg").text("현재 비밀번호 입력이 확인되었습니다.").removeClass("error").addClass("success");
        currentPasswordValid = true;
      } else {
        $("#currentPasswordMsg").text("현재 비밀번호를 입력해주세요.").removeClass("success").addClass("error");
        currentPasswordValid = false;
      }

      /* 
         현재 비밀번호가 바뀌면 '새 비밀번호가 현재와 같은지' 조건에도 영향이 있으므로
         새 비밀번호 검증 로직을 다시 태워서 메시지/상태를 즉시 갱신한다.
      */
      $("#newPassword").trigger("input");
      toggleButton();
    });
  }

  /* =========================================================
     [새 비밀번호 / 새 비밀번호 확인 입력 검사]
     
     둘 중 하나라도 입력이 바뀌면 전체 판정을 다시 수행한다.
     
     검사 순서:
     1) 새 비밀번호 형식 검사 (정규식)
     2) (로그인 변경 흐름일 때) 현재 비밀번호와 동일한지 검사
     3) 새 비밀번호와 확인값 일치 검사
     ========================================================= */
  $("#newPassword, #newPasswordConfirm").on("input", function() {
    const currentPassword = requireCurrent ? $("#currentPassword").val() : "";
    const newPassword = $("#newPassword").val();
    const newPasswordConfirm = $("#newPasswordConfirm").val();

    /* 1) 형식 검사 실패 시 즉시 종료 */
    if (!passwordRegex.test(newPassword)) {
      $("#newPasswordMsg").text("8~16자, 영문/숫자/특수문자 포함").removeClass("success").addClass("error");
      newPasswordValid = false;
      toggleButton();
      return;
    }

    /* 
       2) 로그인 상태 변경 흐름에서는 보안/정책상
          현재 비밀번호와 동일한 비밀번호로 변경하지 못하게 막는다.
       (재설정 흐름에서는 현재 비밀번호 입력칸이 없으므로 이 조건 자체를 적용하지 않음)
    */
    if (requireCurrent && currentPassword.length > 0 && currentPassword === newPassword) {
      $("#newPasswordMsg").text("현재 비밀번호와 다른 비밀번호를 입력해주세요.").removeClass("success").addClass("error");
      newPasswordValid = false;
      toggleButton();
      return;
    }

    /* 
       3) 확인 입력값과 일치 여부 검사
       - 현재 구현은 '빈 문자열끼리 일치'도 false로 처리되지 않고 아래 분기로 들어갈 수 있으나,
         앞 단계 정규식 검사에서 newPassword가 먼저 걸러지므로 실제로는 문제 없이 동작한다.
    */
    if (newPassword === newPasswordConfirm) {
      $("#newPasswordMsg").text("새 비밀번호가 일치합니다.").removeClass("error").addClass("success");
      newPasswordValid = true;
    } else {
      $("#newPasswordMsg").text("새 비밀번호가 일치하지 않습니다.").removeClass("success").addClass("error");
      newPasswordValid = false;
    }

    toggleButton();
  });

  /* =========================================================
     [폼 제출 직전 최종 방어]
     
     버튼 비활성화만 믿지 않고, submit 이벤트에서도 한 번 더 검사한다.
     이유:
     - 사용자가 개발자도구로 disabled를 강제로 해제할 수 있음
     - 예상치 못한 상태 꼬임을 방어하기 위해서
     
     방어 조건:
     1) 로그인 변경 흐름이면 현재/새 비밀번호 동일 금지
     2) currentPasswordValid && newPasswordValid 둘 다 true여야 제출 허용
     ========================================================= */
  $("form").on("submit", function(e) {
    if (requireCurrent) {
      const currentPassword = $("#currentPassword").val();
      const newPassword = $("#newPassword").val();

      /* 현재 비밀번호와 새 비밀번호 동일하면 제출 차단 */
      if (currentPassword === newPassword) {
        e.preventDefault();
        return false;
      }
    }

    /* 검증 미통과 상태면 제출 차단 */
    if (!(currentPasswordValid && newPasswordValid)) {
      e.preventDefault();
      return false;
    }
  });

  /* 페이지 첫 진입 시 초기 상태(비활성 버튼) 반영 */
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
            <%-- 비밀번호 찾기 이후 진입이면 '재설정', 아니면 일반 '변경' 제목 사용 --%>
            <c:when test="${isResetFlow}">비밀번호 재설정</c:when>
            <c:otherwise>비밀번호 변경</c:otherwise>
          </c:choose>
        </h4>

        <%-- 
          비밀번호 변경/재설정 처리 서버 엔드포인트
          내부 경로는 c:url로 만든 changePwActionUrl 사용
        --%>
        <form action="${changePwActionUrl}" method="post">

          <%-- 
            로그인 상태에서의 '비밀번호 변경' 흐름일 때만 현재 비밀번호 입력칸 노출
            재설정 흐름(비밀번호 찾기 인증 완료 후)에서는 현재 비밀번호를 묻지 않음
          --%>
          <c:if test="${isLoginFlow}">
            <div class="login-input">
              <i class="fa fa-lock"></i>
              <input type="password" id="currentPassword" name="currentPassword" placeholder="현재 비밀번호">
            </div>
            <div id="currentPasswordMsg" class="msg"></div>
          </c:if>

          <%-- 새 비밀번호 입력칸 --%>
          <div class="login-input" style="margin-top: 18px;">
            <i class="fa fa-key"></i>
            <input type="password" id="newPassword" name="newPassword" placeholder="새 비밀번호">
          </div>

          <%-- 새 비밀번호 확인 입력칸 (name 없음: 서버 전송용이 아니라 클라이언트 일치 검사 용도) --%>
          <div class="login-input">
            <i class="fa fa-key"></i>
            <input type="password" id="newPasswordConfirm" placeholder="새 비밀번호 확인">
          </div>

          <%-- 새 비밀번호 형식/일치 여부 메시지 영역 --%>
          <div id="newPasswordMsg" class="msg"></div>

          <%-- 
            제출 버튼 문구도 흐름에 맞춰 분기
            - 재설정 흐름: 비밀번호 재설정
            - 로그인 변경 흐름: 비밀번호 변경
          --%>
          <button type="submit" class="btn-main" disabled>
            <c:choose>
              <c:when test="${isResetFlow}">비밀번호 재설정</c:when>
              <c:otherwise>비밀번호 변경</c:otherwise>
            </c:choose>
          </button>

          <%-- 상단에서 계산한 backUrl/backText를 사용해 흐름별 복귀 경로 제공 --%>
          <a href="${backUrl}" class="cancel-link">${backText}</a>

        </form>

      </div>
    </div>
  </div>
</section>

<%@ include file="/WEB-INF/common/footer.jsp" %>

<%-- 페이지 공통 Bootstrap JS 로드 --%>
<script src="${ctx}/js/bootstrap.min.js"></script>
</body>
</html>