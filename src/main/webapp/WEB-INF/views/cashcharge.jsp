<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<%-- 
  공통 contextPath 추출.
  이 페이지는 정적 리소스(css/js/img), 내부 form action, JS에서 사용하는 콜백 URL까지
  경로가 많기 때문에 ${ctx} 기준으로 통일해두면 배포 경로 변경(/animale 등)에도 안전하다.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 
  카카오페이 결제 준비(ready) 요청 URL.
  form submit action에서 사용한다.
  c:url을 쓰면 contextPath 포함/URL 생성 규칙을 JSP 한 곳에서 관리하기 쉽다.
--%>
<c:url var="kakaoReadyUrl" value="/payment/kakaopay/ready" />

<%-- 충전 취소 시 돌아갈 마이페이지 URL --%>
<c:url var="mypageUrl" value="/member/mypage" />

<%-- 
  Toss 결제 승인/실패 콜백 URL (서버 컨트롤러에 이미 구현된 엔드포인트)
  실제 requestPayment 호출 시 successUrl / failUrl로 조합해서 사용.
--%>
<c:url var="tossSuccessUrl" value="/payment/toss/success" />
<c:url var="tossFailUrl" value="/payment/toss/fail" />

<%-- 
  Toss 결제 직전 서버에서 orderId를 발급받는 prepare API.
  프론트가 임의 orderId를 만들지 않고 서버 기준으로 주문 식별값을 받는 구조.
--%>
<c:url var="tossPrepareUrl" value="/payment/toss/prepare" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 캐시 충전</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* 
  충전 카드 전체 박스
  공통 테마(다크톤)에 맞춰 배경색/라운드/패딩 설정
