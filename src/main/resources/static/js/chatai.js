// /js/chatai.js
// =========================================================
// ChatAI Widget (Front, ES5 호환 / 주석 복습용 버전)
// ---------------------------------------------------------
// 목표
// - 어떤 페이지에서든 우하단 FAB 버튼으로 AI 추천 위젯을 열고,
//   서버 세션(쿠키) 기반으로 대화/추천을 진행한다.
//
// 동작 전제
// - JSP에 #chatai 루트가 있어야만 실행한다. (없으면 바로 return)
// - #chatai의 data-endpoint 값이 API base URL이 된다.
//   예) data-endpoint="/animale/api/ai-chat"
//
// 실제 호출되는 엔드포인트(상대 경로)
// - GET  base + "/open"      : 초기 진입 또는 세션 대화 복원
// - POST base + "/message"   : 일반 메시지 전송 (body: { userMessage })
// - POST base + "/reset"     : 대화 초기화
// - POST base + "/more"      : 같은 조건으로 추가 추천
// - POST base + "/change"    : 조건 변경 + 추천 (body: { userMessage })
//
// 핵심 상태(프론트에서 들고 있는 플래그 3개)
// - openedOnce : 위젯을 "처음 열었을 때만" /open 호출(닫았다 열어도 재호출 안 함)
// - busy       : 요청 중복 방지(버튼/엔터/칩 전부 차단)
// - hasRecs    : 추천 카드가 한번이라도 렌더된 이후에만 "더 추천" 허용
//
// UX 정책
// - busy=true 동안은 입력/전송/더추천/조건변경/리셋/칩을 전부 비활성화한다.
// - 추천이 없는 상태에서 더추천을 누르면 서버 호출 없이 안내 문구만 출력한다.
// - 서버가 errorMessage를 내려주면 그 문구를 최우선으로 화면에 출력한다.
//
// 보안/세션
// - fetch 옵션 credentials: "same-origin" 사용
//   -> 동일 오리진일 때만 쿠키(세션)가 자동 포함되도록 한다.
// =========================================================

