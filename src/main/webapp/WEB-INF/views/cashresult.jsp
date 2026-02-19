<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<%-- ✅ 컨텍스트 경로: 정적 리소스에 공통 사용 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- ✅ CHANGED: 내부 이동 URL은 c:url로 변수화 (컨텍스트 중복/인코딩 방지) --%>
<c:url var="mypageUrl" value="/member/mypage" />
<c:url var="cashChargeUrl" value="/cash/charge" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 결제 결과</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
.icon_profile, .icon_search, .search-switch { display: none !important; }

.result-box { max-width: 520px; margin: 0 auto; text-align: center; }

.result-icon { font-size: 64px; margin-bottom: 20px; }
.result-icon.success { color: #4caf50; }
.result-icon.fail { color: #e53935; }

.result-box h4 { font-weight: 700; margin-bottom: 10px; }

.result-desc { font-size: 14px; color: #b7b7b7; margin-bottom: 30px; }

.result-info{
  background: rgba(255,255,255,0.05);
  border-radius: 16px;
  padding: 24px;
  text-align: left;
  margin-bottom: 30px;
}
.result-info dl{
  display: flex;
  justify-content: space-between;
  margin-bottom: 12px;
  font-size: 14px;
}
.result-info dt { color: #b7b7b7; }
.result-info dd { color: #ffffff; font-weight: 600; }

.btn-main{
  width: 100%;
  height: 52px;
  border-radius: 30px;
  background: #2f80ed;
  border: none;
  color: #ffffff;
  font-weight: 600;
}
.btn-main:hover { background: #1c6dd5; }
</style>
</head>

<body>

<%@ include file="/WEB-INF/common/header.jsp" %>

<section class="spad">
  <div class="container">

    <div class="login-box-clean result-box">

      <%-- ✅ 실패 메시지: errorMessage 없으면 message 사용 --%>
      <c:set var="failMsg" value="${not empty errorMessage ? errorMessage : message}" />

      <c:choose>

        <c:when test="${payResult eq 'SUCCESS'}">

          <div class="result-icon success">
            <i class="fa fa-check-circle"></i>
          </div>

          <h4>카카오페이 결제가 완료되었습니다</h4>
          <p class="result-desc">캐시 충전이 정상적으로 승인되었습니다.</p>

          <div class="result-info">
            <dl>
              <dt>결제 금액</dt>
              <dd><c:out value="${totalAmount}" /> 원</dd>
            </dl>
            <dl>
              <dt>결제 수단</dt>
              <dd>카카오페이</dd>
            </dl>
            <dl>
              <dt>결제 승인 시각</dt>
              <dd><c:out value="${approvedAt}" /></dd>
            </dl>
            <dl>
              <dt>보유 캐시</dt>
              <dd><c:out value="${totalCash}" /> 원</dd>
            </dl>
          </div>

          <%-- ✅ CHANGED: 내부 링크는 c:url 변수 사용 --%>
          <a href="${mypageUrl}" class="btn btn-main">마이페이지로</a>

        </c:when>

        <c:otherwise>

          <div class="result-icon fail">
            <i class="fa fa-times-circle"></i>
          </div>

          <h4>결제에 실패했습니다</h4>
          <p class="result-desc">
            결제가 정상적으로 처리되지 않았습니다.<br>
            다시 시도해주세요.
          </p>

          <div class="result-info">
            <dl>
              <dt>실패 사유</dt>
              <dd><c:out value="${failMsg}" /></dd>
            </dl>
          </div>

          <%-- ✅ CHANGED: 다시 결제하기 링크도 c:url 변수 사용 --%>
          <a href="${cashChargeUrl}" class="btn btn-main">다시 결제하기</a>

        </c:otherwise>

      </c:choose>

    </div>

  </div>
</section>

<%@ include file="/WEB-INF/common/footer.jsp" %>

<script src="${ctx}/js/bootstrap.min.js"></script>
</body>
</html>
