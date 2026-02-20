<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" isELIgnored="false" %>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<c:set var="rawLocation" value="${empty location ? '/' : location}" />
<c:set var="finalLocation"
       value="${fn:startsWith(rawLocation,'http') ? rawLocation :
              (fn:startsWith(rawLocation,'/') ? ctx.concat(rawLocation) : ctx.concat('/').concat(rawLocation))}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>메세지 페이지</title>

<link rel="icon" type="image/png" href="${ctx}/favicon.png">
<link rel="stylesheet" type="text/css" href="${ctx}/css/style.css">

<!-- ✅ SweetAlert2 -->
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<style>
.sanction-wrapper {
    background: #0a0a0f;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
}
.sanction-box {
    max-width: 560px;
    width: 100%;
    padding: 36px 32px;
    background: rgba(30, 30, 40, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.15);
    border-radius: 14px;
    color: #fff;
}
.sanction-msg {
    font-size: 16px;
    line-height: 1.7;
    color: #e0e0e0;
    margin-bottom: 24px;
    text-align: center;
    white-space: pre-line;
}
.sanction-notice {
    background: rgba(81, 207, 102, 0.07);
    border: 1px solid rgba(81, 207, 102, 0.2);
    border-radius: 8px;
    padding: 18px 20px;
}
.sanction-notice p {
    margin: 0 0 10px 0;
    font-size: 14px;
    color: #51cf66;
    font-weight: 700;
}
.sanction-notice ul {
    list-style: none;
    padding-left: 0;
    margin: 0;
}
.sanction-notice ul li {
    padding: 4px 0;
    font-size: 14px;
    color: #a8f0b8;
}
.btn-confirm {
    display: block;
    width: 100%;
    margin-top: 24px;
    padding: 13px 0;
    background: linear-gradient(135deg, rgba(120, 190, 255, 0.45), rgba(255, 255, 255, 0.08));
    border: 1px solid rgba(120, 190, 255, 0.35);
    border-radius: 999px;
    color: #fff;
    font-weight: 800;
    font-size: 15px;
    text-align: center;
    text-decoration: none;
    cursor: pointer;
    transition: all 0.3s;
}
.btn-confirm:hover {
    background: linear-gradient(135deg, rgba(120, 190, 255, 0.55), rgba(255, 255, 255, 0.12));
    border-color: rgba(120, 190, 255, 0.45);
    transform: translateY(-1px);
    color: #fff;
    text-decoration: none;
}
</style>
</head>

<body>

<c:choose>

    <%-- ✅ 제재 안내 화면 (showSanctionModal이 있으면) --%>
    <c:when test="${not empty sessionScope.showSanctionModal}">
        <div class="sanction-wrapper">
            <div class="sanction-box">

                <p class="sanction-msg"><c:out value="${msg}" /></p>

                <%-- SUSPEND_7D / SUSPEND_30D: 이용 가능 기능 목록 표시 --%>
                <c:if test="${sessionScope.memberStatus eq 'SUSPEND_7D' or sessionScope.memberStatus eq 'SUSPEND_30D'}">
                    <div class="sanction-notice">
                        <p>✅ 이용 가능 기능</p>
                        <ul>
                            <li>• 게시글/댓글 조회</li>
                            <li>• 좋아요 기능</li>
                            <li>• 캐시 충전/사용</li>
                        </ul>
                    </div>
                    <c:if test="${not empty sessionScope.sanctionEndAt}">
                        <p style="margin-top:14px; font-size:13px; color:#aaa; text-align:center;">
                            정지 해제일: <c:out value="${sessionScope.sanctionEndAt}" />
                        </p>
                    </c:if>
                </c:if>

                <%-- WARNING: 메시지만 표시, 이용 가능 목록 없음 --%>
                <%-- (기능 제한 없으므로 별도 안내 불필요) --%>

                <a href="${finalLocation}" class="btn-confirm">확인</a>
            </div>
        </div>

        <%-- ✅ 한 번만 표시 후 제거 --%>
        <c:remove var="showSanctionModal" scope="session"/>

    </c:when>

    <%-- ✅ 일반 메시지: SweetAlert2로 띄우고 이동 --%>
    <c:otherwise>
        <script>
          const msg = "<c:out value='${msg}' />".replaceAll("&quot;", '"').replaceAll("&#39;", "'");
          const go  = "<c:out value='${finalLocation}' />".replaceAll("&quot;", '"').replaceAll("&#39;", "'");

          const lower = msg.toLowerCase();
          let icon = "info";
          let title = "알림";

          if (lower.includes("성공") || lower.includes("완료") || lower.includes("환영")) {
            icon = "success"; title = "성공";
          }
          if (lower.includes("실패") || lower.includes("오류") || lower.includes("에러") || lower.includes("불가")) {
            icon = "error"; title = "실패";
          }
          if (lower.includes("정지") || lower.includes("제재") || lower.includes("경고") || lower.includes("제한")) {
            icon = "warning"; title = "주의";
          }

          Swal.fire({
             position: "top",
             icon,
             title,
             text: msg,
             confirmButtonText: "확인",
             allowOutsideClick: false
           }).then(() => {
             location.href = go;
           });
        </script>
    </c:otherwise>

</c:choose>

</body>
</html>
