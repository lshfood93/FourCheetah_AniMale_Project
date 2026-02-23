<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<%-- 
  공통 contextPath 추출.
  이 페이지는 favicon / css / js 같은 정적 리소스를 여러 개 로드하므로
  ${ctx} 기준으로 통일하면 배포 경로가 바뀌어도(예: /animale) 수정 범위를 줄일 수 있다.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 
  내부 이동 링크를 c:url로 미리 변수화.
  이유:
  1) contextPath 자동 포함
  2) URL 하드코딩 분산 방지
  3) 파라미터가 생겨도 c:param으로 확장 가능
--%>
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
/* 
  결제 결과 페이지에서는 검색/프로필 아이콘이 핵심 UI가 아니므로 숨김 처리.
  공통 헤더를 그대로 include하면서도 이 페이지 목적(결과 확인/이동)에 집중시키기 위한 설정.
*/
.icon_profile, .icon_search, .search-switch { display: none !important; }

/* 
  결과 카드 전체 래퍼
  - 최대 너비 제한으로 가독성 유지
  - 가운데 정렬
  - 텍스트 중앙 정렬로 '완료/실패 안내' 느낌 강화
*/
.result-box { max-width: 520px; margin: 0 auto; text-align: center; }

/* 상단 아이콘(성공/실패) 크기 */
.result-icon { font-size: 64px; margin-bottom: 20px; }

/* 상태별 아이콘 색상 구분 */
.result-icon.success { color: #4caf50; }
.result-icon.fail { color: #e53935; }

/* 메인 타이틀(결제 완료/실패 문구) */
.result-box h4 { font-weight: 700; margin-bottom: 10px; }

/* 보조 설명 문구 */
.result-desc { font-size: 14px; color: #b7b7b7; margin-bottom: 30px; }

/* 
  결제 상세 정보 박스
  성공 시: 금액/수단/승인시각/보유캐시
  실패 시: 실패 사유
*/
.result-info{
  background: rgba(255,255,255,0.05);
  border-radius: 16px;
  padding: 24px;
  text-align: left;
  margin-bottom: 30px;
}

/* 
  각 정보 줄(dt/dd)을 좌우 정렬.
  label(dt) - value(dd) 구조를 한 줄로 정리하기 위한 flex 사용.
*/
.result-info dl{
  display: flex;
  justify-content: space-between;
  margin-bottom: 12px;
  font-size: 14px;
}

/* 항목명(라벨) / 값 스타일 구분 */
.result-info dt { color: #b7b7b7; }
.result-info dd { color: #ffffff; font-weight: 600; }

/* 하단 메인 이동 버튼 (마이페이지 / 다시 결제하기 공통 스타일) */
.btn-main{
  width: 100%;
  height: 52px;
  border-radius: 30px;
  background: #2f80ed;
  border: none;
  color: #ffffff;
  font-weight: 600;
}

/* hover 시 살짝 진한 톤으로 피드백 */
.btn-main:hover { background: #1c6dd5; }
</style>
</head>

<body>

<%@ include file="/WEB-INF/common/header.jsp" %>

<section class="spad">
  <div class="container">

    <div class="login-box-clean result-box">

      <%-- 
        실패 메시지 통합 처리
        서버에서 상황에 따라 errorMessage 또는 message 중 하나만 내려줄 수 있으므로
        화면에서는 failMsg 하나로 통일해서 출력한다.
        
        우선순위:
        1) errorMessage
        2) 없으면 message
      --%>
      <c:set var="failMsg" value="${not empty errorMessage ? errorMessage : message}" />

      <c:choose>

        <%-- 
          성공 분기
          payResult 값이 SUCCESS일 때만 결제 성공 UI를 렌더링한다.
        --%>
        <c:when test="${payResult eq 'SUCCESS'}">

          <div class="result-icon success">
            <i class="fa fa-check-circle"></i>
          </div>

          <%-- 
            성공 제목
            결제 수단(payMethod)을 함께 보여줘서 사용자가 어떤 방식으로 결제되었는지 바로 인지 가능.
          --%>
          <h4>
            <c:out value="${payMethod}" />
            결제가 완료되었습니다
          </h4>

          <%-- 성공 보조 안내 문구 --%>
          <p class="result-desc">캐시 충전이 정상적으로 승인되었습니다.</p>

          <%-- 
            성공 상세 정보 박스
            c:out 사용 이유:
            서버에서 내려온 값을 그대로 출력하되, 특수문자 이스케이프 처리로 안전하게 표시
          --%>
          <div class="result-info">
            <dl>
              <dt>결제 금액</dt>
              <dd><c:out value="${totalAmount}" /> 원</dd>
            </dl>
            <dl>
              <dt>결제 수단</dt>
              <dd><c:out value="${payMethod}" /></dd>
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

          <%-- 
            성공 후 이동 버튼
            사용자가 결제 완료 뒤 가장 자주 확인할 가능성이 높은 마이페이지로 이동.
          --%>
          <a href="${mypageUrl}" class="btn btn-main">마이페이지로</a>

        </c:when>

        <%-- 
          실패 분기 (SUCCESS가 아닌 모든 경우)
          승인 실패 / 취소 / 서버 처리 실패 등 결과를 하나의 실패 UI로 안내.
        --%>
        <c:otherwise>

          <div class="result-icon fail">
            <i class="fa fa-times-circle"></i>
          </div>

          <h4>결제에 실패했습니다</h4>

          <%-- 
            실패 기본 안내 문구
            상세 사유는 아래 result-info에서 별도로 보여준다.
          --%>
          <p class="result-desc">
            결제가 정상적으로 처리되지 않았습니다.<br>
            다시 시도해주세요.
          </p>

          <%-- 실패 사유 표시 박스 --%>
          <div class="result-info">
            <dl>
              <dt>실패 사유</dt>
              <dd><c:out value="${failMsg}" /></dd>
            </dl>
          </div>

          <%-- 
            실패 후 재시도 동선
            충전 페이지로 다시 보내 사용자가 바로 재결제를 진행할 수 있게 함.
          --%>
          <a href="${cashChargeUrl}" class="btn btn-main">다시 결제하기</a>

        </c:otherwise>

      </c:choose>

    </div>

  </div>
</section>

<%@ include file="/WEB-INF/common/footer.jsp" %>

<%-- 부트스트랩 JS 로드 (공통 UI 컴포넌트 동작용) --%>
<script src="${ctx}/js/bootstrap.min.js"></script>
</body>
</html>