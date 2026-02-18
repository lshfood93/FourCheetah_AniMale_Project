<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" isELIgnored="false" %>
<<<<<<< HEAD
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
=======
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>메세지 페이지</title>
<<<<<<< HEAD
<link rel="icon" type="image/png" href="${pageContext.request.contextPath}/favicon.png">

<link rel="stylesheet" type="text/css" href="css/style.css">
</head>
<body>
 <div class="wrapper">
 
<script>
	alert('${msg}');
	location.href='${location}';
</script>
</div>
=======
<link rel="icon" type="image/png" href="${ctx}/favicon.png">
<link rel="stylesheet" type="text/css" href="${ctx}/css/style.css">

<style>
/* 제재 안내 전용 스타일 */
.sanction-wrapper {
    background: #0a0a0f;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
}

.sanction-box {
    max-width: 600px;
    width: 100%;
    padding: 30px;
    background: rgba(30, 30, 40, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 12px;
    color: #fff;
}

.sanction-box h2 {
    color: #fff;
    font-size: 24px;
    margin-bottom: 20px;
    text-align: center;
}

.sanction-notice {
    background: rgba(255, 107, 107, 0.1);
    border: 1px solid rgba(255, 107, 107, 0.3);
    border-radius: 8px;
    padding: 20px;
    margin-top: 20px;
}

.sanction-notice h3 {
    color: #ff6b6b;
    font-size: 18px;
    margin-bottom: 15px;
    margin-top: 0;
}

.sanction-notice p {
    margin: 10px 0;
    font-size: 15px;
}

.sanction-notice hr {
    border: 0;
    border-top: 1px solid rgba(255, 255, 255, 0.2);
    margin: 15px 0;
}

.sanction-notice ul {
    list-style: none;
    padding-left: 0;
    margin: 10px 0;
}

.sanction-notice ul li {
    padding: 5px 0;
    font-size: 14px;
}

.sanction-notice .allowed {
    color: #51cf66;
}

.sanction-notice .blocked {
    color: #ff6b6b;
}

.btn-confirm {
    display: inline-block;
    margin-top: 20px;
    padding: 12px 30px;
    background: linear-gradient(135deg, rgba(120, 190, 255, 0.45), rgba(255, 255, 255, 0.08));
    border: 1px solid rgba(120, 190, 255, 0.35);
    border-radius: 999px;
    color: #fff;
    font-weight: 800;
    text-decoration: none;
    cursor: pointer;
    transition: all 0.3s;
}

.btn-confirm:hover {
    background: linear-gradient(135deg, rgba(120, 190, 255, 0.55), rgba(255, 255, 255, 0.12));
    border-color: rgba(120, 190, 255, 0.45);
    transform: translateY(-1px);
}

.text-center {
    text-align: center;
}
</style>
</head>
<body>

<c:choose>
    <%-- 제재 안내가 있는 경우 --%>
    <c:when test="${not empty sessionScope.showSanctionModal}">
        <div class="sanction-wrapper">
            <div class="sanction-box">
                <h2>${msg}</h2>
                
                <div class="sanction-notice">
                    <h3>⚠️ 계정 이용 제한 안내</h3>
                    <p><strong>사유:</strong> ${sessionScope.sanctionReason}</p>
                    <p><strong>제한 해제일:</strong> ${sessionScope.sanctionEndAt}</p>
                    <hr>
                    
                    <p><strong class="blocked">🚫 제한 내용:</strong></p>
                    <ul>
                        <li class="blocked">• 게시글 작성/수정/삭제 불가</li>
                        <li class="blocked">• 댓글 작성/수정/삭제 불가</li>
                        <li class="blocked">• 신고 기능 불가</li>
                    </ul>
                    
                    <p><strong class="allowed">✅ 이용 가능:</strong></p>
                    <ul>
                        <li class="allowed">• 게시글/댓글 조회</li>
                        <li class="allowed">• 좋아요 기능</li>
                        <li class="allowed">• 캐시 충전/사용</li>
                    </ul>
                </div>
                
                <div class="text-center">
                    <a href="${ctx}${location}" class="btn-confirm">확인</a>
                </div>
            </div>
        </div>
        
        <%
            // 모달 한 번만 표시 후 제거
            session.removeAttribute("showSanctionModal");
        %>
    </c:when>
    
    <%-- 일반 메시지 (기존 방식) --%>
    <c:otherwise>
        <div class="wrapper">
            <script>
                alert('${msg}');
                location.href='${location}';
            </script>
        </div>
    </c:otherwise>
</c:choose>
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871

</body>
</html>