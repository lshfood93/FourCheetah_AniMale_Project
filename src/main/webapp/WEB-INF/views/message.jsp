<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" isELIgnored="false" %>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- =========================
     location 정규화 (핵심)
     - location이 비면 "/"로
     - http(s)면 그대로 사용
     - "/"로 시작하면 ctx 붙임
     - 그 외면 ctx + "/" + location
   ========================= --%>
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
.sanction-notice .allowed { color: #51cf66; }
.sanction-notice .blocked { color: #ff6b6b; }

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
.text-center { text-align: center; }
</style>
</head>

<body>

<c:choose>

    <%-- ✅ 제재 안내 화면 (showSanctionModal이 있으면) --%>
    <c:when test="${not empty sessionScope.showSanctionModal}">
        <div class="sanction-wrapper">
            <div class="sanction-box">
                <h2><c:out value="${msg}" /></h2>

                <div class="sanction-notice">
                    <h3>⚠️ 계정 이용 제한 안내</h3>

                    <p><strong>사유:</strong> <c:out value="${sessionScope.sanctionReason}" /></p>
                    <p><strong>제한 해제일:</strong> <c:out value="${sessionScope.sanctionEndAt}" /></p>

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
                    <a href="${finalLocation}" class="btn-confirm">확인</a>
                </div>
            </div>
        </div>

        <%-- ✅ 한 번만 표시 후 제거 --%>
        <c:remove var="showSanctionModal" scope="session"/>

    </c:when>

    <%-- ✅ 일반 메시지: SweetAlert2로 띄우고 이동 --%>
    <c:otherwise>
        <script>
          // JSTL로 들어온 문자열을 JS에서 안전하게 쓰기(따옴표/개행 최소 방어)
          const msg = "<c:out value='${msg}' />".replaceAll("&quot;", '"').replaceAll("&#39;", "'");
          const go  = "<c:out value='${finalLocation}' />".replaceAll("&quot;", '"').replaceAll("&#39;", "'");

          // 메시지 문구로 아이콘 자동 분기(원하면 규칙 추가)
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
