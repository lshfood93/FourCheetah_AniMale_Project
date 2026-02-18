/* =========================================================
   MyPage JS (Final / Commented)
   - 프로필 이미지 로더 유지 (DOMContentLoaded 레이스/캐시 이슈 대응)
   - 보기 모드: 전부 잠금 (readonly/disabled)
   - 수정 모드(editMode): 입력/업로드/꾸미기 가능
   - 비용 정책:
     프로필 사진 변경 500
     닉네임 변경 300
     프로필 테두리 200
     닉네임 꾸미기 200
   - ✅ 꾸미기 정책:
     미리보기(프론트) = 즉시 반영
     실제 적용/차감(서버) = '수정 완료' 확정 시점에서만
   ========================================================= */

/* =========================================================
   0) 프로필 이미지 로딩/재시도 (DOMContentLoaded 레이스 방지)
   - img src가 늦게 세팅되거나 캐시/업로드 직후 갱신이 필요한 케이스 대비
   - MAX_WAIT_MS 동안 일정 간격으로 preload 재시도
   ========================================================= */
(function () {
  function addCacheBust(url) {
    if (!url) return url;
    const sep = url.includes('?') ? '&' : '?';
    return url + sep + 'v=' + Date.now();
  }

  function initProfileLoader() {
    const wrap = document.getElementById('profileWrap');
    const img = document.getElementById('profilePreview');
    if (!wrap || !img) return;

    // ✅ JSP에서 data-*로 내려준 우선순위
    // realSrc: “실제 프로필” (서버가 확정한 경로)
    // initialSrc: 최초 렌더 당시 경로 (대개 real과 같음)
    // defaultSrc: 없을 때 쓰는 기본 이미지
    const real = (img.dataset.realSrc || '').trim();
    const initial = (img.dataset.initialSrc || img.dataset.defaultSrc || '').trim();
    const fallback = (img.dataset.defaultSrc || initial || '').trim();

    // 로더 ON
    wrap.classList.add('is-loading');

    // ✅ 실제로 로드할 목표 (real > initial > fallback)
    const target = real || initial || fallback;

    if (!target) {
      wrap.classList.remove('is-loading');
      return;
    }

    const INTERVAL_MS = 250;   // 재시도 간격
    const MAX_WAIT_MS = 15000; // 총 대기 시간(초과 시 fallback로 종료)
    const startAt = Date.now();

    function preload(url, onOk, onFail) {
      const pre = new Image();
      pre.onload = onOk;
      pre.onerror = onFail;
      pre.src = url;
    }

    function done(src) {
      // ✅ 실제 img에 최종 반영 + 로더 OFF
      img.src = src;
      wrap.classList.remove('is-loading');
    }

    function tryLoad(urlToTry) {
      const elapsed = Date.now() - startAt;

      // ✅ 너무 오래 걸리면 fallback로 마무리
      if (elapsed >= MAX_WAIT_MS) {
        const fb = fallback || urlToTry;
        const fbSrc = addCacheBust(fb);
        preload(
          fbSrc,
          function () { done(fbSrc); },
          function () { done(fbSrc); }
        );
        return;
      }

      // ✅ 캐시 무력화를 걸고 preload → 실패 시 재시도
      const testSrc = addCacheBust(urlToTry);
      preload(
        testSrc,
        function () { done(testSrc); },
        function () { setTimeout(function () { tryLoad(urlToTry); }, INTERVAL_MS); }
      );
    }

    tryLoad(target);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initProfileLoader);
  } else {
    initProfileLoader();
  }
})();

/* =========================================================
   1) 페이지 메인 로직 (jQuery)
   - editMode 토글
   - 닉네임 중복확인 게이트
   - 프로필 업로드(임시 토큰)
   - 꾸미기 프리셋/커스텀 + 미리보기
   - 비용 계산 + 저장 버튼 활성화
   - 모달 확정 → (꾸미기 적용) → (필요 시 폼 submit)
   ========================================================= */
