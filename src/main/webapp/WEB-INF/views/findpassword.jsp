<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- 
  이 JSP가 어느 컨텍스트 경로(/, /animale 등)에서 실행되더라도
  정적 리소스(css/js/image)와 내부 링크를 안전하게 만들기 위해 contextPath를 꺼내 둔다.
  이후 ${ctx}/css/... 형태로 재사용하면 배포 경로가 바뀌어도 상대적으로 안전하다.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 
  내부 이동/요청 경로는 c:url로 미리 변수화해 둔다.
  이유:
  1) contextPath 자동 포함
  2) JSP 곳곳에 하드코딩 문자열이 흩어지는 걸 줄임
  3) 나중에 경로 바뀌면 변수 선언부만 수정하면 됨
--%>
<c:url var="loginUrl" value="/login" />
<c:url var="findPwActionUrl" value="/member/password/find" />

<c:url var="urlMemberLookup" value="/FindPasswordMemberLookup" />
<c:url var="urlSendCode" value="/FindPasswordSendCode" />
<c:url var="urlVerifyCode" value="/FindPasswordVerifyCode" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 비밀번호 재설정</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<%-- 
  정지(BAN) 계정 안내를 브라우저 기본 alert 대신 모달 UI로 보여주기 위해 SweetAlert2 사용.
  이 페이지에서는 '아이디 확인' 단계에서 정지 계정이 감지되면 바로 안내 모달을 띄운다.
--%>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<style>
/* 
  비로그인 성격의 페이지(비밀번호 재설정)이므로,
  공통 header가 include되더라도 프로필/검색 아이콘은 노출하지 않게 숨긴다.
  헤더 템플릿을 건드리지 않고 페이지 단에서만 제어하려는 의도.
*/
.icon_profile,
.icon_search,
.search-switch { display:none !important; }

/* 
  혹시 공통 헤더/템플릿에 로그아웃 관련 링크/버튼이 들어오더라도
  이 페이지에서는 사용자 경험상 불필요하므로 함께 숨긴다.
*/
#logoutBtn,
.logoutBtn,
.logout-btn,
.logout,
a[href*="logout"],
a[href$="logout"],
a[href$="/logout"] { display:none !important; }

/* 
  비밀번호 재설정 UI의 메인 카드 래퍼.
  - 가운데 정렬
  - 흰 배경 카드
  - position:relative 로 설정한 이유는
    메일 발송 로딩 오버레이(.loading-overlay)를 이 카드 위에만 덮기 위해서다.
*/
.reset-wrap {
  max-width:420px;
  margin:0 auto;
  background:#fff;
  padding:40px 30px;
  border-radius:16px;
  position: relative; /* 내부 absolute 오버레이의 기준점 */
}

/* 카드 내부 입력 공통 스타일 */
.reset-wrap input {
  width:100%;
  height:50px;
  border-radius:30px;
  padding:0 18px;
}

/* 
  입력 + 버튼을 한 줄로 묶는 공통 레이아웃.
  예: [아이디 입력][아이디 확인], [이메일][인증번호 발송]
*/
.row-inline {
  display:flex;
  gap:12px;
  align-items:center;
  margin-bottom:14px;
}
.row-inline input { flex:1; }

/* 
  보조 동작 버튼 스타일(아이디 확인, 인증번호 발송/재요청/확인 등).
  메인 제출 버튼(btn-main)과 시각적으로 구분하기 위해 outline 스타일 사용.
*/
.btn-outline {
  height:50px;
  min-width:110px;
  border-radius:30px;
  background:#fff;
  border:2px solid #e53637;
  color:#e53637;
  font-weight:600;
}
.btn-outline:disabled {
  opacity:.4;
  cursor:not-allowed;
}

