<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 캐시 충전</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<!-- Google Font -->
<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<!-- CSS -->
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

.charge-btn-wrap { display:flex; gap:14px; margin-top:24px; }

.btn-pay { flex:1; height:56px; background:#e53637; color:#fff; border:none; border-radius:28px; font-size:16px; font-weight:600; cursor:pointer; }
.btn-pay:disabled { opacity:0.45; cursor:not-allowed; }

.btn-cancel { flex:1; height:56px; background:#2a2a4a; color:#fff; border:1px solid #444; border-radius:28px; font-size:16px; cursor:pointer; }

.btn-pay:hover { background:#ff4c4c; }
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
          <p>카카오페이로 간편하게 캐시를 충전하세요.</p>
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

          <form id="chargeForm" action="${ctx}/payment/kakaopay/ready" method="post">
            <input type="hidden" name="selectCash" id="amountInput">

            <div class="charge-btn-wrap">
              <button id="payBtn" type="submit" class="btn-pay" disabled>카카오페이로 결제하기</button>
              <button type="button" class="btn-cancel" onclick="location.href='${ctx}/member/mypage'">충전 취소</button>
            </div>
          </form>

        </div>

      </div>
    </div>
  </div>
</section>

<%@ include file="/WEB-INF/common/footer.jsp"%>

<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
<script>
$(function() {

  function setPayEnabled(enabled) {
    $("#payBtn").prop("disabled", !enabled);
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
    }
  });

});
</script>
</body>
</html>
