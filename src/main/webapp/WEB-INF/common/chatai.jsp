<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%-- 이 위젯 파일 안에서 API 경로/이미지 경로 만들 때 공통으로 쓰는 컨텍스트 경로 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- =========================================================
     ChatAI 위젯 마크업 (공용 include용)
     ---------------------------------------------------------
     이 파일은 '위젯의 화면 골격'만 담당하고,
     실제 열기/닫기/메시지 렌더/서버 통신은 /js/chatai.js가 맡는다.

     핵심 포인트
     1) 루트 #chatai + data-endpoint 는 JS가 시작할 때 잡는 기준점
     2) FAB 클릭 -> 패널 열고 닫는 UI 토글
     3) 메시지 영역 안에 quick 영역은 항상 고정으로 남겨둠
     4) 추천이 나온 뒤에만 하단 액션바(더 추천/조건 바꾸기) 표시
   ========================================================= --%>

<div
  class="chatai"
  id="chatai"
  data-endpoint="${ctx}/api/ai-chat"
  aria-live="polite"
>
  <%-- =========================================================
       [FAB] 우하단 플로팅 버튼
       ---------------------------------------------------------
       역할:
       - 사용자가 위젯을 여는 시작점
       - JS에서 #chataiFab 클릭 이벤트를 걸어 패널 토글 처리

       접근성 메모:
       - aria-label: 버튼 자체의 기능 설명(채팅 열기)
       - img alt: 이미지 대체 텍스트 (너무 길 필요 없음)
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
       [PANEL] 실제 대화 패널
       ---------------------------------------------------------
       기본 상태는 닫힘(aria-hidden="true")
       JS가 열 때 보통 같이 하는 일:
       - 루트(.chatai)에 열림 상태 클래스 추가
       - 이 패널 aria-hidden="false"로 변경
       - 입력창 focus 이동

       role="dialog"를 준 이유:
       - 단순 div가 아니라 '대화 상자 UI'라는 의미를 전달하려고
     ========================================================= --%>
  <section
    class="chatai-panel"
    id="chataiPanel"
    aria-hidden="true"
    role="dialog"
    aria-label="AI 채팅"
  >
    <%-- =========================================================
         [HEADER] 상단 제목 + 제어 버튼들
         ---------------------------------------------------------
         reset 버튼:
         - 대화 세션 초기화(새 대화 시작)
         close 버튼:
         - 서버 초기화가 아니라 UI 패널 닫기

         즉, reset과 close는 목적이 다름
         (세션 초기화 vs 화면 닫기)
       ========================================================= --%>
    <header class="chatai-panel-header">
      <div class="chatai-title">AI 챗봇</div>

      <div class="chatai-header-actions">
        <%-- 새 대화 버튼
             JS에서 #chataiResetBtn 클릭 -> callReset()
             처리 중(busy) 상태일 때는 JS가 disabled 제어 가능 --%>
        <button
          type="button"
          class="chatai-header-btn"
          id="chataiResetBtn"
          aria-label="새 대화"
          title="새 대화"
        >↻</button>

        <%-- 닫기 버튼
             JS에서 #chataiClose 클릭 -> closePanel() --%>
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
         JS가 사용자/AI 말풍선을 이 영역에 append한다.

         중요한 구조 포인트:
         - #chataiQuick(빠른 질문/추천 칩 영역)은 메시지 영역 안에 고정으로 둠
         - reset/open 시 메시지 정리할 때도 quick 컨테이너 자체는 유지하고
           내부 칩만 다시 렌더링하는 방식으로 쓰기 좋음
       ========================================================= --%>
    <div class="chatai-messages" id="chataiMessages">
      <div
        class="chatai-quick"
        id="chataiQuick"
        aria-label="빠른 추천 예시"
      ></div>
    </div>

    <%-- =========================================================
         [ACTIONS] 추천 후 추가 액션 버튼 영역
         ---------------------------------------------------------
         기본은 hidden 상태.
         추천 결과가 실제로 나온 뒤에만 JS가 표시한다.

         버튼 의미:
         - 더 추천: 같은 맥락으로 추천 추가 요청
         - 조건 바꾸기: 입력창 조건으로 재추천 요청
       ========================================================= --%>
    <div class="chatai-actions" id="chataiActions" hidden>
      <button type="button" class="chatai-action-btn" id="chataiMoreBtn">더 추천</button>
      <button type="button" class="chatai-action-btn" id="chataiChangeBtn">조건 바꾸기</button>
    </div>

    <%-- =========================================================
         [INPUT] 입력 폼
         ---------------------------------------------------------
         form으로 감싼 이유:
         - Enter 입력과 전송 버튼 클릭을 submit 한 흐름으로 묶기 쉬움

         JS 동작 포인트:
         - submit 이벤트에서 sendUserMessage()
         - placeholder는 서버 /open, /reset 응답값(initialPrompt 등)으로
           상황에 따라 교체될 수 있음
         - busy 상태일 때 input/button 비활성화 제어 가능
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