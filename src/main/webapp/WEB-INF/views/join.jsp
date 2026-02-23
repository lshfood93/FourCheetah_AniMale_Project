<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- 
  현재 웹 애플리케이션의 contextPath를 꺼내서 ctx 변수에 보관한다.

  왜 필요한가?
  - 로컬에서는 / (루트)로 돌릴 수도 있고
  - 배포 환경에서는 /animale 같은 컨텍스트 경로가 붙을 수 있다.
  - 정적 리소스(css/js/img), favicon 경로를 하드코딩하면 환경에 따라 깨질 수 있으므로
    ${ctx}/... 형태로 통일해서 쓰기 위해 미리 세팅한다.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 
  내부 라우팅(폼 action / 페이지 이동 / AJAX 호출 URL)은 c:url로 미리 만들어 둔다.

  미리 변수로 빼두는 이유!
  1) JS에서 문자열로 '/animale' 같은 컨텍스트를 직접 붙이지 않게 하려고
  2) 경로가 바뀌면 JSP 본문 전체를 찾지 않고 여기만 수정하면 되게 하려고
  3) 내부 경로와 외부 리소스 경로를 역할별로 분리해서 보기 쉽게 하려고
  즉, 아래 변수들은 '이 페이지가 호출하는 서버 엔드포인트 목록'이라고 보면 된다.
--%>
<c:url var="joinActionUrl" value="/join" />
<c:url var="loginUrl" value="/login" />

<c:url var="urlMemberNameCheck" value="/MemberNameCheck" />
<c:url var="urlMemberNickCheck" value="/MemberNickNameCheck" />
<c:url var="urlMemberEmailCheck" value="/MemberEmailCheck" />

<c:url var="urlSendEmailCode" value="/FindPasswordSendCode" />
<c:url var="urlVerifyEmailCode" value="/FindPasswordVerifyCode" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 회원가입</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

<style>
/* 
  회원가입 박스(카드) 영역
  - 가운데 정렬
  - 둥근 테두리
  - 그림자
  - white background로 본문 입력영역 가독성 확보
*/
.reset-wrap {
  width: 420px;
  margin: 0 auto;
  background: #fff;
  border-radius: 20px;
  padding: 36px 34px;
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.2);
}

/* 
  입력칸 + 버튼(중복확인) 한 줄 배치용 공통 레이아웃
  예: [input][중복확인]
*/
.row-inline {
  display: flex;
  gap: 10px;
  align-items: center;
  margin-bottom: 10px;
}

.row-inline input {
  flex: 1;
  height: 46px;
  border: 2px solid #222;
  border-radius: 999px;
  padding: 0 18px;
  outline: none;
  background: #eaf1ff;
}

/* 비활성화된 입력칸은 눈에 띄게 회색 처리해서 '지금 입력 불가' 상태를 사용자에게 보여줌 */
.row-inline input:disabled {
  background: #f0f0f0;
  color: #888;
  border-color: #bbb;
}

/* 중복확인/인증번호 버튼 계열 공통 스타일 */
.btn-outline {
  height: 46px;
  border-radius: 999px;
  padding: 0 18px;
  border: 2px solid #ff2c2c;
  color: #ff2c2c;
  background: #fff;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
}

/* 비활성화 버튼은 클릭 불가 + 시각적으로 흐리게 */
.btn-outline:disabled {
  border-color: #bbb;
  color: #bbb;
  cursor: not-allowed;
}

/* 입력 아래 안내/오류/성공 메시지 공통 */
.msg {
  font-size: 13px;
  margin: 4px 0 12px;
}

/* 메시지 상태별 색상 */
.msg.error { color: #ff2c2c; }
.msg.success { color: #2aa84a; }

/* 이메일 인증코드 입력칸은 일반 입력칸과 구분되게 흰 배경/옅은 테두리 */
#emailAuthArea .row-inline input {
  background: #fff;
  border-color: #bbb;
}

/* 인증 남은 시간 표시 텍스트 */
#emailAuthTimer {
  font-weight: 800;
  margin-top: 6px;
  font-size: 13px;
  color: #333;
}

/* 재요청 제한 안내 문구 (상황에 따라 JS에서 표시/숨김) */
#resendWaitMsg {
  font-size: 12px;
  color: #777;
  margin-top: 6px;
  display: none;
}

/* 비밀번호 영역은 이메일 인증 완료 전까지 숨겨둠 */
#pwArea { display: none; }

/* 최종 회원가입 버튼 (기본은 비활성 상태) */
#joinBtn {
  width: 100%;
  height: 50px;
  border-radius: 999px;
  border: none;
  background: #bbb;
  color: #fff;
  font-weight: 800;
  letter-spacing: 1px;
  cursor: not-allowed;
  margin-top: 10px;
}

/* 모든 검증이 끝나면 active 클래스로 활성 상태 시각화 */
#joinBtn.active {
  background: #444;
  cursor: pointer;
}

/* 로그인 화면으로 돌아가기 버튼 */
.back-login-btn {
  width: 100%;
  margin-top: 14px;
  padding: 12px 0;
  border-radius: 999px;
  border: 1px solid #ddd;
  background: #fff;
  color: #555;
  font-size: 14px;
  cursor: pointer;
}

