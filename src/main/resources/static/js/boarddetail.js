// /js/boarddetail.js
// =========================================================
// Board Detail Page Script - 주석 강화 최종본(ES5 + fetch)
// ---------------------------------------------------------
// 이 파일이 담당하는 것(기능별 책임 분리 기준)
//
// 1) 게시글 본문(CKEditor) 보정
//    - CKEditor가 만든 img/iframe/video/src 경로가 상대경로로 들어오면
//      ctx를 붙여서 정상 노출되게 보정한다.
//
// 2) 좋아요
//    - 좋아요 토글: /BoardLikeToggle (POST)
//    - 좋아요 누른 사람: /LikeMemberList (GET)
//
// 3) 댓글
//    - 댓글 목록 정렬 조회: /ReplyListOrder (GET)
//    - 댓글 작성/수정/삭제: /replyWrite /replyEdit /replyDelete (POST)
//    - 댓글 렌더링 시: 프로필 이미지/닉네임/색상/데코 클래스까지 반영
//
// 4) 신고
//    - 신고 모달 + 신고 접수: /boardReport (POST)
//
// 5) ✅ 제재회원 정책(핵심)
//    - 댓글 작성/수정/삭제 금지
//    - 게시글 수정/삭제 금지
//    - UI에서 숨겨도, 혹시 버튼이 노출되는 예외를 대비해서
//      클릭/submit을 capture 단계에서 차단한다(2중 안전장치).
// =========================================================
(function () {
  'use strict';

  // =========================================================
  // JSP에서 내려온 전역 변수(필수 계약)
  // ---------------------------------------------------------
  // const ctx = '...';
  // const boardId = 123;
  // const isLogin = true/false;
  // const sessionMemberId = '...';
  // const sessionMemberRole = 'ADMIN' or '';
  // const isReported = true/false;
  // const isBanned = true/false;
  // =========================================================

  // =========================================================
  // API 매핑(라우트 한 곳에서 관리)
  // ---------------------------------------------------------
  // 장점:
  // - 엔드포인트 바뀌어도 여기만 수정하면 됨
  // - 기능별로 어떤 API를 쓰는지 한눈에 보임
  // =========================================================
  var API = {
    likeToggle: ctx + '/BoardLikeToggle',     // POST {boardId} -> JSON {result, isLiked, likeCnt, msg}
    likeMembers: ctx + '/LikeMemberList',     // GET  ?boardId= -> JSON {ok, users:[...], message}
    replyOrder: ctx + '/ReplyListOrder',      // GET  ?boardId=&condition= -> JSON Array
    replyWrite: ctx + '/replyWrite',          // POST {boardId, replyContent}
    replyEdit: ctx + '/replyEdit',            // POST {boardId, replyId, replyContent}
    replyDelete: ctx + '/replyDelete',        // POST {boardId, replyId}
    boardReport: ctx + '/boardReport'         // POST {boardId, reportReason, reportContent}
  };

  // =========================================================
  // DOM 캐시(자주 쓰는 요소는 한 번만 찾기)
  // =========================================================
  var $replyList = document.getElementById('replyList');
  var $replyEmpty = document.getElementById('replyEmpty');
  var $replyCount = document.getElementById('replyCount');
  var $replyForm = document.getElementById('replyForm');
  var $replyContent = document.getElementById('replyContent');
  var $replyBoardId = document.getElementById('replyBoardId');

  var $btnLike = document.getElementById('btnLike');
  var $likePill = document.getElementById('likePill');
  var $likeCount = document.getElementById('likeCount');

  var $replySort = document.getElementById('replySort');
  var CONDITION_RECENT = 'REPLY_LIST_RECENT';
  var CONDITION_OLDEST = 'REPLY_LIST_OLDEST';

  var $btnReport = document.getElementById('btnReport');
  var $btnReportSubmit = document.getElementById('btnReportSubmit');
  var $reportReason = document.getElementById('reportReason');
  var $reportContent = document.getElementById('reportContent');

  // =========================================================
  // ✅ 제재회원 공통 안내(메시지 통일)
  // =========================================================
  function alertBanned(actionText) {
    alert('제재회원은 ' + (actionText || '해당 기능') + '이(가) 제한됩니다.');
  }

  // =========================================================
  // Utils - XSS/표시 안정화/값 정규화
  // =========================================================

  // 문자열을 안전한 HTML로(댓글/닉네임/사유 등 출력 시 필수)
  function escapeHtml(v) {
    var s = (v === null || v === undefined) ? '' : String(v);
    return s
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  // 댓글 본문 줄바꿈 유지(텍스트 -> HTML)
  function nl2br(v) {
    return escapeHtml(v).replace(/\r?\n/g, '<br/>');
  }

  // 닉네임/프로필 컬러는 CSS 인젝션 방지용으로 허용 패턴만 통과
  function sanitizeColor(v) {
    if (!v) return '';
    var s = String(v).trim();

    // #RGB / #RRGGBB / #RRGGBBAA
    if (/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(s)) return s;

    // rgb()/rgba()/hsl()/hsla()
    if (/^(rgb|rgba|hsl|hsla)\(\s*[-0-9.,% ]+\s*\)$/.test(s)) return s;

    // color keyword(예: red, blue)
    if (/^[a-zA-Z]+$/.test(s)) return s;

    return '';
  }

  // 프로필 이미지 src를 ctx 기준으로 절대화
  function normalizeUrl(src) {
    if (!src) return '';
    var s = String(src).trim();
    if (!s) return '';

    // 이미 절대/데이터/blob면 그대로
    if (/^(https?:|data:|blob:)/i.test(s)) return s;

    // 이미 ctx로 시작하면 그대로
    if (ctx && s.indexOf(ctx + '/') === 0) return s;

    // /로 시작하면 ctx + '/...'
    if (s.charAt(0) === '/') return ctx + s;

    // 그 외는 ctx + '/...'
    return ctx + '/' + s;
  }

  function setReplyCount(n) {
    if ($replyCount) $replyCount.textContent = String(n);
  }

  function showReplyEmpty(show) {
    if (!$replyEmpty) return;
    $replyEmpty.style.display = show ? 'block' : 'none';
  }

  // 댓글 리스트를 다시 그릴 때 기존 reply-item만 싹 제거(Empty 영역은 유지)
  function removeAllReplyItems() {
    if (!$replyList) return;
    var items = $replyList.querySelectorAll('.reply-item');
    for (var i = 0; i < items.length; i++) {
      items[i].parentNode.removeChild(items[i]);
    }
  }

  // 댓글 수정 가능: 로그인 + 본인 댓글 + (제재 아님)
  function canEditReply(r) {
    if (!isLogin) return false;
    if (typeof isBanned !== 'undefined' && isBanned) return false;
    return String(r.memberId) === String(sessionMemberId);
  }

  // 댓글 삭제 가능: 로그인 + (본인 댓글 or ADMIN) + (제재 아님)
  function canDeleteReply(r) {
    if (!isLogin) return false;
    if (typeof isBanned !== 'undefined' && isBanned) return false;
    if (String(r.memberId) === String(sessionMemberId)) return true;
    return String(sessionMemberRole) === 'ADMIN';
  }

  // 서버에서 boolean을 1/'1'/'true' 등으로 내려주는 경우를 흡수
  function isTruthy(v) {
    return v === true || v === 1 || v === '1' || v === 'true';
  }

  // =========================================================
  // CKEditor src 경로 보정
  // ---------------------------------------------------------
  // CKEditor 내용에 img/video/iframe 등이 상대경로로 들어오면
  // 배포 환경에서 깨지는 일이 많아서 ctx를 붙여주는 보정 루틴
  // =========================================================
  function normalizeEditorMediaUrls() {
    var root = (typeof ctx === 'string') ? ctx : '';
    var nodes = document.querySelectorAll('.bd-content img, .bd-content iframe, .bd-content video, .bd-content source');

    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      var src = el.getAttribute('src');
      if (!src) continue;

      // 절대/데이터/blob면 보정 불필요
      if (/^(https?:|data:|blob:)/i.test(src)) continue;

      // 이미 ctx 포함이면 보정 불필요
      if (root && src.indexOf(root + '/') === 0) continue;

      // '/uploads/..' 같은 절대경로면 ctx+src, 아니면 ctx+'/'+src
      if (src.charAt(0) === '/') el.setAttribute('src', root + src);
      else el.setAttribute('src', root + '/' + src);
    }
  }

  // =========================================================
  // HTTP 래퍼(fetch)
  // ---------------------------------------------------------
  // ✅ 세션 쿠키 안정성 위해 credentials: 'same-origin' 명시
  // (브라우저마다 기본값이 같아도, 의도를 코드에 박아두는 게 안전)
  // =========================================================
  function httpGetJson(url) {
    return fetch(url, { method: 'GET', credentials: 'same-origin' }) // ✅
      .then(function (res) {
        if (!res.ok) throw new Error('GET failed: ' + res.status);
        return res.json();
      });
  }

  function httpPostForm(url, formData) {
    return fetch(url, { method: 'POST', body: formData, credentials: 'same-origin' }) // ✅
      .then(function (res) {
        if (!res.ok) throw new Error('POST failed: ' + res.status);
        return res;
      });
  }

  // =========================================================
  // Like - UI 갱신/토글/목록
  // =========================================================

  // 좋아요 UI를 한 함수로 통일(텍스트/클래스/카운트 동기화)
  function setLikeUI(liked, likeCnt) {
    if ($likePill) $likePill.classList.toggle('is-liked', !!liked);

    if ($btnLike) {
      $btnLike.textContent = liked ? '좋아요 취소' : '좋아요';
      $btnLike.setAttribute('data-liked', liked ? '1' : '0');
    }

    if ($likeCount && likeCnt !== undefined && likeCnt !== null) {
      $likeCount.textContent = String(likeCnt);
    }
  }

  // 초기 liked 상태는 JSP data-liked에 들어있음
  function initLike() {
    if (!$btnLike) return;

    var raw = $btnLike.getAttribute('data-liked');
    if (raw === '1') setLikeUI(true);

    $btnLike.addEventListener('click', function () {
      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }

      var bid = $btnLike.getAttribute('data-board-id') || boardId;

      var fd = new FormData();
      fd.append('boardId', bid);

      httpPostForm(API.likeToggle, fd)
        .then(function (res) { return res.json(); })
        .then(function (json) {
          // 서버 응답 계약이 깨졌을 때 대비(방어)
          if (!json || json.result !== 'OK') {
            alert((json && json.msg) ? json.msg : '처리에 실패했습니다.');
            return;
          }

          var liked = (Number(json.isLiked) === 1);
          var likeCnt = (json.likeCnt != null ? json.likeCnt : 0);

          setLikeUI(liked, likeCnt);
        })
        .catch(function (e) {
          console.error(e);
          alert('서버 통신 오류가 발생했습니다.');
        });
    });
  }

  // 좋아요 누른 사람 목록(간단히 alert로 표시)
  function initLikeUsers() {
    var btn = document.getElementById('btnLikeUsers');
    if (!btn) return;

    btn.addEventListener('click', function () {
      var url = API.likeMembers + '?boardId=' + encodeURIComponent(boardId);

      httpGetJson(url)
        .then(function (json) {
          if (!json || json.ok === false) {
            alert((json && json.message) ? json.message : '목록을 불러오지 못했습니다.');
            return;
          }

          var users = json.users || [];
          if (!users.length) {
            alert('아직 좋아요를 누른 사용자가 없습니다.');
            return;
          }

          var names = [];
          for (var i = 0; i < users.length; i++) {
            names.push(users[i].memberNickname || users[i].nickname || 'unknown');
          }

          alert(names.join('\n'));
        })
        .catch(function (e) {
          console.error(e);
          alert('서버 통신 오류가 발생했습니다.');
        });
    });
  }

  // =========================================================
  // Replies - 조회/렌더/작성/수정/삭제
  // =========================================================

  // 현재 정렬 조건(셀렉트가 없거나 이상값이면 최신순으로 폴백)
  function getSelectedCondition() {
    if (!$replySort) return CONDITION_RECENT;
    var v = ($replySort.value || '').trim();
    return (v === CONDITION_OLDEST) ? CONDITION_OLDEST : CONDITION_RECENT;
  }

  // 댓글 1개를 HTML 문자열로 렌더링
  // 서버가 내려주는 필드가 케이스별로 다를 수 있어서 폴백을 촘촘히 둠
  function renderReplyItem(r) {
    // 작성자 표시(닉네임 없으면 id)
    var nickname = (r.writerNickname && String(r.writerNickname).trim() !== '')
      ? r.writerNickname
      : r.memberId;

    // 프로필 이미지 필드 명이 여러 케이스일 수 있어서 다 흡수
    var profileImgRaw = r.writerProfileImage || r.writerProfileImg || r.writer_profile_image || '';
    var profileImg = normalizeUrl(profileImgRaw);

    // 꾸미기(닉색/프사테두리/데코클래스)
    var nickColor = sanitizeColor(r.writerNicknameColor || r.writer_nickname_color || '');
    var profileColor = sanitizeColor(r.writerProfileColor || r.writer_profile_color || '');
    var decoClass = (r.writerDecoClass || r.writer_deco_class || '').trim();

    // 프로필 테두리/글로우(색이 있을 때만)
    var avatarFx = '';
    if (profileColor) {
      avatarFx =
        'border-color:' + escapeHtml(profileColor) + ';' +
        'box-shadow:0 0 0 3px rgba(255,255,255,0.06), 0 0 18px ' + escapeHtml(profileColor) + ';';
    }

    // 프로필 이미지가 있으면 img, 없으면 이니셜 fallback
    var avatarHtml = '';
    if (profileImg) {
      avatarHtml =
        "<img class='reply-avatar' style='" + avatarFx + "' src='" + escapeHtml(profileImg) + "' alt='profile'/>";
    } else {
      var initial = String(nickname).charAt(0);
      var bg = profileColor ? ('background:' + escapeHtml(profileColor) + ';') : 'background:rgba(255,255,255,0.10);';
      avatarHtml =
        "<div class='reply-avatar' style='width:32px;height:32px;border-radius:50%;display:flex;align-items:center;justify-content:center;" +
        bg + "border:1px solid rgba(255,255,255,0.12);font-weight:900;" + avatarFx + "'>" +
        escapeHtml(initial) +
        "</div>";
    }

    var nickStyleAttr = nickColor ? (" style='color:" + escapeHtml(nickColor) + ";'") : '';

    // ✅ 제재회원이면 actions(수정/삭제 버튼) 자체를 렌더링하지 않음
    // (UI 1차 차단 + JS 클릭 차단이 2차)
    var actions = '';
    if (!(typeof isBanned !== 'undefined' && isBanned) && (canEditReply(r) || canDeleteReply(r))) {
      actions += "<div class='reply-actions'>";
      if (canEditReply(r)) actions += "<button type='button' class='btn-reply-edit'>수정</button>";
      if (canDeleteReply(r)) actions += "<button type='button' class='btn-reply-del'>삭제</button>";
      actions += "</div>";
    }

    // 수정 여부 판단(필드가 없으면 created/updated 비교로 폴백)
    var edited = isTruthy(r.isEdited);
    if (typeof r.isEdited === 'undefined' || r.isEdited === null) {
      edited = !!(r.replyUpdatedAt && r.replyCreatedAt && String(r.replyUpdatedAt) !== String(r.replyCreatedAt));
    }

    return (
      "<div class='reply-item' data-reply-id='" + escapeHtml(r.replyId) + "'>" +
        "<div class='reply-top'>" +
          "<div style='display:flex; gap:10px; align-items:flex-start;'>" +
            avatarHtml +
            "<div>" +
              "<div class='reply-writer " + escapeHtml(decoClass) + "'" + nickStyleAttr + ">" +
                escapeHtml(nickname) +
              "</div>" +
              "<div class='reply-times'>" +
                "<span class='t-created'>작성 " + escapeHtml(r.replyCreatedAt || '') + "</span>" +
                (edited && r.replyUpdatedAt
                  ? "<span class='t-updated'>수정 " + escapeHtml(r.replyUpdatedAt) + "</span>"
                  : "") +
              "</div>" +
            "</div>" +
          "</div>" +
          actions +
        "</div>" +
        "<div class='reply-content'>" + nl2br(r.replyContent) + "</div>" +
      "</div>"
    );
  }

  // 댓글 목록 로드(정렬 조건 포함)
  function loadReplies(condition) {
    if (!$replyList) return Promise.resolve();

    var url = API.replyOrder
      + '?boardId=' + encodeURIComponent(boardId)
      + '&condition=' + encodeURIComponent(condition || CONDITION_RECENT);

    return httpGetJson(url).then(function (list) {
      if (!Array.isArray(list)) list = [];

      setReplyCount(list.length);
      removeAllReplyItems();

      if (!list.length) {
        showReplyEmpty(true);
        return;
      }

      showReplyEmpty(false);

      // replyEmpty 앞에 reply-item들을 삽입(Empty 노드는 유지)
      var html = '';
      for (var i = 0; i < list.length; i++) {
        html += renderReplyItem(list[i]);
      }

      // ✅ replyEmpty가 없으면 replyList 끝에라도 붙이도록 폴백
      if ($replyEmpty && $replyEmpty.insertAdjacentHTML) {
        $replyEmpty.insertAdjacentHTML('beforebegin', html);
      } else {
        $replyList.insertAdjacentHTML('beforeend', html);
      }
    });
  }

  // 댓글 작성
  function writeReply(content) {
    var fd = new FormData();
    var bid = ($replyBoardId && $replyBoardId.value) ? $replyBoardId.value : boardId;

    fd.append('boardId', bid);
    fd.append('replyContent', content);

    return httpPostForm(API.replyWrite, fd);
  }

  // 댓글 수정
  function editReply(replyId, content) {
    var fd = new FormData();
    fd.append('boardId', boardId);
    fd.append('replyId', replyId);
    fd.append('replyContent', content);
    return httpPostForm(API.replyEdit, fd);
  }

  // 댓글 삭제
  function deleteReply(replyId) {
    var fd = new FormData();
    fd.append('boardId', boardId);
    fd.append('replyId', replyId);
    return httpPostForm(API.replyDelete, fd);
  }

  // 댓글 관련 이벤트 바인딩(정렬/작성/수정/삭제)
  function bindReplyEvents() {
    // niceSelect는 있으면 적용, 없으면 그냥 기본 select 사용(폴백)
    if ($replySort && window.jQuery && window.jQuery.fn && window.jQuery.fn.niceSelect) {
      try { window.jQuery($replySort).niceSelect(); } catch (e) {}
    }

    // 정렬 변경 -> 목록 다시 로드
    if ($replySort) {
      $replySort.addEventListener('change', function () {
        loadReplies(getSelectedCondition()).catch(function (e) {
          console.error(e);
        });
      });
    }

    // 댓글 작성 submit
    if ($replyForm) {
      $replyForm.addEventListener('submit', function (e) {
        e.preventDefault();

        if (!isLogin) {
          alert('로그인 후 이용 가능합니다.');
          return;
        }

        // ✅ 제재회원: 댓글 작성 금지(프론트 1차 차단)
        if (typeof isBanned !== 'undefined' && isBanned) {
          alertBanned('댓글 작성');
          return;
        }

        var v = ($replyContent && $replyContent.value) ? $replyContent.value.trim() : '';
        if (!v) {
          alert('댓글 내용을 입력하세요.');
          return;
        }

        writeReply(v)
          .then(function () {
            if ($replyContent) $replyContent.value = '';
            return loadReplies(getSelectedCondition());
          })
          .catch(function (err) {
            console.error(err);
            alert('댓글 등록에 실패했습니다.');
          });
      });
    }

    // 댓글 리스트 내부 이벤트 위임(수정/삭제 버튼)
    if ($replyList) {
      $replyList.addEventListener('click', function (e) {
        var target = e.target;
        if (!target) return;

        // reply-item을 찾는다(버튼 클릭이든 내부 클릭이든 동일)
        var item = target.closest ? target.closest('.reply-item') : null;
        if (!item) return;

        var replyId = item.getAttribute('data-reply-id');

        // ✅ 제재회원: 수정/삭제 클릭 자체를 막고 안내만 출력
        if (typeof isBanned !== 'undefined' && isBanned) {
          if (target.classList.contains('btn-reply-del') || target.classList.contains('btn-reply-edit')) {
            alertBanned('댓글 수정/삭제');
          }
          return;
        }

        // 삭제
        if (target.classList.contains('btn-reply-del')) {
          if (!confirm('댓글을 삭제할까요?')) return;

          deleteReply(replyId)
            .then(function () { return loadReplies(getSelectedCondition()); })
            .catch(function (err) {
              console.error(err);
              alert('삭제에 실패했습니다.');
            });
          return;
        }

        // 수정
        if (target.classList.contains('btn-reply-edit')) {
          var currentEl = item.querySelector('.reply-content');
          var current = currentEl ? (currentEl.innerText || currentEl.textContent || '') : '';
          var next = prompt('수정할 내용을 입력하세요', current);
          if (next === null) return;

          next = String(next).trim();
          if (!next) return;

          editReply(replyId, next)
            .then(function () { return loadReplies(getSelectedCondition()); })
            .catch(function (err) {
              console.error(err);
              alert('수정에 실패했습니다.');
            });
        }
      });
    }
  }

  // =========================================================
  // Report - 모달 열기/신고 접수
  // =========================================================
  function initReport() {
    if (!$btnReport || !$btnReportSubmit) return;

    // 이미 신고한 글이면 버튼 자체를 숨김(UI 정책)
    if (typeof isReported !== 'undefined' && isReported) {
      $btnReport.style.display = 'none';
      return;
    }

    // 신고 버튼 -> 모달 오픈
    $btnReport.addEventListener('click', function () {
      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }
      if (window.jQuery) window.jQuery('#reportModal').modal('show');
    });

    // 신고 접수
    $btnReportSubmit.addEventListener('click', function () {
      var reason = ($reportReason && $reportReason.value) ? String($reportReason.value) : 'ETC';
      var content = ($reportContent && $reportContent.value) ? String($reportContent.value).trim() : '';

      var fd = new FormData();
      fd.append('boardId', boardId);
      fd.append('reportReason', reason);
      fd.append('reportContent', content);

      httpPostForm(API.boardReport, fd)
        .then(function () {
          alert('신고가 접수되었습니다.');
          if ($reportContent) $reportContent.value = '';
          if (window.jQuery) window.jQuery('#reportModal').modal('hide');

          // 접수 후 UI에서 버튼 숨김(중복 신고 방지 UX)
          if ($btnReport) $btnReport.style.display = 'none';
        })
        .catch(function (e) {
          console.error(e);
          alert('신고 접수에 실패했습니다.');
        });
    });
  }

  // =========================================================
  // ✅ 게시글 수정/삭제 2중 차단
  // ---------------------------------------------------------
  // JSP에서 수정/삭제를 숨겨도,
  // - 캐시/렌더 꼬임
  // - 권한 데이터 누락
  // - 개발 중 임시 노출
  // 같은 상황에서 버튼이 살아남을 수 있음.
  //
  // 그래서 data-ban-lock="1" 요소는
  // 제재 상태일 때 클릭/submit 자체를 capture 단계에서 차단한다.
  // =========================================================
  function lockPostManageIfBanned() {
    if (!(typeof isBanned !== 'undefined' && isBanned)) return;

    document.addEventListener('click', function (e) {
      var t = e.target;
      if (!t) return;

      var lockEl = t.closest ? t.closest('[data-ban-lock="1"]') : null;
      if (!lockEl) return;

      e.preventDefault();
      e.stopPropagation();
      alertBanned('게시글 수정/삭제');
      return false;
    }, true);

    document.addEventListener('submit', function (e) {
      var form = e.target;
      if (!form) return;

      if (form.querySelector && form.querySelector('[data-ban-lock="1"]')) {
        e.preventDefault();
        e.stopPropagation();
        alertBanned('게시글 수정/삭제');
        return false;
      }
    }, true);
  }

  // =========================================================
  // Init - 페이지 진입 시 한 번만 실행
  // =========================================================
  function init() {
    normalizeEditorMediaUrls();

    initLike();
    initLikeUsers();
    initReport();

    bindReplyEvents();
    lockPostManageIfBanned();

    loadReplies(getSelectedCondition()).catch(function (e) {
      console.error(e);
      showReplyEmpty(true);
      setReplyCount(0);
      removeAllReplyItems();
    });
  }

  // DOM ready 대응(스크립트 로딩 위치가 바뀌어도 안전)
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