/* 최종 제출 버튼(비밀번호 변경) */
.btn-main {
  width:100%;
  height:52px;
  border-radius:30px;
  background:#e53637;
  border:none;
  color:#fff;
  font-weight:600;
}
.btn-main:disabled { background:#bdbdbd; }

/* 
  입력 검증/서버 응답 메시지 공통 스타일
  success / error 클래스를 JS에서 붙였다 떼면서 색만 바꾼다.
*/
.msg { font-size:12px; margin:4px 0 12px; }
.msg.error { color:#ff4c4c; }
.msg.success { color:#4caf50; }

/* 인증번호 만료 카운트다운 표시 */
.timer { font-size:13px; color:#e53637; margin-bottom:8px; }

/* 비밀번호 입력 칸 간 간격 */
#memberPassword,
#memberPasswordConfirm { margin-top:12px; }

/* 
  기본 입력 상태 (브랜드 컬러 기반 빨강 테두리)
  이 페이지는 상태 피드백을 row 단위 클래스로 주기 때문에,
  기본값은 빨강/성공은 초록/실패는 진한 빨강으로 덮어쓴다.
*/
.row-inline input{
  border:2px solid #e53637;
  outline:none;
}
.row-inline input:focus{
  box-shadow:0 0 0 3px rgba(229,54,55,0.15);
}

/* 
  성공 상태 행:
  row-inline에 is-ok 클래스가 붙으면 해당 줄의 input/버튼을 초록색 톤으로 변경.
  사용자가 '이 단계는 완료됨'을 직관적으로 인식하도록 돕는다.
*/
.row-inline.is-ok input,
.row-inline.is-ok .btn-outline{
  border-color:#4caf50 !important;
  color:#4caf50 !important;
}
.row-inline.is-ok input:focus{
  box-shadow:0 0 0 3px rgba(76,175,80,0.15);
}

/* 
  실패 상태 행:
  잘못된 입력/오류가 난 줄을 빨강으로 강조해서 재입력을 유도.
*/
.row-inline.is-bad input,
.row-inline.is-bad .btn-outline{
  border-color:#ff4c4c !important;
  color:#ff4c4c !important;
}
.row-inline.is-bad input:focus{
  box-shadow:0 0 0 3px rgba(255,76,76,0.15);
}

/* 
  로딩 상태:
  버튼만 살짝 흐리게 해서 클릭 후 처리 중임을 보여줌.
  (완전 비활성화와는 별개로 시각적 피드백)
*/
.row-inline.is-loading .btn-outline{
  opacity:.75;
}

/* 
  메일 발송/재발송 시 카드 전체를 덮는 로딩 오버레이.
  사용자가 연속 클릭하거나 중간에 다른 입력을 건드리는 것을 줄여준다.
*/
.loading-overlay{
  position:absolute;
  inset:0;
  background:rgba(255,255,255,0.75);
  display:flex;
  align-items:center;
  justify-content:center;
  border-radius:16px;
  z-index:50;
}
.loading-card{
  display:flex;
  flex-direction:column;
  align-items:center;
  gap:10px;
  padding:18px 16px;
  border-radius:14px;
  background:#fff;
  box-shadow:0 10px 25px rgba(0,0,0,0.12);
}
.spinner{
  width:28px; height:28px;
  border:3px solid rgba(229,54,55,0.25);
  border-top-color:#e53637;
  border-radius:50%;
  animation:spin 0.8s linear infinite;
}
@keyframes spin{
  from{ transform:rotate(0deg); }
  to{ transform:rotate(360deg); }
}
.loading-text{
  font-size:13px;
  font-weight:700;
  color:#333;
}

/* 
  하단 '로그인 화면으로 이동' 링크를 버튼처럼 보이게 만든 스타일.
  실제 태그는 a 이지만 UI는 버튼처럼 보이도록 설계.
*/
.login-back {
  display:flex;
  align-items:center;
  justify-content:center;
  gap:8px;
  margin-top:18px;
  height:46px;
  border-radius:999px;
  border:1px solid rgba(0,0,0,0.10);
  background:#fafafa;
  color:#222;
  font-size:14px;
  font-weight:700;
  text-decoration:none;
  transition:transform .12s ease, box-shadow .12s ease, background .12s ease;
}
.login-back:hover{
  background:#fff;
  box-shadow:0 10px 20px rgba(0,0,0,0.08);
  transform:translateY(-1px);
  text-decoration:none;
  color:#111;
}
.login-back:active{
  transform:translateY(0);
  box-shadow:none;
}
.login-back .chev{
  font-size:16px;
  line-height:1;
  display:inline-block;
  transform:translateY(-1px);
}
.login-back .hint{
  font-weight:800;
}
</style>

<script>
$(function () {

  /*
    서버 엔드포인트를 JSP(c:url)에서 받아 JS 변수로 보관.
    하드코딩 문자열을 JS 내부에 직접 쓰지 않아서 경로 변경 시 관리가 편함.
  */
  var URL_MEMBER_LOOKUP = "${urlMemberLookup}";
  var URL_SEND_CODE     = "${urlSendCode}";
  var URL_VERIFY_CODE   = "${urlVerifyCode}";

  /*
    인증번호 재요청/만료 타이머 관련 상태값
    - resendTimer   : setInterval 핸들
    - resendLeft    : 남은 초
    - resendEnableAt: 재요청 버튼 활성 허용 시각(현재시간 + 5초)
  */
  var resendTimer  = null;
  var resendLeft   = 0;
  var resendEnableAt = 0;

  /*
    현재 인증 플로우 상태 플래그
    - idChecked : 아이디 확인 완료 여부
    - verified  : 인증번호 검증 완료 여부
  */
  var idChecked = false;
  var verified  = false;

  /*
    비밀번호 정책 정규식
    조건:
    - 영문 1개 이상
    - 숫자 1개 이상
    - 특수문자 1개 이상
    - 전체 길이 8~16자
  */
  var passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+=-]).{8,16}$/;

  /*
    페이지 최초 진입 UI 초기화
    순서 개념:
    1) 아이디 확인
    2) 인증번호 발송/확인
    3) 새 비밀번호 입력
    이 중 2,3번 영역은 처음엔 숨겨 둔다.
  */
  $("#authArea").hide();
  $("#pwArea").hide();

  /*
    이메일은 서버가 아이디 확인 후 채워주는 방식이라 직접 수정하지 못하게 readonly 처리.
    버튼들도 아직 조건 미충족이므로 전부 비활성화 상태로 시작.
  */
  $("#memberEmail").prop("readonly", true);
  $("#sendBtn").prop("disabled", true);
  $("#verifyBtn").prop("disabled", true);
  $("#resendBtn").prop("disabled", true);
  $(".btn-main").prop("disabled", true);

  /*
    메시지 출력 헬퍼
    ok=true면 success 클래스, false면 error 클래스를 붙여 색상/상태를 통일한다.
    개별 필드마다 매번 같은 코드를 쓰지 않기 위한 공통 함수.
  */
  function showMsg($el, msg, ok) {
    $el.text(msg).removeClass("error success").addClass(ok ? "success" : "error");
  }

  /* 메시지 영역 내용/클래스 초기화 */
  function clearMsg($el) {
    $el.text("").removeClass("error success");
  }

  /*
    row 단위 상태 스타일 제어 함수
    state 값:
    - "ok"      : 성공 표시
    - "bad"     : 실패 표시
    - "loading" : 처리 중 표시
    - 그 외     : 클래스 제거(기본 상태)
    
    핵심 포인트:
    CSS가 row-inline.is-ok / is-bad / is-loading 를 기준으로 동작하므로
    JS는 이 함수로만 상태를 바꿔주면 된다.
  */
  function setRowState(rowId, state) {
    var $row = $("#" + rowId);
    $row.removeClass("is-ok is-bad is-loading");
    if (state === "ok")      $row.addClass("is-ok");
    if (state === "bad")     $row.addClass("is-bad");
    if (state === "loading") $row.addClass("is-loading");
  }

  /*
    메일 발송 계열 작업은 사용자 체감상 약간 지연될 수 있어서
    카드 위에 로딩 오버레이를 띄워 중복 클릭/입력 혼선을 줄인다.
  */
  function showLoading(text) {
    $("#loadingText").text(text || "처리 중...");
    $("#loadingOverlay").show();
  }
  function hideLoading() {
    $("#loadingOverlay").hide();
  }

  /*
    정지 계정(BAN) 안내 모달
    기본 alert 대신 모달을 쓰는 이유:
    - UI 일관성
    - 문구/버튼/색상 커스터마이징 가능
    - 사용자가 더 명확하게 상황을 인지함
  */
  function showBanModal(message) {
    Swal.fire({
      icon: "error",
      title: "접근 불가",
      text: message || "영구 정지된 계정입니다. 비밀번호를 재설정할 수 없습니다.",
      confirmButtonText: "확인",
      confirmButtonColor: "#e53637",
      allowOutsideClick: false
    });
  }

  /*
    인증번호/비밀번호 관련 UI를 전체 초기화하는 함수
    언제 쓰는지:
    - 아이디 입력이 바뀌었을 때 (기존 인증 흐름 무효)
    - 아이디 재확인/인증 취소 후 다시 시작할 때
    
    왜 필요한지:
    이 페이지는 단계형 플로우라서, 앞 단계가 바뀌면 뒤 단계 상태를 꼭 정리해야
    잘못된 인증 상태(verified=true 유지 등)가 남지 않는다.
  */
  function resetAuthUI() {
    verified = false;
    $(".btn-main").prop("disabled", true);
    $("#pwArea").hide();

    /*
      이전 타이머가 남아 있으면 중복 setInterval이 생길 수 있으므로
      반드시 clearInterval 후 참조값도 null로 초기화.
    */
    clearInterval(resendTimer);
    resendTimer = null;
    resendLeft = 0;

    /* 인증 영역 자체 숨기고 입력/메시지 초기화 */
    $("#authArea").hide();
    $("#timer").text("");
    $("#verificationCode").val("");
    clearMsg($("#verificationCodeMsg"));

    /*
      인증 관련 버튼 초기 상태 복귀
      - verifyBtn: 눌러서 인증 확인하는 버튼
      - resendBtn: 재요청 버튼
    */
    $("#verifyBtn").prop("disabled", true).text("인증번호 확인");
    $("#resendBtn").prop("disabled", true);

    /* 비밀번호 입력 영역 값/메시지 초기화 */
    $("#memberPassword").val("");
    $("#memberPasswordConfirm").val("");
    clearMsg($("#memberPasswordMsg"));

    /* 이메일행/인증코드행 시각 상태도 기본으로 되돌림 */
    setRowState("rowEmail", "clear");
    setRowState("rowCode", "clear");

    /* 발송 버튼 문구를 기본값으로 */
    $("#sendBtn").text("인증번호 발송");
  }

  /*
    인증번호 만료 타이머 시작 함수
    seconds: 서버가 내려주는 유효시간(기본 180초)
    
    동작 포인트:
    1) 기존 타이머가 있으면 먼저 제거
    2) 화면에 mm:ss 형식으로 표시
    3) 재요청 버튼은 최소 5초 이후부터 허용 (너무 빠른 연타 방지)
    4) 시간이 끝나면 '만료됨' 표시 + 재요청 허용
  */
  function startTimer(seconds) {
    clearInterval(resendTimer);
    resendLeft = seconds;

    /* 재요청 버튼은 발송 직후 바로 누르지 못하게 5초 지연 */
    resendEnableAt = Date.now() + 5000;
    $("#resendBtn").prop("disabled", true);

    /* 남은 시간을 mm:ss 문자열로 렌더링 */
    var render = function() {
      var m = Math.floor(resendLeft / 60);
      var s = resendLeft % 60;
      $("#timer").text(String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0"));
    };

    render();

    resendTimer = setInterval(function () {
      resendLeft--;
      render();

      /*
        아직 인증 완료되지 않은 상태에서만 재요청 버튼 활성화 체크.
        verified=true 이후에는 재요청 자체가 필요 없으므로 막아두는 흐름과 맞춘다.
      */
      if (!verified && Date.now() >= resendEnableAt) {
        $("#resendBtn").prop("disabled", false);
      }

      /* 만료 시 타이머 종료 + 재요청 가능 상태로 전환 */
      if (resendLeft <= 0) {
        clearInterval(resendTimer);
        $("#timer").text("만료됨 (재요청 가능)");
        $("#resendBtn").prop("disabled", false);
      }
    }, 1000);
  }

  /*
    아이디 입력값 변경 이벤트
    핵심 개념:
    '아이디가 바뀌면 이전 인증 흐름은 전부 무효'
    
    예를 들어 A아이디로 인증번호 발송까지 해놓고 B아이디로 바꾸면
    기존 이메일/인증상태가 남아 있으면 보안/UX 모두 꼬일 수 있으므로 전부 초기화한다.
  */
  $("#memberName").on("input", function () {
    idChecked = false;
    verified  = false;

    $("#sendBtn").prop("disabled", true).text("인증번호 발송");
    $("#memberEmail").val("");

    clearMsg($("#memberNameMsg"));
    clearMsg($("#memberEmailMsg"));

    /*
      아이디 확인 성공 후 readonly로 잠갔던 상태를 해제.
      입력이 발생했다는 건 다시 수정 중이라는 뜻이므로 수정 가능 상태 유지.
    */
    $("#memberName").prop("readonly", false);

    setRowState("rowMember", "clear");
    resetAuthUI();
  });

  /*
    1) 아이디 확인 버튼 클릭
    서버에 memberName을 보내서
    - 요청 자체 성공 여부(success)
    - 정지 계정 여부(banned)
    - 존재 여부(exists)
    - 연결된 이메일(memberEmail)
    등을 확인한다.
  */
  $("#memberNameCheckBtn").click(function () {
    var memberName = $("#memberName").val().trim();

    /* 프론트 1차 검증: 빈값이면 서버 요청 전에 바로 안내 */
    if (!memberName) {
      showMsg($("#memberNameMsg"), "아이디를 입력해주세요.", false);
      setRowState("rowMember", "bad");
      return;
    }

    /*
      중복 클릭 방지:
      응답 오기 전까지 버튼 비활성화
      + 시각적으로 loading 상태 표시
    */
    $("#memberNameCheckBtn").prop("disabled", true);
    setRowState("rowMember", "loading");

    $.ajax({
      url: URL_MEMBER_LOOKUP,
      method: "POST",
      dataType: "json",
      data: { memberName: memberName },
      success: function (res) {
        /*
          서버 응답 기본 실패 케이스
          (예: success=false 또는 응답 구조가 기대와 다름)
        */
        if (!res || res.success !== true) {
          showMsg($("#memberNameMsg"), (res && res.message) ? res.message : "요청에 실패했습니다.", false);
          idChecked = false;
          $("#sendBtn").prop("disabled", true);
          setRowState("rowMember", "bad");
          return;
        }

        /*
          정지(BAN) 계정이면 비밀번호 재설정 흐름 자체를 진행하지 않음.
          여기서는 모달 안내 후 상태값/입력 UI를 정리해서 다음 동작을 막는다.
        */
        if (res.banned === true) {
          showBanModal(res.message);
          idChecked = false;
          $("#sendBtn").prop("disabled", true);
          $("#memberEmail").val("");
          setRowState("rowMember", "bad");

          /*
            모달에서 충분히 안내했으므로 memberNameMsg는 비워 UX를 정리.
            (필요하면 여기 남겨도 되지만 현재 코드는 모달 중심)
          */
          clearMsg($("#memberNameMsg"));
          resetAuthUI();
          return;
        }

        /* 존재하지 않는 아이디 */
        if (res.exists !== true) {
          showMsg($("#memberNameMsg"), res.message || "존재하지 않는 아이디입니다.", false);
          idChecked = false;
          $("#sendBtn").prop("disabled", true);
          $("#memberEmail").val("");
          setRowState("rowMember", "bad");
          resetAuthUI();
          return;
        }

        /*
          아이디 확인 성공 처리
          - idChecked=true로 다음 단계(인증번호 발송) 허용
          - 서버가 내려준 이메일 표시
          - 아이디는 이후 흐름 안정성을 위해 readonly 잠금
        */
        idChecked = true;
        showMsg($("#memberNameMsg"), "아이디가 확인되었습니다.", true);
        setRowState("rowMember", "ok");

        $("#memberEmail").val(res.memberEmail || "");
        clearMsg($("#memberEmailMsg"));

        $("#sendBtn").prop("disabled", false).text("인증번호 발송");
        $("#memberName").prop("readonly", true);

        /*
          혹시 이전에 이 페이지에서 진행하던 인증 흔적이 남아 있을 수 있으므로
          아이디 확인 성공 직후 인증 영역 상태를 한 번 더 초기화해 안정성 확보.
        */
        resetAuthUI();
      },
      error: function () {
        /* 네트워크/서버 오류 케이스 */
        showMsg($("#memberNameMsg"), "서버 통신 오류", false);
        idChecked = false;
        $("#sendBtn").prop("disabled", true);
        setRowState("rowMember", "bad");
      },
      complete: function () {
        /*
          성공/실패와 무관하게 버튼은 다시 누를 수 있게 복구.
          단, row 상태는 success/error에서 이미 결정됐을 수 있으므로
          둘 다 아닌 경우에만 clear로 정리.
        */
        $("#memberNameCheckBtn").prop("disabled", false);
        if (!$("#rowMember").hasClass("is-ok") && !$("#rowMember").hasClass("is-bad")) {
          setRowState("rowMember", "clear");
        }
      }
    });
  });

  /*
    2) 인증번호 발송 버튼 클릭
    전제조건:
    - 아이디 확인(idChecked)이 끝나 있어야 함
    - memberName 값이 존재해야 함
  */
  $("#sendBtn").click(function () {
    /* 아이디 확인 없이 바로 누른 경우 방지 */
    if (!idChecked) {
      showMsg($("#memberEmailMsg"), "아이디 확인을 먼저 진행해주세요.", false);
      setRowState("rowEmail", "bad");
      return;
    }

    var memberName = $("#memberName").val().trim();
    if (!memberName) {
      showMsg($("#memberNameMsg"), "아이디를 입력해주세요.", false);
      setRowState("rowMember", "bad");
      return;
    }

    /*
      발송 요청 시작 UI
      - 버튼 비활성화/문구 변경
      - 이메일행 로딩 상태
      - 카드 전체 로딩 오버레이
    */
    $("#sendBtn").prop("disabled", true).text("발송 중...");
    clearMsg($("#memberEmailMsg"));

    setRowState("rowEmail", "loading");
    showLoading("인증번호 발송 중...");

    $.ajax({
      url: URL_SEND_CODE,
      method: "POST",
      dataType: "json",
      data: { memberName: memberName },
      success: function (res) {
        /* 서버가 발송 실패를 응답한 경우 */
        if (!res || res.success !== true) {
          setRowState("rowEmail", "bad");
          $("#sendBtn").prop("disabled", false).text("인증번호 발송");
          showMsg($("#memberEmailMsg"), (res && res.message) ? res.message : "인증번호 발송 실패", false);
          return;
        }

        /*
          발송 성공 후 단계 전환
          - 이메일행 성공 표시
          - 인증 입력 영역(authArea) 노출
          - 인증 확인 버튼 활성화
          - 기존 인증코드 입력/메시지 초기화
        */
        setRowState("rowEmail", "ok");
        $("#sendBtn").prop("disabled", true).text("발송 완료");
        showMsg($("#memberEmailMsg"), "인증번호를 발송했습니다. 이메일을 확인해주세요.", true);

        $("#authArea").slideDown();
        $("#verifyBtn").prop("disabled", false).text("인증번호 확인");

        $("#verificationCode").val("");
        clearMsg($("#verificationCodeMsg"));
        setRowState("rowCode", "clear");

        /*
          발송이 새로 일어났으므로 아직 인증 완료 상태는 아님.
          비밀번호 입력 영역도 숨기고 제출 버튼 비활성화 유지.
        */
        verified = false;
        $("#pwArea").hide();
        $(".btn-main").prop("disabled", true);

        /* 서버가 유효시간을 내려주면 사용, 없으면 기본 180초 */
        var expireSeconds = res.expireSeconds || 180;
        startTimer(expireSeconds);
      },
      error: function () {
        setRowState("rowEmail", "bad");
        $("#sendBtn").prop("disabled", false).text("인증번호 발송");
        showMsg($("#memberEmailMsg"), "서버 통신 오류", false);
      },
      complete: function () {
        /*
          성공/실패와 관계없이 로딩 UI는 해제.
          rowEmail에 남아 있는 is-loading도 제거.
        */
        hideLoading();
        $("#rowEmail").removeClass("is-loading");
      }
    });
  });

  /*
    3) 인증번호 재요청 버튼 클릭
    기본 흐름은 발송과 거의 같지만,
    이미 인증 UI가 열려 있는 상태에서 '새 코드 재발급' 개념으로 동작.
  */
  $("#resendBtn").click(function () {
    if (!idChecked) return;

    var memberName = $("#memberName").val().trim();
    if (!memberName) return;

    /*
      재발송 중에는 재요청 버튼도 다시 못 누르게 잠그고,
      sendBtn 문구도 발송 중으로 맞춰 사용자에게 현재 상태를 명확히 보여준다.
    */
    $("#resendBtn").prop("disabled", true);
    $("#sendBtn").prop("disabled", true).text("발송 중...");
    setRowState("rowEmail", "loading");
    showLoading("인증번호 재발송 중...");

    /*
      새 코드를 보내는 시점이므로 이전 인증 실패/성공 메시지는 지워서
      현재 상태와 섞이지 않게 정리.
    */
    clearMsg($("#verificationCodeMsg"));

    $.ajax({
      url: URL_SEND_CODE,
      method: "POST",
      dataType: "json",
      data: { memberName: memberName },
      success: function (res) {
        if (!res || res.success !== true) {
          showMsg($("#verificationCodeMsg"), (res && res.message) ? res.message : "재요청 실패", false);
          $("#sendBtn").prop("disabled", true).text("발송 완료");
          setRowState("rowEmail", "bad");
          return;
        }

        /*
          재발송 성공
          - 인증코드 입력칸 비우기 (새 코드 입력 유도)
          - 타이머 재시작 (새 코드 기준 유효시간)
        */
        showMsg($("#verificationCodeMsg"), "인증번호를 재발송했습니다.", true);
        $("#verificationCode").val("");

        setRowState("rowEmail", "ok");
        $("#sendBtn").prop("disabled", true).text("발송 완료");

        var expireSeconds = res.expireSeconds || 180;
        startTimer(expireSeconds);
      },
      error: function () {
        showMsg($("#verificationCodeMsg"), "서버 통신 오류", false);
        setRowState("rowEmail", "bad");
      },
      complete: function () {
        hideLoading();
        $("#rowEmail").removeClass("is-loading");
      }
    });
  });

  /*
    4) 인증번호 확인 버튼 클릭
    성공하면 이 페이지의 핵심 전환점:
    - verified=true
    - 재발송/재확인 막기
    - 비밀번호 입력 영역 열기
  */
  $("#verifyBtn").click(function () {
    var code = $("#verificationCode").val().trim();

    /* 빈 입력 방지 */
    if (!code) {
      showMsg($("#verificationCodeMsg"), "인증번호를 입력해주세요.", false);
      setRowState("rowCode", "bad");
      return;
    }

    /* 확인 중 UI */
    $("#verifyBtn").prop("disabled", true).text("확인 중...");
    setRowState("rowCode", "loading");

    $.ajax({
      url: URL_VERIFY_CODE,
      method: "POST",
      dataType: "json",
      data: { code: code },
      success: function (res) {
        if (!res || res.success !== true) {
          /*
            인증 실패면 다시 입력할 수 있어야 하므로 verifyBtn을 재활성화
          */
          showMsg($("#verificationCodeMsg"), (res && res.message) ? res.message : "인증 실패", false);
          $("#verifyBtn").prop("disabled", false).text("인증번호 확인");
          setRowState("rowCode", "bad");
          return;
        }

        /*
          인증 성공
          - verified=true 설정
          - 타이머 종료 (더 이상 만료 카운트 필요 없음)
          - 재요청/재확인/재발송 관련 버튼 잠금
          - 비밀번호 입력 UI 노출
        */
        verified = true;
        clearInterval(resendTimer);

        showMsg($("#verificationCodeMsg"), "인증되었습니다.", true);
        setRowState("rowCode", "ok");

        $("#verifyBtn").text("인증 완료").prop("disabled", true);
        $("#resendBtn").prop("disabled", true);
        $("#sendBtn").prop("disabled", true).text("발송 완료");

        $("#pwArea").slideDown();
      },
      error: function () {
        showMsg($("#verificationCodeMsg"), "서버 통신 오류", false);
        $("#verifyBtn").prop("disabled", false).text("인증번호 확인");
        setRowState("rowCode", "bad");
      },
      complete: function () {
        /*
          success/error 어디로 끝나든 로딩 클래스는 제거.
          이후 상태는 ok/bad에서 다시 결정됨.
        */
        $("#rowCode").removeClass("is-loading");
      }
    });
  });

  /*
    5) 인증 취소 버튼 클릭
    의미:
    '이 인증 흐름을 버리고 처음부터 다시 할게요'
    
    그래서 단순히 인증코드만 지우는 게 아니라
    아이디/이메일/인증상태/비밀번호입력까지 전체 초기화한다.
  */
  $("#emailEditBtn").click(function () {
    idChecked = false;
    verified  = false;

    /*
      아이디를 다시 바꿀 수 있도록 readonly 해제 + 값 비움
      (이 버튼 이름이 emailEditBtn이어도 실제 동작은 전체 재시작에 가깝다)
    */
    $("#memberName").prop("readonly", false).val("");
    $("#memberEmail").val("");

    $("#sendBtn").prop("disabled", true).text("인증번호 발송");
    $("#verifyBtn").prop("disabled", true).text("인증번호 확인");
    $("#resendBtn").prop("disabled", true);

    /* 메시지 전부 정리 */
    clearMsg($("#memberNameMsg"));
    clearMsg($("#memberEmailMsg"));
    clearMsg($("#verificationCodeMsg"));
    clearMsg($("#memberPasswordMsg"));

    setRowState("rowMember", "clear");
    resetAuthUI();
  });

  /*
    6) 새 비밀번호 입력 검증 (실시간)
    동작 순서:
    1) 인증 완료 상태(verified) 아니면 검사 안 함
    2) 비밀번호 정책(정규식) 검사
    3) 비밀번호/확인값 일치 검사
    4) 둘 다 만족하면 제출 버튼 활성화
  */
  $("#memberPassword, #memberPasswordConfirm").on("input", function () {
    /*
      인증번호 검증 전에는 비밀번호를 입력해도 실제 제출 단계가 아니므로
      검증 로직을 동작시키지 않음.
    */
    if (!verified) return;

    var pw  = $("#memberPassword").val();
    var pw2 = $("#memberPasswordConfirm").val();

    /*
      먼저 정책 검사:
      형식 자체가 안 맞으면 일치 여부를 보기 전에 정책 안내를 보여주는 게 UX상 명확함.
    */
    if (!passwordRegex.test(pw)) {
      showMsg($("#memberPasswordMsg"), "8~16자, 영문/숫자/특수문자 포함", false);
      $(".btn-main").prop("disabled", true);
      return;
    }

    /*
      정책을 통과한 뒤에는 확인 입력과 일치하는지 검사.
      - 둘 다 같고
      - 확인칸 길이가 1자 이상일 때만 성공 처리
        (빈 문자열끼리 같다고 성공 처리되는 걸 방지)
    */
    if (pw === pw2 && pw2.length > 0) {
      showMsg($("#memberPasswordMsg"), "비밀번호가 일치합니다.", true);
      $(".btn-main").prop("disabled", false);
    } else {
      showMsg($("#memberPasswordMsg"), "비밀번호가 일치하지 않습니다.", false);
      $(".btn-main").prop("disabled", true);
    }
  });

});
</script>

</head>

<body>

<%@ include file="/WEB-INF/common/header.jsp" %>

<section class="login spad">
  <div class="container">

    <h3 style="text-align:center;font-weight:700;color:#fff;margin:30px 0 24px;">
      비밀번호 재설정
    </h3>

    <div class="reset-wrap">

      <%-- 
        최종 비밀번호 변경 폼
        주의:
        인증번호 확인은 AJAX로 별도 처리되고,
        여기 form submit은 '인증이 끝난 뒤 새 비밀번호 저장' 단계에서만 사용된다.
      --%>
      <form action="${findPwActionUrl}" method="post">

        <%-- 1단계: 아이디 확인 영역 --%>
        <div class="row-inline" id="rowMember">
          <input type="text" id="memberName" name="memberName" placeholder="아이디">
          <button type="button" id="memberNameCheckBtn" class="btn-outline">아이디 확인</button>
        </div>
        <div id="memberNameMsg" class="msg"></div>

        <%-- 
          2단계 준비: 이메일 표시 + 인증번호 발송 버튼
          이메일은 서버 조회 결과를 채워 보여주는 용도라 readonly로 관리됨(JS에서 설정).
        --%>
        <div class="row-inline" id="rowEmail">
          <input type="email" id="memberEmail" name="memberEmail" placeholder="이메일">
          <button type="button" id="sendBtn" class="btn-outline">인증번호 발송</button>
        </div>
        <div id="memberEmailMsg" class="msg"></div>

        <%-- 
          2단계 본체: 인증번호 입력/확인 영역
          처음에는 숨겨져 있다가 '인증번호 발송 성공' 시 slideDown으로 표시됨.
        --%>
        <div id="authArea">
          <div class="timer" id="timer"></div>

          <div class="row-inline" id="rowCode">
            <input type="text" id="verificationCode" placeholder="인증번호">
            <button type="button" id="verifyBtn" class="btn-outline">인증번호 확인</button>
          </div>
          <div id="verificationCodeMsg" class="msg"></div>

          <%-- 재발송 / 전체 인증 취소(처음부터 다시) 버튼 --%>
          <div class="row-inline">
            <button type="button" id="resendBtn" class="btn-outline">재요청</button>
            <button type="button" id="emailEditBtn" class="btn-outline">인증 취소</button>
          </div>
        </div>

        <%-- 
          3단계: 인증 완료 후 열리는 새 비밀번호 입력 영역
          인증 성공 전에는 숨겨져 있어야 순서가 꼬이지 않는다.
        --%>
        <div id="pwArea" style="display:none;">
          <input type="password" id="memberPassword" name="memberPassword" placeholder="새 비밀번호">
          <input type="password" id="memberPasswordConfirm" placeholder="새 비밀번호 확인">
          <div id="memberPasswordMsg" class="msg"></div>

          <%-- JS 실시간 검증 통과 시에만 활성화됨 --%>
          <button type="submit" class="btn-main" disabled>비밀번호 변경</button>
        </div>

        <%-- 사용자가 이 흐름을 중단하고 로그인 화면으로 돌아갈 수 있는 보조 링크 --%>
        <a href="${loginUrl}" class="login-back">
          <span class="chev">&lt;</span>
          <span class="hint">로그인 화면으로 이동</span>
        </a>

      </form>

      <%-- 
        메일 발송/재발송 요청 중 표시되는 로딩 오버레이
        reset-wrap 내부에 위치시키고 absolute로 덮어씌워 카드 영역만 가린다.
      --%>
      <div id="loadingOverlay" class="loading-overlay" style="display:none;">
        <div class="loading-card">
          <div class="spinner"></div>
          <div id="loadingText" class="loading-text">처리 중...</div>
        </div>
      </div>

    </div>
  </div>
</section>

<%@ include file="/WEB-INF/common/footer.jsp" %>

<script src="${ctx}/js/bootstrap.min.js"></script>
</body>
</html>