.back-login-btn:hover { background: #f7f7f7; }

/* 
  로딩 오버레이
  - 중복 클릭 방지
  - AJAX 처리 중 진행중임을 사용자에게 명확히 전달
  - 화면 전체를 덮는 fixed 레이어
*/
#loadingOverlay {
  display: none;
  position: fixed;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.45);
  z-index: 9999;
}

/* 로딩 메시지 박스 중앙 배치 */
#loadingBox {
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  background: #fff;
  padding: 16px 18px;
  border-radius: 12px;
  font-weight: 700;
}
</style>
</head>

<body>

  <%@ include file="/WEB-INF/common/header.jsp"%>

  <section class="spad">
    <div class="container">

      <h3 style="text-align: center; color: #fff; margin-bottom: 24px;">회원가입</h3>

      <div class="reset-wrap">
        <%-- 
          최종 회원가입 폼 제출 대상.
          c:url로 만든 joinActionUrl을 사용해서 내부 매핑 경로를 안전하게 연결한다.
        --%>
        <form id="joinForm" action="${joinActionUrl}" method="post">

          <%-- 
            아이디 입력 영역
            - 사용자가 직접 입력
            - 바로 옆 버튼으로 중복확인 수행
            - 결과 메시지는 memberNameMsg에 출력
          --%>
          <div class="row-inline" id="rowMember">
            <input type="text" id="memberName" name="memberName" placeholder="아이디">
            <button type="button" id="memberNameCheckBtn" class="btn-outline">중복확인</button>
          </div>
          <div id="memberNameMsg" class="msg"></div>

          <%-- 
            닉네임 입력 영역
            - 형식 검증 후 중복확인 버튼으로 서버 체크
            - 결과 메시지는 memberNicknameMsg에 출력
          --%>
          <div class="row-inline" id="rowNickname">
            <input type="text" id="memberNickname" name="memberNickname" placeholder="닉네임">
            <button type="button" id="memberNicknameCheckBtn" class="btn-outline">중복확인</button>
          </div>
          <div id="memberNicknameMsg" class="msg"></div>

          <%-- 
            이메일 입력 영역
            - 먼저 형식 검사
            - 이후 '중복확인'을 통과해야 인증번호 발송 단계로 진행 가능
          --%>
          <div class="row-inline" id="rowEmail">
            <input type="email" id="memberEmail" name="memberEmail" placeholder="이메일">
            <button type="button" id="emailCheckBtn" class="btn-outline">중복확인</button>
          </div>
          <div id="memberEmailMsg" class="msg"></div>

          <%-- 
            이메일 중복확인 성공 후에만 보여주는 영역
            즉, 이메일이 사용 가능하다는 확인이 끝났을 때만 인증번호 발송 버튼 노출
          --%>
          <div class="row-inline" id="emailSendArea" style="display: none;">
            <button type="button" id="sendEmailAuthBtn" class="btn-outline" style="width: 100%;">인증번호 발송</button>
          </div>

          <%-- 
            이메일 인증 영역
            - 인증번호 발송 성공 후 열림
            - 인증코드 입력 / 인증 확인 / 재요청 / 타이머 / 안내메시지 포함
          --%>
          <div id="emailAuthArea" style="display: none; margin-top: 10px;">
            <div class="row-inline">
              <input type="text" id="emailAuthCode" placeholder="인증번호 입력" disabled>
              <button type="button" id="verifyEmailAuthBtn" class="btn-outline" disabled>인증번호 확인</button>
            </div>

            <button type="button" id="resendEmailAuthBtn" class="btn-outline" style="width: 110px;" disabled>재요청</button>

            <div id="emailAuthTimer"></div>
            <div id="resendWaitMsg"></div>
            <div id="emailAuthMsg" class="msg"></div>
          </div>

          <%-- 
            비밀번호 입력 영역
            - 이메일 인증 완료 전에는 숨김
            - 인증 완료 후에만 열어서 가입 흐름을 단계적으로 진행
            - 비밀번호 규칙 검사 + 확인 비밀번호 일치 검사 결과를 각각 메시지로 표시
          --%>
          <div id="pwArea">
            <div class="row-inline">
              <input type="password" id="memberPassword" name="memberPassword" placeholder="비밀번호">
            </div>
            <div id="memberPasswordMsg" class="msg"></div>

            <div class="row-inline">
              <input type="password" id="memberPasswordConfirm" placeholder="비밀번호 확인">
            </div>
            <div id="memberPasswordConfirmMsg" class="msg"></div>
          </div>

          <%-- 
            최종 회원가입 버튼
            - 기본 비활성화
            - JS에서 모든 조건이 충족되면 활성화
            - type=button인 이유: 검증 완료 전 자동 submit 방지 (직접 submit 제어)
          --%>
          <button type="button" id="joinBtn" disabled>회원가입</button>

          <%-- 
            로그인 화면으로 돌아가기 버튼
            내부 이동 경로도 c:url로 만든 loginUrl 사용
          --%>
          <button type="button" class="back-login-btn"
            onclick="location.href='${loginUrl}'">
            &lt; 로그인 화면으로 이동
          </button>

        </form>
      </div>
    </div>
  </section>

  <%-- 
    AJAX 처리 중 띄우는 로딩 레이어
    showLoading()/hideLoading()에서 제어
  --%>
  <div id="loadingOverlay">
    <div id="loadingBox">
      <span id="loadingText">처리 중...</span>
    </div>
  </div>

  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <script>
