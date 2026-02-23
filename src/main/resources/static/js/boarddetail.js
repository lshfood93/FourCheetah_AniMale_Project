// /js/boarddetail.js
// =========================================================
// Board Detail Page Script (ES5 + fetch)
//
// 이 파일의 핵심 역할
// ---------------------------------------------------------
// 1) 게시글 상세 화면의 비동기 기능(좋아요 / 좋아요 사용자 목록 / 댓글 정렬 조회 / 신고)을 담당
// 2) 댓글 작성/수정/삭제 폼 제출을 fetch로 감싸서 403 응답(삭제된 게시글)을 공통 처리
// 3) 서버가 403(삭제된 게시글 접근 차단)을 주면, 사용자에게 안내 모달을 띄우고
//    이후 모든 액션(좋아요/신고/댓글)을 잠가서 UX 혼란을 줄임
//
// 구현 스타일
// ---------------------------------------------------------
// - ES5 문법 기준(프로젝트 호환성 고려)
// - IIFE(즉시실행함수)로 전역 오염 최소화
// - 이벤트 위임 사용(댓글 목록은 비동기 렌더링되므로 동적으로 생기는 버튼 대응 필요)
// =========================================================
(function () {
  'use strict';

  // =========================================================
  // JSP 전역 변수(계약)
  // ---------------------------------------------------------
  // 아래 변수들은 boarddetail.jsp에서 script로 미리 내려준다고 가정한다.
  // (이 JS 파일에서는 "존재한다고 믿고 사용"하는 계약 구조)
  //
  // const ctx                 : 컨텍스트 경로 (예: /animale)
  // const boardId             : 현재 게시글 ID
  // const isLogin             : 로그인 여부(boolean 성격)
  // const sessionMemberId     : 현재 로그인 사용자 ID
  // const sessionMemberRole   : 현재 로그인 사용자 권한(예: ADMIN)
  // const isReported          : 현재 사용자가 이미 이 글을 신고했는지 여부
  // const isBanned            : 제재회원 여부
  // =========================================================

  // =========================================================
  // API 매핑 (비동기 호출용 엔드포인트만 관리)
  // ---------------------------------------------------------
  // 목적:
  // - URL 하드코딩을 한 곳에 모아서 관리성 확보
  // - ctx(컨텍스트 경로) 변경 시도 대비
  // =========================================================
  var API = {
    likeToggle: ctx + '/BoardLikeToggle',
    likeMembers: ctx + '/LikeMemberList',
    replyOrder: ctx + '/ReplyListOrder',
    boardReport: ctx + '/report/board'
  };

  // =========================================================
  // DOM 캐시
  // ---------------------------------------------------------
  // 자주 접근하는 요소를 미리 가져와서 재사용한다.
  // 장점:
  // - querySelector/getElementById 반복 호출 감소
  // - 코드 가독성 향상(의미 있는 변수명 사용)
  // 주의:
  // - 일부 요소는 페이지 상태에 따라 없을 수 있으므로(null 가능성 항상 고려)
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
  // 댓글 정렬 조건값은 서버/DAO에서 기대하는 condition 문자열과 맞춰야 함
  var CONDITION_RECENT = 'REPLY_LIST_RECENT';
  var CONDITION_OLDEST = 'REPLY_LIST_OLDEST';

  var $btnReport = document.getElementById('btnReport');
  var $btnReportSubmit = document.getElementById('btnReportSubmit');
  var $reportReason = document.getElementById('reportReason');
  var $reportContent = document.getElementById('reportContent');

  // 댓글 수정용 hidden form (동기 submit 대신 fetch 래핑용으로도 사용)
  var $replyEditForm = document.getElementById('replyEditForm');
  var $editBoardId = document.getElementById('editBoardId');
  var $editReplyId = document.getElementById('editReplyId');
  var $editReplyContent = document.getElementById('editReplyContent');

  // 댓글 삭제용 hidden form
  var $replyDeleteForm = document.getElementById('replyDeleteForm');
  var $delBoardId = document.getElementById('delBoardId');
  var $delReplyId = document.getElementById('delReplyId');

  // 좋아요 누른 사용자 목록 모달 영역
  var $likeUsersList = document.getElementById('likeUsersList');
  var $likeUsersEmpty = document.getElementById('likeUsersEmpty');

  // 제재회원 안내 모달 내 텍스트 영역 (페이지에 있을 수도 / 없을 수도 있음)
  var $banActionText = document.getElementById('banActionText');

  // =========================================================
  // Deleted Guard (403 응답 공통 처리)
  // ---------------------------------------------------------
  // 배경:
  // - 상세 페이지에 머무는 동안, 다른 곳에서 게시글이 삭제될 수 있음
  // - 이때 사용자가 좋아요/댓글/신고를 누르면 서버가 403을 줄 수 있음
  // - 서버 응답마다 제각각 처리하면 UX가 들쭉날쭉하므로 "공통 가드"로 통합
  //
  // 전략:
  // 1) fetch 응답에서 status===403 감지
  // 2) 안내 모달 표시
  // 3) 화면 내 액션 UI 전체 잠금
  // 4) 이후 요청은 __deletedBlocked로 선차단
  // =========================================================
  var __deletedBlocked = false;

  function ensureDeletedModal() {
    // 이미 생성되어 있으면 중복 생성 방지
    if (document.getElementById('deletedGuardModal')) return;

    // 문자열 템플릿으로 모달 DOM 생성
    // 주의:
    // - ctx를 링크에 삽입하므로 escapeHtml(ctx) 적용
    // - innerHTML 사용 구간이므로 외부 입력 값은 반드시 escape 처리
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

    // wrap.firstChild만 body에 붙여 실제 모달 DOM 삽입
    document.body.appendChild(wrap.firstChild);
  }

  function showDeleted403Modal() {
    // 한 번 403을 받으면 이후 액션은 모두 차단하도록 플래그 고정
    __deletedBlocked = true;

    // 모달이 없으면 생성
    ensureDeletedModal();

    // 현재 화면에서 누를 수 있는 액션들 비활성화
    lockAllActionsUI();

    // Bootstrap(jQuery modal) 사용 가능하면 모달 표시
    // 없으면 fallback alert라도 띄워서 사용자에게 사유 전달
    if (window.jQuery) {
      window.jQuery('#deletedGuardModal').modal('show');
    } else {
      alert('삭제된 게시글입니다. 목록으로 이동 후 다시 시도해주세요.');
    }
  }

  function lockAllActionsUI() {
    // 좋아요/신고 버튼 잠금
    // - disabled로 클릭 자체 차단
    // - 클래스 추가로 시각적 상태도 표현(회색 처리 등 CSS 연동 가능)
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

    // 댓글 작성 폼 잠금
    if ($replyContent) $replyContent.disabled = true;
    if ($replyForm) {
      var btns = $replyForm.querySelectorAll('button, input[type="submit"]');
      for (var i = 0; i < btns.length; i++) btns[i].disabled = true;
    }

    // 댓글 리스트 내부의 수정/삭제 등 버튼 잠금
    // (비동기 렌더된 버튼들까지 한번에 잠그기 위함)
    if ($replyList) {
      var actBtns = $replyList.querySelectorAll('button');
      for (var j = 0; j < actBtns.length; j++) actBtns[j].disabled = true;
    }
  }

  // =========================================================
  // 제재회원 공통 안내
  // ---------------------------------------------------------
  // 여러 기능(댓글 작성/수정/삭제 등)에서 같은 경고를 반복하므로
  // 메시지 문구를 공통 함수로 통일한다.
  // =========================================================
  function alertBanned(actionText) {
    alert('제재회원은 ' + (actionText || '해당 기능') + '이(가) 제한됩니다.');
  }

  // =========================================================
  // Utils (공통 유틸 함수)
  // =========================================================

  function escapeHtml(v) {
    // HTML 문자열 조립(innerHTML) 전에 XSS/마크업 깨짐 방지용 이스케이프
    // 댓글 닉네임/텍스트/속성값 등 사용자 데이터는 반드시 escape 후 삽입
    var s = (v === null || v === undefined) ? '' : String(v);
    return s
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function nl2br(v) {
    // 댓글 본문을 텍스트로 안전 출력하면서 줄바꿈만 <br>로 반영
    // 순서가 중요함:
    // 1) escapeHtml로 HTML 무력화
    // 2) 줄바꿈 문자만 <br>로 변환
    return escapeHtml(v).replace(/\r?\n/g, '<br/>');
  }

  function sanitizeColor(v) {
    // 스타일 속성에 들어갈 색상 값 화이트리스트 검증
    // 목적:
    // - style='color: ...' / border-color 등에 임의 문자열 주입 방지
    // 허용:
    // - hex(#fff / #ffffff / #ffffffff)
    // - rgb()/rgba()/hsl()/hsla()
    // - 단순 알파벳 색상명(red, blue ...)
    if (!v) return '';
    var s = String(v).trim();

    if (/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(s)) return s;
    if (/^(rgb|rgba|hsl|hsla)\(\s*[-0-9.,% ]+\s*\)$/.test(s)) return s;
    if (/^[a-zA-Z]+$/.test(s)) return s;

    return '';
  }

  function normalizeUrl(src) {
    // 프로필 이미지/미디어 src 경로를 프로젝트 ctx 기준으로 정규화
    // 허용 케이스:
    // - 절대 URL(http/https)
    // - data:, blob:
    // - 이미 ctx로 시작하는 앱 내부 경로
    // - '/...' 루트 상대 경로 -> ctx + src 로 변환
    // - 그 외 상대경로 -> ctx + '/' + src
    if (!src) return '';
    var s = String(src).trim();
    if (!s) return '';

    if (/^(https?:|data:|blob:)/i.test(s)) return s;
    if (ctx && s.indexOf(ctx + '/') === 0) return s;
    if (s.charAt(0) === '/') return ctx + s;

    return ctx + '/' + s;
  }

  function isTruthy(v) {
    // 서버 응답값이 boolean/number/string 형태로 섞여 내려올 수 있어서
    // true / 1 / '1' / 'true'를 모두 truthy로 통일
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
    // 댓글 목록을 새로 렌더링하기 전에 기존 reply-item만 제거
    // 주의:
    // - replyList 전체 innerHTML=''로 날리면 고정 영역/빈 상태 영역 구조를 깨뜨릴 수 있어
    // - 그래서 .reply-item만 선택 제거
    if (!$replyList) return;

    var items = $replyList.querySelectorAll('.reply-item');
    for (var i = 0; i < items.length; i++) {
      items[i].parentNode.removeChild(items[i]);
    }
  }

  function canEditReply(r) {
    // 댓글 수정 가능 조건:
    // 1) 로그인 상태
    // 2) 제재회원 아님
    // 3) 댓글 작성자 == 현재 로그인 사용자
    if (!isLogin) return false;
    if (typeof isBanned !== 'undefined' && isBanned) return false;
    return String(r.memberId) === String(sessionMemberId);
  }

  function canDeleteReply(r) {
    // 댓글 삭제 가능 조건:
    // 1) 로그인 상태
    // 2) 제재회원 아님
    // 3) 본인 댓글이거나 ADMIN
    if (!isLogin) return false;
    if (typeof isBanned !== 'undefined' && isBanned) return false;

    if (String(r.memberId) === String(sessionMemberId)) return true;
    return String(sessionMemberRole) === 'ADMIN';
  }

  // =========================================================
  // CKEditor src 보정
  // ---------------------------------------------------------
  // 게시글 본문(.bd-content)에 들어간 미디어(img/iframe/video/source)의 src가
  // 상대경로로 저장되어 있으면 현재 페이지 기준으로 깨질 수 있다.
  // 이를 ctx 기준 절대에 가까운 앱 경로로 보정해서 미디어가 정상 출력되게 한다.
  // =========================================================
  function normalizeEditorMediaUrls() {
    var root = (typeof ctx === 'string') ? ctx : '';
    var nodes = document.querySelectorAll('.bd-content img, .bd-content iframe, .bd-content video, .bd-content source');

    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      var src = el.getAttribute('src');
      if (!src) continue;

      // 이미 완전한 URL / data/blob 이면 건드리지 않음
      if (/^(https?:|data:|blob:)/i.test(src)) continue;

      // 이미 ctx가 붙어 있으면 중복 보정 방지
      if (root && src.indexOf(root + '/') === 0) continue;

      if (src.charAt(0) === '/') el.setAttribute('src', root + src);
      else el.setAttribute('src', root + '/' + src);
    }
  }

  // =========================================================
  // HTTP 래퍼 (403 처리 포함)
  // ---------------------------------------------------------
  // 목적:
  // - fetch 호출마다 403 처리 로직 중복 제거
  // - 삭제된 게시글 상태를 공통으로 감지/차단
  // - GET/POST/Form 제출 패턴을 통일
  // =========================================================
  function guard403(res) {
    // 서버가 403을 응답하면 "삭제된 게시글 접근 불가"로 간주
    // (현재 프로젝트 정책 기준)
    if (res && res.status === 403) {
      showDeleted403Modal();

      // catch에서 구분하기 쉽게 code=403를 가진 Error 생성
      var err = new Error('FORBIDDEN_403');
      err.code = 403;
      throw err;
    }
    return res;
  }

  function httpGetJson(url) {
    // 이미 삭제 가드가 발동한 상태면 네트워크 요청 자체를 보내지 않음
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

  // 폼 submit을 fetch로 감싸는 공통 함수
  // ---------------------------------------------------------
  // 왜 필요한가?
  // - 일반 form.submit()은 응답 status를 JS에서 가로채기 어려움
  // - fetch로 보내면 403(삭제된 글)을 감지해서 모달 처리 가능
  // - redirect 응답(res.redirected)도 감지해서 자연스럽게 이동 가능
  function submitFormByFetch(formEl, formData) {
    if (__deletedBlocked) return Promise.reject(new Error('BLOCKED'));

    var url = formEl.getAttribute('action');
    var method = (formEl.getAttribute('method') || 'POST').toUpperCase();

    return fetch(url, { method: method, body: formData, credentials: 'same-origin' })
      .then(guard403)
      .then(function (res) {
        // 댓글 작성/수정/삭제 후 서버가 redirect를 주는 기존 컨트롤러 흐름 유지
        if (res.redirected) {
          window.location.href = res.url;
          return null;
        }

        if (!res.ok) throw new Error('FORM failed: ' + res.status);

        // OK인데 redirect가 없으면 현재 페이지 새로고침으로 상태 반영
        window.location.reload();
        return null;
      });
  }

  // =========================================================
  // Like (좋아요)
  // =========================================================
  function setLikeUI(liked, likeCnt) {
    // 좋아요 pill 스타일 상태 갱신
    if ($likePill) $likePill.classList.toggle('is-liked', !!liked);

    // 버튼 텍스트 / 상태값(data-liked) 갱신
    if ($btnLike) {
      $btnLike.textContent = liked ? '좋아요 취소' : '좋아요';
      $btnLike.setAttribute('data-liked', liked ? '1' : '0');
    }

    // 좋아요 카운트 갱신
    if ($likeCount && likeCnt !== undefined && likeCnt !== null) {
      $likeCount.textContent = String(likeCnt);
    }
  }

  function initLike() {
    if (!$btnLike) return;

    // 초기 렌더된 data-liked 값 반영 (서버에서 이미 좋아요 상태를 내려준 경우)
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
          // 서버 표준 응답: { result:'OK', isLiked:1/0, likeCnt:n, msg?... } 가정
          if (!json || json.result !== 'OK') {
            alert((json && json.msg) ? json.msg : '처리에 실패했습니다.');
            return;
          }

          var liked = (Number(json.isLiked) === 1);
          var likeCnt = (json.likeCnt != null ? json.likeCnt : 0);

          setLikeUI(liked, likeCnt);
        })
        .catch(function (e) {
          // 403은 guard403에서 모달 처리 끝났으므로 여기서는 조용히 종료
          if (e && e.code === 403) return;

          console.error(e);
          alert('서버 통신 오류가 발생했습니다.');
        });
    });
  }

  function openLikeUsersModal(users) {
    // 모달 영역이 없는 페이지/템플릿이면 fallback alert 출력
    if (!$likeUsersList || !$likeUsersEmpty) {
      var namesFallback = [];
      for (var i = 0; i < users.length; i++) {
        namesFallback.push(users[i].memberNickname || users[i].nickname || 'unknown');
      }
      alert(namesFallback.join('\n'));
      return;
    }

    // 이전 목록 제거 후 새로 렌더
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

        // innerHTML 조립 시 name/img는 escape/normalize 처리된 값만 사용
        if (img) {
          li.innerHTML =
            "<img class='like-user-avatar' src='" + escapeHtml(img) + "' alt='avatar'/>" +
            "<div class='like-user-name'>" + escapeHtml(name) + "</div>";
        } else {
          // 프로필 이미지가 없으면 닉네임 첫 글자 fallback avatar 사용
          var initial = String(name).charAt(0);
          li.innerHTML =
            "<div class='like-user-avatar like-user-avatar--fallback'>" + escapeHtml(initial) + "</div>" +
            "<div class='like-user-name'>" + escapeHtml(name) + "</div>";
        }

        $likeUsersList.appendChild(li);
      }
    }

    // Bootstrap 모달 사용 가능 시 표시
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
          // 서버 응답 형식 가정:
          // { ok:true, users:[...] } 또는 { ok:false, message:'...' }
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
  // Replies - 조회 / 렌더 / 정렬
  // =========================================================
  function getSelectedCondition() {
    // 정렬 select가 없으면 최신순 기본값 사용
    if (!$replySort) return CONDITION_RECENT;

    var v = ($replySort.value || '').trim();
    return (v === CONDITION_OLDEST) ? CONDITION_OLDEST : CONDITION_RECENT;
  }

  function renderReplyItem(r) {
    // 댓글 작성자 표시명 우선순위:
    // writerNickname > memberId
    var nickname = (r.writerNickname && String(r.writerNickname).trim() !== '')
      ? r.writerNickname
      : r.memberId;

    // 관리자 작성자 여부 판단 (관리자 기본 무지개 스타일 폴백 처리용)
    // 서버에서 별도 role을 항상 내려주지 않는 구조를 고려해 닉네임 기반 보조 판정
    var isAdminWriter = false;
    try {
      var nn = String(nickname || '').trim();
      isAdminWriter = (nn === '관리자' || nn.toUpperCase() === 'ADMIN');
    } catch (e) { }

    // 서버 필드명 차이 대응 (camel/snake/별칭 혼용)
    var profileImgRaw = r.writerProfileImage || r.writerProfileImg || r.writer_profile_image || '';
    var profileImg = normalizeUrl(profileImgRaw);

    // 닉네임 색상 처리
    // -------------------------------------------------------
    // 정책:
    // - 'RAINBOW' 문자열은 인라인 색(style=color)로 넣지 않고
    //   CSS 클래스(is-rainbow)로 표현해야 함
    // - 일반 색상값만 sanitizeColor 통과 후 style 적용
    var rawNickColor = r.writerNicknameColor || r.writer_nickname_color || '';
    var isRainbowNick = (String(rawNickColor).trim().toUpperCase() === 'RAINBOW');
    var nickColor = isRainbowNick ? '' : sanitizeColor(rawNickColor);

    // 프로필 테두리/오라 색상 처리도 동일 정책
    var rawProfileColor = r.writerProfileColor || r.writer_profile_color || '';
    var isRainbowProfile = (String(rawProfileColor).trim().toUpperCase() === 'RAINBOW');
    var profileColor = isRainbowProfile ? '' : sanitizeColor(rawProfileColor);

    // 서버에서 내려줄 수 있는 추가 꾸밈 클래스
    var decoClass = (r.writerDecoClass || r.writer_deco_class || '').trim();

    // 닉네임 무지개 처리 보정
    // -------------------------------------------------------
    // 1) 관리자 작성자 + 닉네임 색상 null(관리자 기본 폴백)
    // 2) DB 값이 명시적으로 RAINBOW
    // 둘 다 is-rainbow 클래스 적용
    if ((isAdminWriter && !nickColor) || isRainbowNick) {
      decoClass = (decoClass ? (decoClass + ' ') : '') + 'is-rainbow';
    }

    // 프로필 아바타 외곽 효과(style) 구성
    // sanitizeColor 통과값만 사용하므로 style 삽입 안전성 확보
    var avatarFx = '';
    if (profileColor) {
      avatarFx =
        'border-color:' + escapeHtml(profileColor) + ';' +
        'box-shadow:0 0 0 3px rgba(255,255,255,0.06), 0 0 18px ' + escapeHtml(profileColor) + ';';
    }

    // 프로필 링 무지개 처리 보정
    // - 관리자 폴백 또는 DB RAINBOW이면 reply-avatar-ring.is-rainbow 적용
    var useRainbowRing = (isAdminWriter && !profileColor) || isRainbowProfile;

    // 아바타 HTML 생성 (이미지/폴백 분기)
    var avatarHtml = '';
    if (profileImg) {
      avatarHtml =
        (useRainbowRing ? "<div class='reply-avatar-ring is-rainbow'>" : "") +
        "<img class='reply-avatar' style='" + avatarFx + "' src='" + escapeHtml(profileImg) + "' alt='profile'/>" +
        (useRainbowRing ? "</div>" : "");
    } else {
      // 프로필 이미지가 없을 때 첫 글자 아바타
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

    // 닉네임 인라인 색상(style) 적용 여부 결정
    // - is-rainbow 클래스가 있으면 CSS 효과가 우선이므로 color style 적용 안 함
    var nickStyleAttr = (nickColor && !/\bis-rainbow\b/.test(decoClass))
      ? (" style='color:" + escapeHtml(nickColor) + ";'")
      : '';

    // 수정/삭제 액션 버튼 영역 생성
    // - 제재회원이면 렌더 자체를 숨김
    // - 권한(canEditReply / canDeleteReply) 기준으로 버튼 노출
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
    // -------------------------------------------------------
    // 1) 서버가 isEdited 내려주면 우선 사용
    // 2) 없으면 createdAt !== updatedAt 로 추론
    var edited = isTruthy(r.isEdited);
    if (typeof r.isEdited === 'undefined' || r.isEdited === null) {
      edited = !!(r.replyUpdatedAt && r.replyCreatedAt && String(r.replyUpdatedAt) !== String(r.replyCreatedAt));
    }

    // 작성일/수정일 표시 문구
    var timeHtml = '';
    if (edited && r.replyUpdatedAt) {
      timeHtml = "<span class='t-time'>수정일 " + escapeHtml(r.replyUpdatedAt || '') + "</span>";
    } else {
      timeHtml = "<span class='t-time'>작성일 " + escapeHtml(r.replyCreatedAt || '') + "</span>";
    }

    // 댓글 아이템 HTML 최종 조립
    // replyContent는 nl2br()로 escape + 줄바꿈 변환 후 삽입
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
    // 댓글 목록 영역이 없으면 아무 동작 안 하고 종료
    if (!$replyList) return Promise.resolve();

    var url = API.replyOrder
      + '?boardId=' + encodeURIComponent(boardId)
      + '&condition=' + encodeURIComponent(condition || CONDITION_RECENT);

    return httpGetJson(url).then(function (list) {
      // 서버가 배열이 아닌 값을 줘도 화면이 깨지지 않게 방어
      if (!Array.isArray(list)) list = [];

      setReplyCount(list.length);
      removeAllReplyItems();

      if (!list.length) {
        showReplyEmpty(true);
        return;
      }

      showReplyEmpty(false);

      // 문자열 누적으로 한 번에 insertAdjacentHTML 하여 DOM 조작 횟수 감소
      var html = '';
      for (var i = 0; i < list.length; i++) {
        html += renderReplyItem(list[i]);
      }

      // 빈 상태 안내문 앞(beforebegin)에 넣어서 안내문 위치/구조 유지
      if ($replyEmpty && $replyEmpty.insertAdjacentHTML) {
        $replyEmpty.insertAdjacentHTML('beforebegin', html);
      } else {
        // fallback: replyList 맨 끝에 추가
        $replyList.insertAdjacentHTML('beforeend', html);
      }
    });
  }

  // =========================================================
  // Replies - 이벤트(정렬 / 작성 / 수정 / 삭제)
  // =========================================================
  function bindReplyEvents() {
    // niceSelect 플러그인 적용 (있을 때만)
    // 플러그인 미존재 환경에서도 에러 없이 기본 select 동작 유지
    if ($replySort && window.jQuery && window.jQuery.fn && window.jQuery.fn.niceSelect) {
      try { window.jQuery($replySort).niceSelect(); } catch (e) {}
    }

    // -------------------------------------------------------
    // 댓글 정렬 변경 이벤트
    // -------------------------------------------------------
    // niceSelect 사용 시 change 이벤트가 중복 발생할 수 있어
    // 같은 조건 + 매우 짧은 간격(200ms) 내 중복 요청은 무시
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

      // 기본 select change
      $replySort.addEventListener('change', requestReloadBySort);

      // niceSelect/jQuery 이벤트도 함께 대응 (테마/플러그인 환경별 차이 흡수)
      if (window.jQuery) {
        try { window.jQuery($replySort).on('change.replySort', requestReloadBySort); } catch (e) {}

        try {
          window.jQuery(document).on('click.replySort', '.reply-card .nice-select .option', function () {
            // niceSelect가 실제 select 값을 갱신한 뒤 읽도록 setTimeout 0
            setTimeout(requestReloadBySort, 0);
          });
        } catch (e) {}
      }
    }

    // -------------------------------------------------------
    // 댓글 작성 submit
    // -------------------------------------------------------
    // fetch로 전환한 이유:
    // - 403(삭제된 게시글) 응답을 가로채서 공통 모달 처리하기 위해
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

    // -------------------------------------------------------
    // 댓글 리스트 버튼 이벤트 위임
    // -------------------------------------------------------
    // 이유:
    // - 댓글 목록은 loadReplies()로 매번 다시 렌더링됨
    // - 개별 버튼에 직접 바인딩하면 재렌더 때마다 재바인딩 필요
    // - 상위 컨테이너(replyList)에서 클릭을 받아 target으로 분기하는 구조가 적합
    if ($replyList) {
      $replyList.addEventListener('click', function (e) {
        var target = e.target;
        if (!target) return;

        // 클릭된 버튼이 어떤 reply-item 안에 있는지 찾기
        var item = target.closest ? target.closest('.reply-item') : null;
        if (!item) return;

        var replyId = item.getAttribute('data-reply-id');

        // 제재회원은 수정/삭제 관련 버튼 클릭 시 공통 안내 후 종료
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

        // =====================================================
        // 댓글 삭제
        // =====================================================
        if (target.classList.contains('btn-reply-del')) {
          if (!confirm('댓글을 삭제할까요?')) return;

          // hidden form 없으면 안전하게 종료
          if (!$replyDeleteForm || !$delBoardId || !$delReplyId) {
            alert('삭제 폼이 없어 삭제가 불가능합니다.');
            return;
          }

          // 서버 컨트롤러가 기대하는 값 세팅
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

        // =====================================================
        // 댓글 수정 시작 (인라인 편집 UI로 전환)
        // =====================================================
        if (target.classList.contains('btn-reply-edit')) {
          // 이미 편집 중이면 중복 진입 방지
          if (item.classList.contains('is-editing')) return;

          var contentEl = item.querySelector('.reply-content');
          if (!contentEl) return;

          // 취소 시 복원할 원문 저장
          var currentText = (contentEl.innerText || contentEl.textContent || '');
          item.setAttribute('data-original-content', currentText);

          // 댓글 본문 영역을 textarea로 교체
          contentEl.innerHTML = "<textarea class='reply-inline-textarea' rows='3' maxlength='500'></textarea>";

          var ta = contentEl.querySelector('textarea');
          if (ta) {
            ta.value = currentText;
            try { ta.focus(); } catch (err) {}
          }

          // 일반 액션 숨김 / 편집 액션 표시
          var act = item.querySelector('.reply-actions');
          var editAct = item.querySelector('.reply-edit-actions');
          if (act) act.style.display = 'none';
          if (editAct) editAct.style.display = 'flex';

          item.classList.add('is-editing');
          return;
        }

        // =====================================================
        // 댓글 수정 저장
        // =====================================================
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

        // =====================================================
        // 댓글 수정 취소
        // =====================================================
        if (target.classList.contains('btn-reply-cancel')) {
          // 저장해둔 원문 텍스트 복원
          var original = item.getAttribute('data-original-content') || '';
          var contentEl2 = item.querySelector('.reply-content');

          if (contentEl2) contentEl2.innerHTML = nl2br(original);

          // 액션 버튼 상태 원복
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
  // Report (게시글 신고)
  // ---------------------------------------------------------
  // 정책:
  // - 로그인 필요
  // - 제재회원은 신고 불가(전용 안내 모달/alert)
  // - 이미 신고한 경우 버튼 숨김
  // - 신고 제출도 fetch + 403 공통 처리
  // =========================================================
  function initReport() {
    if (!$btnReport || !$btnReportSubmit) return;

    // 이미 신고한 사용자면 버튼 자체를 숨겨 중복 신고 방지 UX 제공
    if (typeof isReported !== 'undefined' && isReported) {
      $btnReport.style.display = 'none';
      return;
    }

    function openBanActionModal(htmlMsg, fallbackMsg) {
      // 페이지에 제재 안내 모달이 있을 경우 동적 문구 주입
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

    // 신고 버튼 클릭 -> 신고 모달 열기 (로그인/제재 상태 확인)
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

    // 신고 제출 버튼 클릭
    $btnReportSubmit.addEventListener('click', function () {
      if (!isLogin) {
        alert('로그인 후 이용 가능합니다.');
        return;
      }

      if (typeof isBanned !== 'undefined' && isBanned) {
        // 신고 작성 모달이 열려 있다면 닫고 제재 안내 모달로 전환
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
          // 성공 시 신고 모달 닫기 / 입력값 초기화 / 버튼 숨김
          if (window.jQuery) window.jQuery('#reportModal').modal('hide');
          if ($reportContent) $reportContent.value = '';
          if ($btnReport) $btnReport.style.display = 'none';

          // SweetAlert2 사용 가능하면 예쁜 성공 모달, 없으면 alert fallback
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
  // Init (초기화 진입점)
  // ---------------------------------------------------------
  // 초기화 순서 의도:
  // 1) 본문 미디어 src 보정
  // 2) 삭제 가드 모달 준비
  // 3) 개별 기능 초기화(좋아요/좋아요목록/신고)
  // 4) 댓글 이벤트 바인딩
  // 5) 댓글 목록 최초 로드
  // =========================================================
  function init() {
    normalizeEditorMediaUrls();

    // 미리 생성해두면 403 발생 시 즉시 표시 가능(렌더 지연 감소)
    ensureDeletedModal();

    initLike();
    initLikeUsers();
    initReport();

    bindReplyEvents();

    // 초기 댓글 목록 로드 (현재 정렬값 기준)
    loadReplies(getSelectedCondition()).catch(function (e) {
      if (e && e.code === 403) return;

      console.error(e);

      // 실패 시 화면을 "빈 상태"로 정리해서 깨진 댓글 목록 방지
      showReplyEmpty(true);
      setReplyCount(0);
      removeAllReplyItems();
    });
  }

  // DOMContentLoaded 안전 실행
  // - 스크립트 위치가 body 하단이더라도 재사용성을 위해 상태 체크 후 처리
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();