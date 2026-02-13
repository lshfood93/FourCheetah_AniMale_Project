/* =========================================================
   ChatAI Widget JS (chatai.js)
   - 역할:
     1) FAB 클릭 -> 패널 열기/닫기 토글
     2) 닫기 버튼 / ESC -> 닫기
     3) 메시지 렌더링 (유저/봇)
     4) (선택) 서버 호출(fetch) 자리 마련
   ========================================================= */

(function () {
  // ---------------------------------------------------------
  // 0) DOM 참조 (없으면 조용히 종료)
  // ---------------------------------------------------------
  const root = document.getElementById('chatai');
  if (!root) return;

  const fab = document.getElementById('chataiFab');
  const panel = document.getElementById('chataiPanel');
  const closeBtn = document.getElementById('chataiClose');
  const form = document.getElementById('chataiForm');
  const input = document.getElementById('chataiInput');
  const messages = document.getElementById('chataiMessages');

  if (!fab || !panel || !closeBtn || !form || !input || !messages) return;

  // API 엔드포인트(나중에 백엔드 붙일 때 사용)
  const endpoint = root.getAttribute('data-endpoint') || '';

  // ---------------------------------------------------------
  // 1) 열림/닫힘 상태 유틸
  // ---------------------------------------------------------
  function isOpen() {
    return root.classList.contains('is-open');
  }

  function openPanel() {
    root.classList.add('is-open');
    panel.setAttribute('aria-hidden', 'false');

    // 패널이 열리고 애니메이션이 끝나기 전에 focus 주면 튀는 경우가 있어 약간 지연
    window.setTimeout(() => {
      input.focus();
      // 커서 맨 뒤로
      const v = input.value;
      input.value = '';
      input.value = v;
    }, 50);
  }

  function closePanel() {
    root.classList.remove('is-open');
    panel.setAttribute('aria-hidden', 'true');
  }

  function togglePanel() {
    if (isOpen()) closePanel();
    else openPanel();
  }

  // ---------------------------------------------------------
  // 2) 메시지 렌더링
  // ---------------------------------------------------------
  function scrollToBottom() {
    messages.scrollTop = messages.scrollHeight;
  }

  function addMessage(text, who) {
    // who: 'user' | 'bot'
    const row = document.createElement('div');
    row.className = 'chatai-msg ' + (who === 'user' ? 'chatai-msg-user' : 'chatai-msg-bot');

    const bubble = document.createElement('div');
    bubble.className = 'chatai-bubble';
    bubble.textContent = text;

    row.appendChild(bubble);
    messages.appendChild(row);

    scrollToBottom();
  }

  // 로딩/대기 말풍선(선택)
  function addTyping() {
    const row = document.createElement('div');
    row.className = 'chatai-msg chatai-msg-bot';
    row.setAttribute('data-typing', '1');

    const bubble = document.createElement('div');
    bubble.className = 'chatai-bubble';
    bubble.textContent = '...';

    row.appendChild(bubble);
    messages.appendChild(row);
    scrollToBottom();
  }

  function removeTyping() {
    const typing = messages.querySelector('[data-typing="1"]');
    if (typing) typing.remove();
  }

  // ---------------------------------------------------------
  // 3) 서버 호출(현재는 자리만) - 필요 없으면 내부만 지우면 됨
  // ---------------------------------------------------------
  async function requestReply(userText) {
    // 아직 백엔드가 없으면, 임시 답변으로 대체
    if (!endpoint) {
      return '서버 엔드포인트가 아직 연결되지 않았어요.';
    }

    // 예시: JSON POST
    // 백엔드가 준비되면 endpoint에 맞춰 payload/응답 키만 조정하면 됨
    const res = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: userText })
    });

    if (!res.ok) {
      return '응답을 가져오지 못했어요. 잠시 후 다시 시도해주세요.';
    }

    const data = await res.json();

    // 백엔드 응답 형식에 맞춰 키만 조절
    // 예: { reply: "..." }
    return (data && data.reply) ? data.reply : '응답 형식을 확인해주세요.';
  }

  // ---------------------------------------------------------
  // 4) 이벤트 바인딩
  // ---------------------------------------------------------
  // FAB 클릭 -> 토글
  fab.addEventListener('click', togglePanel);

  // 닫기 버튼 -> 닫기
  closeBtn.addEventListener('click', closePanel);

  // ESC -> 닫기
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && isOpen()) {
      closePanel();
    }
  });

  // (선택) 패널 바깥 클릭 시 닫기
  // - 원치 않으면 이 블록 통째로 삭제
  document.addEventListener('click', (e) => {
    if (!isOpen()) return;

    const clickedInside = root.contains(e.target);
    if (!clickedInside) closePanel();
  });

  // 전송 submit 처리
  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const text = (input.value || '').trim();
    if (!text) return;

    // 유저 메시지 추가
    addMessage(text, 'user');
    input.value = '';

    // 봇 대기 표시(선택)
    addTyping();

    try {
      const reply = await requestReply(text);
      removeTyping();
      addMessage(reply, 'bot');
    } catch (err) {
      removeTyping();
      addMessage('오류가 발생했어요. 잠시 후 다시 시도해주세요.', 'bot');
    }
  });

  // 처음 로드시 패널은 닫힌 상태 보장
  closePanel();
})();
