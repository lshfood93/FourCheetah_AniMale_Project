// =========================================================
// Board Detail Page Script (ES5 + fetch) - 동기/비동기 정책 최종본
// ---------------------------------------------------------
// [비동기(fetch + JSON)]
// 1) 좋아요 토글: /BoardLikeToggle
// 2) 좋아요 누른 사람: /LikeMemberList  -> 모달
// 3) 댓글 목록 + 정렬: /ReplyListOrder  -> 화면 부분 렌더
// 4) 신고 접수: /report/board (fetch 유지)
//
// [동기(form submit)]
// 5) 댓글 작성: POST /replyWrite  -> ReplyController redirect/message 그대로 사용
// 6) 댓글 수정: POST /replyEdit   -> 인라인 편집 후 hidden form submit
// 7) 댓글 삭제: POST /replyDelete -> hidden form submit
// =========================================================
(function () {
  'use strict';

  // =========================================================
  // JSP 전역 변수(계약)
  // const ctx, boardId, boardStatus, isLogin, sessionMemberId, sessionMemberRole, isReported, isBanned
  // =========================================================

  // =========================================================
  // API 매핑(비동기용만 관리)
  // =========================================================
  var API = {
    likeToggle: ctx + '/BoardLikeToggle',     // POST {boardId} -> JSON {result,isLiked,likeCnt,msg}
    likeMembers: ctx + '/LikeMemberList',     // GET  ?boardId= -> JSON {ok,users:[...],message}
    replyOrder: ctx + '/ReplyListOrder',      // GET  ?boardId=&condition= -> JSON Array
    boardReport: ctx + '/report/board'        // POST {boardId, reasonCode} -> JSON {ok} or {fail}
  };

  // =========================================================
  // DOM 캐시
  // =========================================================
  var $replyList = document.getElementById('replyList');
  var $replyEmpty = document.getElementById('replyEmpty');
  var $replyCount = document.getElementById('replyCount');
  var $replyForm = document.getElementById('replyForm');
  var $replyContent = document.getElementById('replyContent');

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

  // ✅ CHANGED: 댓글 수정/삭제 동기 submit용 hidden form
  var $replyEditForm = document.getElementById('replyEditForm');
  var $editBoardId = document.getElementById('editBoardId');
  var $editReplyId = document.getElementById('editReplyId');
  var $editReplyContent = document.getElementById('editReplyContent');

  var $replyDeleteForm = document.getElementById('replyDeleteForm');
  var $delBoardId = document.getElementById('delBoardId');
  var $delReplyId = document.getElementById('delReplyId');

  // ✅ CHANGED: 좋아요 누른 사람 모달 DOM
  var $likeUsersList = document.getElementById('likeUsersList');
  var $likeUsersEmpty = document.getElementById('likeUsersEmpty');
  
  // ✅ CHANGED: 제재 안내 모달 텍스트 DOM
  var $banActionText = document.getElementById('banActionText');

  // =========================================================
  // ✅ NEW: 삭제된 게시글 여부 체크
  // =========================================================
  function isDeletedBoard() {
    return (typeof boardStatus !== 'undefined' && boardStatus !== '정상');
  }

  // =========================================================
  // ✅ NEW: 삭제된 게시글 안내 모달
  // =========================================================
  function alertDeletedBoard() {
    if (window.jQuery) {
      window.jQuery('#deletedBoardModal').modal('show');
    } else {
      alert('이미 삭제된 게시글입니다.');
    }
  }

  // =========================================================
  // ✅ 제재회원 공통 안내
  // =========================================================
  function alertBanned(actionText) {
    var $msg = document.getElementById('bannedModalMsg');
    if ($msg) $msg.textContent = '제재 중인 계정은 ' + (actionText || '해당 기능') + '이(가) 제한됩니다.';
    if (window.jQuery) window.jQuery('#bannedModal').modal('show');
    else alert('제재 중인 계정은 ' + (actionText || '해당 기능') + '이(가) 제한됩니다.');
  }

  // =========================================================
  // Utils
  // =========================================================
  function escapeHtml(v) {
    var s = (v === null || v === undefined) ? '' : String(v);
    return s
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function nl2br(v) {
    return escapeHtml(v).replace(/\r?\n/g, '<br/>');
  }

  function sanitizeColor(v) {
    if (!v) return '';
    var s = String(v).trim();
    if (/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(s)) return s;
    if (/^(rgb|rgba|hsl|hsla)\(\s*[-0-9.,% ]+\s*\)$/.test(s)) return s;
    if (/^[a-zA-Z]+$/.test(s)) return s;
    return '';
  }

  function normalizeUrl(src) {
    if (!src) return '';
    var s = String(src).trim();
    if (!s) return '';
    if (/^(https?:|data:|blob:)/i.test(s)) return s;
    if (ctx && s.indexOf(ctx + '/') === 0) return s;
    if (s.charAt(0) === '/') return ctx + s;
    return ctx + '/' + s;
  }

  function isTruthy(v) {
    return v === true || v === 1 || v === '1' || v === 'true';
  }

  function setReplyCount(n) {
    if ($replyCount) $replyCount.textContent = String(n);
  }

  function showReplyEmpty(show) {
    if (!$replyEmpty) return;
    $replyEmpty.style.display = show ? 'block' : 'none';
  }

  function removeAllReplyItems() {
    if (!$replyList) return;
    var items = $replyList.querySelectorAll('.reply-item');
    for (var i = 0; i < items.length; i++) {
      items[i].parentNode.removeChild(items[i]);
    }
  }

  function canEditReply(r) {
    if (!isLogin) return false;
    if (typeof isBanned !== 'undefined' && isBanned) return false;
    return String(r.memberId) === String(sessionMemberId);
  }

  function canDeleteReply(r) {
    if (!isLogin) return false;
    if (typeof isBanned !== 'undefined' && isBanned) return false;
    if (String(r.memberId) === String(sessionMemberId)) return true;
    return String(sessionMemberRole) === 'ADMIN';
  }

  // =========================================================
  // CKEditor src 보정
  // =========================================================
  function normalizeEditorMediaUrls() {
    var root = (typeof ctx === 'string') ? ctx : '';
    var nodes = document.querySelectorAll('.bd-content img, .bd-content iframe, .bd-content video, .bd-content source');

    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      var src = el.getAttribute('src');
      if (!src) continue;
      if (/^(https?:|data:|blob:)/i.test(src)) continue;
      if (root && src.indexOf(root + '/') === 0) continue;
      if (src.charAt(0) === '/') el.setAttribute('src', root + src);
      else el.setAttribute('src', root + '/' + src);
    }
  }

  // =========================================================
  // HTTP 래퍼
  // =========================================================
  function httpGetJson(url) {
    return fetch(url, { method: 'GET', credentials: 'same-origin' })
      .then(function (res) {
        if (!res.ok) throw new Error('GET failed: ' + res.status);
        return res.json();
      });
  }

  function httpPostForm(url, formData) {
    return fetch(url, { method: 'POST', body: formData, credentials: 'same-origin' })
      .then(function (res) {
        if (!res.ok) throw new Error('POST failed: ' + res.status);
        return res;
      });
  }

  // =========================================================
  // Like
  // =========================================================
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

  function initLike() {
    if (!$btnLike) return;

    var raw = $btnLike.getAttribute('data-liked');
    if (raw === '1') setLikeUI(true);

<<<<<<< HEAD
    $btnLike.addEventListener('click', function () {
      // NEW: 삭제된 게시글 차단
      if (isDeletedBoard()) {
        alertDeletedBoard();
        return;
      }

      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }
=======
	$btnLike.addEventListener('click', function () {
	  if (!isLogin) {
	    alert('로그인 후 이용 가능합니다.');
	    return;
	  }
>>>>>>> develop

	  // ✅ CHANGED: 제재회원은 좋아요 차단(요청 자체를 안 보냄)
	  if (typeof isBanned !== 'undefined' && isBanned) {
	    openBanActionModal(
	      '제재회원은 좋아요를 누를 수 없습니다.<br/>현재는 조회만 가능합니다.',
	      '제재회원은 좋아요를 누를 수 없습니다. 현재는 조회만 가능합니다.'
	    );
	    return;
	  }

	  var bid = $btnLike.getAttribute('data-board-id') || boardId;

	  var fd = new FormData();
	  fd.append('boardId', bid);

	  httpPostForm(API.likeToggle, fd)
	    .then(function (res) { return res.json(); })
	    .then(function (json) {
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

  // CHANGED: 좋아요 누른 사람 -> alert 대신 모달
  function openLikeUsersModal(users) {
    // 모달 DOM이 없으면 폴백(alert)
    if (!$likeUsersList || !$likeUsersEmpty) {
      var namesFallback = [];
      for (var i = 0; i < users.length; i++) {
        namesFallback.push(users[i].memberNickname || users[i].nickname || 'unknown');
      }
      alert(namesFallback.join('\n'));
      return;
    }

    // 초기화
    $likeUsersList.innerHTML = '';

    if (!users || !users.length) {
      $likeUsersEmpty.style.display = 'block';
    } else {
      $likeUsersEmpty.style.display = 'none';

      for (var j = 0; j < users.length; j++) {
        var u = users[j];
        var name = u.memberNickname || u.nickname || u.memberId || 'unknown';
        var img = normalizeUrl(u.profileImage || u.profileImg || u.memberProfileImage || '');

        var li = document.createElement('li');
        li.className = 'like-user-item';

        if (img) {
          li.innerHTML =
            "<img class='like-user-avatar' src='" + escapeHtml(img) + "' alt='avatar'/>" +
            "<div class='like-user-name'>" + escapeHtml(name) + "</div>";
        } else {
          var initial = String(name).charAt(0);
          li.innerHTML =
            "<div class='like-user-avatar like-user-avatar--fallback'>" + escapeHtml(initial) + "</div>" +
            "<div class='like-user-name'>" + escapeHtml(name) + "</div>";
        }

        $likeUsersList.appendChild(li);
      }
    }

    // 부트스트랩 모달 오픈
    if (window.jQuery) window.jQuery('#likeUsersModal').modal('show');
    else alert('모달 라이브러리가 없어 목록을 표시할 수 없습니다.');
  }

  function initLikeUsers() {
    var btn = document.getElementById('btnLikeUsers');
    if (!btn) return;

    btn.addEventListener('click', function () {
      // NEW: 삭제된 게시글 차단
      if (isDeletedBoard()) {
        alertDeletedBoard();
        return;
      }

      var url = API.likeMembers + '?boardId=' + encodeURIComponent(boardId);

      httpGetJson(url)
        .then(function (json) {
          if (!json || json.ok === false) {
            alert((json && json.message) ? json.message : '목록을 불러오지 못했습니다.');
            return;
          }

          var users = json.users || [];
          openLikeUsersModal(users);
        })
        .catch(function (e) {
          console.error(e);
          alert('서버 통신 오류가 발생했습니다.');
        });
    });
  }

  // =========================================================
  // Replies - 조회/렌더/정렬
  // =========================================================
  function getSelectedCondition() {
    if (!$replySort) return CONDITION_RECENT;
    var v = ($replySort.value || '').trim();
    return (v === CONDITION_OLDEST) ? CONDITION_OLDEST : CONDITION_RECENT;
  }

  // ✅ CHANGED: 작성일/수정일 표시 정책
  // - 수정됨이면 "수정일"만 표시
  // - 아니면 "작성일"만 표시
  function renderReplyItem(r) {
    var nickname = (r.writerNickname && String(r.writerNickname).trim() !== '')
      ? r.writerNickname
      : r.memberId;

    // ✅ ADDED: 관리자 여부 판별 (닉네임 기반 휴리스틱)
    var isAdminWriter = false;
    try {
      var nn = String(nickname || '').trim();
      isAdminWriter = (nn === '관리자' || nn.toUpperCase() === 'ADMIN');
    } catch (e) { /* ignore */ }

    var profileImgRaw = r.writerProfileImage || r.writerProfileImg || r.writer_profile_image || '';
    var profileImg = normalizeUrl(profileImgRaw);

    var nickColor = sanitizeColor(r.writerNicknameColor || r.writer_nickname_color || '');
    var profileColor = sanitizeColor(r.writerProfileColor || r.writer_profile_color || '');
    var decoClass = (r.writerDecoClass || r.writer_deco_class || '').trim();

    // ADDED: 관리자이고 닉네임 색이 없으면 레인보우 클래스 기본 적용
    if (isAdminWriter && !nickColor) {
      decoClass = (decoClass ? (decoClass + ' ') : '') + 'is-rainbow';
    }

    var avatarFx = '';
    if (profileColor) {
      avatarFx =
        'border-color:' + escapeHtml(profileColor) + ';' +
        'box-shadow:0 0 0 3px rgba(255,255,255,0.06), 0 0 18px ' + escapeHtml(profileColor) + ';';
    }

    // ADDED: 관리자 + 프로필 색 없으면 레인보우 링 래퍼 사용
    var useRainbowRing = (isAdminWriter && !profileColor);

    var avatarHtml = '';
    if (profileImg) {
      avatarHtml =
        (useRainbowRing ? "<div class='reply-avatar-ring is-rainbow'>" : "") +
        "<img class='reply-avatar' style='" + avatarFx + "' src='" + escapeHtml(profileImg) + "' alt='profile'/>" +
        (useRainbowRing ? "</div>" : "");
    } else {
      var initial = String(nickname).charAt(0);
      var bg = profileColor ? ('background:' + escapeHtml(profileColor) + ';') : 'background:rgba(255,255,255,0.10);';
      avatarHtml =
        (useRainbowRing ? "<div class='reply-avatar-ring is-rainbow'>" : "") +
        "<div class='reply-avatar reply-avatar--fallback' style='" +
          bg + avatarFx +
        "'>" +
          escapeHtml(initial) +
        "</div>" +
        (useRainbowRing ? "</div>" : "");
    }

    // ADDED: 레인보우 클래스 있으면 인라인 color 제거 (그라데이션 깨짐 방지)
    var nickStyleAttr = (nickColor && !/is-rainbow/.test(decoClass))
      ? (" style='color:" + escapeHtml(nickColor) + ";'")
      : '';

    // NEW: 관리자 삭제 댓글 여부 (내용 치환 방식)
    // CHANGED: startsWith로 비교 (관리자 삭제 후 내용 추가 수정된 경우도 커버)
    var isAdminDeleted = (r.replyContent && r.replyContent.indexOf('관리자에 의해 삭제된 댓글입니다.') === 0);

    var actions = '';
    if (!isAdminDeleted && !(typeof isBanned !== 'undefined' && isBanned) && (canEditReply(r) || canDeleteReply(r))) {
      actions += "<div class='reply-actions-wrap'>";
      actions += "<div class='reply-actions'>";
      if (canEditReply(r)) actions += "<button type='button' class='btn-reply-edit'>수정</button>";
      if (canDeleteReply(r)) actions += "<button type='button' class='btn-reply-del'>삭제</button>";
      actions += "</div>";
      // CHANGED: 인라인 편집 버튼(저장/취소)
      actions += "<div class='reply-edit-actions' style='display:none;'>";
      actions += "<button type='button' class='btn-reply-save'>저장</button>";
      actions += "<button type='button' class='btn-reply-cancel'>취소</button>";
      actions += "</div>";
      actions += "</div>";
    }

    var edited = isTruthy(r.isEdited);
    if (typeof r.isEdited === 'undefined' || r.isEdited === null) {
      edited = !!(r.replyUpdatedAt && r.replyCreatedAt && String(r.replyUpdatedAt) !== String(r.replyCreatedAt));
    }

    // CHANGED: 시간 라인 1개만
    var timeHtml = '';
    if (edited && r.replyUpdatedAt) {
      timeHtml = "<span class='t-time'>수정일 " + escapeHtml(r.replyUpdatedAt || '') + "</span>";
    } else {
      timeHtml = "<span class='t-time'>작성일 " + escapeHtml(r.replyCreatedAt || '') + "</span>";
    }

    return (
      "<div class='reply-item'" +
        " data-reply-id='" + escapeHtml(r.replyId) + "'" +
        (isAdminDeleted ? " data-admin-deleted='1'" : "") +
        ">" +
        "<div class='reply-top'>" +
          "<div style='display:flex; gap:10px; align-items:flex-start;'>" +
            avatarHtml +
            "<div>" +
              "<div class='reply-writer " + escapeHtml(decoClass) + "'" + nickStyleAttr + ">" +
                escapeHtml(nickname) +
              "</div>" +
              "<div class='reply-times'>" + timeHtml + "</div>" +
            "</div>" +
          "</div>" +
          actions +
        "</div>" +
        "<div class='reply-content'>" + nl2br(r.replyContent) + "</div>" +
      "</div>"
    );
  }

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

      var html = '';
      for (var i = 0; i < list.length; i++) {
        html += renderReplyItem(list[i]);
      }

      if ($replyEmpty && $replyEmpty.insertAdjacentHTML) {
        $replyEmpty.insertAdjacentHTML('beforebegin', html);
      } else {
        $replyList.insertAdjacentHTML('beforeend', html);
      }
    });
  }

  // =========================================================
  // CHANGED: 댓글 수정/삭제는 동기 submit
  // =========================================================
  function submitReplyEdit(replyId, content) {
    if (!$replyEditForm || !$editBoardId || !$editReplyId || !$editReplyContent) {
      alert('수정 폼이 없어 동기 수정이 불가능합니다.');
      return;
    }
    $editBoardId.value = String(boardId);
    $editReplyId.value = String(replyId);
    $editReplyContent.value = String(content);
    $replyEditForm.submit(); // 동기 전환(redirect/message 화면 정상 동작)
  }

  function submitReplyDelete(replyId) {
    if (!$replyDeleteForm || !$delBoardId || !$delReplyId) {
      alert('삭제 폼이 없어 동기 삭제가 불가능합니다.');
      return;
    }
    $delBoardId.value = String(boardId);
    $delReplyId.value = String(replyId);
    $replyDeleteForm.submit(); // 동기 전환
  }

  // =========================================================
  // Replies - 이벤트(정렬/작성/수정/삭제)
  // =========================================================
  function bindReplyEvents() {
    // niceSelect 적용
    if ($replySort && window.jQuery && window.jQuery.fn && window.jQuery.fn.niceSelect) {
      try { window.jQuery($replySort).niceSelect(); } catch (e) {}
    }

	// 정렬 변경 -> 목록 다시 로드
	// ✅ nice-select가 적용되면 DOM addEventListener('change')가 안 타는 케이스가 있음
	// ✅ 그래서 DOM change + jQuery change + nice-select option click까지 모두 커버한다.
	if ($replySort) {

	  // ✅ 중복 호출 방지(같은 값이 짧은 시간에 여러 번 트리거되는 경우 방어)
	  var _lastSortCond = null;
	  var _lastSortAt = 0;

	  function requestReloadBySort() {
	    var cond = getSelectedCondition();
	    var now = Date.now();

	    // 같은 조건이 200ms 안에 다시 들어오면 무시(중복 방지)
	    if (_lastSortCond === cond && (now - _lastSortAt) < 200) return;

	    _lastSortCond = cond;
	    _lastSortAt = now;

	    loadReplies(cond).catch(function (e) {
	      console.error(e);
	    });
	  }

	  // ✅ 1) 기본 DOM change (nice-select 미사용/정상 케이스)
	  $replySort.addEventListener('change', requestReloadBySort);

	  // ✅ 2) jQuery change (nice-select가 trigger('change')로만 쏘는 케이스 대응)
	  if (window.jQuery) {
	    try {
	      window.jQuery($replySort).on('change.replySort', requestReloadBySort);
	    } catch (e) {}
	  }

	  // ✅ 3) nice-select 옵션 클릭 (일부 버전에서 change가 누락되는 케이스 대응)
	  if (window.jQuery) {
	    try {
	      window.jQuery(document).on('click.replySort', '.reply-card .nice-select .option', function () {
	        // 값 반영 후 호출되게 0ms 지연
	        setTimeout(requestReloadBySort, 0);
	      });
	    } catch (e) {}
	  }
	}

    // ✅ CHANGED: 댓글 작성은 동기 submit
    // - 단, 프론트에서 1차 검증만 하고(비었으면 막기), 정상 값이면 submit 통과
    if ($replyForm) {
      $replyForm.addEventListener('submit', function (e) {
        // ✅ NEW: 삭제된 게시글 차단
        if (isDeletedBoard()) {
          e.preventDefault();
          alertDeletedBoard();
          return;
        }

        // 로그인/제재는 JSP UI로 1차 처리되어있지만, 방어적으로 체크
        if (!isLogin) {
          e.preventDefault();
          alert('로그인 후 이용 가능합니다.');
          return;
        }
        if (typeof isBanned !== 'undefined' && isBanned) {
          e.preventDefault();
          alertBanned('댓글 작성');
          return;
        }

        var v = ($replyContent && $replyContent.value) ? $replyContent.value.trim() : '';
        if (!v) {
          e.preventDefault();
          alert('댓글 내용을 입력하세요.');
          return;
        }
        if (v.length > 500) {
          e.preventDefault();
          alert('댓글은 500자 이내로 작성해주세요.');
          return;
        }

        // ✅ 여기서부터는 막지 않음 -> form submit(동기) 진행
      });
    }

    // 댓글 리스트 내부 이벤트 위임(수정/삭제 + 저장/취소)
    if ($replyList) {
      $replyList.addEventListener('click', function (e) {
        var target = e.target;
        if (!target) return;

        var item = target.closest ? target.closest('.reply-item') : null;
        if (!item) return;

        var replyId = item.getAttribute('data-reply-id');

        var isReplyBtn =
          target.classList.contains('btn-reply-del') ||
          target.classList.contains('btn-reply-edit') ||
          target.classList.contains('btn-reply-save') ||
          target.classList.contains('btn-reply-cancel');

        // ✅ NEW: 삭제된 게시글 차단
        if (isDeletedBoard()) {
          if (isReplyBtn) {
            alertDeletedBoard();
          }
          return;
        }

        // ✅ NEW: 관리자 삭제 댓글 차단
        if (item.getAttribute('data-admin-deleted') === '1') {
          if (target.classList.contains('btn-reply-del') || target.classList.contains('btn-reply-edit')) {
            alertDeletedBoard();
          }
          return;
        }

        // 제재회원 차단
        if (typeof isBanned !== 'undefined' && isBanned) {
          if (isReplyBtn) {
            alertBanned('댓글 수정/삭제');
          }
          return;
        }

        // 삭제(동기 submit)
        if (target.classList.contains('btn-reply-del')) {
          if (!confirm('댓글을 삭제할까요?')) return;
          submitReplyDelete(replyId);
          return;
        }

        // ✅ CHANGED: 수정(인라인 편집 시작)
        if (target.classList.contains('btn-reply-edit')) {
          if (item.classList.contains('is-editing')) return;

          var contentEl = item.querySelector('.reply-content');
          if (!contentEl) return;

          var currentText = (contentEl.innerText || contentEl.textContent || '');
          item.setAttribute('data-original-content', currentText);

          // textarea로 교체
          contentEl.innerHTML =
            "<textarea class='reply-inline-textarea' rows='3' maxlength='500'></textarea>";
          var ta = contentEl.querySelector('textarea');
          if (ta) {
            ta.value = currentText;
            try { ta.focus(); } catch (err) {}
          }

          // 버튼 상태 전환
          var act = item.querySelector('.reply-actions');
          var editAct = item.querySelector('.reply-edit-actions');
          if (act) act.style.display = 'none';
          if (editAct) editAct.style.display = 'flex';

          item.classList.add('is-editing');
          return;
        }

        // ✅ CHANGED: 저장(동기 submit)
        if (target.classList.contains('btn-reply-save')) {
          var contentBox = item.querySelector('.reply-content');
          var ta2 = contentBox ? contentBox.querySelector('textarea.reply-inline-textarea') : null;
          var next = ta2 ? String(ta2.value || '').trim() : '';

          if (!next) {
            alert('댓글 내용을 입력하세요.');
            return;
          }
          if (next.length > 500) {
            alert('댓글은 500자 이내로 작성해주세요.');
            return;
          }

          submitReplyEdit(replyId, next);
          return;
        }

        // ✅ CHANGED: 취소(원복)
        if (target.classList.contains('btn-reply-cancel')) {
          var original = item.getAttribute('data-original-content') || '';

          var contentEl2 = item.querySelector('.reply-content');
          if (contentEl2) contentEl2.innerHTML = nl2br(original);

          var act2 = item.querySelector('.reply-actions');
          var editAct2 = item.querySelector('.reply-edit-actions');
          if (act2) act2.style.display = 'flex';
          if (editAct2) editAct2.style.display = 'none';

          item.classList.remove('is-editing');
          item.removeAttribute('data-original-content');
          return;
        }
      });
    }
  }

  // =========================================================
  // Report
  // =========================================================
  function initReport() {
    if (!$btnReport || !$btnReportSubmit) return;

    if (typeof isReported !== 'undefined' && isReported) {
      $btnReport.style.display = 'none';
      return;
    }

    // ✅ CHANGED: 제재회원 안내 모달
	// ✅ CHANGED: 제재회원 안내 모달(공용 함수 사용)
	function openBanReportModal() {
	  openBanActionModal(
	    '제재회원은 게시글 신고를 이용할 수 없습니다.<br/>현재는 조회만 가능합니다.',
	    '제재회원은 게시글 신고를 이용할 수 없습니다. 현재는 조회만 가능합니다.'
	  );
	}
    $btnReport.addEventListener('click', function () {
      // ✅ NEW: 삭제된 게시글 차단
      if (isDeletedBoard()) {
        alertDeletedBoard();
        return;
      }

      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }

      // ✅ CHANGED: 제재회원이면 신고 모달 대신 안내 모달
      if (typeof isBanned !== 'undefined' && isBanned) {
        openBanReportModal();
        return;
      }

      if (window.jQuery) window.jQuery('#reportModal').modal('show');
    });

    $btnReportSubmit.addEventListener('click', function () {
<<<<<<< HEAD
      // ✅ CHANGED: 파라미터 맞춤 - reasonCode만 전송 (reportContent 제거)
      var reasonCode = ($reportReason && $reportReason.value) ? String($reportReason.value) : 'ETC';

      var fd = new FormData();
      fd.append('boardId', boardId);
      fd.append('reasonCode', reasonCode);

      // ✅ CHANGED: 403 포함 모든 응답을 JSON으로 파싱 (제재 차단 메시지 표시)
      fetch(API.boardReport, { method: 'POST', body: fd, credentials: 'same-origin' })
        .then(function (res) { return res.json(); })
        .then(function (json) {
          if (window.jQuery) window.jQuery('#reportModal').modal('hide');
          if ($reportContent) $reportContent.value = '';

          var msg = (json && (json.ok || json.fail || json.message))
            ? (json.ok || json.fail || json.message)
            : '신고 처리 중 오류가 발생했습니다.';

          var $msgEl = document.getElementById('reportResultMsg');
          if ($msgEl) $msgEl.textContent = msg;
          if (window.jQuery) window.jQuery('#reportResultModal').modal('show');

          // 신고 성공 시 버튼 숨김
          if (json && json.ok && $btnReport) $btnReport.style.display = 'none';
        })
        .catch(function (e) {
          console.error(e);
          if (window.jQuery) window.jQuery('#reportModal').modal('hide');
          var $msgEl2 = document.getElementById('reportResultMsg');
          if ($msgEl2) $msgEl2.textContent = '서버 통신 오류가 발생했습니다.';
          if (window.jQuery) window.jQuery('#reportResultModal').modal('show');
=======
      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }

      // ✅ CHANGED: 제재회원이면 제출 자체 차단
      if (typeof isBanned !== 'undefined' && isBanned) {
        // 혹시 reportModal이 열려있으면 닫고 안내 모달로 전환
        if (window.jQuery) window.jQuery('#reportModal').modal('hide');
        openBanReportModal();
        return;
      }

      var reason = ($reportReason && $reportReason.value) ? String($reportReason.value) : 'ETC';
      var content = ($reportContent && $reportContent.value) ? String($reportContent.value).trim() : '';

      var fd = new FormData();
      fd.append('boardId', boardId);
      fd.append('reasonCode', reason);
      fd.append('reasonDetail', content);

      httpPostForm(API.boardReport, fd)
        .then(function () {
          alert('신고가 접수되었습니다.');
          if ($reportContent) $reportContent.value = '';
          if (window.jQuery) window.jQuery('#reportModal').modal('hide');
          if ($btnReport) $btnReport.style.display = 'none';
        })
        .catch(function (e) {
          console.error(e);
          alert('신고 접수에 실패했습니다.');
>>>>>>> develop
        });
    });
  }

  // =========================================================
  // 게시글 수정/삭제 2중 차단(제재)
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
  
  // ✅ CHANGED: 제재 안내 모달(신고/좋아요 등 공용)
  function openBanActionModal(htmlMsg, fallbackMsg) {
    if ($banActionText && htmlMsg) $banActionText.innerHTML = htmlMsg;

    if (window.jQuery) window.jQuery('#banReportModal').modal('show');
    else alert(fallbackMsg || '제재회원은 해당 기능을 이용할 수 없습니다. 현재는 조회만 가능합니다.');
  }

  // =========================================================
  // ✅ NEW: 게시글 수정/삭제 차단 - 삭제된 게시글
  // =========================================================
  function lockDeletedBoardActions() {
    if (!isDeletedBoard()) return;

    document.addEventListener('click', function (e) {
      var t = e.target;
      if (!t) return;

      var lockEl = t.closest ? t.closest('[data-deleted-lock="1"]') : null;
      if (!lockEl) return;

      e.preventDefault();
      e.stopPropagation();
      alertDeletedBoard();
      return false;
    }, true);

    document.addEventListener('submit', function (e) {
      var form = e.target;
      if (!form) return;

      if (form.querySelector && form.querySelector('[data-deleted-lock="1"]')) {
        e.preventDefault();
        e.stopPropagation();
        alertDeletedBoard();
        return false;
      }
    }, true);
  }

  // =========================================================
  // Init
  // =========================================================
  function init() {
    normalizeEditorMediaUrls();

    initLike();
    initLikeUsers();
    initReport();

    bindReplyEvents();
    lockPostManageIfBanned();
    lockDeletedBoardActions(); // ✅ NEW

    loadReplies(getSelectedCondition()).catch(function (e) {
      console.error(e);
      showReplyEmpty(true);
      setReplyCount(0);
      removeAllReplyItems();
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