document.addEventListener('DOMContentLoaded', function () {

  // ---------------------------------------------------------
  // [0] 루트 가드
  // - 이 페이지에 위젯 DOM 자체가 없으면 아무것도 하지 않는다.
  // - 공통 JS로 모든 페이지에 로드해도 안전하게 만들기 위한 방어 장치.
  // ---------------------------------------------------------
  var root = document.getElementById('chatai');
  if (!root) return;

  // ---------------------------------------------------------
  // [1] DOM 캐싱
  // - 자주 쓰는 요소들을 미리 잡아두고 재탐색을 줄인다.
  // - id 기반이라 페이지 구조가 바뀌면 여기부터 확인.
  // ---------------------------------------------------------
  var fab = document.getElementById('chataiFab');
  var panel = document.getElementById('chataiPanel');
  var closeBtn = document.getElementById('chataiClose');

  var resetBtn = document.getElementById('chataiResetBtn');

  var form = document.getElementById('chataiForm');
  var input = document.getElementById('chataiInput');
  var sendBtn = document.getElementById('chataiSendBtn');

  var messages = document.getElementById('chataiMessages');
  var quick = document.getElementById('chataiQuick');

  var actions = document.getElementById('chataiActions');
  var moreBtn = document.getElementById('chataiMoreBtn');
  var changeBtn = document.getElementById('chataiChangeBtn');

  // ---------------------------------------------------------
  // [2] API base(endpoint) 구성
  // - JSP에서 #chatai에 data-endpoint를 주입해준다.
  // - 끝에 "/"가 붙어도 동일하게 처리되도록 마지막 "/"는 제거한다.
  // - base가 비어있으면 서버 호출은 불가능하므로 안내 메시지를 띄운다.
  // ---------------------------------------------------------
  var base = '';
  if (root.dataset && root.dataset.endpoint) base = root.dataset.endpoint;
  base = String(base || '').replace(/\/$/, '');

  // ---------------------------------------------------------
  // [3] ctx 계산(추천 카드 링크용)
  // - base가 "/{ctx}/api/ai-chat" 형태라고 가정하고 ctx를 만든다.
  // - 추천 카드 클릭 시 상세 페이지로 보내는 링크에 ctx를 붙이기 위함.
  // - 상세 페이지 URL 규칙이 바뀌면 여기와 appendRecommendations의 href만 보면 된다.
  // ---------------------------------------------------------
  var ctx = base.replace(/\/api\/ai-chat$/, '');

  // ---------------------------------------------------------
  // [4] 상태 플래그
  // - openedOnce : 패널을 처음 열 때만 /open 호출
  // - busy       : 요청 중 중복 호출 방지 + 입력/버튼 잠금
  // - hasRecs    : 추천 카드가 찍힌 이후에만 더추천 허용
  // ---------------------------------------------------------
  var openedOnce = false;
  var busy = false;
  var hasRecs = false;

  // ---------------------------------------------------------
  // [5] Quick chips
  // - label: 화면에 보이는 텍스트
  // - text : 서버로 넘길 실제 조건 문장(키워드)
  // - 이 배열만 바꾸면 칩 구성이 바뀐다.
  // ---------------------------------------------------------
  var QUICK_LIST = [
    { label: '판타지 성장', text: '판타지 성장 모험' },
    { label: '로맨스 학원', text: '로맨스 학원 설렘' },
    { label: '액션 복수', text: '액션 복수 통쾌함' },
    { label: '일상 힐링', text: '일상 힐링 잔잔함' },
    { label: '스릴러 추리', text: '스릴러 추리 반전' },
    { label: 'SF 모험', text: 'SF 모험 세계관' }
  ];

  // ---------------------------------------------------------
  // [UTIL] busy 토글
  // - true: 입력/버튼 비활성화 + quick 클릭도 막는다.
  // - panel aria-busy는 접근성(스크린리더)용 힌트.
  // - quick은 클래스 토글로 pointer-events를 막는 방식.
  // ---------------------------------------------------------
  function setBusy(v) {
    busy = !!v;

    if (panel) panel.setAttribute('aria-busy', busy ? 'true' : 'false');

    if (input) input.disabled = busy;
    if (sendBtn) sendBtn.disabled = busy;
    if (moreBtn) moreBtn.disabled = busy;
    if (changeBtn) changeBtn.disabled = busy;
    if (resetBtn) resetBtn.disabled = busy;

    if (quick) {
      if (busy) quick.classList.add('is-disabled');
      else quick.classList.remove('is-disabled');
    }
  }

  // ---------------------------------------------------------
  // [UTIL] JSON 파싱 안전 처리
  // - res.json()은 body가 비어있거나 JSON이 깨지면 예외가 날 수 있다.
  // - 여기서는 실패해도 null로 떨어뜨려 흐름이 죽지 않게 한다.
  // ---------------------------------------------------------
  function safeJson(res) {
    try {
      return res.json().catch(function () { return null; });
    } catch (e) {
      return Promise.resolve(null);
    }
  }

  // ---------------------------------------------------------
  // [UTIL] 서버 메시지 우선순위
  // - 서버 응답에 여러 키로 메시지가 올 수 있으니 우선순위를 정한다.
  // - errorMessage > message > error > fallback
  // ---------------------------------------------------------
  function pickServerMessage(data, fallback) {
    if (!data) return fallback;
    return data.errorMessage || data.message || data.error || fallback;
  }

  // ---------------------------------------------------------
  // [UTIL] 메시지 영역 스크롤을 항상 아래로 고정
  // - 새 메시지를 붙일 때마다 최신 메시지가 보이게 하는 용도.
  // ---------------------------------------------------------
  function scrollToBottom() {
    if (!messages) return;
    messages.scrollTop = messages.scrollHeight;
  }

  // ---------------------------------------------------------
  // [UTIL] 메시지 초기화(quick 영역 유지)
  // - /open이나 /reset에서 화면을 "깨끗하게" 만들 때 사용.
  // - quick chips 컨테이너(#chataiQuick)는 유지한다.
  // ---------------------------------------------------------
  function clearMessagesKeepQuick() {
    if (!messages) return;

    var children = messages.children;
    for (var i = children.length - 1; i >= 0; i--) {
      var node = children[i];
      if (quick && node === quick) continue;
      messages.removeChild(node);
    }
  }

  // ---------------------------------------------------------
  // [UTIL] 추천 후 액션바(더추천/조건바꾸기) 표시 제어
  // - 추천이 찍히기 전에는 숨겨두고, 추천 후에만 노출한다.
  // ---------------------------------------------------------
  function showActions() {
    if (actions) actions.hidden = false;
  }
  function hideActions() {
    if (actions) actions.hidden = true;
  }

  // ---------------------------------------------------------
  // [RENDER] 텍스트 말풍선
  // - who: "user" | "bot"
  // - textContent로 넣어서 HTML 주입(스크립트/태그) 위험을 막는다.
  // ---------------------------------------------------------
  function appendTextBubble(who, text) {
    if (!messages) return null;

    var row = document.createElement('div');
    row.className = 'chatai-msg chatai-msg-' + who;

    var bubble = document.createElement('div');
    bubble.className = 'chatai-bubble';
    bubble.textContent = text;

    row.appendChild(bubble);
    messages.appendChild(row);
    scrollToBottom();
    return row;
  }

  // ---------------------------------------------------------
  // [RENDER] 로딩 말풍선
  // - 서버 응답을 기다리는 동안 "진행 중" 느낌을 주기 위한 용도.
  // - 완료되면 removeRow로 삭제한다.
  // ---------------------------------------------------------
  function appendLoadingBubble(text) {
    if (!messages) return null;

    var row = document.createElement('div');
    row.className = 'chatai-msg chatai-msg-bot';

    var bubble = document.createElement('div');
    bubble.className = 'chatai-bubble';
    bubble.textContent = text;

    row.appendChild(bubble);
    messages.appendChild(row);
    scrollToBottom();
    return row;
  }

  // ---------------------------------------------------------
  // [UTIL] 특정 row 제거(있을 때만)
  // ---------------------------------------------------------
  function removeRow(row) {
    if (row && row.parentNode) row.parentNode.removeChild(row);
  }

  // ---------------------------------------------------------
  // [RENDER] quick chips 렌더
  // - open/reset 시 다시 렌더해서 버튼을 최신 상태로 맞춘다.
  // - 이벤트는 위임 방식이므로 여기서는 버튼만 만들어 끼운다.
  // ---------------------------------------------------------
  function renderQuickChips() {
    if (!quick) return;

    quick.innerHTML = '';

    for (var i = 0; i < QUICK_LIST.length; i++) {
      var item = QUICK_LIST[i];

      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'chatai-chip';
      btn.textContent = item.label;
      btn.setAttribute('data-text', item.text);

      quick.appendChild(btn);
    }
  }

  // ---------------------------------------------------------
  // [복원용 UTIL] 값이 배열이 아니면 빈 배열로 처리
  // - /open 응답이 null이거나 스키마가 조금 달라도 안전하게 굴리기 위함.
  // ---------------------------------------------------------
  function toArray(v) {
    return Array.isArray(v) ? v : [];
  }

  // ---------------------------------------------------------
  // [복원용 UTIL] chatHistory.role 정규화
  // - 백엔드에서 role이 "assistant" 같은 값으로 올 수 있으니
  //   프론트 렌더 규칙("bot"/"user")으로 맞춰준다.
  // ---------------------------------------------------------
  function normalizeHistoryRole(role) {
    var r = String(role || '').toLowerCase();

    if (r === 'user') return 'user';
    if (r === 'assistant') return 'bot';
    if (r === 'bot') return 'bot';
    if (r === 'system') return 'bot';

    // 모르는 값이면 안전하게 bot 처리
    return 'bot';
  }

  // ---------------------------------------------------------
  // [복원] chatHistory 말풍선 복원
  // - 기대 스키마: [{ role, content }, ...]
  // - 내용이 비어있는 항목은 스킵한다.
  // ---------------------------------------------------------
  function restoreChatHistoryBubbles(historyList) {
    var list = toArray(historyList);

    for (var i = 0; i < list.length; i++) {
      var item = list[i] || {};

      var text = (item.content == null) ? '' : String(item.content);
      text = text.replace(/\r\n/g, '\n').trim();

      if (!text) continue;

      appendTextBubble(normalizeHistoryRole(item.role), text);
    }
  }

  // ---------------------------------------------------------
  // [복원/초기 분기] /open 응답을 기반으로 화면을 다시 구성
  //
  // 기본 정책
  // 1) 메시지 영역을 비우고(quick 제외) quick chips를 다시 렌더한다.
  // 2) 복원 데이터(chatHistory / lastRecommendedAnimes)가 있으면 복원 렌더.
  // 3) 복원할 게 없으면 환영 메시지 기반 초기 UI 렌더.
  //
  // 이유
  // - 페이지 이동 시 프론트 DOM/JS 상태는 사라지는 게 정상.
  // - 서버 세션엔 대화/추천 상태가 남아 있을 수 있으니,
  //   /open 결과를 기준으로 화면을 다시 그려야 "이어하기"가 된다.
  // ---------------------------------------------------------
  function restoreOpenState(data) {
    clearMessagesKeepQuick();
    renderQuickChips();

    // 새로 그리는 시점엔 추천 상태도 기본값으로 돌려놓고,
    // 실제 추천 복원 데이터가 있으면 appendRecommendations에서 다시 켜진다.
    hasRecs = false;
    hideActions();

    // 서버가 입력 힌트를 주면 placeholder에 반영
    if (data && data.initialPrompt && input) {
      input.placeholder = data.initialPrompt;
    }

    var historyList = toArray(data && data.chatHistory);
    var lastRecs = toArray(data && data.lastRecommendedAnimes);

    // resumed 플래그가 없어도 history/recs가 있으면 복원으로 본다.
    var resumed = !!(data && data.resumed);
    var hasRestorableData = resumed || historyList.length > 0 || lastRecs.length > 0;

    if (hasRestorableData) {
      // 텍스트 히스토리 복원
      restoreChatHistoryBubbles(historyList);

      // 마지막 추천 카드 복원
      if (lastRecs.length > 0) {
        appendRecommendations(lastRecs);
      } else {
        hasRecs = false;
        hideActions();
      }

      // 복원 플래그만 있고 실제 데이터가 비어있는 예외 케이스는 환영 문구로 폴백
      if (historyList.length === 0 && lastRecs.length === 0) {
        appendTextBubble('bot', (data && data.welcomeMessage) ? data.welcomeMessage : '안녕하세요. 무엇을 도와드릴까요?');
      }

      return;
    }

    // 최초 진입(복원할 게 없음)
    appendTextBubble('bot', (data && data.welcomeMessage) ? data.welcomeMessage : '안녕하세요. 무엇을 도와드릴까요?');
  }

  // ---------------------------------------------------------
  // [RENDER] 추천 카드 렌더
  //
  // 기대 스키마
  // - animeId, title, thumbnailUrl
  // - genres(옵션), reason(옵션)
  //
  // 포인트
  // - animeId는 URL에 들어가므로 encodeURIComponent로 안전하게 처리한다.
  // - 텍스트들은 방어적으로 비어있어도 깨지지 않게 처리한다.
  // ---------------------------------------------------------
  function appendRecommendations(list) {
    if (!messages) return;

    var row = document.createElement('div');
    row.className = 'chatai-msg chatai-msg-bot';

    var bubble = document.createElement('div');
    bubble.className = 'chatai-bubble';

    var title = document.createElement('div');
    title.className = 'chatai-rec-title';
    title.textContent = '이런 작품을 추천해요';
    bubble.appendChild(title);

    var wrap = document.createElement('div');
    wrap.className = 'chatai-rec-list';

    for (var i = 0; i < list.length; i++) {
      var a = list[i] || {};

      var animeId = (a.animeId != null) ? a.animeId : '';
      var animeTitle = a.title ? a.title : '';
      var thumb = a.thumbnailUrl ? a.thumbnailUrl : '';
      var reasonText = a.reason ? a.reason : '';

      var genresText = '';
      if (a.genres && Array.isArray(a.genres)) {
        genresText = a.genres.join(' · ');
      }

      // 카드 전체를 링크로 구성해서 클릭 영역을 크게 만든다.
      var item = document.createElement('a');
      item.className = 'chatai-rec-item';
      item.href = ctx + '/animeDetail?animeId=' + encodeURIComponent(animeId);

      var img = document.createElement('img');
      img.className = 'chatai-rec-thumb';
      img.alt = animeTitle || 'anime';
      img.src = thumb || '';

      var meta = document.createElement('div');
      meta.className = 'chatai-rec-meta';

      var name = document.createElement('div');
      name.className = 'chatai-rec-name';
      name.textContent = animeTitle;
      meta.appendChild(name);

      if (genresText) {
        var genres = document.createElement('div');
        genres.className = 'chatai-rec-genres';
        genres.textContent = genresText;
        meta.appendChild(genres);
      }

      if (reasonText) {
        var reason = document.createElement('div');
        reason.className = 'chatai-rec-reason';
        reason.textContent = reasonText;
        meta.appendChild(reason);
      }

      item.appendChild(img);
      item.appendChild(meta);
      wrap.appendChild(item);
    }

    bubble.appendChild(wrap);
    row.appendChild(bubble);
    messages.appendChild(row);
    scrollToBottom();

    // 추천이 한 번이라도 찍혔으면 더추천 가능 상태로 전환
    hasRecs = true;

    // 추천 후에만 액션바 노출
    showActions();
  }

  // ---------------------------------------------------------
  // [UI] 패널 열기/닫기
  // - openPanel: is-open 클래스 + aria-hidden 갱신
  // - 열자마자 input에 포커스 준다.
  // - openedOnce=false일 때만 /open 호출(첫 오픈 1회만)
  // ---------------------------------------------------------
  function openPanel() {
    if (!panel) return;

    root.classList.add('is-open');
    panel.setAttribute('aria-hidden', 'false');

    setTimeout(function () {
      if (input) input.focus();
    }, 0);

    if (!openedOnce) {
      openedOnce = true;
      callOpen();
    }
  }

  function closePanel() {
    if (!panel) return;

    root.classList.remove('is-open');
    panel.setAttribute('aria-hidden', 'true');
  }

  function togglePanel() {
    if (root.classList.contains('is-open')) closePanel();
    else openPanel();
  }

  // ---------------------------------------------------------
  // [SEND] 공통 전송 함수
  // - 입력 전송/칩 클릭 전송 모두 여기로 모은다.
  // - busy 상태면 연타 방지 차단.
  // ---------------------------------------------------------
  function sendUserMessage(text) {
    var msg = String(text || '').trim();
    if (!msg) return;

    if (busy) return;

    appendTextBubble('user', msg);

    if (input) input.value = '';

    callMessage(msg);
  }

  // ---------------------------------------------------------
  // [API] /open
  // - 위젯 최초 오픈 시 1회 호출되는 흐름.
  // - 서버 세션 기준으로 "새 대화" 또는 "기존 대화 복원" 응답이 올 수 있다.
  // - 프론트는 restoreOpenState(data)로 화면을 다시 구성한다.
  //
  // 예외 처리
  // - base가 비어있으면 안내 메시지를 띄우고 openedOnce를 false로 되돌린다.
  //   -> 다음에 패널 열 때 다시 시도할 수 있게 하기 위함.
  // ---------------------------------------------------------
  function callOpen() {
    if (busy) return;

    if (!base) {
      appendTextBubble('bot', 'endpoint 설정이 없어서 실행할 수 없어요. data-endpoint를 확인해주세요.');
      openedOnce = false;
      return;
    }

    setBusy(true);

    fetch(base + '/open', {
      method: 'GET',
      credentials: 'same-origin'
    })
      .then(function (res) {
        return safeJson(res).then(function (data) {
          setBusy(false);

          if (!res.ok) {
            appendTextBubble('bot', pickServerMessage(data, '초기화/복원에 실패했어요. 잠시 후 다시 시도해주세요.'));
            openedOnce = false;
            return;
          }

          restoreOpenState(data);
        });
      })
      .catch(function () {
        setBusy(false);
        appendTextBubble('bot', '서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
        openedOnce = false;
      });
  }

  // ---------------------------------------------------------
  // [API] /message
  // - 사용자가 입력한 메시지를 서버로 전송하고 추천 리스트를 받아 렌더한다.
  // - 에러/추천없음/정상추천의 케이스를 분기 처리한다.
  // ---------------------------------------------------------
  function callMessage(userMessage) {
    if (busy) return;

    if (!base) {
      appendTextBubble('bot', 'endpoint 설정이 없어서 실행할 수 없어요. data-endpoint를 확인해주세요.');
      return;
    }

    var loadingRow = appendLoadingBubble('추천을 찾는 중이에요...');
    setBusy(true);

    fetch(base + '/message', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userMessage: userMessage })
    })
      .then(function (res) {
        return safeJson(res).then(function (data) {
          setBusy(false);
          removeRow(loadingRow);

          if (!res.ok) {
            appendTextBubble('bot', pickServerMessage(data, '요청 처리 중 문제가 발생했어요. 다시 시도해주세요.'));
            return;
          }

          if (data && data.errorMessage) {
            appendTextBubble('bot', data.errorMessage);
            return;
          }

          var list = (data && Array.isArray(data.recommendedAnimes)) ? data.recommendedAnimes : [];
          if (list.length === 0) {
            appendTextBubble('bot', '조건에 맞는 작품을 찾지 못했어요. 다른 키워드로 말해볼까요?');
            return;
          }

          appendRecommendations(list);
        });
      })
      .catch(function () {
        setBusy(false);
        removeRow(loadingRow);
        appendTextBubble('bot', '서버에 연결할 수 없어요. 잠시 후 다시 시도해주세요.');
      });
  }

  // ---------------------------------------------------------
  // [API] /reset
  // - 대화를 새로 시작한다.
  // - 체감 속도를 위해 UI는 먼저 초기화하고 서버 호출을 한다.
  // - 서버 응답이 오면 환영 문구/placeholder를 다시 세팅한다.
  // ---------------------------------------------------------
  function callReset() {
    if (busy) return;

    if (!base) {
      appendTextBubble('bot', 'endpoint 설정이 없어서 실행할 수 없어요. data-endpoint를 확인해주세요.');
      return;
    }

    setBusy(true);

    clearMessagesKeepQuick();
    renderQuickChips();

    hasRecs = false;
    hideActions();

    var loadingRow = appendLoadingBubble('새 대화를 준비 중이에요...');

    fetch(base + '/reset', {
      method: 'POST',
      credentials: 'same-origin'
    })
      .then(function (res) {
        return safeJson(res).then(function (data) {
          setBusy(false);
          removeRow(loadingRow);

          if (!res.ok) {
            appendTextBubble('bot', pickServerMessage(data, '새 대화 시작에 실패했어요. 잠시 후 다시 시도해주세요.'));
            return;
          }

          var welcome = (data && data.welcomeMessage) ? data.welcomeMessage : '안녕하세요. 무엇을 도와드릴까요?';
          appendTextBubble('bot', welcome);

          if (data && data.initialPrompt && input) {
            input.placeholder = data.initialPrompt;
          }
        });
      })
      .catch(function () {
        setBusy(false);
        removeRow(loadingRow);
        appendTextBubble('bot', '서버에 연결할 수 없어요. 잠시 후 다시 시도해주세요.');
      });
  }

  // ---------------------------------------------------------
  // [API] /more
  // - "추가 추천"만 수행한다.
  // - 추천을 한 번도 받은 적이 없으면(hasRecs=false) 서버 호출을 하지 않는다.
  // ---------------------------------------------------------
  function callMore() {
    if (busy) return;

    if (!hasRecs) {
      appendTextBubble('bot', '먼저 추천을 받아야 더 추천이 가능해요.');
      return;
    }

    if (!base) {
      appendTextBubble('bot', 'endpoint 설정이 없어서 실행할 수 없어요. data-endpoint를 확인해주세요.');
      return;
    }

    var loadingRow = appendLoadingBubble('추가 추천을 찾는 중이에요...');
    setBusy(true);

    fetch(base + '/more', {
      method: 'POST',
      credentials: 'same-origin'
    })
      .then(function (res) {
        return safeJson(res).then(function (data) {
          setBusy(false);
          removeRow(loadingRow);

          if (!res.ok) {
            appendTextBubble('bot', pickServerMessage(data, '추가 추천 요청에 실패했어요.'));
            return;
          }

          if (data && data.errorMessage) {
            appendTextBubble('bot', data.errorMessage);
            return;
          }

          var list = (data && Array.isArray(data.recommendedAnimes)) ? data.recommendedAnimes : [];
          if (list.length === 0) {
            appendTextBubble('bot', '추가 추천을 찾지 못했어요. 조건을 바꿔볼까요?');
            return;
          }

          appendRecommendations(list);
        });
      })
      .catch(function () {
        setBusy(false);
        removeRow(loadingRow);
        appendTextBubble('bot', '서버에 연결할 수 없어요. 잠시 후 다시 시도해주세요.');
      });
  }

  // ---------------------------------------------------------
  // [API] /change
  // - 현재 조건을 바꾸고 새 추천을 받는다.
  // - 버튼 클릭 시 input 값을 그대로 조건 문장으로 사용한다.
  // - 조건이 비어있으면 안내 후 종료한다.
  // ---------------------------------------------------------
  function callChange(newCondition) {
    var msg = String(newCondition || '').trim();

    if (!msg) {
      appendTextBubble('bot', '조건을 입력해줘!');
      return;
    }
    if (busy) return;

    if (!base) {
      appendTextBubble('bot', 'endpoint 설정이 없어서 실행할 수 없어요. data-endpoint를 확인해주세요.');
      return;
    }

    // 조건 변경도 대화 흐름상 "사용자 발화"로 남겨두는 게 자연스럽다.
    appendTextBubble('user', msg);
    if (input) input.value = '';

    var loadingRow = appendLoadingBubble('조건을 바꿔서 다시 찾는 중이에요...');
    setBusy(true);

    fetch(base + '/change', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userMessage: msg })
    })
      .then(function (res) {
        return safeJson(res).then(function (data) {
          setBusy(false);
          removeRow(loadingRow);

          if (!res.ok) {
            appendTextBubble('bot', pickServerMessage(data, '조건 변경 요청에 실패했어요.'));
            return;
          }

          if (data && data.errorMessage) {
            appendTextBubble('bot', data.errorMessage);
            return;
          }

          var list = (data && Array.isArray(data.recommendedAnimes)) ? data.recommendedAnimes : [];
          if (list.length === 0) {
            appendTextBubble('bot', '조건에 맞는 작품을 찾지 못했어요. 다른 키워드로 말해볼까요?');
            return;
          }

          appendRecommendations(list);
        });
      })
      .catch(function () {
        setBusy(false);
        removeRow(loadingRow);
        appendTextBubble('bot', '서버에 연결할 수 없어요. 잠시 후 다시 시도해주세요.');
      });
  }

  // ---------------------------------------------------------
  // [EVENT] 이벤트 바인딩
  // - FAB: 열기/닫기 토글
  // - X 버튼: 닫기
  // - reset/more/change: 각 API 호출
  // - ESC: 닫기
  // - 바깥 클릭: 닫기(패널 내부/버튼 클릭은 제외)
  // - form submit(엔터): 메시지 전송
  // - quick 영역: 이벤트 위임으로 칩 클릭 처리
  // ---------------------------------------------------------

  if (fab) fab.addEventListener('click', togglePanel);
  if (closeBtn) closeBtn.addEventListener('click', closePanel);

  if (resetBtn) resetBtn.addEventListener('click', function () {
    callReset();
  });

  if (moreBtn) moreBtn.addEventListener('click', function () {
    callMore();
  });

  if (changeBtn) changeBtn.addEventListener('click', function () {
    var text = (input && input.value ? input.value : '').trim();
    callChange(text);
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closePanel();
  });

  document.addEventListener('click', function (e) {
    if (!root.classList.contains('is-open')) return;
    if (panel && panel.contains(e.target)) return;
    if (fab && fab.contains(e.target)) return;
    closePanel();
  });

  if (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();

      if (busy) return;

      var text = (input && input.value ? input.value : '').trim();
      if (!text) return;

      sendUserMessage(text);
    });
  }

  if (quick) {
    quick.addEventListener('click', function (e) {
      var t = e.target;
      if (!t) return;

      if (busy) return;

      // quick 영역 안에서 칩 버튼만 반응하게 한다.
      if (t.className && String(t.className).indexOf('chatai-chip') === -1) return;

      var text = t.getAttribute('data-text') || '';
      text = String(text || '').trim();
      if (!text) return;

      sendUserMessage(text);
    });
  }
});