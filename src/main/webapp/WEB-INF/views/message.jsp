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

<%-- ✅ CHANGED: 백엔드에서 명시적으로 넣어준 sanctionType 기준으로 경고 여부 판별
     - WARNING: 경고(기능 제한 없음, 안내만)
     - SUSPEND_7D / SUSPEND_30D: 정지(제한 안내 표시)
--%>
<c:set var="isWarningNotice" value="${sessionScope.sanctionType eq 'WARNING'}" />

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
/* 제재/경고 안내 전용 스타일 */
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
    line-height: 1.55;
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

/* ✅ CHANGED: 경고 전용(노란톤) 간단 안내 박스 */
.sanction-notice.warning-only {
    background: rgba(255, 193, 7, 0.08);
    border-color: rgba(255, 193, 7, 0.28);
}
.sanction-notice.warning-only h3 {
    color: #ffd43b;
}

/* ✅ CHANGED: 이메일 안내 문구 공통 스타일 */
.sanction-notice .email-guide {
    margin-top: 14px;
    padding-top: 12px;
    border-top: 1px dashed rgba(255, 255, 255, 0.2);
    color: rgba(255, 255, 255, 0.9);
    font-size: 14px;
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
.text-center { text-align: center; }
</style>
</head>

<body>

<c:choose>

    <%-- ✅ 제재/경고 안내 화면 (로그인 직후 1회 표시) --%>
    <c:when test="${not empty sessionScope.showSanctionModal}">
        <div class="sanction-wrapper">
            <div class="sanction-box">

                <%-- ✅ CHANGED: sanctionType 기준으로 상단 제목 분기
                     기존처럼 ${msg}(예: 로그인 성공!)를 쓰면 UX가 어색할 수 있어 별도 제목 사용
                --%>
                <c:choose>
                    <c:when test="${isWarningNotice}">
                        <h2>경고 안내</h2>
                    </c:when>
                    <c:otherwise>
                        <h2>이용 제한 안내</h2>
                    </c:otherwise>
                </c:choose>

                <%-- ✅ CHANGED: 경고회원 / 제재회원 출력 내용 분리 --%>
                <c:choose>

                    <%-- =========================================================
                         ✅ 경고회원 (WARNING)
                         - 경고 누적 2회차까지는 게시글 이용 제한 없음
                         - 제한 내용/이용 가능 기능 목록 출력하지 않음
                         - 간단 안내 + 이메일 확인 안내만 표시
                       ========================================================= --%>
                    <c:when test="${isWarningNotice}">
                        <div class="sanction-notice warning-only">
                            <h3>⚠️ 커뮤니티 이용 경고 안내</h3>

                            <%-- 사유는 간단히 보여줄 수도 있고 숨길 수도 있음
                                 현재는 사용자 안내를 위해 표시 유지
                            --%>
                            <p><strong>사유:</strong> <c:out value="${sessionScope.sanctionReason}" /></p>

                            <p>회원님 계정에 경고가 부여되었습니다.</p>
                            <p>현재 게시글 이용에 제한은 없으며, 정상적으로 커뮤니티를 이용하실 수 있습니다.</p>
                            <p>원활한 커뮤니티 이용을 위해 서로를 배려하는 표현과 예의를 지켜 주세요.</p>

                            <%-- ✅ CHANGED: 이메일 확인 안내 문구 추가 --%>
                            <p class="email-guide">
                                경고 관련 상세 내용은 회원님의 이메일로 발송되었으니, 자세한 내용은 이메일을 확인해 주세요.
                            </p>
                        </div>
                    </c:when>

                    <%-- =========================================================
                         ✅ 제재회원 (SUSPEND_7D / SUSPEND_30D 등)
                         - 기존 상세 제한/이용 가능 기능 안내 유지
                         - 이메일 확인 안내 문구 추가
                       ========================================================= --%>
                    <c:otherwise>
                        <div class="sanction-notice">
                            <h3>⚠️ 계정 이용 제한 안내</h3>

                            <p><strong>사유:</strong> <c:out value="${sessionScope.sanctionReason}" /></p>
                            <p><strong>제한 해제일:</strong> <c:out value="${sessionScope.sanctionEndAt}" /></p>

                            <%-- ✅ CHANGED: 이메일 확인 안내 문구 추가 --%>
                            <p class="email-guide">
                                제재 관련 상세 내용은 회원님의 이메일로 발송되었으니, 자세한 내용은 이메일을 확인해 주세요.
                            </p>

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
                    </c:otherwise>

                </c:choose>

                <div class="text-center">
                    <a href="${finalLocation}" class="btn-confirm">확인</a>
                </div>
            </div>
        </div>

        <%-- ✅ 한 번만 표시 후 제거 (모달 재노출 방지) --%>
        <c:remove var="showSanctionModal" scope="session"/>

    </c:when>

    <%-- ✅ 일반 메시지: SweetAlert2로 띄우고 이동 --%>
    <c:otherwise>
        <script>
          // JSTL 문자열을 JS 문자열로 안전하게 받기 위한 최소 방어
          // (큰따옴표/작은따옴표 엔티티 복원)
          const msg = "<c:out value='${msg}' />"
              .replaceAll("&quot;", '"')
              .replaceAll("&#39;", "'");
          const go  = "<c:out value='${finalLocation}' />"
              .replaceAll("&quot;", '"')
              .replaceAll("&#39;", "'");

          // 메시지 문구 기반 아이콘 자동 분기
          const lower = msg.toLowerCase();
          let icon = "info";
          let title = "알림";

          if (lower.includes("성공") || lower.includes("완료") || lower.includes("환영")) {
            icon = "success";
            title = "성공";
          }
          if (lower.includes("실패") || lower.includes("오류") || lower.includes("에러") || lower.includes("불가")) {
            icon = "error";
            title = "실패";
          }
          if (lower.includes("정지") || lower.includes("제재") || lower.includes("경고") || lower.includes("제한")) {
            icon = "warning";
            title = "주의";
          }

          Swal.fire({
             position: "top",
             icon: icon,
             title: title,
             text: msg,
             confirmButtonText: "확인",
             allowOutsideClick: false
           }).then(function () {
             location.href = go;
           });
        </script>
    </c:otherwise>

</c:choose>

</body>
</html>