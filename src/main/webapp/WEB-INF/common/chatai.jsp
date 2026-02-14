<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%-- 
  chatai.jsp (공통 위젯 조각)
  - 목적: 모든 페이지에서 사용할 '우하단 채팅 위젯'의 HTML 구조(마크업)만 담당
  - CSS/JS 로드는 여기서 하지 않고, header.jsp 같은 공통 로더에서 1번만 로드(중복 방지)
  - JS는 아래 id들을 기준으로 요소를 찾아서 '열기/닫기 토글'을 수행한다
    - chataiFab / chataiPanel / chataiClose / chataiForm / chataiInput / chataiMessages
--%>

<%-- 프로젝트 컨텍스트 경로 (예: /animale) --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 
  [ROOT] 위젯 전체 컨테이너
  - id="chatai" : JS가 위젯 전체를 제어할 때 사용하는 루트
  - class="chatai" : CSS 범위(scope)를 잡기 위한 클래스
  - data-endpoint : 나중에 AI 서버 API 붙일 때 JS가 읽어서 요청을 보내는 주소
    예) POST ${ctx}/api/chat  로 { message: "..." } 보내고 { reply: "..." } 받는 형태
  - aria-live="polite" : 보조기기(스크린리더)에게 메시지 변경을 부드럽게 알림(선택)
--%>
<div
  class="chatai"
  id="chatai"
  data-endpoint="${ctx}/api/chat"
  aria-live="polite"
>

  <%-- 
    [1] FAB 버튼(우하단 떠있는 아이콘)
    - 화면 우하단 고정(fixed)은 CSS가 담당
    - 클릭 시 JS가 위젯 상태를 토글해서 패널을 열거나 닫는다
    - aria-label : 아이콘 버튼은 텍스트가 없으니 접근성용 라벨을 반드시 준다
  --%>
  <button type="button" class="chatai-fab" id="chataiFab" aria-label="AI 채팅 열기">
	  <img src="${ctx}/img/chatai_icon.jpg" alt="AI" class="chatai-fab-img">
  </button>


  <%-- 
    [2] 채팅 패널(작게 펼쳐지는 창)
    - 기본 상태는 '숨김'이다 (CSS/JS로 제어)
    - JS가 열릴 때:
        1) 루트(#chatai)에 is-open 같은 상태 클래스를 붙인다
        2) aria-hidden="false" 로 바꾸고, 입력창에 focus 준다
    - role="dialog" : 대화창 UI임을 명시(선택)
    - aria-label : 패널 의미를 설명
  --%>
  <section
    class="chatai-panel"
    id="chataiPanel"
    aria-hidden="true"
    role="dialog"
    aria-label="AI 채팅"
  >

    <%-- 
      [2-1] 패널 상단 헤더
      - 제목 + 닫기 버튼 영역
      - 닫기 버튼 클릭 시 JS가 패널을 닫는다
    --%>
    <header class="chatai-panel-header">
      <div class="chatai-title">AI 챗봇</div>

      <button
        type="button"
        class="chatai-close"
        id="chataiClose"
        aria-label="닫기"
      >
        ✕
      </button>
    </header>


    <%-- 
      [2-2] 메시지 리스트 영역(스크롤 영역)
      - 메시지가 계속 쌓이는 컨테이너
      - CSS에서 이 영역만 overflow: auto 로 스크롤 되게 만드는 게 일반적
      - JS가 사용자/봇 메시지를 여기에 append 한다
      - msg-bot / msg-user 클래스로 좌우 정렬(말풍선 색 등)을 구분한다
    --%>
    <div class="chatai-messages" id="chataiMessages">

      <%-- 초기 안내 메시지(봇) 1개 --%>
      <div class="chatai-msg chatai-msg-bot">
        <div class="chatai-bubble">안녕하세요. 무엇을 도와드릴까요?</div>
      </div>

    </div>


    <%-- 
      [2-3] 입력 바(하단 고정 영역)
      - form 제출(submit) 이벤트를 JS가 가로채서(fetch 등) 서버 요청을 보낸다
      - autocomplete="off" : 브라우저 자동완성 방지(취향)
      - input은 메시지 입력, button은 전송
    --%>
    <form class="chatai-inputbar" id="chataiForm" autocomplete="off">

      <input
        type="text"
        class="chatai-input"
        id="chataiInput"
        placeholder="메시지를 입력하세요"
      />

      <button type="submit" class="chatai-send" aria-label="보내기">
        전송
      </button>

    </form>

  </section>
</div>
