// /js/boarddetail.js
// =========================================================
// Board Detail Page Script (ES5 + fetch)
//
// 목표
// 1) 게시글 상세에서 좋아요/댓글/신고를 비동기로 처리
// 2) 서버에서 403(삭제된 게시글)을 내려주면 모달 띄우고 이후 모든 액션 차단
//
// 전제(서버/JSP에서 주입되는 전역 변수)
// - ctx: contextPath
// - boardId: 현재 게시글 ID
// - isLogin: 로그인 여부(boolean 또는 1/0 등)
// - sessionMemberId: 로그인한 회원 ID
// - sessionMemberRole: 로그인한 회원 권한(ADMIN/USER 등)
// - isReported: 이미 신고한 게시글인지 여부
// - isBanned: 제재 회원인지 여부
// =========================================================
(function () {
  'use strict';

  // =========================================================
  // 비동기 요청이 필요한 URL만 한곳에 모아두기
  // (JSP에서 ctx 주입되니까 상대경로를 ctx 기준으로 합쳐서 만든다)
  // =========================================================
  var API = {
    likeToggle: ctx + '/BoardLikeToggle',
    likeMembers: ctx + '/LikeMemberList',
    replyOrder: ctx + '/ReplyListOrder',
    boardReport: ctx + '/report/board'
  };

  // =========================================================
  // DOM 캐시
  // 자주 쓰는 요소는 한번만 찾아서 변수로 들고 있는 방식
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
  // 삭제된 게시글(403) 상태 플래그
  // 한번 403을 받으면 이후 fetch 요청은 전부 차단해서
  // "삭제된 글인데도 좋아요/댓글/신고 눌리는" 상황을 막는다
  // =========================================================
  var __deletedBlocked = false;

  // =========================================================
  // 삭제 안내 모달 DOM이 없으면 생성해둔다
  // Bootstrap 모달을 기준으로 만들었고, jQuery 없으면 alert로 대체됨
  // =========================================================
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

  // =========================================================
  // 403(삭제된 글) 수신 시 실행되는 루틴
  // 1) blocked 플래그 켜기
  // 2) UI 버튼/입력 잠금
  // 3) 모달 표시(없으면 alert)
  // =========================================================
  function showDeleted403Modal() {
    __deletedBlocked = true;
    ensureDeletedModal();

    lockAllActionsUI();

    if (window.jQuery) {
      window.jQuery('#deletedGuardModal').modal('show');
    } else {
      alert('삭제된 게시글입니다. 목록으로 이동 후 다시 시도해주세요.');
    }
  }

  // =========================================================
  // 페이지 내 사용자 액션을 전부 잠그는 처리
  // (좋아요/신고/댓글 작성/댓글 액션 버튼 등)
  // =========================================================
  function lockAllActionsUI() {
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

    if ($replyContent) $replyContent.disabled = true;
    if ($replyForm) {
      var btns = $replyForm.querySelectorAll('button, input[type="submit"]');
      for (var i = 0; i < btns.length; i++) btns[i].disabled = true;
    }

    if ($replyList) {
      var actBtns = $replyList.querySelectorAll('button');
      for (var j = 0; j < actBtns.length; j++) actBtns[j].disabled = true;
    }
  }

  // =========================================================
  // 제재 회원 공통 안내 메시지
  // 액션별로 텍스트만 바꿔서 재사용한다
  // =========================================================
  function alertBanned(actionText) {
    alert('제재회원은 ' + (actionText || '해당 기능') + '이(가) 제한됩니다.');
  }

  // =========================================================
  // Utils
  // =========================================================

  // HTML 이스케이프(댓글/닉네임/이미지 경로 등 XSS 방지용)
  function escapeHtml(v) {
    var s = (v === null || v === undefined) ? '' : String(v);
    return s
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  // textarea에서 줄바꿈을 화면 출력용 <br/>로 변환
  function nl2br(v) {
    return escapeHtml(v).replace(/\r?\n/g, '<br/>');
  }

  // 색상값을 CSS에 바로 넣기 전에 화이트리스트로 제한
  // (임의 문자열 주입 방지 + 깨진 스타일 방지)
  function sanitizeColor(v) {
    if (!v) return '';
    var s = String(v).trim();
    if (/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(s)) return s;
    if (/^(rgb|rgba|hsl|hsla)\(\s*[-0-9.,% ]+\s*\)$/.test(s)) return s;
    if (/^[a-zA-Z]+$/.test(s)) return s;
    return '';
  }

  // 프로필 이미지 등 경로 정규화
  // - http(s)/data/blob는 그대로 사용
  // - "/..." 절대경로면 ctx 붙여서 사용
  // - 그 외 상대경로면 ctx + "/" 붙여서 사용
  function normalizeUrl(src) {
    if (!src) return '';
    var s = String(src).trim();
    if (!s) return '';
    if (/^(https?:|data:|blob:)/i.test(s)) return s;
    if (ctx && s.indexOf(ctx + '/') === 0) return s;
    if (s.charAt(0) === '/') return ctx + s;
    return ctx + '/' + s;
  }

  // 서버에서 boolean/1/'true' 등 여러 형태로 내려오는 값을 한 번에 판정
  function isTruthy(v) {
    return v === true || v === 1 || v === '1' || v === 'true';
  }

  // 댓글 수 텍스트 업데이트
  function setReplyCount(n) {
    if ($replyCount) $replyCount.textContent = String(n);
  }

  // 댓글 없음 안내 영역 표시/숨김
  function showReplyEmpty(show) {
    if (!$replyEmpty) return;
    $replyEmpty.style.display = show ? 'block' : 'none';
  }

  // 기존 댓글 아이템 DOM 제거(정렬/리로드 시 중복 방지)
  function removeAllReplyItems() {
    if (!$replyList) return;
    var items = $replyList.querySelectorAll('.reply-item');
    for (var i = 0; i < items.length; i++) {
      items[i].parentNode.removeChild(items[i]);
    }
  }

  // 댓글 수정 가능 조건: 로그인 + 제재아님 + 본인 댓글
  function canEditReply(r) {
    if (!isLogin) return false;
    if (typeof isBanned !== 'undefined' && isBanned) return false;
    return String(r.memberId) === String(sessionMemberId);
  }

  // 댓글 삭제 가능 조건: 로그인 + 제재아님 + 본인 댓글 or ADMIN
  function canDeleteReply(r) {
    if (!isLogin) return false;
    if (typeof isBanned !== 'undefined' && isBanned) return false;
    if (String(r.memberId) === String(sessionMemberId)) return true;
    return String(sessionMemberRole) === 'ADMIN';
  }

  // =========================================================
  // CKEditor 본문(이미지/영상 등)의 src 보정
  // 에디터가 상대경로로 저장하는 경우가 있어서 ctx 기준으로 경로 붙여준다
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
  // 공통 포인트:
  // - blocked 상태면 요청 자체를 거부
  // - 응답이 403이면 모달 띄우고 예외로 흐름 끊기
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

  // 폼 제출도 fetch로 보내서 403을 동일하게 잡는다
  // 서버에서 redirect 응답이면 그 URL로 이동, 아니면 reload 처리
  function submitFormByFetch(formEl, formData) {
    if (__deletedBlocked) return Promise.reject(new Error('BLOCKED'));
    var url = formEl.getAttribute('action');
    var method = (formEl.getAttribute('method') || 'POST').toUpperCase();

    return fetch(url, { method: method, body: formData, credentials: 'same-origin' })
      .then(guard403)
      .then(function (res) {
        if (res.redirected) {
          window.location.href = res.url;
          return null;
        }
        if (!res.ok) throw new Error('FORM failed: ' + res.status);
        window.location.reload();
        return null;
      });
  }

  // =========================================================
  // Like
  // =========================================================

  // 좋아요 UI 토글 (버튼 텍스트/상태/카운트)
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

  // 좋아요 버튼 클릭 → 토글 API 호출
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
          if (e && e.code === 403) return;
          console.error(e);
          alert('서버 통신 오류가 발생했습니다.');
        });
    });
  }

  // 좋아요 누른 유저 목록 모달 렌더링
  // 리스트 DOM이 없으면 최소한의 fallback(alert)로 이름만 출력
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

  // 좋아요 유저 목록 버튼 클릭 → 목록 조회 API 호출 → 모달 오픈
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

  // 정렬 select의 현재 값
  function getSelectedCondition() {
    if (!$replySort) return CONDITION_RECENT;
    var v = ($replySort.value || '').trim();
    return (v === CONDITION_OLDEST) ? CONDITION_OLDEST : CONDITION_RECENT;
  }

  // 댓글 1개를 HTML로 변환
  // - 닉네임/프로필/색상/관리자 장식(rainbow) 처리 포함
  // - 수정/삭제 버튼은 권한에 따라 노출
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

    // 관리자가 작성한 댓글인데 닉네임 색이 없으면, 기본 장식 클래스로 무지개 처리
    if (isAdminWriter && !nickColor) {
      decoClass = (decoClass ? (decoClass + ' ') : '') + 'is-rainbow';
    }

    // 프로필 컬러가 있으면 링/쉐도우 효과를 inline style로 준다
    var avatarFx = '';
    if (profileColor) {
      avatarFx =
        'border-color:' + escapeHtml(profileColor) + ';' +
        'box-shadow:0 0 0 3px rgba(255,255,255,0.06), 0 0 18px ' + escapeHtml(profileColor) + ';';
    }

    // 관리자인데 별도 프로필 색상이 없으면 무지개 링을 적용
    var useRainbowRing = (isAdminWriter && !profileColor);

    // 프로필 이미지가 있으면 img, 없으면 첫 글자 fallback
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

    // 닉네임 색상이 있고, 무지개 클래스가 아니면 inline color 적용
    var nickStyleAttr = (nickColor && !/\bis-rainbow\b/.test(decoClass))
      ? (" style='color:" + escapeHtml(nickColor) + ";'")
      : '';

    // 액션 버튼(수정/삭제)은 권한에 따라 생성
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

    // 수정 여부 판정
    // - isEdited가 오면 그 값을 우선
    // - 없으면 createdAt/updatedAt 비교로 추정
    var edited = isTruthy(r.isEdited);
    if (typeof r.isEdited === 'undefined' || r.isEdited === null) {
      edited = !!(r.replyUpdatedAt && r.replyCreatedAt && String(r.replyUpdatedAt) !== String(r.replyCreatedAt));
    }

    // 시간 표시 텍스트(수정일/작성일)
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

  // 댓글 목록 로드
  // - 정렬 조건(condition) 포함해서 API 호출
  // - 기존 목록 제거 후 새로 렌더
  // - 0개면 "댓글 없음" 안내 표시
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

      // empty 안내 영역 앞(beforebegin)에 끼워 넣는 방식(레이아웃 유지 목적)
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
    // niceSelect 사용 중이면 select UI 적용(없으면 무시)
    if ($replySort && window.jQuery && window.jQuery.fn && window.jQuery.fn.niceSelect) {
      try { window.jQuery($replySort).niceSelect(); } catch (e) {}
    }

    // 정렬 변경 시 댓글 리로드
    // 같은 값으로 짧은 시간 안에 여러 번 호출되는 경우를 막기 위해 간단한 디바운스/중복 방지 처리
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

      // niceSelect가 DOM 이벤트를 별도로 쏘는 경우가 있어서 jQuery 이벤트도 같이 묶어둠
      if (window.jQuery) {
        try { window.jQuery($replySort).on('change.replySort', requestReloadBySort); } catch (e) {}
        try {
          window.jQuery(document).on('click.replySort', '.reply-card .nice-select .option', function () {
            setTimeout(requestReloadBySort, 0);
          });
        } catch (e) {}
      }
    }

    // 댓글 작성
    // - 기본 submit을 막고 fetch로 전송해서 403을 통일 처리
    // - 작성 성공 시 redirect가 오면 그 URL로 이동, 아니면 reload
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

    // 댓글 리스트 영역에서 발생하는 버튼 클릭을 이벤트 위임으로 처리
    // (댓글이 동적으로 렌더되기 때문에 개별 바인딩이 아니라 상위에서 잡는다)
    if ($replyList) {
      $replyList.addEventListener('click', function (e) {
        var target = e.target;
        if (!target) return;

        var item = target.closest ? target.closest('.reply-item') : null;
        if (!item) return;

        var replyId = item.getAttribute('data-reply-id');

        // 제재 회원은 수정/삭제 액션을 눌러도 안내만 띄우고 종료
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

        // 댓글 삭제
        // - hidden form에 boardId/replyId 세팅 후 fetch 제출
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

        // 댓글 수정 시작(인라인 textarea로 교체)
        // - 기존 텍스트는 data-original-content로 저장해두고 취소 시 복구
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

        // 댓글 수정 저장
        // - hidden form에 boardId/replyId/content 세팅 후 fetch 제출
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

        // 댓글 수정 취소
        // - data-original-content로 원복하고 버튼 상태도 원래대로 되돌린다
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
  // - 이미 신고한 글(isReported)이면 신고 버튼 숨김
  // - 제재 회원은 신고 모달 대신 제한 안내 모달로 유도
  // - 신고 제출도 fetch로 처리해서 403을 통일 처리
  // =========================================================
  function initReport() {
    if (!$btnReport || !$btnReportSubmit) return;

    if (typeof isReported !== 'undefined' && isReported) {
      $btnReport.style.display = 'none';
      return;
    }

    // 제재 회원 안내 모달(텍스트만 바꿔 재사용)
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

    // 신고 버튼 클릭 → 로그인/제재 체크 후 신고 모달 열기
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

    // 신고 제출 버튼 클릭 → FormData 구성 후 신고 API 호출
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

          // SweetAlert가 있으면 그걸 우선 사용(없으면 alert)
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
  // 페이지 로드시 한 번만 실행되는 초기화 루틴
  // 1) 에디터 본문 src 보정
  // 2) 삭제 안내 모달 미리 생성
  // 3) 좋아요/목록/신고/댓글 이벤트 바인딩
  // 4) 댓글 첫 로드(기본은 최신순)
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

  // DOMContentLoaded 이전이면 이벤트로 걸고, 이미 로드된 상태면 바로 실행
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();