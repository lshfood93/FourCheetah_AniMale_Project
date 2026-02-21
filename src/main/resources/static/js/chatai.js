// /js/chatai.js
// =========================================================
// ChatAI Widget (Front, ES5 호환 최종본 + 상세 주석판)
// ---------------------------------------------------------
// 1) 목적
//   - 어떤 페이지에서든 우하단 FAB 클릭으로 AI 추천 위젯을 열고,
//     서버 세션 기반으로 추천 대화를 진행한다.
//
// 2) 전제
//   - JSP에 #chatai 루트가 존재해야 동작한다. (없으면 즉시 return)
//   - #chatai의 data-endpoint가 API base가 된다.
//     예) data-endpoint='/animale/api/ai-chat'
//     실제 호출 URL:
//       GET  base + '/open'
//       POST base + '/message' (body: { userMessage })
//       POST base + '/reset'
//       POST base + '/more'
//       POST base + '/change'  (body: { userMessage })
//
// 3) 핵심 상태(3개)
//   - openedOnce : 위젯을 '처음 열었을 때만' /open을 호출하기 위한 플래그
//                 (닫았다 다시 열어도 open 재호출 안함, reset은 별도 버튼으로)
//   - busy       : 요청 진행 중 중복 요청 방지(버튼/엔터/칩 클릭 전부 차단)
//   - hasRecs    : 추천 카드가 한번이라도 출력된 이후에만 '더 추천' 가능
//
// 4) UX 정책
//   - busy=true 동안: 입력/전송/더추천/조건바꾸기/리셋/칩 모두 비활성화
//   - 추천이 없는 상태에서 더추천을 누르면: 안내 메시지 출력 후 종료
//   - 서버에서 errorMessage를 주면: 그 문구를 최우선으로 출력
//
// 5) 보안/세션
//   - credentials: 'same-origin' 사용
//     -> 쿠키 기반 세션을 동일 오리진에서만 자동 포함
//
// 6) 커스터마이징 포인트
//   - QUICK_LIST : 칩 목록만 바꾸면 추천 예시가 바뀜
//   - ctx 계산  : 추천 카드 링크 경로가 바뀌면 ctx 생성 규칙 수정
// =========================================================

