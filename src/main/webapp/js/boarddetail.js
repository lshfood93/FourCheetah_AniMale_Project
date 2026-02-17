(function () {
  'use strict';

  // JSP에서 내려온 전역: ctx, boardId, isLogin, sessionMemberId, sessionMemberRole

  // =========================================================
  // API 매핑 (Spring Boot Controller 기준)
  // =========================================================
  var API = {
    // 좋아요(네 프로젝트 기존 유지)
    likeToggle: ctx + '/BoardLikeToggle',     // POST  {boardId}
    likeMembers: ctx + '/LikeMemberList',     // GET   ?boardId=
    replyOrder: ctx + '/ReplyListOrder',      // GET   ?boardId=&condition=

    // ✅ 댓글(네 ReplyController 기준: /replyWrite, /replyEdit, /replyDelete)
    replyWrite: ctx + '/replyWrite',          // POST {boardId, replyContent}
    replyEdit: ctx + '/replyEdit',            // POST {boardId, replyId, replyContent}
    replyDelete: ctx + '/replyDelete',        // POST {boardId, replyId}

    // ✅ 게시글 신고(프론트만 먼저 추가)
    // 백엔드 컨트롤러는 /boardReport 로 맞춰서 만들면 됨
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

  // 신고
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
          // 응답 포맷이 프로젝트마다 다를 수 있으니 여기만 맞춰주면 됨
          // 예: { ok:true, users:[{memberNickname:"..."}] }
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

  // ✅ 댓글 작성자 프로필 노출(서버가 내려주면 표시)
  // r.writerNickname, r.writerProfileImg, r.writerDecoClass 같은 필드가 있으면 바로 반영됨
  function renderReplyItem(r) {
    var nickname = (r.writerNickname && String(r.writerNickname).trim() !== '')
      ? r.writerNickname
      : r.memberId;

    var profileImg = r.writerProfileImg;     // 서버에서 내려주면 사용
    var decoClass = r.writerDecoClass || ''; // 서버에서 내려주면 사용(꾸미기 효과)

    var avatarHtml = '';
    if (profileImg) {
      avatarHtml = "<img class='reply-avatar' src='" + escapeHtml(profileImg) + "' alt='profile'/>";
    } else {
      // fallback: 첫 글자
      var initial = String(nickname).charAt(0);
      avatarHtml = "<div class='reply-avatar' style='width:32px;height:32px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,0.10);border:1px solid rgba(255,255,255,0.12);font-weight:900;'>" + escapeHtml(initial) + "</div>";
    }

    var actions = '';
    if (canEditReply(r) || canDeleteReply(r)) {
      actions += "<div class='reply-actions'>";
      if (canEditReply(r)) actions += "<button type='button' class='btn-reply-edit'>수정</button>";
      if (canDeleteReply(r)) actions += "<button type='button' class='btn-reply-del'>삭제</button>";
      actions += "</div>";
    }

    return (
      "<div class='reply-item' data-reply-id='" + escapeHtml(r.replyId) + "'>" +
        "<div class='reply-top'>" +
          "<div style='display:flex; gap:10px; align-items:flex-start;'>" +
            avatarHtml +
            "<div>" +
              "<div class='reply-writer " + escapeHtml(decoClass) + "'>" + escapeHtml(nickname) + "</div>" +
              "<div class='reply-times'>" +
                "<span class='t-created'>작성 " + escapeHtml(r.replyCreatedAt || '') + "</span>" +
                (r.replyUpdatedAt && String(r.replyUpdatedAt) !== String(r.replyCreatedAt)
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

    // ✅ hidden input이 있으면 그걸 우선 사용(바인딩 실패 방지)
    var bid = ($replyBoardId && $replyBoardId.value) ? $replyBoardId.value : boardId;

    fd.append('boardId', bid);
    fd.append('replyContent', content);

    return httpPostForm(API.replyWrite, fd);
  }

  function editReply(replyId, content) {
    var fd = new FormData();
    fd.append('boardId', boardId);     // ✅ ReplyController가 boardId 검증함 (필수)
    fd.append('replyId', replyId);
    fd.append('replyContent', content);
    return httpPostForm(API.replyEdit, fd);
  }

  function deleteReply(replyId) {
    var fd = new FormData();
    fd.append('boardId', boardId);     // ✅ ReplyController가 boardId 검증함 (필수)
    fd.append('replyId', replyId);
    return httpPostForm(API.replyDelete, fd);
  }

  function bindReplyEvents() {
    // nice-select 적용(있으면)
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
            // 여기서 500이 나면, 서버(ReplyController/AOP)에서 boardId=0으로 본 케이스가 많음
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

    $btnReport.addEventListener('click', function () {
      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }
      // bootstrap modal
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
        .then(function (res) {
          // 서버가 JSON을 주면 여기서 res.json()으로 바꿔도 됨
          alert('신고가 접수되었습니다.');
          if ($reportContent) $reportContent.value = '';
          if (window.jQuery) window.jQuery('#reportModal').modal('hide');
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