*/
.charge-box { background:#0b0c2a; border-radius:12px; padding:40px; }

/* 카드 제목 */
.charge-title { font-size:22px; font-weight:700; color:#fff; margin-bottom:30px; }

/* 금액 선택 버튼 행 */
.charge-amounts { display:flex; gap:15px; margin-bottom:30px; }

/* 금액 버튼 기본 상태 */
.charge-amounts button { 
  flex:1; 
  background:#1c1d4a; 
  border:none; 
  border-radius:30px; 
  padding:14px 0; 
  color:#fff; 
  font-weight:600; 
  cursor:pointer; 
}

/* 선택된 금액 버튼 상태(활성 표시) */
.charge-amounts button.active { background:#e53637; }

/* 현재 선택 금액 표시 영역 */
.selected-amount { background:#fff; border-radius:30px; padding:14px 20px; font-weight:600; margin-bottom:30px; }

/* 결제/취소 버튼 래퍼 (반응형 줄바꿈 가능) */
.charge-btn-wrap { display:flex; gap:14px; margin-top:24px; flex-wrap: wrap; }

/* 카카오페이 버튼 */
.btn-pay{
  flex:1;
  min-width: 200px;
  height:56px;
  background:#FEE500;
  color:#000;
  border:none;
  border-radius:28px;
  font-size:16px;
  font-weight:700;
  cursor:pointer;
}
.btn-pay:hover{
  background:#FFD500;
}

/* 토스 버튼 */
.btn-toss { 
  flex:1; 
  min-width: 200px; 
  height:56px; 
  background:#2f80ed; 
  color:#fff; 
  border:none; 
  border-radius:28px; 
  font-size:16px; 
  font-weight:600; 
  cursor:pointer; 
}
.btn-toss:hover { background:#1c6dd5; }

/* 결제 버튼 비활성 상태 */
.btn-pay:disabled, .btn-toss:disabled { opacity:0.45; cursor:not-allowed; }

/* 취소 버튼 (별도 스타일) */
.btn-cancel { 
  width:100%; 
  height:56px; 
  background:#2a2a4a; 
  color:#fff; 
  border:1px solid #444; 
  border-radius:28px; 
  font-size:16px; 
  cursor:pointer; 
  margin-top: 10px; 
}
.btn-cancel:hover { background:#3a3a6a; }

/* 이 페이지에서는 헤더 검색 아이콘 숨김 */
.header__right__icons .icon_search { display:none; }
</style>
</head>

<body class="cash-charge-page">

<%@ include file="/WEB-INF/common/header.jsp"%>

<%-- 
  상단 브레드크럼/타이틀 영역
  data-setbg는 공통 main.js에서 배경 이미지로 치환하는 패턴을 사용하는 구조.
--%>
<section class="normal-breadcrumb set-bg" data-setbg="${ctx}/img/normal-breadcrumb.jpg">
  <div class="container">
    <div class="row">
      <div class="col-lg-12 text-center">
        <div class="normal__breadcrumb__text">
          <h2>캐시 충전</h2>
          <p>원하는 결제 수단으로 간편하게 충전하세요.</p>
        </div>
      </div>
    </div>
  </div>
</section>

<%-- 본문 충전 UI 영역 --%>
<section class="spad">
  <div class="container">
    <div class="row justify-content-center">
      <div class="col-lg-6">

        <div class="charge-box">
          <div class="charge-title">충전 금액 선택</div>

          <%-- 
            금액 선택 버튼들
            data-amount에 실제 결제 금액(숫자)을 넣고,
            JS에서 클릭 시 hidden input / 표시 텍스트를 동기화한다.
          --%>
          <div class="charge-amounts">
            <button type="button" data-amount="1000">1,000원</button>
            <button type="button" data-amount="5000">5,000원</button>
            <button type="button" data-amount="10000">10,000원</button>
            <button type="button" data-amount="50000">50,000원</button>
          </div>

          <%-- 사용자에게 현재 선택 상태를 보여주는 표시 영역 --%>
          <div class="selected-amount">
            선택 금액 : <span id="selectedAmountText">0</span> 원
          </div>

          <%-- 
            카카오페이용 기본 폼
            - 카카오는 form submit으로 ready API로 보냄
            - 토스는 같은 화면에서 JS 버튼 클릭으로 별도 흐름 진행
            따라서 hidden input(selectCash)을 두 결제수단이 공통으로 사용한다.
          --%>
          <form id="chargeForm" action="${kakaoReadyUrl}" method="post">
            <%-- 선택 금액 저장용 hidden input (카카오 submit / 토스 클릭 둘 다 참조) --%>
            <input type="hidden" name="selectCash" id="amountInput">

            <div class="charge-btn-wrap">
              <%-- 금액 선택 전에는 비활성, 금액 선택 후 활성 --%>
              <button id="kakaoBtn" type="submit" class="btn-pay" disabled>카카오페이로 결제하기</button>

              <%-- 토스는 JS requestPayment 진입 버튼 --%>
              <button id="tossBtn" type="button" class="btn-toss" disabled>토스로 결제하기</button>

              <%-- 
                충전 취소 버튼
                현재 페이지에서 별도 폼 submit 없이 마이페이지로 이동.
                (onclick location.href 사용)
              --%>
              <button id="cancelBtn" type="button" class="btn-cancel" onclick="location.href='${mypageUrl}'">충전 취소</button>
            </div>
          </form>

          <%-- 보조 안내 문구 --%>
          <p style="margin-top:12px; color:#b7b7b7; font-size:12px;">
            ※ 결제 수단을 선택하면 결제가 진행됩니다.
          </p>

        </div>

      </div>
    </div>
  </div>
</section>

<%@ include file="/WEB-INF/common/footer.jsp"%>

<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
<script src="https://js.tosspayments.com/v1"></script>

<script>
$(function() {

  /*
    토스 클라이언트 키를 서버 설정(application.properties/yml의 toss.clientKey)에서 읽어옴.
    spring:eval을 사용해 Environment 프로퍼티를 JSP 시점에 문자열로 주입.
    
    주의:
    값이 비어 있거나 잘못되면 requestPayment 진입 전 프론트에서 차단(alert)한다.
  */
  const clientKey = "<spring:eval expression='@environment.getProperty(\"toss.clientKey\")'/>";

  /* ===== 금액 초기화 (토스 취소 / 뒤로가기 / 에러 공통 사용) ===== */
  /*
    resetAmount()
    역할:
    1) 금액 버튼 active 해제
    2) hidden input 비움
    3) 화면 표시 금액 0으로 복원
    4) 결제 버튼 비활성화
    5) 취소 버튼은 다시 활성화
    
    왜 필요한가?
    - 토스 결제창을 닫거나
    - 에러가 발생했거나
    - 뒤로가기(bfcache)로 복원된 상태에서 버튼 잠금 상태가 남아있을 때
    화면을 "처음 진입 상태"로 되돌리기 위해 공통 함수로 사용.
  */
  function resetAmount() {
    $(".charge-amounts button").removeClass("active");
    $("#amountInput").val("");
    $("#selectedAmountText").text("0");
    $("#kakaoBtn").prop("disabled", true);
    $("#tossBtn").prop("disabled", true);
    $("#cancelBtn").prop("disabled", false);
  }

  /*
    결제 버튼 2개(카카오/토스)만 on/off 제어하는 함수.
    금액이 선택된 경우에만 활성화시키려는 목적.
  */
  function setPayEnabled(enabled) {
    $("#kakaoBtn").prop("disabled", !enabled);
    $("#tossBtn").prop("disabled", !enabled);
  }

  /*
    결제 진행 중 중복 클릭 방지용 잠금 함수.
    카카오 submit 직전 / 토스 준비 요청~결제창 호출 시점에서 사용한다.
    
    lock=true  -> 버튼 잠금
    lock=false -> 잠금 해제 (이 코드는 현재 직접 호출은 없고 resetAmount로 복구)
  */
  function lockButtons(lock) {
    $("#kakaoBtn").prop("disabled", lock);
    $("#tossBtn").prop("disabled", lock);
    $("#cancelBtn").prop("disabled", lock);
  }

  /* 초기 진입 시 결제 버튼은 비활성 상태 유지 (금액 미선택 상태) */
  setPayEnabled(false);

  /* ===== 금액 선택 ===== */
  /*
    금액 버튼 클릭 흐름
    - 같은 버튼 재클릭 시 선택 해제(toggle off)
    - 다른 버튼 클릭 시 기존 active 제거 후 새 버튼 활성화
    - 선택 금액(hidden + 화면 텍스트) 동기화
    - 결제 버튼 활성화
  */
  $(".charge-amounts button").click(function() {
    if ($(this).hasClass("active")) {
      /* 이미 선택된 버튼 다시 클릭 → 해제 */
      $(this).removeClass("active");
      $("#amountInput").val("");
      $("#selectedAmountText").text("0");
      setPayEnabled(false);
      return;
    }

    /* 다른 금액 선택: 단일 선택 유지 */
    $(".charge-amounts button").removeClass("active");
    $(this).addClass("active");

    const amount = $(this).data("amount");

    /* 
      hidden input에는 실제 전송값(숫자),
      화면 텍스트에는 천 단위 콤마 포맷으로 표시
    */
    $("#amountInput").val(amount);
    $("#selectedAmountText").text(amount.toLocaleString());

    /* 금액이 선택되었으므로 결제 버튼 활성화 */
    setPayEnabled(true);
  });

  /* ===== 카카오페이 폼 submit ===== */
  /*
    카카오는 form submit 기반이므로 submit 직전에 최종 검증 수행.
    (사용자가 개발자도구 등으로 상태를 바꿨을 가능성까지 최소한 방어)
  */
  $("#chargeForm").on("submit", function(e) {
    const v = $("#amountInput").val();

    if (!v || parseInt(v, 10) <= 0) {
      alert("충전 금액을 선택해주세요.");
      setPayEnabled(false);
      e.preventDefault();
      return;
    }

    /*
      유효한 금액이면 중복 submit/중복 클릭 방지를 위해 버튼 잠금.
      이후 서버 ready 응답 후 페이지 이동되는 흐름을 기대.
    */
    lockButtons(true);
  });

  /* ===== 토스 결제 버튼 클릭 ===== */
  /*
    토스 결제 흐름(프론트 기준):
    1) 금액 검증
    2) clientKey 검증
    3) 버튼 잠금
    4) 서버 prepare API 호출 -> orderId 발급
    5) TossPayments(clientKey).requestPayment(...)
    6) 사용자가 결제창 닫으면 catch -> 금액 초기화
  */
  $("#tossBtn").on("click", function() {
    const amountStr = $("#amountInput").val();
    const amount = parseInt(amountStr, 10);

    /* 금액 미선택/비정상 금액 방어 */
    if (!amount || amount <= 0) {
      alert("충전 금액을 선택해주세요.");
      return;
    }

    /* 클라이언트 키 미설정 방어 (운영/개발 설정 누락 시 빠르게 원인 파악 가능) */
    if (!clientKey || clientKey.trim().length < 5) {
      alert("토스 클라이언트 키가 설정되지 않았습니다. (toss.clientKey)");
      return;
    }

    /* 중복 클릭 방지 */
    lockButtons(true);

    /* 1) 서버에서 orderId 발급 */
    $.ajax({
      url: "${ctx}${tossPrepareUrl}",
      type: "POST",
      dataType: "json",
      data: { amount: amount },

      success: function(res) {
        /*
          prepare API 응답에서 orderId 추출.
          서버가 정상 응답했더라도 구조가 틀리면 결제 진행 중단.
        */
        const orderId = res && res.orderId ? res.orderId : null;

        if (!orderId) {
          alert("토스 결제 준비 응답이 올바르지 않습니다.(orderId 없음)");
          resetAmount();
          return;
        }

        /*
          Toss 결제 완료/실패 후 리다이렉트될 절대 URL 구성.
          requestPayment의 successUrl/failUrl은 절대 URL 형태가 필요하므로
          window.location.origin + (ctx 포함 경로) 형태로 조합.
        */
        const successUrl = window.location.origin + "${ctx}${tossSuccessUrl}";
        const failUrl    = window.location.origin + "${ctx}${tossFailUrl}";

        /* 토스 SDK 인스턴스 생성 */
        const tossPayments = TossPayments(clientKey);

        /* 2) 결제 요청 - 취소(X) 시 catch로 넘어옴 */
        tossPayments.requestPayment("토스페이", {
          amount: amount,
          orderId: orderId,
          orderName: "캐시 충전 " + amount.toLocaleString() + "원",
          successUrl: successUrl,
          failUrl: failUrl
        }).catch(function(err) {
          /*
            사용자가 결제창 X 눌러서 취소한 경우 등
            requestPayment Promise reject 시 여기로 들어온다.
            
            현재 정책:
            - 에러 상세 분기 없이 화면 상태 초기화(resetAmount)
            - 사용자가 다시 금액을 선택해서 재시도하도록 유도
          */
          resetAmount();
        });
      },

      error: function(xhr) {
        /*
          prepare API 자체 실패 (서버 오류/응답 오류/통신 문제)
          responseText가 있으면 사용자/개발자 확인용으로 메시지에 덧붙임
        */
        let msg = "토스 결제 준비 실패";
        try {
          if (xhr.responseText) msg += ": " + xhr.responseText;
        } catch(e) {}

        alert(msg);
        resetAmount();
      }
    });
  });

  /* ===== 뒤로가기(bfcache) 복원 시 초기화 ===== */
  /*
    브라우저 뒤로가기 복원 이슈 대응 (특히 bfcache)
    
    상황:
    - 카카오 결제 페이지로 이동 직전에 lockButtons(true) 됨
    - 사용자가 뒤로가기 하면 브라우저가 이전 페이지 DOM 상태를 그대로 복원할 수 있음
    - 그 결과 cancelBtn / 결제 버튼이 disabled 상태로 남는 문제가 생김
    
    대응:
    - pageshow 이벤트 + e.persisted === true 인 경우
      브라우저 캐시 복원으로 판단하고 resetAmount()로 초기화
  */
  window.addEventListener("pageshow", function(e) {
    if (e.persisted) {
      resetAmount();
    }
  });

});
</script>
</body>
</html>