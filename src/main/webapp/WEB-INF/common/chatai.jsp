<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- =========================================================
     ChatAI Widget (JSP 최종본 + 상세 주석판)
     ---------------------------------------------------------
     1) 포함 위치
       - 보통 공용 footer.jsp / layout 하단에 include해서
         모든 페이지에서 FAB(우하단 버튼) + 패널이 뜨게 만든다.

     2) JS 연동 포인트
       - 루트 id="chatai" 가 존재해야 /js/chatai.js가 동작한다.
       - data-endpoint는 JS가 API base로 사용한다.
         예) ${ctx}/api/ai-chat
         실제 호출:
           GET  ${ctx}/api/ai-chat/open
           POST ${ctx}/api/ai-chat/message
           POST ${ctx}/api/ai-chat/reset
           POST ${ctx}/api/ai-chat/more
           POST ${ctx}/api/ai-chat/change

     3) 접근성(ARIA)
       - aria-live="polite" : 새로운 메시지가 추가될 때
         스크린리더가 '너무 끼어들지 않게' 부드럽게 알림.
       - panel(role="dialog") + aria-hidden 토글:
         JS가 열림/닫힘 상태를 명확히 표현.

     4) 메시지 컨테이너 구조
       - #chataiMessages 안에 #chataiQuick(칩 영역)을 고정으로 둔다.
       - JS reset 시 메시지를 비우지만 quick 컨테이너는 유지한다.
   ========================================================= --%>

<div
  class="chatai"
  id="chatai"
  data-endpoint="${ctx}/api/ai-chat"
  aria-live="polite"
>
  <%-- =========================================================
       [FAB] Floating Action Button (우하단 동그란 버튼)
       ---------------------------------------------------------
       - JS: #chataiFab 클릭 → togglePanel()
       - CSS: --chatai-fab-right/bottom 변수로 위치 조절
       - 이미지 사용 시:
         - alt는 스크린리더용 최소 정보 제공
         - aria-label은 버튼 자체 의미(열기) 제공
     ========================================================= --%>
  <button
    type="button"
    class="chatai-fab"
    id="chataiFab"
    aria-label="AI 채팅 열기"
  >
    <img
      src="${ctx}/img/chatai_icon.jpg"
      alt="AI"
      class="chatai-fab-img"
    >
  </button>

  <%-- =========================================================
       [PANEL] 대화 패널(기본은 닫힘)
       ---------------------------------------------------------
       - aria-hidden="true" 상태에서 CSS가 visibility/opacity로 숨김 처리
       - JS가 열면:
         1) .chatai에 .is-open 클래스 추가
         2) #chataiPanel aria-hidden="false"
         3) input focus
       - role="dialog": '대화 상자'임을 의미
       - aria-label: dialog의 목적 설명
     ========================================================= --%>
  <section
    class="chatai-panel"
    id="chataiPanel"
    aria-hidden="true"
    role="dialog"
    aria-label="AI 채팅"
  >
    <%-- =========================================================
         [HEADER] 상단 제목 + 우측 액션(Reset/Close)
         ---------------------------------------------------------
         - reset 버튼은 대화 세션을 새로 시작(callReset)
         - close 버튼은 단순히 UI만 닫는다(closePanel)
       ========================================================= --%>
    <header class="chatai-panel-header">
      <div class="chatai-title">AI 챗봇</div>

      <div class="chatai-header-actions">
        <%-- 새 대화(Reset)
             - JS: #chataiResetBtn 클릭 → callReset()
             - busy일 때는 JS에서 disabled 처리됨 --%>
        <button
          type="button"
          class="chatai-header-btn"
          id="chataiResetBtn"
          aria-label="새 대화"
          title="새 대화"
        >↻</button>

        <%-- 닫기
             - JS: #chataiClose 클릭 → closePanel() --%>
        <button
          type="button"
          class="chatai-close"
          id="chataiClose"
          aria-label="닫기"
        >✕</button>
      </div>
    </header>

    <%-- =========================================================
         [MESSAGES] 메시지 출력 영역
         ---------------------------------------------------------
         - JS가 말풍선 DOM을 여기 아래에 append한다.
         - #chataiQuick은 '칩 버튼 자리'로 고정 존재.
           JS가 open/reset 때 QUICK_LIST를 렌더링한다.
       ========================================================= --%>
    <div class="chatai-messages" id="chataiMessages">
      <div
        class="chatai-quick"
        id="chataiQuick"
        aria-label="빠른 추천 예시"
      ></div>
    </div>

    <%-- =========================================================
         [ACTIONS] 추천 이후에만 보이는 하단 액션바
         ---------------------------------------------------------
         - 기본 hidden
         - JS에서 추천 카드가 1번이라도 나오면:
           hasRecs=true + showActions() 로 표시
         - 더 추천: /more
         - 조건 바꾸기: /change (input 값을 사용)
       ========================================================= --%>
    <div class="chatai-actions" id="chataiActions" hidden>
      <button type="button" class="chatai-action-btn" id="chataiMoreBtn">더 추천</button>
      <button type="button" class="chatai-action-btn" id="chataiChangeBtn">조건 바꾸기</button>
    </div>

    <%-- =========================================================
         [INPUT] 입력 바(전송 폼)
         ---------------------------------------------------------
         - form submit(엔터/전송 버튼) → sendUserMessage()
         - input placeholder는 /open 또는 /reset 응답의 initialPrompt로 교체 가능
         - busy일 때 input/send는 JS에서 disabled 처리됨
       ========================================================= --%>
    <form class="chatai-inputbar" id="chataiForm" autocomplete="off">
      <input
        type="text"
        class="chatai-input"
        id="chataiInput"
        placeholder="메시지를 입력하세요"
      />
      <button
        type="submit"
        class="chatai-send"
        id="chataiSendBtn"
        aria-label="보내기"
      >
        전송
      </button>
    </form>
  </section>
</div>
