<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

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

<!-- ✅ TossPayments 결제창 SDK (v1) -->
<!-- TODO: 나중에 v2(권장)로 바꿀 수 있음. 일단은 동작 점검용으로 v1 유지 -->
<script src="https://js.tosspayments.com/v1/payment"></script>

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

/* ✅ 토스 버튼 색만 살짝 구분(원하면 수정) */
.btn-toss { background:#1e88ff; }
.btn-toss:hover { background:#3a9bff; }
/* ✅ 충전 취소 버튼만 아래 줄로 내리기 */
.charge-btn-wrap{
  flex-wrap: wrap;   /* 줄바꿈 허용 */
}

.btn-cancel--down{
  flex-basis: 100%;  /* 한 줄 다 먹기 -> 다음 줄로 내려감 */
  margin-top: 12px;  /* 위 버튼들과 간격 */
}
/* ✅ 카카오페이 버튼만 노란색 */
.btn-kakao{
  background: #FEE500;      /* 카카오 노랑 */
  color: #191919;           /* 검정 글씨 */
}

.btn-kakao:hover{
  background: #FFD400;      /* 호버 시 살짝 진하게 */
}

/* disabled일 때도 글씨 잘 보이게 */
.btn-kakao:disabled{
  background: #FEE500;
  color: #191919;
  opacity: 0.45;            /* 기존 disabled 느낌 유지 */
}

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
          <p>카카오페이 또는 토스페이로 간편하게 캐시를 충전하세요.</p>
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
				<!-- ✅ 카카오페이: 기존 그대로 -->
				<form id="chargeForm" action="${ctx}/payment/kakaopay/ready"
					method="post">
					<input type="hidden" name="selectCash" id="amountInput">
					<div class="charge-btn-wrap">
						<button id="payBtn" type="submit" class="btn-pay btn-kakao" disabled>카카오페이로 결제하기</button>
						<!-- ✅ 토스페이: 같은 페이지에서 버튼만 추가 (submit 아님) -->
						<button id="tossBtn" type="button" class="btn-pay btn-toss"
							disabled>토스로 결제하기</button>
						<button type="button" class="btn-cancel btn-cancel--down"
							onclick="location.href='${ctx}/member/mypage'">충전 취소</button>
					</div>
				</form>
				
			<!-- (선택) 안내 문구 -->
          <div style="margin-top:14px;color:#b9b9c7;font-size:13px;">
            ※ 결제 수단을 선택하면 결제창이 열립니다.
          </div>

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
    $("#tossBtn").prop("disabled", !enabled);
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

  // =========================================================
  // ✅ TossPayments 결제창 호출 (프론트)
  // - 지금 단계: '결제창 열기' + success/fail로 리다이렉트 확인용
  // - 실제 운영: success에서 서버 confirm(승인) 로직 반드시 필요
  // =========================================================

  // ✅ TODO 1) 본인 토스 "클라이언트 키"로 교체하세요 (test_ck_... / live_ck_...)
  const TOSS_CLIENT_KEY = "test_ck_Z1aOwX7K8mvml0pWyvQm3yQxzvNP";

  // 키를 안 넣었으면 결제창 못 열게 방어
  function isTossKeyReady() {
    return TOSS_CLIENT_KEY && TOSS_CLIENT_KEY.indexOf("✅") === -1;
  }

  // (임시) 주문번호 생성 - 실제로는 서버에서 생성 권장
  function makeOrderId() {
    return "CASH_" + Date.now();
  }

  $("#tossBtn").on("click", function() {
    const v = $("#amountInput").val();
    const amount = parseInt(v, 10);

    if (!amount || amount <= 0) {
      alert("충전 금액을 선택해주세요.");
      setPayEnabled(false);
      return;
    }

    if (!isTossKeyReady()) {
      alert("토스 클라이언트 키를 설정해주세요. (TOSS_CLIENT_KEY)");
      return;
    }

    // ✅ TODO 2) 성공/실패 URL 매핑을 서버에 만들어야 합니다.
    // 예: @GetMapping("/payment/toss/success"), @GetMapping("/payment/toss/fail")
    const successUrl = location.origin + "${ctx}" + "/payment/toss/success";
    const failUrl    = location.origin + "${ctx}" + "/payment/toss/fail";

    try {
      const tossPayments = TossPayments(TOSS_CLIENT_KEY);

      tossPayments.requestPayment("카드", {
        amount: amount,
        orderId: makeOrderId(),
        orderName: "캐시 충전 " + amount + "원",

        // ✅ TODO 3) 실제 로그인 사용자 이름을 넣고 싶으면 서버에서 내려받아 세팅하세요
        customerName: "테스트유저",

        successUrl: successUrl,
        failUrl: failUrl
      }).catch(function (error) {
        console.log(error);
        if (error.code === "USER_CANCEL") {
          alert("결제가 취소되었습니다.");
        } else {
          alert("토스 결제창 오류: " + (error.message || error.code));
        }
      });

    } catch (e) {
      console.log(e);
      alert("토스 결제 초기화 실패: " + e.message);
    }
  });

});
</script>
</body>
</html>
