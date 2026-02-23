<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" isELIgnored="false" %>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<%-- 컨텍스트 경로 공통 변수
     정적 리소스(css/js/favicon), 이동 경로(location) 조합할 때 전부 이 값 기준으로 맞춘다. --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- =========================================================
     location 정규화
     ---------------------------------------------------------
     message.jsp는 컨트롤러에서 location을 다양하게 넘길 수 있어서
     화면에서 한 번 규칙대로 정리해 finalLocation으로 통일해 둔다.

     처리 규칙
     1) location 비어있음      -> "/" 사용
     2) http/https 절대 URL    -> 그대로 사용 (외부 이동)
     3) "/"로 시작하는 내부 경로 -> ctx + location
     4) 그 외 문자열           -> ctx + "/" + location

     이렇게 해두면 컨트롤러마다 location 형식이 조금 달라도
     최종 이동 주소를 안정적으로 만들 수 있다.
   ========================================================= --%>
<c:set var="rawLocation" value="${empty location ? '/' : location}" />
<c:set var="finalLocation"
       value="${fn:startsWith(rawLocation,'http') ? rawLocation :
              (fn:startsWith(rawLocation,'/') ? ctx.concat(rawLocation) : ctx.concat('/').concat(rawLocation))}" />

<%-- 로그인 직후 제재/경고 안내 분기용 플래그
     백엔드에서 sessionScope.sanctionType을 명시적으로 넣어준 값을 기준으로 판단한다.

     - WARNING: 경고 (기능 제한 없이 안내만 표시)
     - SUSPEND_7D / SUSPEND_30D 등: 이용 제한 안내 표시
--%>
<c:set var="isWarningNotice" value="${sessionScope.sanctionType eq 'WARNING'}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>메세지 페이지</title>

<link rel="icon" type="image/png" href="${ctx}/favicon.png">
<link rel="stylesheet" type="text/css" href="${ctx}/css/style.css">

<%-- 일반 메시지 알림은 SweetAlert2로 처리
     (기존 alert() 대신 UI 일관성 맞추기) --%>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<style>
/* ---------------------------------------------------------
   제재/경고 안내 전용 레이아웃 스타일
   - 로그인 직후 1회성 안내 화면에서만 사용
   - 중앙 카드형 UI
--------------------------------------------------------- */
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

/* 경고 전용(노란톤) 안내 박스
   WARNING일 때는 정지/제한 UI보다 톤을 약하게 표시 */
.sanction-notice.warning-only {
    background: rgba(255, 193, 7, 0.08);
    border-color: rgba(255, 193, 7, 0.28);
}
.sanction-notice.warning-only h3 {
    color: #ffd43b;
}

/* 이메일 확인 안내 문구 (경고/제재 공용) */
.sanction-notice .email-guide {
    margin-top: 14px;
    padding-top: 12px;
    border-top: 1px dashed rgba(255, 255, 255, 0.2);
    color: rgba(255, 255, 255, 0.9);
    font-size: 14px;
}

