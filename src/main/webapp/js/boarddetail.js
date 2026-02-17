(function () {
  'use strict';

  // JSP에서 내려온 전역: ctx, boardId, isLogin, sessionMemberId, sessionMemberRole, isReported

  // =========================================================
  // API 매핑
  // =========================================================
  var API = {
    likeToggle: ctx + '/BoardLikeToggle',     // POST {boardId}
    likeMembers: ctx + '/LikeMemberList',     // GET  ?boardId=
    replyOrder: ctx + '/ReplyListOrder',      // GET  ?boardId=&condition=
    replyWrite: ctx + '/replyWrite',          // POST {boardId, replyContent}
    replyEdit: ctx + '/replyEdit',            // POST {boardId, replyId, replyContent}
    replyDelete: ctx + '/replyDelete',        // POST {boardId, replyId}
    boardReport: ctx + '/boardReport'         // POST {boardId, reportReason, reportContent}
  };

  // =========================================================
  // DOM
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
    return String(r.memberId) === String(sessionMemberId);
  }

  function canDeleteReply(r) {
    if (!isLogin) return false;
    if (String(r.memberId) === String(sessionMemberId)) return true;
    return String(sessionMemberRole) === 'ADMIN';
  }

  function isTruthy(v) {
    return v === true || v === 1 || v === '1' || v === 'true';
  }

  // =========================================================
  // CKEditor src 경로 보정
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
  // HTTP
  // =========================================================
  function httpGetJson(url) {
    return fetch(url, { method: 'GET' }).then(function (res) {
      if (!res.ok) throw new Error('GET failed: ' + res.status);
      return res.json();
    });
  }

  function httpPostForm(url, formData) {
    return fetch(url, { method: 'POST', body: formData }).then(function (res) {
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
          console.error(e);
          alert('서버 통신 오류가 발생했습니다.');
        });
    });
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
  // Replies
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

    // 서버 필드명 폴백들
    var profileImgRaw = r.writerProfileImage || r.writerProfileImg || r.writer_profile_image || '';
    var profileImg = normalizeUrl(profileImgRaw);

    var nickColor = sanitizeColor(r.writerNicknameColor || r.writer_nickname_color || '');
    var profileColor = sanitizeColor(r.writerProfileColor || r.writer_profile_color || '');
    var decoClass = (r.writerDecoClass || r.writer_deco_class || '').trim();

    // 아바타 스타일
    var avatarFx = '';
    if (profileColor) {
      avatarFx =
        'border-color:' + escapeHtml(profileColor) + ';' +
        'box-shadow:0 0 0 3px rgba(255,255,255,0.06), 0 0 18px ' + escapeHtml(profileColor) + ';';
    }

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

    // 닉네임 스타일
    var nickStyleAttr = nickColor ? (" style='color:" + escapeHtml(nickColor) + ";'") : '';

    // 액션
    var actions = '';
    if (canEditReply(r) || canDeleteReply(r)) {
      actions += "<div class='reply-actions'>";
      if (canEditReply(r)) actions += "<button type='button' class='btn-reply-edit'>수정</button>";
      if (canDeleteReply(r)) actions += "<button type='button' class='btn-reply-del'>삭제</button>";
      actions += "</div>";
    }

    // 수정 여부
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
      $replyEmpty.insertAdjacentHTML('beforebegin', html);
    });
  }

  function writeReply(content) {
    var fd = new FormData();
    var bid = ($replyBoardId && $replyBoardId.value) ? $replyBoardId.value : boardId;

    fd.append('boardId', bid);
    fd.append('replyContent', content);

    return httpPostForm(API.replyWrite, fd);
  }

  function editReply(replyId, content) {
    var fd = new FormData();
    fd.append('boardId', boardId);
    fd.append('replyId', replyId);
    fd.append('replyContent', content);
    return httpPostForm(API.replyEdit, fd);
  }

  function deleteReply(replyId) {
    var fd = new FormData();
    fd.append('boardId', boardId);
    fd.append('replyId', replyId);
    return httpPostForm(API.replyDelete, fd);
  }

  function bindReplyEvents() {
    if ($replySort && window.jQuery && window.jQuery.fn && window.jQuery.fn.niceSelect) {
      try { window.jQuery($replySort).niceSelect(); } catch (e) {}
    }

    if ($replySort) {
      $replySort.addEventListener('change', function () {
        loadReplies(getSelectedCondition()).catch(function (e) {
          console.error(e);
        });
      });
    }

    if ($replyForm) {
      $replyForm.addEventListener('submit', function (e) {
        e.preventDefault();

        if (!isLogin) {
          alert('로그인 후 이용 가능합니다.');
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

    if ($replyList) {
      $replyList.addEventListener('click', function (e) {
        var target = e.target;
        if (!target) return;

        var item = target.closest ? target.closest('.reply-item') : null;
        if (!item) return;

        var replyId = item.getAttribute('data-reply-id');

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
  // Report
  // =========================================================
  function initReport() {
    if (!$btnReport || !$btnReportSubmit) return;

    // JSP에서 버튼 자체를 안 그리지만, 혹시 남는 케이스 대비
    if (typeof isReported !== 'undefined' && isReported) {
      $btnReport.style.display = 'none';
      return;
    }

    $btnReport.addEventListener('click', function () {
      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }
      if (window.jQuery) window.jQuery('#reportModal').modal('show');
    });

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

          // 즉시 UX 반영
          if ($btnReport) $btnReport.style.display = 'none';
        })
        .catch(function (e) {
          console.error(e);
          alert('신고 접수에 실패했습니다.');
        });
    });
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
