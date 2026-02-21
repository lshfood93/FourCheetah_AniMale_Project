// ✅ FINAL: /js/boarddetail.js
// =========================================================
// Board Detail Page Script (ES5 + fetch)
// - 403(삭제된 게시글) 수신 시: 모달 표시 + 모든 액션 차단
// =========================================================
(function () {
  'use strict';

  // =========================================================
  // JSP 전역 변수(계약)
  // const ctx, boardId, isLogin, sessionMemberId, sessionMemberRole, isReported, isBanned
  // =========================================================

  // =========================================================
  // API 매핑(비동기용만 관리)
  // =========================================================
  var API = {
    likeToggle: ctx + '/BoardLikeToggle',
    likeMembers: ctx + '/LikeMemberList',
    replyOrder: ctx + '/ReplyListOrder',
    boardReport: ctx + '/report/board'
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

  var $replyEditForm = document.getElementById('replyEditForm');
  var $editBoardId = document.getElementById('editBoardId');
  var $editReplyId = document.getElementById('editReplyId');
  var $editReplyContent = document.getElementById('editReplyContent');

  var $replyDeleteForm = document.getElementById('replyDeleteForm');
  var $delBoardId = document.getElementById('delBoardId');
  var $delReplyId = document.getElementById('delReplyId');

  var $likeUsersList = document.getElementById('likeUsersList');
  var $likeUsersEmpty = document.getElementById('likeUsersEmpty');

  var $banActionText = document.getElementById('banActionText');

  // =========================================================
  // ✅ Deleted Guard (403)
  // =========================================================
  var __deletedBlocked = false;

  function ensureDeletedModal() {
    if (document.getElementById('deletedGuardModal')) return;

    var wrap = document.createElement('div');
    wrap.innerHTML =
      "<div class='modal fade deleted-guard-modal' id='deletedGuardModal' tabindex='-1' role='dialog' aria-hidden='true'>" +
        "<div class='modal-dialog modal-dialog-centered' role='document'>" +
          "<div class='modal-content'>" +
            "<div class='modal-header'>" +
              "<h5 class='modal-title'>삭제된 게시글입니다</h5>" +
              "<button type='button' class='close' data-dismiss='modal' aria-label='Close' style='background:transparent;border:0;color:#fff;font-size:22px;line-height:1;'>" +
                "<span aria-hidden='true'>&times;</span>" +
              "</button>" +
            "</div>" +
            "<div class='modal-body'>" +
              "<div class='dg-text'>해당 게시글은 삭제되어 더 이상 이용할 수 없습니다.<br/>목록으로 이동 후 다른 게시글을 확인해주세요.</div>" +
            "</div>" +
            "<div class='modal-footer'>" +
              "<button type='button' class='btn btn-light' data-dismiss='modal'>확인</button>" +
              "<a href='" + escapeHtml(ctx) + "/boardList' class='btn btn-primary'>목록으로</a>" +
            "</div>" +
          "</div>" +
        "</div>" +
      "</div>";
    document.body.appendChild(wrap.firstChild);
  }

  function showDeleted403Modal() {
    __deletedBlocked = true;
    ensureDeletedModal();

    // UI 잠금(버튼/입력)
    lockAllActionsUI();

    if (window.jQuery) {
      window.jQuery('#deletedGuardModal').modal('show');
    } else {
      alert('삭제된 게시글입니다. 목록으로 이동 후 다시 시도해주세요.');
    }
  }

  function lockAllActionsUI() {
    // 좋아요/신고 버튼 잠금
    if ($btnLike) {
      $btnLike.disabled = true;
      $btnLike.classList.add('is-blocked');
    }
    if ($likePill) $likePill.classList.add('is-blocked');

    if ($btnReport) {
      $btnReport.disabled = true;
      $btnReport.classList.add('is-blocked');
    }
    if ($btnReportSubmit) {
      $btnReportSubmit.disabled = true;
    }

    // 댓글 폼 잠금
    if ($replyContent) $replyContent.disabled = true;
    if ($replyForm) {
      var btns = $replyForm.querySelectorAll('button, input[type="submit"]');
      for (var i = 0; i < btns.length; i++) btns[i].disabled = true;
    }

    // 댓글 리스트 내 액션 버튼 잠금
    if ($replyList) {
      var actBtns = $replyList.querySelectorAll('button');
      for (var j = 0; j < actBtns.length; j++) actBtns[j].disabled = true;
    }
  }

  // =========================================================
  // ✅ 제재회원 공통 안내
  // =========================================================
  function alertBanned(actionText) {
    alert('제재회원은 ' + (actionText || '해당 기능') + '이(가) 제한됩니다.');
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
  // HTTP 래퍼 (403 처리 포함)
  // =========================================================
  function guard403(res) {
    if (res && res.status === 403) {
      showDeleted403Modal();
      var err = new Error('FORBIDDEN_403');
      err.code = 403;
      throw err;
    }
    return res;
  }

  function httpGetJson(url) {
    if (__deletedBlocked) return Promise.reject(new Error('BLOCKED'));
    return fetch(url, { method: 'GET', credentials: 'same-origin' })
      .then(guard403)
      .then(function (res) {
        if (!res.ok) throw new Error('GET failed: ' + res.status);
        return res.json();
      });
  }

  function httpPostForm(url, formData) {
    if (__deletedBlocked) return Promise.reject(new Error('BLOCKED'));
    return fetch(url, { method: 'POST', body: formData, credentials: 'same-origin' })
      .then(guard403)
      .then(function (res) {
        if (!res.ok) throw new Error('POST failed: ' + res.status);
        return res;
      });
  }

  // ✅ 폼을 fetch로 보내서 403 잡고, redirect면 이동
  function submitFormByFetch(formEl, formData) {
    if (__deletedBlocked) return Promise.reject(new Error('BLOCKED'));
    var url = formEl.getAttribute('action');
    var method = (formEl.getAttribute('method') || 'POST').toUpperCase();

    return fetch(url, { method: method, body: formData, credentials: 'same-origin' })
      .then(guard403)
      .then(function (res) {
        // redirect면 그 URL로 이동 (댓글 작성 후 detail로 redirect 등)
        if (res.redirected) {
          window.location.href = res.url;
          return null;
        }
        if (!res.ok) throw new Error('FORM failed: ' + res.status);
        // ok인데 redirect가 없으면 새로고침
        window.location.reload();
        return null;
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
          if (!json || json.result !== 'OK') {
            alert((json && json.msg) ? json.msg : '처리에 실패했습니다.');
            return;
          }

          var liked = (Number(json.isLiked) === 1);
          var likeCnt = (json.likeCnt != null ? json.likeCnt : 0);

          setLikeUI(liked, likeCnt);
        })
        .catch(function (e) {
          if (e && e.code === 403) return; // ✅ 삭제된 글 모달은 guard403에서 처리
          console.error(e);
          alert('서버 통신 오류가 발생했습니다.');
        });
    });
  }

  function openLikeUsersModal(users) {
    if (!$likeUsersList || !$likeUsersEmpty) {
      var namesFallback = [];
      for (var i = 0; i < users.length; i++) {
        namesFallback.push(users[i].memberNickname || users[i].nickname || 'unknown');
      }
      alert(namesFallback.join('\n'));
      return;
    }

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

    if (window.jQuery) window.jQuery('#likeUsersModal').modal('show');
    else alert('모달 라이브러리가 없어 목록을 표시할 수 없습니다.');
  }

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
          openLikeUsersModal(users);
        })
        .catch(function (e) {
          if (e && e.code === 403) return;
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

  function renderReplyItem(r) {
    var nickname = (r.writerNickname && String(r.writerNickname).trim() !== '')
      ? r.writerNickname
      : r.memberId;

    var isAdminWriter = false;
    try {
      var nn = String(nickname || '').trim();
      isAdminWriter = (nn === '관리자' || nn.toUpperCase() === 'ADMIN');
    } catch (e) { }

    var profileImgRaw = r.writerProfileImage || r.writerProfileImg || r.writer_profile_image || '';
    var profileImg = normalizeUrl(profileImgRaw);

    var nickColor = sanitizeColor(r.writerNicknameColor || r.writer_nickname_color || '');
    var profileColor = sanitizeColor(r.writerProfileColor || r.writer_profile_color || '');
    var decoClass = (r.writerDecoClass || r.writer_deco_class || '').trim();

    if (isAdminWriter && !nickColor) {
      decoClass = (decoClass ? (decoClass + ' ') : '') + 'is-rainbow';
    }

    var avatarFx = '';
    if (profileColor) {
      avatarFx =
        'border-color:' + escapeHtml(profileColor) + ';' +
        'box-shadow:0 0 0 3px rgba(255,255,255,0.06), 0 0 18px ' + escapeHtml(profileColor) + ';';
    }

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

    var nickStyleAttr = (nickColor && !/\bis-rainbow\b/.test(decoClass))
      ? (" style='color:" + escapeHtml(nickColor) + ";'")
      : '';

    var actions = '';
    if (!(typeof isBanned !== 'undefined' && isBanned) && (canEditReply(r) || canDeleteReply(r))) {
      actions += "<div class='reply-actions-wrap'>";
      actions += "<div class='reply-actions'>";
      if (canEditReply(r)) actions += "<button type='button' class='btn-reply-edit'>수정</button>";
      if (canDeleteReply(r)) actions += "<button type='button' class='btn-reply-del'>삭제</button>";
      actions += "</div>";
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

    var timeHtml = '';
    if (edited && r.replyUpdatedAt) {
      timeHtml = "<span class='t-time'>수정일 " + escapeHtml(r.replyUpdatedAt || '') + "</span>";
    } else {
      timeHtml = "<span class='t-time'>작성일 " + escapeHtml(r.replyCreatedAt || '') + "</span>";
    }

    return (
      "<div class='reply-item' data-reply-id='" + escapeHtml(r.replyId) + "'>" +
        "<div class='reply-top'>" +
          "<div class='reply-left'>" +
            "<div class='reply-avatar-slot'>" +
              avatarHtml +
            "</div>" +
            "<div class='reply-meta-col'>" +
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
  // Replies - 이벤트(정렬/작성/수정/삭제)
  // =========================================================
  function bindReplyEvents() {
    if ($replySort && window.jQuery && window.jQuery.fn && window.jQuery.fn.niceSelect) {
      try { window.jQuery($replySort).niceSelect(); } catch (e) {}
    }

    if ($replySort) {
      var _lastSortCond = null;
      var _lastSortAt = 0;

      function requestReloadBySort() {
        var cond = getSelectedCondition();
        var now = Date.now();
        if (_lastSortCond === cond && (now - _lastSortAt) < 200) return;
        _lastSortCond = cond;
        _lastSortAt = now;

        loadReplies(cond).catch(function (e) {
          if (e && e.code === 403) return;
          console.error(e);
        });
      }

      $replySort.addEventListener('change', requestReloadBySort);

      if (window.jQuery) {
        try { window.jQuery($replySort).on('change.replySort', requestReloadBySort); } catch (e) {}
        try {
          window.jQuery(document).on('click.replySort', '.reply-card .nice-select .option', function () {
            setTimeout(requestReloadBySort, 0);
          });
        } catch (e) {}
      }
    }

    // ✅ 댓글 작성: fetch로 전환(403 잡기)
    if ($replyForm) {
      $replyForm.addEventListener('submit', function (e) {
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

        e.preventDefault();

        var fd = new FormData($replyForm);
        submitFormByFetch($replyForm, fd).catch(function (err) {
          if (err && err.code === 403) return;
          console.error(err);
          alert('서버 통신 오류가 발생했습니다.');
        });
      });
    }

    // 댓글 리스트 이벤트 위임
    if ($replyList) {
      $replyList.addEventListener('click', function (e) {
        var target = e.target;
        if (!target) return;

        var item = target.closest ? target.closest('.reply-item') : null;
        if (!item) return;

        var replyId = item.getAttribute('data-reply-id');

        if (typeof isBanned !== 'undefined' && isBanned) {
          if (
            target.classList.contains('btn-reply-del') ||
            target.classList.contains('btn-reply-edit') ||
            target.classList.contains('btn-reply-save') ||
            target.classList.contains('btn-reply-cancel')
          ) {
            alertBanned('댓글 수정/삭제');
          }
          return;
        }

        // 삭제: fetch로 전환(403 잡기)
        if (target.classList.contains('btn-reply-del')) {
          if (!confirm('댓글을 삭제할까요?')) return;
          if (!$replyDeleteForm || !$delBoardId || !$delReplyId) {
            alert('삭제 폼이 없어 삭제가 불가능합니다.');
            return;
          }
          $delBoardId.value = String(boardId);
          $delReplyId.value = String(replyId);

          var fdDel = new FormData($replyDeleteForm);
          submitFormByFetch($replyDeleteForm, fdDel).catch(function (err) {
            if (err && err.code === 403) return;
            console.error(err);
            alert('서버 통신 오류가 발생했습니다.');
          });
          return;
        }

        // 수정 시작
        if (target.classList.contains('btn-reply-edit')) {
          if (item.classList.contains('is-editing')) return;

          var contentEl = item.querySelector('.reply-content');
          if (!contentEl) return;

          var currentText = (contentEl.innerText || contentEl.textContent || '');
          item.setAttribute('data-original-content', currentText);

          contentEl.innerHTML = "<textarea class='reply-inline-textarea' rows='3' maxlength='500'></textarea>";
          var ta = contentEl.querySelector('textarea');
          if (ta) {
            ta.value = currentText;
            try { ta.focus(); } catch (err) {}
          }

          var act = item.querySelector('.reply-actions');
          var editAct = item.querySelector('.reply-edit-actions');
          if (act) act.style.display = 'none';
          if (editAct) editAct.style.display = 'flex';

          item.classList.add('is-editing');
          return;
        }

        // 저장: fetch로 전환(403 잡기)
        if (target.classList.contains('btn-reply-save')) {
          if (!$replyEditForm || !$editBoardId || !$editReplyId || !$editReplyContent) {
            alert('수정 폼이 없어 수정이 불가능합니다.');
            return;
          }

          var contentBox = item.querySelector('.reply-content');
          var ta2 = contentBox ? contentBox.querySelector('textarea.reply-inline-textarea') : null;
          var next = ta2 ? String(ta2.value || '').trim() : '';

          if (!next) { alert('댓글 내용을 입력하세요.'); return; }
          if (next.length > 500) { alert('댓글은 500자 이내로 작성해주세요.'); return; }

          $editBoardId.value = String(boardId);
          $editReplyId.value = String(replyId);
          $editReplyContent.value = String(next);

          var fdEdit = new FormData($replyEditForm);
          submitFormByFetch($replyEditForm, fdEdit).catch(function (err) {
            if (err && err.code === 403) return;
            console.error(err);
            alert('서버 통신 오류가 발생했습니다.');
          });
          return;
        }

        // 취소
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
  // Report (403 처리 포함)
  // =========================================================
  function initReport() {
    if (!$btnReport || !$btnReportSubmit) return;

    if (typeof isReported !== 'undefined' && isReported) {
      $btnReport.style.display = 'none';
      return;
    }

    function openBanActionModal(htmlMsg, fallbackMsg) {
      if ($banActionText && htmlMsg) $banActionText.innerHTML = htmlMsg;
      if (window.jQuery) window.jQuery('#banReportModal').modal('show');
      else alert(fallbackMsg || '제재회원은 해당 기능을 이용할 수 없습니다.');
    }

    function openBanReportModal() {
      openBanActionModal(
        '제재회원은 게시글 신고를 이용할 수 없습니다.<br/>현재는 조회만 가능합니다.',
        '제재회원은 게시글 신고를 이용할 수 없습니다. 현재는 조회만 가능합니다.'
      );
    }

    $btnReport.addEventListener('click', function () {
      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }

      if (typeof isBanned !== 'undefined' && isBanned) {
        openBanReportModal();
        return;
      }

      if (window.jQuery) window.jQuery('#reportModal').modal('show');
    });

    $btnReportSubmit.addEventListener('click', function () {
      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }

      if (typeof isBanned !== 'undefined' && isBanned) {
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
          if (window.jQuery) window.jQuery('#reportModal').modal('hide');
          if ($reportContent) $reportContent.value = '';
          if ($btnReport) $btnReport.style.display = 'none';

          if (window.Swal && typeof window.Swal.fire === 'function') {
            return window.Swal.fire({
              icon: 'success',
              title: '신고 접수 완료',
              text: '신고가 정상적으로 접수되었습니다.',
              confirmButtonText: '확인'
            });
          } else {
            alert('신고가 접수되었습니다.');
          }
        })
        .catch(function (e) {
          if (e && e.code === 403) return;
          console.error(e);
          if (window.Swal && typeof window.Swal.fire === 'function') {
            window.Swal.fire({
              icon: 'error',
              title: '신고 접수 실패',
              text: '신고 접수에 실패했습니다. 잠시 후 다시 시도해주세요.',
              confirmButtonText: '확인'
            });
          } else {
            alert('신고 접수에 실패했습니다.');
          }
        });
    });
  }

  // =========================================================
  // Init
  // =========================================================
  function init() {
    normalizeEditorMediaUrls();
    ensureDeletedModal();

    initLike();
    initLikeUsers();
    initReport();

    bindReplyEvents();

    loadReplies(getSelectedCondition()).catch(function (e) {
      if (e && e.code === 403) return;
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