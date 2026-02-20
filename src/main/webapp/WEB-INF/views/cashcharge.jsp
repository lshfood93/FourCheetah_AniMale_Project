<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<c:url var="kakaoReadyUrl" value="/payment/kakaopay/ready" />
<c:url var="mypageUrl" value="/member/mypage" />

<%-- Toss 콜백 URL (컨트롤러에 이미 존재) --%>
<c:url var="tossSuccessUrl" value="/payment/toss/success" />
<c:url var="tossFailUrl" value="/payment/toss/fail" />

<%-- ✅ 서버에서 orderId 발급받는 준비(prepare) API (추가 필요) --%>
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
.charge-box { background:#0b0c2a; border-radius:12px; padding:40px; }
.charge-title { font-size:22px; font-weight:700; color:#fff; margin-bottom:30px; }

.charge-amounts { display:flex; gap:15px; margin-bottom:30px; }
.charge-amounts button { flex:1; background:#1c1d4a; border:none; border-radius:30px; padding:14px 0; color:#fff; font-weight:600; cursor:pointer; }
.charge-amounts button.active { background:#e53637; }

.selected-amount { background:#fff; border-radius:30px; padding:14px 20px; font-weight:600; margin-bottom:30px; }

.charge-btn-wrap { display:flex; gap:14px; margin-top:24px; flex-wrap: wrap; }

/* 카카오 버튼 */
.btn-pay{
  flex:1;
  min-width: 200px;
  height:56px;
  background:#FEE500;          /* 카카오 노랑 */
  color:#000;                  /* 검정 글씨 */
  border:none;
  border-radius:28px;
  font-size:16px;
  font-weight:700;
  cursor:pointer;
}
.btn-pay:hover{
  background:#FFD500;          /* 살짝 진한 노랑 */
}

/* 토스 버튼 */
.btn-toss { flex:1; min-width: 200px; height:56px; background:#2f80ed; color:#fff; border:none; border-radius:28px; font-size:16px; font-weight:600; cursor:pointer; }
.btn-toss:hover { background:#1c6dd5; }

.btn-pay:disabled, .btn-toss:disabled { opacity:0.45; cursor:not-allowed; }

.btn-cancel { width:100%; height:56px; background:#2a2a4a; color:#fff; border:1px solid #444; border-radius:28px; font-size:16px; cursor:pointer; margin-top: 10px; }
.btn-cancel:hover { background:#3a3a6a; }

.header__right__icons .icon_search { display:none; }
</style>
</head>

<body class="cash-charge-page">

<%@ include file="/WEB-INF/common/header.jsp"%>

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

<section class="spad">
  <div class="container">
    <div class="row justify-content-center">
      <div class="col-lg-6">

        <div class="charge-box">
          <div class="charge-title">충전 금액 선택</div>

          <div class="charge-amounts">
            <button type="button" data-amount="1000">1,000원</button>
            <button type="button" data-amount="5000">5,000원</button>
            <button type="button" data-amount="10000">10,000원</button>
            <button type="button" data-amount="50000">50,000원</button>
          </div>

          <div class="selected-amount">
            선택 금액 : <span id="selectedAmountText">0</span> 원
          </div>

          <form id="chargeForm" action="${kakaoReadyUrl}" method="post">
            <input type="hidden" name="selectCash" id="amountInput">

            <div class="charge-btn-wrap">
              <button id="kakaoBtn" type="submit" class="btn-pay" disabled>카카오페이로 결제하기</button>
              <button id="tossBtn" type="button" class="btn-toss" disabled>토스로 결제하기</button>
              <button id="cancelBtn" type="button" class="btn-cancel" onclick="location.href='${mypageUrl}'">충전 취소</button>
            </div>
          </form>

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

  const clientKey = "<spring:eval expression='@environment.getProperty(\"toss.clientKey\")'/>";

  function setPayEnabled(enabled) {
    $("#kakaoBtn").prop("disabled", !enabled);
    $("#tossBtn").prop("disabled", !enabled);
  }

  function lockButtons(lock) {
    // 결제 중 중복 클릭 방지용
    $("#kakaoBtn").prop("disabled", lock);
    $("#tossBtn").prop("disabled", lock);
    $("#cancelBtn").prop("disabled", lock);
  }

  setPayEnabled(false);

  $(".charge-amounts button").click(function() {
    if ($(this).hasClass("active")) {
      $(this).removeClass("active");
      $("#amountInput").val("");
      $("#selectedAmountText").text("0");
      setPayEnabled(false);
      return;
    }

    $(".charge-amounts button").removeClass("active");
    $(this).addClass("active");

    const amount = $(this).data("amount");
    $("#amountInput").val(amount);
    $("#selectedAmountText").text(amount.toLocaleString());
    setPayEnabled(true);
  });

  $("#chargeForm").on("submit", function(e) {
    const v = $("#amountInput").val();
    if (!v || parseInt(v, 10) <= 0) {
      alert("충전 금액을 선택해주세요.");
      setPayEnabled(false);
      e.preventDefault();
      return;
    }
    // 카카오 결제 진행 중 잠금 (선택)
    lockButtons(true);
  });

  // =========================
  // ✅ 토스 결제 버튼 클릭
  // - orderId는 절대 프론트에서 만들지 않음
  // - 서버 /payment/toss/prepare 에서 발급받아 사용
  // =========================
  $("#tossBtn").on("click", function() {
    const amountStr = $("#amountInput").val();
    const amount = parseInt(amountStr, 10);

    if (!amount || amount <= 0) {
      alert("충전 금액을 선택해주세요.");
      setPayEnabled(false);
      return;
    }

    if (!clientKey || clientKey.trim().length < 5) {
      alert("토스 클라이언트 키가 설정되지 않았습니다. (toss.clientKey)");
      return;
    }

    lockButtons(true);

    // ✅ 1) 서버에 prepare 호출해서 orderId 발급 + 세션에 pending 저장
    $.ajax({
      url: "${ctx}${tossPrepareUrl}",
      type: "POST",
      dataType: "json",
      data: { amount: amount },
      success: function(res) {
        const orderId = res && res.orderId ? res.orderId : null;

        if (!orderId) {
          alert("토스 결제 준비 응답이 올바르지 않습니다.(orderId 없음)");
          lockButtons(false);
          setPayEnabled(true);
          return;
        }

        const successUrl = window.location.origin + "${ctx}${tossSuccessUrl}";
        const failUrl    = window.location.origin + "${ctx}${tossFailUrl}";

        const tossPayments = TossPayments(clientKey);

        // ✅ 2) 결제 요청
        tossPayments.requestPayment("토스페이", {
          amount: amount,
          orderId: orderId,
          orderName: "캐시 충전 " + amount.toLocaleString() + "원",
          successUrl: successUrl,
          failUrl: failUrl
        });
      },
      error: function(xhr) {
        // 서버가 결제 준비를 거절하면(비로그인/금액불가/세션문제) 여기로 옴
        let msg = "토스 결제 준비 실패";
        try {
          if (xhr.responseText) msg += ": " + xhr.responseText;
        } catch(e) {}
        alert(msg);

        lockButtons(false);
        // 금액이 유지되고 있으니 다시 선택할 필요는 없음
        setPayEnabled(true);
      }
    });
  });

});
</script>
</body>
</html>