$(function () {

  /* =========================================================
     [서버 엔드포인트 상수화]
     
     JSP에서 c:url로 만들어둔 값을 JS 상수로 받는다.
     여기서 직접 ctx + '/xxx' 식으로 조합하지 않는 이유는:
     - 컨텍스트 경로 누락/중복 실수 방지
     - 배포 경로가 바뀌어도 JSP c:url이 알아서 맞춰줌
     - JS 로직은 '어떤 기능 호출인지'에 집중하고, 경로 조합 책임은 JSP에 맡기기 위함
     ========================================================= */
  const URL_MEMBER_NAME_CHECK = "${urlMemberNameCheck}";
  const URL_MEMBER_NICK_CHECK = "${urlMemberNickCheck}";
  const URL_MEMBER_EMAIL_CHECK = "${urlMemberEmailCheck}";
  const URL_SEND_EMAIL_CODE   = "${urlSendEmailCode}";
  const URL_VERIFY_EMAIL_CODE = "${urlVerifyEmailCode}";

  /* =========================================================
     [상태 변수]
     
     입력값 자체(value)와 별개로,
     '검증 완료 여부'를 기억하는 boolean 상태를 둔다.
     
     예를 들어 아이디 input에 글자가 있다고 해서 가입 가능 상태가 아님.
     반드시 중복확인을 통과해야 memberNameChecked=true가 된다.
     이런 식으로 최종 버튼 활성화를 정확하게 제어하기 위해 상태를 분리한다.
     ========================================================= */
  let memberNameChecked = false;      // 아이디 중복확인 통과 여부
  let memberNicknameChecked = false;  // 닉네임 중복확인 통과 여부
  let memberPasswordValid = false;    // 비밀번호 규칙 + 확인 일치 통과 여부

  let emailChecked = false;           // 이메일 중복확인 통과 여부
  let emailAuthVerified = false;      // 이메일 인증번호 확인 완료 여부

  let emailAuthTimer = null;          // setInterval 타이머 핸들
  let emailAuthRemain = 0;            // 인증 남은 시간(초)

  /* =========================================================
     [인증번호 재요청 제한 정책 상태]
     
     의도:
     - 발송 버튼/재요청 버튼 연타 방지
     - 서버 메일 발송 과부하 완화
     - 사용자 입장에서도 '왜 재요청이 안 되는지'를 안내 문구로 명확히 표시
     
     정책:
     1) 최초 발송 직후 5초는 무조건 잠금
     2) 재요청을 한 번이라도 수행하면, 그 인증번호 유효시간(기본 3분)이 끝날 때까지 잠금
     ========================================================= */
  let firstRequestLockUntil = 0; // 최초 발송 후 5초 잠금이 해제되는 시각(timestamp ms)
  let hasResentOnce = false;     // 현재 인증 사이클에서 재요청을 이미 한 번 했는지 여부

  /* =========================================================
     [클라이언트 1차 형식 검증용 정규식]
     
     주의:
     - 이 검사는 UX 개선용(빠른 피드백)이다.
     - 최종 보안/검증 책임은 서버 검증이 가져가야 한다.
     ========================================================= */
  const memberNameRegex = /^[a-zA-Z0-9]{4,12}$/;
  const memberNicknameRegex = /^[a-zA-Z0-9가-힣]{2,8}$/;
  const memberEmailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
  const memberPasswordRegex = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+=-]).{8,16}$/;

  /* =========================================================
     [공통 UI 유틸 함수]
     같은 동작을 여러 곳에서 반복하므로 함수로 분리
     ========================================================= */

  /* 
     메시지 영역에 텍스트를 넣고 상태 클래스(error/success)를 교체한다.
     - 이전 상태 클래스 제거 후 새 상태만 부여해서 스타일 꼬임 방지
  */
  function setMsg($el, msg, type) {
    $el.text(msg).removeClass("error success");
    if (type === "error") $el.addClass("error");
    if (type === "success") $el.addClass("success");
  }

  /* AJAX 처리 중 오버레이 표시 */
  function showLoading(text) {
    $("#loadingText").text(text || "처리 중...");
    $("#loadingOverlay").show();
  }

  /* AJAX 처리 종료 시 오버레이 숨김 */
  function hideLoading() {
    $("#loadingOverlay").hide();
  }

  /* 
     최종 회원가입 버튼 활성/비활성 제어.
     이 페이지의 핵심 게이트 역할을 한다.
     
     활성 조건(모두 true여야 함):
     - 아이디 중복확인 완료
     - 닉네임 중복확인 완료
     - 비밀번호 규칙 + 확인 일치 완료
     - 이메일 인증 완료
  */
  function toggleJoinBtn() {
    const ok = memberNameChecked && memberNicknameChecked && memberPasswordValid && emailAuthVerified;
    $("#joinBtn").prop("disabled", !ok).toggleClass("active", ok);
  }

  /* 
     이메일 인증 타이머 정리.
     - 새 타이머 시작 전에 기존 타이머 제거 (중복 실행 방지)
     - 화면 시간 표시 초기화
  */
  function clearEmailTimer() {
    if (emailAuthTimer) {
      clearInterval(emailAuthTimer);
      emailAuthTimer = null;
    }
    emailAuthRemain = 0;
    $("#emailAuthTimer").text("");
  }

  /* 남은 시간을 mm:ss 형식으로 렌더링 */
  function updateTimerText() {
    const min = String(Math.floor(emailAuthRemain / 60)).padStart(2, '0');
    const sec = String(emailAuthRemain % 60).padStart(2, '0');
    $("#emailAuthTimer").text(min + ":" + sec);
  }

  /* 
     재요청 가능 여부/제한 사유를 사용자에게 안내하는 문구 업데이트.
     
     분기 의도:
     - 이미 재요청 1회 사용했고 아직 유효시간 남음 => 3분 끝날 때까지 대기 안내
     - 최초 발송 후 5초 잠금 중 => 5초 대기 안내
     - 인증 전이지만 위 조건 아니면 => 정책상 유효시간 종료 후 가능 안내
     - 인증 완료 후 => 안내 문구 숨김
  */
  function updateResendInfoText() {
    if (hasResentOnce && emailAuthRemain > 0 && !emailAuthVerified) {
      $("#resendWaitMsg").text("재요청은 인증 유효시간(3분)이 끝난 후에 가능합니다.").show();
      return;
    }

    if (!hasResentOnce && !emailAuthVerified && Date.now() < firstRequestLockUntil) {
      $("#resendWaitMsg").text("재요청은 5초 후 가능합니다.").show();
      return;
    }

    if (!emailAuthVerified) {
      $("#resendWaitMsg").text("재요청은 인증 유효시간(3분)이 끝난 후에 가능합니다.").show();
    } else {
      $("#resendWaitMsg").hide();
    }
  }

  /* 
     이메일 인증 관련 UI/상태 전체 초기화 함수.

     왜 크게 초기화하나?
     - 이메일 값이 바뀌면 이전 중복확인 결과/인증번호 상태가 모두 무효가 되기 때문
     - 잘못하면 '다른 이메일로 바꿨는데 인증 완료 상태가 남아있는' 버그가 생김
     
     같이 초기화하는 항목:
     - 이메일 중복확인 상태
     - 인증 완료 상태
     - 인증 타이머
     - 재요청 정책 상태
     - 이메일 인증 영역 표시 상태
     - 비밀번호 영역(이메일 인증 이후 단계라서 함께 숨김)
  */
  function resetEmailAuthUI() {
    emailChecked = false;
    emailAuthVerified = false;
    hasResentOnce = false;
    firstRequestLockUntil = 0;

    clearEmailTimer();

    $("#emailSendArea").hide();
    $("#emailAuthArea").hide();

    $("#sendEmailAuthBtn").prop("disabled", true).removeClass("done").text("인증번호 발송");
    $("#emailAuthCode").prop("disabled", true).val("");
    $("#verifyEmailAuthBtn").prop("disabled", true).text("인증번호 확인");
    $("#resendEmailAuthBtn").prop("disabled", true).addClass("wait").text("재요청");

    $("#resendWaitMsg").hide();
    setMsg($("#emailAuthMsg"), "", "");
    setMsg($("#memberEmailMsg"), "", "");

    $("#pwArea").hide();
    memberPasswordValid = false;
    setMsg($("#memberPasswordMsg"), "", "");
    setMsg($("#memberPasswordConfirmMsg"), "", "");

    toggleJoinBtn();
  }

  /* 
     인증시간이 만료되었을 때 UI 처리.
     - 인증 완료 상태 해제
     - 입력/확인 버튼 다시 활성화 (재시도 가능)
     - 재요청 버튼 활성화
     - 사용자에게 만료 안내
  */
  function expireEmailAuth() {
    emailAuthVerified = false;
    setMsg($("#emailAuthMsg"), "인증번호가 만료되었습니다. 재요청 후 다시 입력해주세요.", "error");
    $("#emailAuthTimer").text("만료됨");

    $("#resendEmailAuthBtn").prop("disabled", false).removeClass("wait").text("재요청");
    $("#verifyEmailAuthBtn").prop("disabled", false).text("인증번호 확인");
    $("#emailAuthCode").prop("disabled", false);

    $("#resendWaitMsg").text("인증번호가 만료되었습니다. 재요청 해주세요.").show();
    toggleJoinBtn();
  }

  /* 
     이메일 인증 타이머 시작.
     - 서버가 expireSeconds를 내려주면 그 값을 사용
     - 없으면 기본 180초(3분) 사용
     - 1초마다 감소시키고 0이 되면 만료 처리 함수 호출
  */
  function startEmailTimer(seconds) {
    clearEmailTimer();

    emailAuthRemain = seconds || 180;
    updateTimerText();

    emailAuthTimer = setInterval(function () {
      emailAuthRemain--;
      updateTimerText();

      if (emailAuthRemain <= 0) {
        clearEmailTimer();
        expireEmailAuth();
      }
    }, 1000);
  }

  /* 
     페이지 진입 시 이메일 인증 관련 UI를 초기 상태로 맞춘다.
     (브라우저 캐시/뒤로가기 등으로 이전 상태가 어색하게 남는 경우 방지 목적도 있음)
  */
  resetEmailAuthUI();

  /* =========================================================
     [아이디 중복확인]
     흐름:
     1) 입력값 trim
     2) 정규식으로 형식 검사 (클라이언트 1차)
     3) 서버 중복확인 요청
     4) 결과에 따라 memberNameChecked 상태 갱신
     5) 최종 가입 버튼 활성 조건 재계산
     ========================================================= */
  $("#memberNameCheckBtn").on("click", function () {
    const memberName = $("#memberName").val().trim();

    if (!memberNameRegex.test(memberName)) {
      setMsg($("#memberNameMsg"), "4~12자 (영문/숫자)", "error");
      memberNameChecked = false;
      toggleJoinBtn();
      return;
    }

    $.ajax({
      url: URL_MEMBER_NAME_CHECK,
      type: "POST",
      dataType: "json",
      data: { memberName: memberName },
      success: function (res) {
        /* 
           서버 응답 구조가 비정상이거나 success=false면
           중복확인 실패로 간주하고 버튼 활성 조건에서 제외
        */
        if (!res || res.success === false) {
          memberNameChecked = false;
          setMsg($("#memberNameMsg"), (res && res.message) ? res.message : "중복확인 중 오류가 발생했습니다.", "error");
          toggleJoinBtn();
          return;
        }

        /* 사용 가능 여부에 따라 상태 boolean을 정확히 동기화 */
        if (res.available) {
          memberNameChecked = true;
          setMsg($("#memberNameMsg"), "사용 가능한 아이디입니다.", "success");
        } else {
          memberNameChecked = false;
          setMsg($("#memberNameMsg"), "이미 사용 중인 아이디입니다.", "error");
        }
        toggleJoinBtn();
      },
      error: function () {
        /* 통신 오류도 당연히 중복확인 미완료 상태로 처리 */
        memberNameChecked = false;
        setMsg($("#memberNameMsg"), "중복확인 중 오류가 발생했습니다.", "error");
        toggleJoinBtn();
      }
    });
  });

  /* =========================================================
     [닉네임 중복확인]
     아이디 중복확인과 동일한 패턴
     - 형식 검사 -> 서버 확인 -> 상태 반영 -> 버튼 재평가
     ========================================================= */
  $("#memberNicknameCheckBtn").on("click", function () {
    const memberNickname = $("#memberNickname").val().trim();

    if (!memberNicknameRegex.test(memberNickname)) {
      setMsg($("#memberNicknameMsg"), "2~8자 (한글/영문/숫자)", "error");
      memberNicknameChecked = false;
      toggleJoinBtn();
      return;
    }

    $.ajax({
      url: URL_MEMBER_NICK_CHECK,
      type: "POST",
      dataType: "json",
      data: { memberNickname: memberNickname },
      success: function (res) {
        if (!res || res.success === false) {
          memberNicknameChecked = false;
          setMsg($("#memberNicknameMsg"), (res && res.message) ? res.message : "중복확인 중 오류가 발생했습니다.", "error");
          toggleJoinBtn();
          return;
        }

        if (res.available) {
          memberNicknameChecked = true;
          setMsg($("#memberNicknameMsg"), "사용 가능한 닉네임입니다.", "success");
        } else {
          memberNicknameChecked = false;
          setMsg($("#memberNicknameMsg"), "이미 사용 중인 닉네임입니다.", "error");
        }
        toggleJoinBtn();
      },
      error: function () {
        memberNicknameChecked = false;
        setMsg($("#memberNicknameMsg"), "중복확인 중 오류가 발생했습니다.", "error");
        toggleJoinBtn();
      }
    });
  });

  /* =========================================================
     [이메일 입력값 변경 감지]
     
     핵심 포인트:
     이메일은 '중복확인 + 인증번호 확인'까지 연결되는 값이므로,
     입력이 바뀌는 순간 이전 검증 결과를 모두 폐기해야 한다.
     
     그래서 oninput 시점마다 resetEmailAuthUI()로 관련 상태를 싹 초기화한다.
     ========================================================= */
  $("#memberEmail").on("input", function () {
    resetEmailAuthUI();

    const value = $(this).val().trim();

    /* 
       입력 상태에 따라 사용자에게 다음 행동을 안내
       - 빈 값: 메시지 비움
       - 형식 오류: 이메일 형식부터 수정 요청
       - 형식 정상: 중복확인 먼저 하라고 안내
    */
    if (value === "") {
      setMsg($("#memberEmailMsg"), "", "");
    } else if (!memberEmailRegex.test(value)) {
      setMsg($("#memberEmailMsg"), "올바른 이메일 형식이 아닙니다.", "error");
    } else {
      setMsg($("#memberEmailMsg"), "이메일 중복확인을 진행해주세요.", "error");
    }
    toggleJoinBtn();
  });

  /* =========================================================
     [이메일 중복확인]
     흐름:
     1) 이메일 형식 검사
     2) 서버 중복확인 요청
     3) 사용 가능하면 '인증번호 발송' 버튼 영역 노출
     4) 사용 불가능하면 발송/인증 영역 숨김 유지
     ========================================================= */
  $("#emailCheckBtn").on("click", function () {
    const email = $("#memberEmail").val().trim();

    if (!memberEmailRegex.test(email)) {
      setMsg($("#memberEmailMsg"), "올바른 이메일 형식이 아닙니다.", "error");
      return;
    }

    showLoading("이메일 중복확인 중...");

    $.ajax({
      url: URL_MEMBER_EMAIL_CHECK,
      type: "POST",
      dataType: "json",
      data: { memberEmail: email },
      success: function (res) {
        if (!res || res.success === false) {
          emailChecked = false;
          setMsg($("#memberEmailMsg"), (res && res.message) ? res.message : "이메일 중복확인 중 오류가 발생했습니다.", "error");
          $("#emailSendArea").hide();
          return;
        }

        if (res.available) {
          /* 
             이메일 사용 가능:
             - 중복확인 완료 상태 저장
             - 인증번호 발송 단계 열기
             - 인증영역은 아직 발송 전이므로 숨겨둠
          */
          emailChecked = true;
          setMsg($("#memberEmailMsg"), res.message, "success");

          $("#emailSendArea").show();
          $("#sendEmailAuthBtn").prop("disabled", false).removeClass("done").text("인증번호 발송");
          $("#emailAuthArea").hide();
        } else {
          /* 이메일 사용 불가(중복 등) */
          emailChecked = false;
          setMsg($("#memberEmailMsg"), res.message, "error");
          $("#emailSendArea").hide();
          $("#emailAuthArea").hide();
        }
      },
      error: function () {
        emailChecked = false;
        setMsg($("#memberEmailMsg"), "이메일 중복검사 중 오류가 발생했습니다.", "error");
        $("#emailSendArea").hide();
        $("#emailAuthArea").hide();
      },
      complete: hideLoading
    });
  });

  /* =========================================================
     [인증번호 발송]
     
     사전 조건:
     - 이메일 중복확인 완료(emailChecked=true)
     - 이메일 형식 정상
     
     성공 시:
     - 인증 입력 영역 활성화
     - 타이머 시작
     - 재요청 정책(최초 5초 잠금) 적용
     ========================================================= */
  $("#sendEmailAuthBtn").on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    const email = $("#memberEmail").val().trim();

    if (!emailChecked) {
      setMsg($("#memberEmailMsg"), "이메일 중복확인을 먼저 진행해주세요.", "error");
      return;
    }
    if (!memberEmailRegex.test(email)) {
      setMsg($("#memberEmailMsg"), "올바른 이메일 형식이 아닙니다.", "error");
      return;
    }

    showLoading("인증번호 발송 중...");

    /* 
       발송 요청 직후 UI를 잠시 '진행중 상태'로 전환
       - 중복 클릭 방지
       - 인증영역 미리 열고 입력/확인 버튼은 비활성화 (응답 후 활성화)
    */
    $("#sendEmailAuthBtn").prop("disabled", true).removeClass("done").text("발송 중...");
    $("#emailAuthArea").show();
    $("#emailAuthCode").prop("disabled", true).val("");
    $("#verifyEmailAuthBtn").prop("disabled", true).text("인증번호 확인");
    $("#resendEmailAuthBtn").prop("disabled", true).addClass("wait").text("재요청");
    $("#resendWaitMsg").hide();
    setMsg($("#emailAuthMsg"), "", "");

    $.ajax({
      url: URL_SEND_EMAIL_CODE,
      type: "POST",
      dataType: "json",
      data: { purpose: "JOIN", memberEmail: email },
      success: function (res) {
        if (res && res.success) {
          /* 
             발송 성공:
             - 발송 버튼을 완료 상태로 고정
             - 인증코드 입력/확인 버튼 활성화
             - 최초 발송 후 5초 잠금 정책 시작
             - 서버 제공 만료시간으로 타이머 시작
          */
          $("#sendEmailAuthBtn").prop("disabled", true).addClass("done").text("발송 완료");

          $("#emailAuthCode").prop("disabled", false).val("").focus();
          $("#verifyEmailAuthBtn").prop("disabled", false).text("인증번호 확인");

          firstRequestLockUntil = Date.now() + 5000;
          hasResentOnce = false;

          const expireSeconds = (res.expireSeconds) ? res.expireSeconds : 180;
          startEmailTimer(expireSeconds);

          $("#resendEmailAuthBtn").prop("disabled", true).addClass("wait").text("재요청");
          updateResendInfoText();

          setMsg($("#emailAuthMsg"), "인증번호가 발송되었습니다. 이메일을 확인해주세요.", "success");

          /* 
             5초 잠금 해제 시점 이후 재요청 버튼 활성화 시도
             (단, 이미 인증 완료했거나 / 이미 재요청했고 / 만료되었으면 그대로 유지)
          */
          setTimeout(function () {
            if (!emailAuthVerified && !hasResentOnce && emailAuthRemain > 0) {
              $("#resendEmailAuthBtn").prop("disabled", false).removeClass("wait").text("재요청");
            }
            updateResendInfoText();
          }, 5000);
        } else {
          /* 발송 실패 시 발송 버튼 원복 */
          $("#sendEmailAuthBtn").prop("disabled", false).removeClass("done").text("인증번호 발송");
          setMsg($("#emailAuthMsg"), (res && res.message) ? res.message : "인증번호 발송에 실패했습니다.", "error");
        }
      },
      error: function () {
        $("#sendEmailAuthBtn").prop("disabled", false).removeClass("done").text("인증번호 발송");
        setMsg($("#emailAuthMsg"), "인증번호 발송 중 오류가 발생했습니다.", "error");
      },
      complete: hideLoading
    });
  });

  /* =========================================================
     [인증번호 재요청]
     
     재요청 가능 조건:
     - 아직 인증 완료가 아니어야 함
     - 최초 5초 잠금이 끝났어야 함 (첫 발송 직후)
     - 이미 재요청했다면 현재 인증 유효시간이 종료된 이후여야 함
     
     성공 시:
     - 새 인증번호 기준으로 타이머 재시작
     - 이번 인증 사이클에서는 재요청 버튼 다시 잠금
     ========================================================= */
  $("#resendEmailAuthBtn").on("click", function () {
    if (emailAuthVerified) return;

    if (!hasResentOnce && Date.now() < firstRequestLockUntil) {
      updateResendInfoText();
      return;
    }

    if (hasResentOnce && emailAuthRemain > 0) {
      updateResendInfoText();
      return;
    }

    const email = $("#memberEmail").val().trim();
    if (!memberEmailRegex.test(email)) {
      setMsg($("#memberEmailMsg"), "올바른 이메일 형식이 아닙니다.", "error");
      return;
    }

    /* 
       재요청 시도 시작 시점에 먼저 true로 올려 정책 반영.
       실패하면 아래 error/success 분기에서 다시 false로 되돌리는 흐름이 있다.
    */
    hasResentOnce = true;
    updateResendInfoText();

    showLoading("인증번호 재발송 중...");

    $("#resendEmailAuthBtn").prop("disabled", true).addClass("wait").text("재요청 중...");
    $("#verifyEmailAuthBtn").prop("disabled", true).text("인증번호 확인");
    $("#emailAuthCode").prop("disabled", true);

    $.ajax({
      url: URL_SEND_EMAIL_CODE,
      type: "POST",
      dataType: "json",
      data: { purpose: "JOIN", memberEmail: email },
      success: function (res) {
        if (res && res.success) {
          /* 
             재발송 성공:
             - 사용자는 새 인증번호를 입력해야 하므로 입력칸 초기화/포커스
             - 새 만료시간으로 타이머 재시작
             - 정책상 재요청 버튼은 다시 잠금 유지
          */
          setMsg($("#emailAuthMsg"), "인증번호를 재발송했습니다. 새 인증번호를 입력해주세요.", "success");

          $("#emailAuthCode").prop("disabled", false).val("").focus();
          $("#verifyEmailAuthBtn").prop("disabled", false).text("인증번호 확인");

          const expireSeconds = (res.expireSeconds) ? res.expireSeconds : 180;
          startEmailTimer(expireSeconds);

          $("#resendEmailAuthBtn").prop("disabled", true).addClass("wait").text("재요청");
          updateResendInfoText();
        } else {
          /* 재발송 실패 시 정책 상태/버튼 상태 일부 원복 */
          hasResentOnce = false;

          $("#resendEmailAuthBtn").prop("disabled", false).removeClass("wait").text("재요청");
          $("#verifyEmailAuthBtn").prop("disabled", false).text("인증번호 확인");
          $("#emailAuthCode").prop("disabled", false);

          setMsg($("#emailAuthMsg"), (res && res.message) ? res.message : "재요청에 실패했습니다.", "error");
          updateResendInfoText();
        }
      },
      error: function () {
        hasResentOnce = false;

        $("#resendEmailAuthBtn").prop("disabled", false).removeClass("wait").text("재요청");
        $("#verifyEmailAuthBtn").prop("disabled", false).text("인증번호 확인");
        $("#emailAuthCode").prop("disabled", false);

        setMsg($("#emailAuthMsg"), "인증번호 재발송 중 오류가 발생했습니다.", "error");
        updateResendInfoText();
      },
      complete: hideLoading
    });
  });

  /* =========================================================
     [인증번호 확인]
     
     성공 시:
     - emailAuthVerified=true
     - 타이머 종료
     - 인증 입력/버튼 잠금
     - 비밀번호 입력 영역 노출
     - 최종 가입 버튼 활성 조건 재계산
     ========================================================= */
  $("#verifyEmailAuthBtn").on("click", function () {
    const code = $("#emailAuthCode").val().trim();
    if (!code) {
      setMsg($("#emailAuthMsg"), "인증번호를 입력해주세요.", "error");
      return;
    }

    showLoading("인증번호 확인 중...");

    /* 중복 클릭 방지 + 진행 상태 표시 */
    $("#verifyEmailAuthBtn").prop("disabled", true).text("확인 중...");

    $.ajax({
      url: URL_VERIFY_EMAIL_CODE,
      type: "POST",
      dataType: "json",
      data: { purpose: "JOIN", code: code },
      success: function (res) {
        if (res && res.success) {
          emailAuthVerified = true;

          /* 이메일 영역/인증 영역 둘 다 완료 메시지를 보여서 사용자가 상태를 확실히 인지하게 함 */
          setMsg($("#memberEmailMsg"), "이메일 인증이 완료되었습니다.", "success");
          setMsg($("#emailAuthMsg"), "이메일 인증이 완료되었습니다.", "success");

          /* 인증이 끝났으므로 타이머 정지 */
          clearEmailTimer();

          /* 인증 관련 UI는 완료 상태로 고정 */
          $("#emailAuthCode").prop("disabled", true);
          $("#verifyEmailAuthBtn").prop("disabled", true).text("인증 완료");
          $("#resendEmailAuthBtn").prop("disabled", true).addClass("wait").text("재요청");
          $("#sendEmailAuthBtn").prop("disabled", true).addClass("done").text("발송 완료");
          $("#resendWaitMsg").hide();

          /* 다음 단계(비밀번호 입력) 오픈 */
          $("#pwArea").slideDown();
        } else {
          /* 인증 실패 시 다시 입력/확인 가능하게 복구 */
          $("#verifyEmailAuthBtn").prop("disabled", false).text("인증번호 확인");
          setMsg($("#emailAuthMsg"), (res && res.message) ? res.message : "인증번호가 올바르지 않습니다.", "error");
        }
        toggleJoinBtn();
      },
      error: function () {
        $("#verifyEmailAuthBtn").prop("disabled", false).text("인증번호 확인");
        setMsg($("#emailAuthMsg"), "인증번호 확인 중 오류가 발생했습니다.", "error");
        toggleJoinBtn();
      },
      complete: hideLoading
    });
  });

  /* =========================================================
     [비밀번호 유효성 검사 + 확인 일치 검사]
     
     이 함수 하나에서 두 입력칸 상태를 같이 판단한다.
     이유:
     - 비밀번호 규칙 통과 여부
     - 확인 비밀번호 일치 여부
     둘이 결합되어야 최종 회원가입 가능 상태를 계산할 수 있기 때문
     ========================================================= */
  function validatePassword() {
    const pw = $("#memberPassword").val().trim();
    const pw2 = $("#memberPasswordConfirm").val().trim();

    /* 1) 먼저 비밀번호 규칙 검사 */
    if (!memberPasswordRegex.test(pw)) {
      memberPasswordValid = false;
      setMsg($("#memberPasswordMsg"), "8~16자 / 영문+숫자+특수문자 포함", "error");

      /* 
         규칙 자체가 안 맞으면 확인 비밀번호 일치 여부는 의미가 약하므로
         확인 메시지는 비워서 UX를 단순하게 유지
      */
      setMsg($("#memberPasswordConfirmMsg"), "", "");
      toggleJoinBtn();
      return;
    }

    setMsg($("#memberPasswordMsg"), "사용 가능한 비밀번호입니다.", "success");

    /* 2) 확인 비밀번호를 입력한 상태에서 불일치하면 실패 */
    if (pw2.length > 0 && pw !== pw2) {
      memberPasswordValid = false;
      setMsg($("#memberPasswordConfirmMsg"), "비밀번호가 일치하지 않습니다.", "error");
      toggleJoinBtn();
      return;
    }

    /* 3) 확인 비밀번호까지 입력했고 일치하면 최종 통과 */
    if (pw2.length > 0 && pw === pw2) {
      memberPasswordValid = true;
      setMsg($("#memberPasswordConfirmMsg"), "비밀번호가 일치합니다.", "success");
    } else {
      /* 확인 비밀번호를 아직 안 쓴 상태면 완료 처리하지 않음 */
      memberPasswordValid = false;
      setMsg($("#memberPasswordConfirmMsg"), "", "");
    }

    toggleJoinBtn();
  }

  /* 
     두 입력칸 중 어느 하나가 바뀌어도 다시 전체 판정
     (규칙/일치 여부가 서로 영향 주기 때문)
  */
  $("#memberPassword").on("input", validatePassword);
  $("#memberPasswordConfirm").on("input", validatePassword);

  /* =========================================================
     [최종 회원가입 버튼]
     
     버튼이 활성화된 경우에만 폼 submit.
     혹시 UI 상에서 disabled가 유지 중이면 방어적으로 return 처리.
     ========================================================= */
  $("#joinBtn").on("click", function () {
    if ($(this).prop("disabled")) return;
    $("#joinForm").submit();
  });

});
  </script>

</body>
</html>