$(function () {
  const body = document.body;

  // =========================================================
  // 1-1) URL / 비용 상수 (JSP body data-*에서 주입)
  // =========================================================
  const URL_PROFILE_UPLOAD = body.dataset.urlProfileUpload;
  const URL_NICK_CHECK = body.dataset.urlNickCheck;
  const URL_APPLY_DECOR = body.dataset.urlApplyDecoration;

  const COST_NICK = parseInt(body.dataset.costNick, 10) || 300;
  const COST_PROFILE = parseInt(body.dataset.costProfile, 10) || 500;
  const COST_NICK_DECOR = parseInt(body.dataset.costNickDecor, 10) || 200;
  const COST_BORDER_DECOR = parseInt(body.dataset.costBorderDecor, 10) || 200;

  // ✅ 닉네임 정책: 2~12자, 한글/영문/숫자만
  const NICK_REGEX = /^[A-Za-z0-9가-힣]{2,12}$/;

  // =========================================================
  // 1-2) 상태 플래그
  // =========================================================
  let editMode = false;          // ✅ 수정 모드 여부
  let nicknameChecked = false;   // ✅ 닉네임 변경 시 “중복확인 통과” 필수
  let profileChanged = false;    // ✅ 프로필 업로드가 성공했는지

  // =========================================================
  // 1-3) 원본 스냅샷(비교 기준)
  // - 수정모드에서 현재 입력값과 비교해서 비용/버튼 활성화 계산
  // =========================================================
  const originalNickname = ($('#nicknameInput').val() || '').trim();
  const originalProfileSrc = ($('#profilePreview').data('initialSrc') || '').toString();

  function normalize(v) {
    return (v || '').toString().trim().toLowerCase();
  }

  function addCacheBust(url) {
    if (!url) return url;
    const sep = url.indexOf('?') >= 0 ? '&' : '?';
    return url + sep + 'v=' + Date.now();
  }

  function formatWon(num) {
    return (num || 0).toLocaleString('ko-KR') + '원';
  }

  // =========================================================
  // 1-4) 꾸미기 값(원본 / 현재) 접근 헬퍼
  // - origin* : JSP hidden에 박혀있는 “서버 기준 원본”
  // - current* : “현재 선택 값” (서버 바인딩용 hidden)
  // =========================================================
  function getOriginNickColor() {
    return ($('#originNicknameColor').val() || '').toString();
  }
  function getOriginBorderColor() {
    return ($('#originBorderColor').val() || '').toString();
  }
  function getCurrentNickColor() {
    return ($('#nicknameColorInput').val() || '').toString();
  }
  function getCurrentBorderColor() {
    return ($('#borderColorInput').val() || '').toString();
  }

  /* =========================================================
     2) Preview Apply
     - ✅ “저장”과 무관하게 UI 미리보기는 즉시 반영
     - 실제 차감/적용은 모달 확정 후 서버 호출에서 진행
     ========================================================= */
  function applyNicknamePreview() {
    const color = getCurrentNickColor();
    const nick = ($('#nicknameInput').val() || '').trim() || originalNickname;

    const $preview = $('#nickDecorPreview');

    // ✅ 기본 상태 초기화
    $preview.text(nick);
    $preview.removeClass('is-rainbow');
    $preview.css('color', '');

    // 색상이 없으면 “기본”으로 둠
    if (!color) return;

    // ✅ 무지개는 class로 처리
    if (color === 'RAINBOW') {
      $preview.addClass('is-rainbow');
      return;
    }

    // ✅ 일반 색상은 color 스타일로 처리
    $preview.css('color', color);
  }

  function applyBorderPreview() {
    const color = getCurrentBorderColor();
    const $wrap = $('#profileWrap');
    const $swatch = $('#borderDecorSwatch');

    // ✅ 초기화(테두리 제거)
    $wrap.removeClass('has-border border-rainbow');
    $wrap.css('--profile-border-color', 'transparent');

    // ✅ 스와치도 초기화
    $swatch.removeClass('is-empty');
    $swatch.css('background', '');

    if (!color) {
      // 기본 선택: 빈 스와치 표시
      $swatch.addClass('is-empty');
      return;
    }

    if (color === 'RAINBOW') {
      // ✅ 무지개 테두리: class + 스와치는 그라데이션으로 표시
      $wrap.addClass('has-border border-rainbow');
      $swatch.css('background', 'linear-gradient(90deg,#ff4c4c,#ff8a00,#ffc107,#25d366,#3b82f6,#1e3a8a,#a855f7)');
      return;
    }

    // ✅ 단색 테두리: CSS 변수로 테두리색 전달
    $wrap.addClass('has-border');
    $wrap.css('--profile-border-color', color);
    $swatch.css('background', color);
  }

  // =========================================================
  // 2-1) 프리셋 “선택 표시” 동기화
  // - 현재 값이 프리셋에 있으면 is-selected 표시
  // - 커스텀 색이면 프리셋 선택 표시 없이 둠(정책)
  // =========================================================
  function syncPresetSelected(kind, color) {
    const $chips = $('.decorate-presets[data-kind="' + kind + '"] .color-chip');
    $chips.removeClass('is-selected');

    const target = normalize(color);
    let matched = false;

    $chips.each(function () {
      const c = normalize($(this).data('color'));
      if (c === target) {
        $(this).addClass('is-selected');
        matched = true;
      }
    });

    if (!matched && target) {
      // ✅ 커스텀 색인 경우
      // 정책상 프리셋 선택 표시 없음
      // 원하면 여기서 “CUSTOM” 배지 같은 추가도 가능
    }
  }

  // =========================================================
  // 2-2) 꾸미기 값 세팅 (hidden + preview + 프리셋 표시 + 비용계산)
  // =========================================================
  function setDecorValue(kind, color) {
    if (kind === 'nickname') {
      $('#nicknameColorInput').val(color || '');
      applyNicknamePreview();
      syncPresetSelected('nickname', color || '');
    } else {
      $('#borderColorInput').val(color || '');
      applyBorderPreview();
      syncPresetSelected('border', color || '');
    }
    updateCostAndButtons();
  }

  // =========================================================
  // 2-3) 보기/수정 모드에 따른 꾸미기 컨트롤 잠금
  // - editMode가 아닐 땐 버튼/컬러피커/적용버튼 모두 disabled
  // =========================================================
  function setDecorControlsEnabled(enabled) {
    // 프리셋 버튼
    $('#decorateWrap .color-chip').prop('disabled', !enabled);
    // 커스텀
    $('#nickColorPicker, #borderColorPicker').prop('disabled', !enabled);
    $('#decorateWrap .custom-apply').prop('disabled', !enabled);

    if (enabled) $('#decorCostMsg').show();
    else $('#decorCostMsg').hide();
  }

  /* =========================================================
     3) Enter / Exit Edit
     - editBtn: 보기 → 수정 모드
     - cancelBtn/모달No: 수정 취소 + 원복
     ========================================================= */
  $('#editBtn').on('click', function () {
    editMode = true;
    $('body').addClass('mypage-editing');

    // ✅ 버튼 영역 전환
    $('#viewActions').hide();
    $('#editActions').show();
    $('#costBox').show();

    // ✅ 입력/업로드 unlock
    $('#nicknameInput').prop('readonly', false);
    $('#nickCheckBtn').removeClass('disabled-btn');
    $('#profileBtnLabel').removeClass('disabled-btn');

    // 비용 안내 표시
    $('#nickCostMsg').show();
    $('#profileCostMsg').show();

    // ✅ 수정 모드 진입 시 검증 플래그 리셋
    nicknameChecked = false;
    profileChanged = false;
    $('#nicknameMsg').text('');

    // ✅ 임시 업로드 토큰/파일 선택 초기화
    $('#temporaryProfileImageToken').val('');
    $('#profileInput').val('');

    // ✅ 꾸미기 컨트롤 활성화
    setDecorControlsEnabled(true);

    updateCostAndButtons();
  });

  $('#cancelBtn').on('click', function () {
    exitEditMode(true);
  });

  // =========================================================
  // 3-1) 수정모드 종료 + (선택) 값 원복
  // - resetValues=true면: 닉네임/프로필/꾸미기 모두 원복
  // =========================================================
  function exitEditMode(resetValues) {
    editMode = false;
    $('body').removeClass('mypage-editing');

    if (resetValues) {
      // ✅ 닉네임 원복
      $('#nicknameInput').val(originalNickname);

      // ✅ 프로필 이미지 원복 (load/error 시점에 로더 OFF)
      const base = (originalProfileSrc || '').split('?')[0];
      const target = addCacheBust(base || $('#profilePreview').data('defaultSrc'));

      $('#profileWrap').addClass('is-loading');

      const $img = $('#profilePreview');
      $img.off('load.__revert error.__revert');
      $img.on('load.__revert error.__revert', function () {
        $('#profileWrap').removeClass('is-loading');
        $img.off('load.__revert error.__revert');
      });
      $img.attr('src', target);

      // ✅ 임시 업로드 토큰 초기화
      $('#temporaryProfileImageToken').val('');
      $('#profileInput').val('');

      // ✅ 꾸미기 원복(원본 hidden 기준)
      setDecorValue('nickname', getOriginNickColor());
      setDecorValue('border', getOriginBorderColor());
    }

    // ✅ 입력/업로드 다시 잠금
    $('#nicknameInput').prop('readonly', true);
    $('#nickCheckBtn').addClass('disabled-btn').text('중복 확인');
    $('#profileBtnLabel').addClass('disabled-btn');

    // 비용 안내 숨김
    $('#nickCostMsg').hide();
    $('#profileCostMsg').hide();

    // ✅ 비용 박스/버튼 영역 복귀
    $('#costBox').hide();
    $('#editActions').hide();
    $('#viewActions').show();

    $('#cashWarn').hide();
    $('#nicknameMsg').text('');

    nicknameChecked = false;
    profileChanged = false;

    setDecorControlsEnabled(false);
    updateCostAndButtons();
  }

  /* =========================================================
     4) Nickname change + check
     - input 변화 시: 미리보기 갱신 + 정규식 검사 + 중복확인 리셋
     - 중복확인 성공해야 save 가능 (닉네임 변경 케이스)
     ========================================================= */
  $('#nicknameInput').on('input', function () {
    // ✅ 닉네임 바꾸면 미리보기에도 즉시 반영(꾸미기 색상과 함께)
    applyNicknamePreview();

    if (!editMode) return;

    const val = $('#nicknameInput').val().trim();

    // ✅ 로컬 유효성: 정규식 미통과 시 에러 표시
    if (val.length > 0 && !NICK_REGEX.test(val)) {
      $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
        .text('닉네임은 2~12자, 한글/영문/숫자만 사용할 수 있습니다.');
    } else {
      $('#nicknameMsg').text('');
    }

    // ✅ 입력이 바뀌면 “중복확인 다시 해야 함”
    nicknameChecked = false;
    $('#nickCheckBtn').text('중복 확인');
    updateCostAndButtons();
  });

  $('#nickCheckBtn').on('click', function () {
    if (!editMode) return;

    const nickname = $('#nicknameInput').val().trim();

    // ✅ 정규식 미통과면 서버 호출 X
    if (!NICK_REGEX.test(nickname)) {
      $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
        .text('닉네임은 2~12자, 한글/영문/숫자만 사용할 수 있습니다.');
      nicknameChecked = false;
      updateCostAndButtons();
      return;
    }

    // ✅ 원본과 같으면 변경으로 인정하지 않음
    if (nickname === originalNickname) {
      $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
        .text('현재 닉네임과 동일합니다.');
      nicknameChecked = false;
      updateCostAndButtons();
      return;
    }

    // ✅ 서버 중복 확인
    $.ajax({
      url: URL_NICK_CHECK,
      type: 'GET',
      dataType: 'json',
      data: { memberNickname: nickname },
      success: function (res) {
        // 서버가 success=false면 실패 처리
        if (!res || res.success !== true) {
          $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
            .text((res && res.message) ? res.message : '중복확인에 실패했습니다.');
          nicknameChecked = false;
          $('#nickCheckBtn').text('중복 확인');
          updateCostAndButtons();
          return;
        }

        // ✅ 사용 가능/불가 분기
        if (res.available === true) {
          $('#nicknameMsg').removeClass('msg-error').addClass('msg-ok')
            .text('사용 가능한 닉네임입니다.');
          nicknameChecked = true;
          $('#nickCheckBtn').text('확인 완료');
        } else {
          $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
            .text('이미 사용 중인 닉네임입니다.');
          nicknameChecked = false;
          $('#nickCheckBtn').text('중복 확인');
        }
        updateCostAndButtons();
      },
      error: function () {
        $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
          .text('중복확인 서버 호출에 실패했습니다.');
        nicknameChecked = false;
        $('#nickCheckBtn').text('중복 확인');
        updateCostAndButtons();
      }
    });
  });

  /* =========================================================
     5) Profile upload
     - 파일 선택 → 서버에 업로드(임시 저장)
     - 성공 시: 임시 URL로 preview 갱신 + 임시 토큰(hidden) 저장
     - 최종 확정은 폼 submit(/member/profile)에서 token으로 처리
     ========================================================= */
  $('#profileInput').on('change', function () {
    if (!editMode) return;

    const file = this.files[0];
    if (!file) return;

    // ✅ 이미지 타입만 허용
    if (!file.type || !file.type.startsWith('image/')) {
      alert('이미지 파일만 선택할 수 있습니다.');
      $(this).val('');
      return;
    }

    // 로더 ON
    $('#profileWrap').addClass('is-loading');

    const formData = new FormData();
    formData.append('profileImageFile', file);

    $.ajax({
      url: URL_PROFILE_UPLOAD,
      type: 'POST',
      data: formData,
      processData: false,
      contentType: false,
      dataType: 'json',
      success: function (res) {
        if (!res || res.result !== 'SUCCESS') {
          alert((res && res.errorMessage) ? res.errorMessage : '업로드에 실패했습니다.');
          $('#profileInput').val('');
          $('#profileWrap').removeClass('is-loading');
          return;
        }

        // ✅ 임시 URL로 preview 갱신(캐시무력화)
        const tempUrl = addCacheBust(res.temporaryProfileImageUrl);

        const $img = $('#profilePreview');
        $img.off('load.__upload error.__upload');
        $img.on('load.__upload error.__upload', function () {
          $('#profileWrap').removeClass('is-loading');
          $img.off('load.__upload error.__upload');
        });
        $img.attr('src', tempUrl);

        // ✅ 임시 토큰 저장(최종 submit 때 서버가 이 토큰을 확정 처리)
        $('#temporaryProfileImageToken').val(res.temporaryProfileImageToken);

        profileChanged = true;
        updateCostAndButtons();
      },
      error: function (xhr) {
        alert('프로필 업로드 실패(' + xhr.status + '). 다시 시도해주세요.');
        $('#profileInput').val('');
        $('#profileWrap').removeClass('is-loading');
      }
    });
  });

  /* =========================================================
     6) Decoration events
     - 프리셋 클릭 / 커스텀 적용 버튼 클릭
     - editMode에서만 동작
     ========================================================= */
  $('#decorateWrap').on('click', '.decorate-presets .color-chip', function () {
    if (!editMode) return;
    const kind = $(this).closest('.decorate-presets').data('kind');
    const color = ($(this).data('color') || '').toString();
    setDecorValue(kind, color);
  });

  $('#decorateWrap').on('click', '.custom-apply', function () {
    if (!editMode) return;
    const kind = ($(this).data('kind') || '').toString();
    if (kind === 'nickname') {
      setDecorValue('nickname', $('#nickColorPicker').val());
    } else {
      setDecorValue('border', $('#borderColorPicker').val());
    }
  });

  /* =========================================================
     7) Cost & Save enable
     - ✅ 핵심: "변경이 있어야" 저장 가능
     - 닉네임 변경이면: 정규식 통과 + 중복확인 완료 필수
     - 프로필 변경이면: 임시 토큰 존재 필수
     - 보유 캐시 < 총 비용이면 저장 불가 + 경고 표시
     ========================================================= */
  function updateCostAndButtons() {
    const currentCash = parseInt($('#cashRaw').val(), 10) || 0;

    const newNickname = $('#nicknameInput').val().trim();
    const token = $('#temporaryProfileImageToken').val().trim();

    // ✅ 닉네임 변경 여부/비용
    const nickChanged = editMode && (newNickname !== originalNickname);
    const nickCost = nickChanged ? COST_NICK : 0;

    // ✅ 프로필 변경 여부/비용 (업로드 성공 + 토큰 존재)
    const profileCost = (editMode && profileChanged && token.length > 0) ? COST_PROFILE : 0;

    // ✅ 꾸미기 변경 여부/비용 (원본 vs 현재 비교)
    const originNickColor = getOriginNickColor();
    const originBorderColor = getOriginBorderColor();

    const nickColor = getCurrentNickColor();
    const borderColor = getCurrentBorderColor();

    const nickDecorChanged = editMode && (normalize(nickColor) !== normalize(originNickColor));
    const borderDecorChanged = editMode && (normalize(borderColor) !== normalize(originBorderColor));

    const nickDecorCost = nickDecorChanged ? COST_NICK_DECOR : 0;
    const borderDecorCost = borderDecorChanged ? COST_BORDER_DECOR : 0;

    // ✅ 총 비용/차감 후 캐시
    const totalCost = nickCost + profileCost + nickDecorCost + borderDecorCost;
    const cashAfter = currentCash - totalCost;

    // UI 반영(상세 박스)
    $('#costNick').text(formatWon(nickCost));
    $('#costProfile').text(formatWon(profileCost));
    $('#costNickDecor').text(formatWon(nickDecorCost));
    $('#costBorderDecor').text(formatWon(borderDecorCost));
    $('#costTotal').text(formatWon(totalCost));
    $('#cashAfter').text(formatWon(Math.max(cashAfter, 0)));

    let canSave = true;

    // ✅ 변경이 하나도 없으면 저장 불가
    const hasAnyChange =
      nickChanged ||
      (profileChanged && token.length > 0) ||
      nickDecorChanged ||
      borderDecorChanged;

    if (!editMode || !hasAnyChange) canSave = false;

    // ✅ 닉네임 변경이면: 유효성 + 중복확인 통과 필수
    if (nickChanged) {
      if (!NICK_REGEX.test(newNickname)) canSave = false;
      if (!nicknameChecked) canSave = false;
    }

    // ✅ 프로필 변경 플래그는 true인데 토큰이 없으면(비정상) 저장 불가
    if (profileChanged && token.length === 0) canSave = false;

    // ✅ 캐시 부족이면 저장 불가 + 경고 표시
    if (totalCost > currentCash) {
      canSave = false;
      $('#cashWarn').show();
    } else {
      $('#cashWarn').hide();
    }

    // 저장 버튼 활성/비활성
    if (editMode && canSave) $('#saveBtn').removeClass('disabled-btn');
    else $('#saveBtn').addClass('disabled-btn');

    // 모달 비용 표기
    $('#mCostNick').text(formatWon(nickCost));
    $('#mCostProfile').text(formatWon(profileCost));
    $('#mCostNickDecor').text(formatWon(nickDecorCost));
    $('#mCostBorderDecor').text(formatWon(borderDecorCost));
    $('#mCostTotal').text(formatWon(totalCost));
  }

  /* =========================================================
     8) Modal + Submit flow
     - saveBtn: 모달 열기
     - modalNo: 모달 닫고 “원복 후 종료”
     - modalYes:
         1) (필요 시) 꾸미기 서버 적용
         2) 닉/프로필 변경 있으면 form submit
         3) 꾸미기만 변경이면 reload로 화면 반영
     ========================================================= */
  $('#saveBtn').on('click', function () {
    if ($(this).hasClass('disabled-btn')) return;
    $('#modalBackdrop').css('display', 'flex');
  });

  function hideConfirmModal() {
    $('#modalBackdrop').hide();
  }

  // ✅ 모달 박스 클릭은 backdrop 닫힘 방지
  $('.modal-box').on('click', function (e) {
    e.stopPropagation();
  });

  $('#modalNoBtn').on('click', function () {
    hideConfirmModal();
    exitEditMode(true);
  });

  // =========================================================
  // 8-1) 꾸미기 적용이 필요한지 판단 후 서버 호출
  // - 변경이 없으면 done({applied:false})
  // - 성공 시: cash/origin hidden을 갱신해서 “중복 차감” 방지
  // =========================================================
  function applyDecorationIfNeeded(done) {
    const originNickColor = getOriginNickColor();
    const originBorderColor = getOriginBorderColor();

    const nickColor = getCurrentNickColor();
    const borderColor = getCurrentBorderColor();

    const nickDecorChanged = normalize(nickColor) !== normalize(originNickColor);
    const borderDecorChanged = normalize(borderColor) !== normalize(originBorderColor);

    if (!nickDecorChanged && !borderDecorChanged) {
      done({ applied: false });
      return;
    }

    const payload = {};

    // ✅ 서버 DTO 바인딩 대비로 키를 2개씩 넣어둔 형태
    // (서버에서 하나만 쓰고 다른 건 무시해도 문제 없음)
    if (nickDecorChanged) {
      payload.nicknameColor = nickColor;
      payload.memberNicknameColor = nickColor;
    }
    if (borderDecorChanged) {
      payload.borderColor = borderColor;
      payload.memberProfileColor = borderColor;
    }

    $.ajax({
      url: URL_APPLY_DECOR,
      type: 'POST',
      dataType: 'json',
      data: payload,
      success: function (res) {
        if (!res || res.code !== 'SUCCESS') {
          const msg = (res && res.message) ? res.message : '꾸미기 적용에 실패했습니다.';
          alert(msg);
          done({ applied: false, failed: true });
          return;
        }

        // ✅ 성공 시 캐시 표시를 먼저 동기화(UX)
        if (typeof res.newCashBalance !== 'undefined') {
          const newCash = parseInt(res.newCashBalance, 10) || 0;
          $('#cashRaw').val(newCash);
          $('#cashDisplay').val(formatWon(newCash).replace('원원', '원'));
        }

        // ✅ 원본값도 갱신(중복 차감/중복 적용 방지)
        if (res.appliedNicknameColor !== undefined) $('#originNicknameColor').val(res.appliedNicknameColor || '');
        if (res.appliedBorderColor !== undefined) $('#originBorderColor').val(res.appliedBorderColor || '');

        done({ applied: true });
      },
      error: function () {
        alert('꾸미기 적용 서버 호출에 실패했습니다.');
        done({ applied: false, failed: true });
      }
    });
  }

  // =========================================================
  // 8-2) 확정 버튼(Yes)
  // - 중복 클릭 방지 위해 버튼 disabled
  // =========================================================
  $('#modalYesBtn').on('click', function () {
    if ($('#saveBtn').hasClass('disabled-btn')) return;

    const $yes = $('#modalYesBtn');
    $yes.prop('disabled', true);

    const token = ($('#temporaryProfileImageToken').val() || '').trim();
    const newNickname = ($('#nicknameInput').val() || '').trim();

    const nickChanged = editMode && (newNickname !== originalNickname);

    // ✅ 닉네임/프로필 변경이 있으면 form submit 필요
    // (서버가 token/닉네임을 처리하면서 캐시 차감 포함 로직 수행)
    const profileSubmitNeeded = editMode && (
      nickChanged || (profileChanged && token.length > 0)
    );

    // ✅ 꾸미기 먼저 적용 → 그 다음 submit(필요 시)
    applyDecorationIfNeeded(function (r) {
      if (r && r.failed) {
        $yes.prop('disabled', false);
        return;
      }

      if (profileSubmitNeeded) {
        // ✅ 꾸미기(있다면) → 그 다음 프로필/닉네임 확정(폼 submit)
        $('#mypageForm').submit();
        return;
      }

      // ✅ 꾸미기만 변경한 경우: reload로 반영
      hideConfirmModal();
      alert('꾸미기가 적용되었습니다.');
      location.reload();
    });
  });

  /* =========================================================
     9) Init state
     - 초기(보기 모드): 꾸미기 컨트롤 잠금
     - 현재 값(서버에서 내려온 hidden) 기준으로 미리보기 반영
     ========================================================= */
  setDecorControlsEnabled(false);
  applyNicknamePreview();
  applyBorderPreview();
  syncPresetSelected('nickname', getCurrentNickColor());
  syncPresetSelected('border', getCurrentBorderColor());

  updateCostAndButtons();
});