/* 하단 확인 버튼 */
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

    <%-- =========================================================
         제재/경고 안내 화면 분기 (로그인 직후 1회 표시)
         ---------------------------------------------------------
         sessionScope.showSanctionModal 값이 있으면 일반 알림(SweetAlert) 대신
         전용 안내 화면을 렌더링한다.
       ========================================================= --%>
    <c:when test="${not empty sessionScope.showSanctionModal}">
        <div class="sanction-wrapper">
            <div class="sanction-box">

                <%-- 상단 제목 분기
                     일반 msg(예: 로그인 성공) 문구를 그대로 제목에 쓰지 않고,
                     sanctionType 기준으로 목적에 맞는 제목을 별도로 표시한다. --%>
                <c:choose>
                    <c:when test="${isWarningNotice}">
                        <h2>경고 안내</h2>
                    </c:when>
                    <c:otherwise>
                        <h2>이용 제한 안내</h2>
                    </c:otherwise>
                </c:choose>

                <%-- =========================================================
                     경고 / 제재 안내 내용 분리
                     ---------------------------------------------------------
                     WARNING:
                       - 경고 안내만 표시
                       - 제한/가능 기능 목록은 보여주지 않음

                     SUSPEND_*:
                       - 제한 사유/해제일 + 제한 항목/가능 항목 표시
                   ========================================================= --%>
                <c:choose>

                    <%-- 경고 회원 안내 (WARNING)
                         경고 상태에서는 게시글/댓글 이용 제한이 없다는 점을 명확히 보여준다.
                         사용자 경험상 과도하게 위협적으로 보이지 않게 간단 안내 중심으로 구성. --%>
                    <c:when test="${isWarningNotice}">
                        <div class="sanction-notice warning-only">
                            <h3>⚠️ 커뮤니티 이용 경고 안내</h3>

                            <%-- 경고 사유 표시
                                 필요 시 숨길 수도 있지만 현재는 사용자 안내 목적상 노출 유지 --%>
                            <p><strong>사유:</strong> <c:out value="${sessionScope.sanctionReason}" /></p>

                            <p>회원님 계정에 경고가 부여되었습니다.</p>
                            <p>현재 게시글 이용에 제한은 없으며, 정상적으로 커뮤니티를 이용하실 수 있습니다.</p>
                            <p>원활한 커뮤니티 이용을 위해 서로를 배려하는 표현과 예의를 지켜 주세요.</p>

                            <%-- 상세 내용은 이메일에서 확인하도록 안내
                                 화면에는 핵심 요약만 두고, 긴 내용은 메일로 분리 --%>
                            <p class="email-guide">
                                경고 관련 상세 내용은 회원님의 이메일로 발송되었으니, 자세한 내용은 이메일을 확인해 주세요.
                            </p>
                        </div>
                    </c:when>

                    <%-- 제재 회원 안내 (SUSPEND_7D / SUSPEND_30D 등)
                         실제 이용 제한이 발생한 상태이므로
                         사유 / 해제일 / 제한 항목 / 이용 가능 항목을 구체적으로 표시한다. --%>
                    <c:otherwise>
                        <div class="sanction-notice">
                            <h3>⚠️ 계정 이용 제한 안내</h3>

                            <%-- 제재 사유 / 해제 시점 표시 --%>
                            <p><strong>사유:</strong> <c:out value="${sessionScope.sanctionReason}" /></p>
                            <p><strong>제한 해제일:</strong> <c:out value="${sessionScope.sanctionEndAt}" /></p>

                            <%-- 제재 상세 내역은 이메일 안내 병행 --%>
                            <p class="email-guide">
                                제재 관련 상세 내용은 회원님의 이메일로 발송되었으니, 자세한 내용은 이메일을 확인해 주세요.
                            </p>

                            <hr>

                            <%-- 제한 기능 목록 --%>
                            <p><strong class="blocked">🚫 제한 내용:</strong></p>
                            <ul>
                                <li class="blocked">• 게시글 작성/수정/삭제 불가</li>
                                <li class="blocked">• 댓글 작성/수정/삭제 불가</li>
                                <li class="blocked">• 신고 기능 불가</li>
                            </ul>

                            <%-- 이용 가능한 기능 목록
                                 사용자 입장에서 "뭐가 되는지"도 같이 보여줘야 혼선이 적다. --%>
                            <p><strong class="allowed">✅ 이용 가능:</strong></p>
                            <ul>
                                <li class="allowed">• 게시글/댓글 조회</li>
                                <li class="allowed">• 좋아요 기능</li>
                                <li class="allowed">• 캐시 충전/사용</li>
                            </ul>
                        </div>
                    </c:otherwise>

                </c:choose>

                <%-- 확인 버튼 클릭 시 정규화된 최종 이동 경로(finalLocation)로 이동 --%>
                <div class="text-center">
                    <a href="${finalLocation}" class="btn-confirm">확인</a>
                </div>
            </div>
        </div>

        <%-- 1회성 안내 처리 후 세션 플래그 제거
             제거하지 않으면 다음 요청에서도 같은 안내 화면이 반복 노출될 수 있다. --%>
        <c:remove var="showSanctionModal" scope="session"/>

    </c:when>

    <%-- =========================================================
         일반 메시지 분기
         ---------------------------------------------------------
         제재/경고 전용 화면이 아닌 경우에는 SweetAlert2 팝업으로 msg를 보여주고
         확인 후 finalLocation으로 이동한다.
       ========================================================= --%>
    <c:otherwise>
        <script>
          // JSTL에서 출력된 문자열을 JS 문자열로 받는 구간
          // c:out으로 기본 escape는 유지하고, JS 표시에서 필요한 최소 엔티티만 복원한다.
          // (큰따옴표/작은따옴표 복원)
          const msg = "<c:out value='${msg}' />"
              .replaceAll("&quot;", '"')
              .replaceAll("&#39;", "'");
          const go  = "<c:out value='${finalLocation}' />"
              .replaceAll("&quot;", '"')
              .replaceAll("&#39;", "'");

          // 메시지 문구 기반으로 아이콘/제목 자동 선택
          // 컨트롤러에서 별도 타입(success/error/warning)을 안 넘겨도
          // 기본 UX가 어느 정도 맞게 나오도록 키워드 기준으로 분기한다.
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

          // 팝업 확인 후 이동
          // 외부 클릭으로 닫히지 않게 해서 메시지 확인 흐름을 보장한다.
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