document.addEventListener('DOMContentLoaded', function () {
  // =========================================================
  // [0] 루트 가드
  // - 페이지에 위젯이 포함되지 않았으면 아무것도 하지 않는다.
  // =========================================================
  var root = document.getElementById('chatai');
  if (!root) return;

  // =========================================================
  // [1] DOM 캐시
  // - 반복 접근하는 요소를 변수로 잡아 성능/가독성 확보
  // =========================================================
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

  // =========================================================
  // [2] API endpoint(base) 설정
  // - JSP에서 data-endpoint를 주입한다.
  // - 끝에 '/'가 붙어도 동일하게 동작하도록 제거한다.
  //
  // 주의:
  // - base가 비어있으면 위젯 UI는 열리지만 서버 호출은 불가
  // - 이 경우 callOpen/callMessage 등에서 친절한 안내 메시지를 출력한다.
  // =========================================================
  var base = '';
  if (root.dataset && root.dataset.endpoint) base = root.dataset.endpoint;
  base = String(base || '').replace(/\/$/, '');

  // =========================================================
  // [3] ctx 계산(추천 카드 링크 생성용)
  // - base = '/{ctx}/api/ai-chat' 라고 가정하고 ctx를 만든다.
  // - 추천 카드 링크는 ctx + '/animeDetail?animeId=...'
  //
  // 만약 너 프로젝트에서 상세 페이지가 다른 경로라면
  // 여기 규칙을 1번만 바꾸면 카드 링크 전체가 바뀐다.
  // =========================================================
  var ctx = base.replace(/\/api\/ai-chat$/, '');

  // =========================================================
  // [4] 상태 플래그
  // =========================================================
  var openedOnce = false; // 최초 open 1회 제어
  var busy = false;       // 요청 중 UI 잠금
  var hasRecs = false;    // 추천 이후 더추천 가능 여부

  // =========================================================
  // [5] Quick chips 목록
  // - label: 버튼에 보이는 텍스트
  // - text : 서버로 전달될 userMessage(실제 추천 조건)
  // =========================================================
  var QUICK_LIST = [
    { label: '판타지 성장', text: '판타지 성장 모험' },
    { label: '로맨스 학원', text: '로맨스 학원 설렘' },
    { label: '액션 복수', text: '액션 복수 통쾌함' },
    { label: '일상 힐링', text: '일상 힐링 잔잔함' },
    { label: '스릴러 추리', text: '스릴러 추리 반전' },
    { label: 'SF 모험', text: 'SF 모험 세계관' }
  ];

  // =========================================================
  // [UTIL] busy 상태 처리
  // - busy=true : 중복 요청 방지 + UX 일관성(여러번 클릭/엔터 방지)
  // - panel aria-busy는 접근성 힌트(스크린리더)
  // - quick chips는 CSS 클래스 토글로 pointer-events 차단
  // =========================================================
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

  // =========================================================
  // [UTIL] 안전한 JSON 파싱
  // - res.json()은 body가 비었거나 JSON이 깨지면 throw/catch가 필요하다.
  // - 이 함수는 실패해도 null로 떨어져서 이후 흐름이 죽지 않게 한다.
  // =========================================================
  function safeJson(res) {
    try {
      return res.json().catch(function () { return null; });
    } catch (e) {
      return Promise.resolve(null);
    }
  }

  // =========================================================
  // [UTIL] 서버 메시지 우선순위
  // - 서버가 errorMessage / message / error 를 내려줄 수 있으니
  //   가장 적절한 문구를 골라 출력한다.
  // =========================================================
  function pickServerMessage(data, fallback) {
    if (!data) return fallback;
    return data.errorMessage || data.message || data.error || fallback;
  }

  // =========================================================
  // [UTIL] 스크롤 최하단 고정
  // - 메시지 추가 시 항상 최신 메시지가 보이도록 한다.
  // =========================================================
  function scrollToBottom() {
    if (!messages) return;
    messages.scrollTop = messages.scrollHeight;
  }

  // =========================================================
  // [UTIL] 메시지 초기화(quick 영역 유지)
  // - reset/open 때 메시지들을 싹 비우지만,
  //   quick chips 컨테이너(#chataiQuick)는 유지한다.
  // =========================================================
  function clearMessagesKeepQuick() {
    if (!messages) return;

    var children = messages.children;
    for (var i = children.length - 1; i >= 0; i--) {
      var node = children[i];
      if (quick && node === quick) continue;
      messages.removeChild(node);
    }
  }

  // =========================================================
  // [UTIL] 추천 이후 액션바 표시 제어
  // - 기본은 hidden=true
  // - 추천 카드가 출력된 이후에만 showActions()
  // =========================================================
  function showActions() {
    if (actions) actions.hidden = false;
  }
  function hideActions() {
    if (actions) actions.hidden = true;
  }

  // =========================================================
  // [RENDER] 말풍선 추가 (텍스트)
  // who: 'user' | 'bot'
  // - DOM 생성 → messages에 append → 스크롤 최하단
  // =========================================================
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

  // =========================================================
  // [RENDER] 로딩 버블
  // - 서버 응답 전까지 유저에게 진행중임을 보여준다.
  // - 완료 시 removeRow로 삭제한다.
  // =========================================================
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

  // DOM row 제거(있으면)
  function removeRow(row) {
    if (row && row.parentNode) row.parentNode.removeChild(row);
  }

  // =========================================================
  // [RENDER] quick chips 렌더
  // - open/reset 시 호출
  // - QUICK_LIST만 수정하면 칩 세트가 바뀐다.
  // =========================================================
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
  
  // =========================================================
  // ✅ [추가] 서버 /open 응답 복원 유틸
  // ---------------------------------------------------------
  // 목적:
  // - open 응답이 "새 대화"인지 "기존 대화 복원"인지 판별
  // - chatHistory / lastRecommendedAnimes 를 화면에 재렌더
  //
  // 왜 필요한가?
  // - 페이지 이동 시 JS 메모리 상태/DOM은 사라진다(정상)
  // - 하지만 서버 세션에는 대화 상태가 남아 있을 수 있으므로
  //   /open 응답을 기반으로 화면을 다시 그려야 한다.
  // =========================================================

  // ✅ 안전한 배열 변환
  // - null/undefined/배열 아닌 값이 와도 빈 배열로 처리
  function toArray(v) {
    return Array.isArray(v) ? v : [];
  }

  // ✅ 히스토리 role 정규화
  // - 백엔드 ChatMessage.role이 'assistant'일 수 있으므로
  //   프론트 appendTextBubble('bot'|'user') 규칙으로 매핑한다.
  function normalizeHistoryRole(role) {
    var r = String(role || '').toLowerCase();

    if (r === 'user') return 'user';
    if (r === 'assistant') return 'bot';
    if (r === 'bot') return 'bot';
    if (r === 'system') return 'bot';

    // 알 수 없는 role은 bot으로 처리(안전 폴백)
    return 'bot';
  }

  // ✅ chatHistory 말풍선 복원
  // 기대 스키마:
  //   [{ role: 'user'|'assistant', content: '...' }, ...]
  function restoreChatHistoryBubbles(historyList) {
    var list = toArray(historyList);

    for (var i = 0; i < list.length; i++) {
      var item = list[i] || {};

      var text = (item.content == null) ? '' : String(item.content);
      text = text.replace(/\r\n/g, '\n').trim();

      // 내용 없는 히스토리 항목은 스킵
      if (!text) continue;

      appendTextBubble(normalizeHistoryRole(item.role), text);
    }
  }

  // ✅ /open 응답 기반 화면 구성 (초기/복원 분기)
  // ---------------------------------------------------------
  // 정책:
  // 1) 항상 메시지 영역을 정리하고 quick chips는 다시 렌더
  // 2) 복원 가능한 데이터가 있으면(chatHistory/lastRecommendedAnimes)
  //    -> 복원 렌더
  // 3) 아니면 기존처럼 환영 메시지 기반 초기 UI 렌더
  //
  // 참고:
  // - resumed=true 가 기본 신호이지만,
  //   방어적으로 history/recs 존재 여부도 함께 본다.
  // =========================================================
  function restoreOpenState(data) {
    // 1) 기본 UI 골격 재정리(중복 append 방지)
    clearMessagesKeepQuick();
    renderQuickChips();

    // 2) 추천 관련 상태 초기화(복원하면서 다시 세팅될 수 있음)
    hasRecs = false;
    hideActions();

    // 3) placeholder 갱신(서버가 내려주면 반영)
    if (data && data.initialPrompt && input) {
      input.placeholder = data.initialPrompt;
    }

    // 4) 복원 데이터 추출(방어적으로 배열 처리)
    var historyList = toArray(data && data.chatHistory);
    var lastRecs = toArray(data && data.lastRecommendedAnimes);

    // resumed=true 뿐 아니라 실제 복원 가능한 데이터 존재 여부도 함께 판단
    var resumed = !!(data && data.resumed);
    var hasRestorableData = resumed || historyList.length > 0 || lastRecs.length > 0;

    // 5) 복원 분기
    if (hasRestorableData) {
      // (a) 텍스트 히스토리 복원
      restoreChatHistoryBubbles(historyList);

      // (b) 마지막 추천 카드 1세트 복원
      //     appendRecommendations 내부에서:
      //     - hasRecs = true
      //     - showActions()
      //     처리됨
      if (lastRecs.length > 0) {
        appendRecommendations(lastRecs);
      } else {
        // 추천 복원 데이터가 없으면 더추천 버튼은 숨김 유지
        hasRecs = false;
        hideActions();
      }

      // (c) 복원 데이터가 매우 비어있는 예외 케이스 폴백
      if (historyList.length === 0 && lastRecs.length === 0) {
        appendTextBubble('bot', (data && data.welcomeMessage) ? data.welcomeMessage : '안녕하세요. 무엇을 도와드릴까요?');
      }

      return;
    }

    // 6) 초기 진입 분기(기존 동작)
    appendTextBubble('bot', (data && data.welcomeMessage) ? data.welcomeMessage : '안녕하세요. 무엇을 도와드릴까요?');
  }

  // =========================================================
  // [RENDER] 추천 카드 렌더
  // list 아이템 기대 스키마:
  //   {
  //     animeId: number|string,
  //     title: string,
  //     thumbnailUrl: string,
  //     genres: string[],   (optional)
  //     reason: string      (optional)
  //   }
  //
  // 주의:
  // - animeId는 링크에 들어가므로 encodeURIComponent 처리한다.
  // - title/genres/reason은 없을 수 있으니 방어적으로 처리한다.
  // =========================================================
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

      // 카드 전체가 링크가 되도록 <a>로 구성
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

    // 상태 전이:
    // - 추천 카드가 한번이라도 찍히면 hasRecs=true (더 추천 허용)
    hasRecs = true;

    // 추천 이후에만 액션바 표시
    showActions();
  }

  // =========================================================
  // [UI] 패널 열기/닫기
  // - openPanel: .is-open 클래스 + aria-hidden 갱신
  // - openedOnce=false일 때만 callOpen()
  // =========================================================
  function openPanel() {
    if (!panel) return;

    root.classList.add('is-open');
    panel.setAttribute('aria-hidden', 'false');

    // UX: 열리자마자 입력 포커스
    setTimeout(function () {
      if (input) input.focus();
    }, 0);

    // 최초 1회만 open 호출
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

  // =========================================================
  // [SEND] 공통 전송 함수
  // - 입력/칩/조건바꾸기 흐름에서 재사용한다.
  // - busy이면 즉시 return 해서 중복 요청 방지
  // =========================================================
  function sendUserMessage(text) {
    var msg = String(text || '').trim();
    if (!msg) return;

    // 중복/연타 방지
    if (busy) return;

    // UI에 사용자 메시지 출력
    appendTextBubble('user', msg);

    // 입력창 비우기
    if (input) input.value = '';

    // 서버 요청
    callMessage(msg);
  }

  // =========================================================
  // [API] /open
  // GET base + '/open'
  // 기대 응답:
  //   {
  //     welcomeMessage: string (optional),
  //     initialPrompt: string (optional)
  //   }
  //
  // 역할:
  // - 서버 세션에서 대화 초기화/환영 메시지/힌트 제공
  // - 프론트는 quick chips 렌더 + hasRecs false + actions hidden으로 초기 상태 정리
  // =========================================================
  // =========================================================
  // ✅ [교체] [API] /open
  // GET base + '/open'
  // 기대 응답(복원 대응):
  //   {
  //     welcomeMessage: string (optional),
  //     initialPrompt: string (optional),
  //     resumed: boolean (optional),
  //     chatHistory: array (optional),
  //     moreCount: number (optional),
  //     lastRecommendedAnimes: array (optional)
  //   }
  //
  // 역할(변경점):
  // - 기존: 항상 초기 UI 렌더
  // - 변경: 서버 응답 기준으로 "초기/복원" 분기 렌더
  // =========================================================
  function callOpen() {
    if (busy) return;

    if (!base) {
      appendTextBubble('bot', 'endpoint 설정이 없어서 실행할 수 없어요. data-endpoint를 확인해주세요.');
      // open이 실패했으니 다음에 패널 열 때 재시도 가능하게 롤백
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

          // HTTP 실패(4xx/5xx) 처리
          if (!res.ok) {
            appendTextBubble('bot', pickServerMessage(data, '초기화/복원에 실패했어요. 잠시 후 다시 시도해주세요.'));
            openedOnce = false;
            return;
          }

          // ✅ [핵심 변경]
          // /open 응답을 기반으로 "초기 진입" 또는 "복원 렌더"를 수행한다.
          restoreOpenState(data);
        });
      })
      .catch(function () {
        setBusy(false);
        appendTextBubble('bot', '서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
        openedOnce = false;
      });
  }

  // =========================================================
  // [API] /message
  // POST base + '/message'
  // body: { userMessage: string }
  // 기대 응답:
  //   {
  //     recommendedAnimes: array (optional),
  //     errorMessage: string (optional)
  //   }
  //
  // 역할:
  // - 유저 메시지를 서버로 보내고 추천 리스트를 받아 렌더링한다.
  // - 추천이 없으면 안내 문구 출력
  // =========================================================
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

          // 서버가 논리 에러를 errorMessage로 내려주는 경우
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

  // =========================================================
  // [API] /reset
  // POST base + '/reset'
  // 기대 응답:
  //   { welcomeMessage?, initialPrompt? }
  //
  // 역할:
  // - 대화를 새로 시작한다.
  // - UI는 즉시 초기화(사용자 체감 빠르게)
  // - 서버 응답 후 환영 문구를 다시 출력
  // =========================================================
  function callReset() {
    if (busy) return;

    if (!base) {
      appendTextBubble('bot', 'endpoint 설정이 없어서 실행할 수 없어요. data-endpoint를 확인해주세요.');
      return;
    }

    setBusy(true);

    // 즉시 UI 초기화
    clearMessagesKeepQuick();
    renderQuickChips();

    // 추천 상태 초기화
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

  // =========================================================
  // [API] /more
  // POST base + '/more'
  // 기대 응답:
  //   { recommendedAnimes?, errorMessage? }
  //
  // 역할:
  // - '추가 추천'만 수행한다.
  // - 단, 추천을 받은 적이 없으면(hasRecs=false) 호출하지 않는다.
  // =========================================================
  function callMore() {
    if (busy) return;

    // 더추천 가드: 추천을 한번도 안 받았으면 의미가 없다.
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

  // =========================================================
  // [API] /change
  // POST base + '/change'
  // body: { userMessage: string }   // 새 조건 문장
  // 기대 응답:
  //   { recommendedAnimes?, errorMessage? }
  //
  // 역할:
  // - 기존 추천 조건을 바꾸고 새 추천을 받는다.
  // - '조건 바꾸기' 버튼은 현재 input 값을 사용한다.
  // - msg가 비면 안내 후 종료한다.
  // =========================================================
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

    // 사용자 메시지로도 남겨서 대화 맥락이 유지되게 한다.
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

  // =========================================================
  // [EVENT] 이벤트 연결
  // - 클릭/ESC/바깥 클릭/폼 submit/칩 클릭 위임
  // =========================================================

  if (fab) fab.addEventListener('click', togglePanel);
  if (closeBtn) closeBtn.addEventListener('click', closePanel);

  // reset은 openedOnce와 무관하게 언제든 가능
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

  // ESC 닫기
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closePanel();
  });

  // 패널 외부 클릭 닫기
  document.addEventListener('click', function (e) {
    if (!root.classList.contains('is-open')) return;
    if (panel && panel.contains(e.target)) return;
    if (fab && fab.contains(e.target)) return;
    closePanel();
  });

  // 엔터 전송(폼 submit)
  if (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();

      // busy면 submit 이벤트가 와도 전송 차단
      if (busy) return;

      var text = (input && input.value ? input.value : '').trim();
      if (!text) return;

      sendUserMessage(text);
    });
  }

  // 칩 클릭 위임
  if (quick) {
    quick.addEventListener('click', function (e) {
      var t = e.target;
      if (!t) return;

      // busy 중이면 칩 클릭 무시
      if (busy) return;

      // 칩 버튼이 아닌 요소 클릭 방지
      if (t.className && String(t.className).indexOf('chatai-chip') === -1) return;

      var text = t.getAttribute('data-text') || '';
      text = String(text || '').trim();
      if (!text) return;

      sendUserMessage(text);
    });
  }
});
