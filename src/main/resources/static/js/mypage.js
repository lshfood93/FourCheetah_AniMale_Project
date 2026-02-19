/* =========================================================
   MyPage JS (Final)
   - 프로필 이미지 로더 유지
   - 수정 모드에서만 편집 가능
   - 비용 정책:
     프로필 사진 변경 500
     닉네임 변경 300
     프로필 테두리 200
     닉네임 꾸미기 200
   - 꾸미기: 미리보기는 즉시 반영, 최종 차감은 '수정 완료'에서만
   ========================================================= */

/* ✅ 프로필 이미지 로딩/재시도 (DOMContentLoaded 레이스 방지) */
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

    const real = (img.dataset.realSrc || '').trim();
    const initial = (img.dataset.initialSrc || img.dataset.defaultSrc || '').trim();
    const fallback = (img.dataset.defaultSrc || initial || '').trim();

    wrap.classList.add('is-loading');

    const target = real || initial || fallback;

    if (!target) {
      wrap.classList.remove('is-loading');
      return;
    }

    const INTERVAL_MS = 250;
    const MAX_WAIT_MS = 15000;
    const startAt = Date.now();

    function preload(url, onOk, onFail) {
      const pre = new Image();
      pre.onload = onOk;
      pre.onerror = onFail;
      pre.src = url;
    }

    function done(src) {
      img.src = src;
      wrap.classList.remove('is-loading');
    }

    function tryLoad(urlToTry) {
      const elapsed = Date.now() - startAt;

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

$(function () {
  const body = document.body;

  const URL_PROFILE_UPLOAD = body.dataset.urlProfileUpload;
  const URL_NICK_CHECK = body.dataset.urlNickCheck;
  const URL_APPLY_DECOR = body.dataset.urlApplyDecoration;

  const COST_NICK = parseInt(body.dataset.costNick, 10) || 300;
  const COST_PROFILE = parseInt(body.dataset.costProfile, 10) || 500;
  const COST_NICK_DECOR = parseInt(body.dataset.costNickDecor, 10) || 200;
  const COST_BORDER_DECOR = parseInt(body.dataset.costBorderDecor, 10) || 200;

  const NICK_REGEX = /^[A-Za-z0-9가-힣]{2,12}$/;

  let editMode = false;
  let nicknameChecked = false;
  let profileChanged = false;

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

  /* =========================
     Preview Apply
  ========================= */
  function applyNicknamePreview() {
    const color = (getCurrentNickColor() || '').toString().trim();
    const nick = ($('#nicknameInput').val() || '').trim() || originalNickname;

    const $preview = $('#nickDecorPreview');

    const $nickInput = $('#nicknameInput'); // ✅ 실제 닉네임 표시(입력칸)도 같이 적용

    // 1) 텍스트 동기화

    $preview.text(nick);

    if (!color) return;

    // 2) 초기화(미리보기)
    $preview.removeClass('is-rainbow').css('color', '');

    // 3) 초기화(실제 닉네임 입력칸)
    $nickInput.removeClass('is-rainbow').css('color', ''); // ✅

    if (!color) return;

    // 4) 일반 단색 처리
    $preview.css('color', color);
    $nickInput.css('color', color); // ✅
  }
  
  function applyBorderPreview() {
    const color = getCurrentBorderColor();
    const $wrap = $('#profileWrap');
    const $swatch = $('#borderDecorSwatch');

    $wrap.removeClass('has-border border-rainbow');
    $wrap.css('--profile-border-color', 'transparent');

    $swatch.removeClass('is-empty');
    $swatch.css('background', '');

    if (!color) {
      $swatch.addClass('is-empty');
      return;
    }

    if (color === 'RAINBOW') {
      $wrap.addClass('has-border border-rainbow');
      $swatch.css('background', 'linear-gradient(90deg,#ff4c4c,#ff8a00,#ffc107,#25d366,#3b82f6,#1e3a8a,#a855f7)');
      return;
    }

    $wrap.addClass('has-border');
    $wrap.css('--profile-border-color', color);
    $swatch.css('background', color);
  }

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
      // 커스텀 색인 경우: 프리셋에 없으면 선택 표시 없이 둠 (원하면 여기서 커스텀 배지 넣어도 됨)
    }
  }

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

  function setDecorControlsEnabled(enabled) {
    // 프리셋 버튼
    $('#decorateWrap .color-chip').prop('disabled', !enabled);
    // 커스텀
    $('#nickColorPicker, #borderColorPicker').prop('disabled', !enabled);
    $('#decorateWrap .custom-apply').prop('disabled', !enabled);

    if (enabled) $('#decorCostMsg').show();
    else $('#decorCostMsg').hide();
  }

  /* =========================
     Enter / Exit Edit
  ========================= */
  $('#editBtn').on('click', function () {
    editMode = true;
    $('body').addClass('mypage-editing');

    $('#viewActions').hide();
    $('#editActions').show();
    $('#costBox').show();

    $('#nicknameInput').prop('readonly', false);
    $('#nickCheckBtn').removeClass('disabled-btn');
    $('#profileBtnLabel').removeClass('disabled-btn');

    $('#nickCostMsg').show();
    $('#profileCostMsg').show();

    nicknameChecked = false;
    profileChanged = false;
    $('#nicknameMsg').text('');

    $('#temporaryProfileImageToken').val('');
    $('#profileInput').val('');

    setDecorControlsEnabled(true);

    updateCostAndButtons();
  });

  $('#cancelBtn').on('click', function () {
    exitEditMode(true);
  });

  function exitEditMode(resetValues) {
    editMode = false;
    $('body').removeClass('mypage-editing');

    if (resetValues) {
      // 닉네임 원복
      $('#nicknameInput').val(originalNickname);

      // 프로필 이미지 원복 (load 이벤트로 로더 끄기)
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

      $('#temporaryProfileImageToken').val('');
      $('#profileInput').val('');

      // ✅ 꾸미기 원복
      setDecorValue('nickname', getOriginNickColor());
      setDecorValue('border', getOriginBorderColor());
    }

    $('#nicknameInput').prop('readonly', true);
    $('#nickCheckBtn').addClass('disabled-btn').text('중복 확인');
    $('#profileBtnLabel').addClass('disabled-btn');

    $('#nickCostMsg').hide();
    $('#profileCostMsg').hide();

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

  /* =========================
     Nickname change + check
  ========================= */
  $('#nicknameInput').on('input', function () {
    applyNicknamePreview();

    if (!editMode) return;

    const val = $('#nicknameInput').val().trim();
    if (val.length > 0 && !NICK_REGEX.test(val)) {
      $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
        .text('닉네임은 2~12자, 한글/영문/숫자만 사용할 수 있습니다.');
    } else {
      $('#nicknameMsg').text('');
    }

    nicknameChecked = false;
    $('#nickCheckBtn').text('중복 확인');
    updateCostAndButtons();
  });

  $('#nickCheckBtn').on('click', function () {
    if (!editMode) return;

    const nickname = $('#nicknameInput').val().trim();

    if (!NICK_REGEX.test(nickname)) {
      $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
        .text('닉네임은 2~12자, 한글/영문/숫자만 사용할 수 있습니다.');
      nicknameChecked = false;
      updateCostAndButtons();
      return;
    }

    if (nickname === originalNickname) {
      $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
        .text('현재 닉네임과 동일합니다.');
      nicknameChecked = false;
      updateCostAndButtons();
      return;
    }

    $.ajax({
      url: URL_NICK_CHECK,
      type: 'GET',
      dataType: 'json',
      data: { memberNickname: nickname },
      success: function (res) {
        if (!res || res.success !== true) {
          $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
            .text((res && res.message) ? res.message : '중복확인에 실패했습니다.');
          nicknameChecked = false;
          $('#nickCheckBtn').text('중복 확인');
          updateCostAndButtons();
          return;
        }

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

  /* =========================
     Profile upload
  ========================= */
  $('#profileInput').on('change', function () {
    if (!editMode) return;

    const file = this.files[0];
    if (!file) return;

    if (!file.type || !file.type.startsWith('image/')) {
      alert('이미지 파일만 선택할 수 있습니다.');
      $(this).val('');
      return;
    }

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

        const tempUrl = addCacheBust(res.temporaryProfileImageUrl);

        const $img = $('#profilePreview');
        $img.off('load.__upload error.__upload');
        $img.on('load.__upload error.__upload', function () {
          $('#profileWrap').removeClass('is-loading');
          $img.off('load.__upload error.__upload');
        });
        $img.attr('src', tempUrl);

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

  /* =========================
     Decoration events
  ========================= */
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

  /* =========================
     Cost & Save enable
  ========================= */
  function updateCostAndButtons() {
    const currentCash = parseInt($('#cashRaw').val(), 10) || 0;

    const newNickname = $('#nicknameInput').val().trim();
    const token = $('#temporaryProfileImageToken').val().trim();

    const nickChanged = editMode && (newNickname !== originalNickname);
    const nickCost = nickChanged ? COST_NICK : 0;

    const profileCost = (editMode && profileChanged && token.length > 0) ? COST_PROFILE : 0;

    const originNickColor = getOriginNickColor();
    const originBorderColor = getOriginBorderColor();

    const nickColor = getCurrentNickColor();
    const borderColor = getCurrentBorderColor();

    const nickDecorChanged = editMode && (normalize(nickColor) !== normalize(originNickColor));
    const borderDecorChanged = editMode && (normalize(borderColor) !== normalize(originBorderColor));

    const nickDecorCost = nickDecorChanged ? COST_NICK_DECOR : 0;
    const borderDecorCost = borderDecorChanged ? COST_BORDER_DECOR : 0;

    const totalCost = nickCost + profileCost + nickDecorCost + borderDecorCost;
    const cashAfter = currentCash - totalCost;

    $('#costNick').text(formatWon(nickCost));
    $('#costProfile').text(formatWon(profileCost));
    $('#costNickDecor').text(formatWon(nickDecorCost));
    $('#costBorderDecor').text(formatWon(borderDecorCost));
    $('#costTotal').text(formatWon(totalCost));
    $('#cashAfter').text(formatWon(Math.max(cashAfter, 0)));

    let canSave = true;

    const hasAnyChange =
      nickChanged ||
      (profileChanged && token.length > 0) ||
      nickDecorChanged ||
      borderDecorChanged;

    if (!editMode || !hasAnyChange) canSave = false;

    if (nickChanged) {
      if (!NICK_REGEX.test(newNickname)) canSave = false;
      if (!nicknameChecked) canSave = false;
    }

    if (profileChanged && token.length === 0) canSave = false;

    if (totalCost > currentCash) {
      canSave = false;
      $('#cashWarn').show();
    } else {
      $('#cashWarn').hide();
    }

    if (editMode && canSave) $('#saveBtn').removeClass('disabled-btn');
    else $('#saveBtn').addClass('disabled-btn');

    $('#mCostNick').text(formatWon(nickCost));
    $('#mCostProfile').text(formatWon(profileCost));
    $('#mCostNickDecor').text(formatWon(nickDecorCost));
    $('#mCostBorderDecor').text(formatWon(borderDecorCost));
    $('#mCostTotal').text(formatWon(totalCost));
  }

  /* =========================
     Modal + Submit flow
  ========================= */
  $('#saveBtn').on('click', function () {
    if ($(this).hasClass('disabled-btn')) return;
    $('#modalBackdrop').css('display', 'flex');
  });

  function hideConfirmModal() {
    $('#modalBackdrop').hide();
  }

  $('.modal-box').on('click', function (e) {
    e.stopPropagation();
  });

  $('#modalNoBtn').on('click', function () {
    hideConfirmModal();
    exitEditMode(true);
  });

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
    if (nickDecorChanged) {
      payload.nicknameColor = nickColor;
      payload.memberNicknameColor = nickColor; // DTO 매핑 대비(서버에서 무시해도 됨)
    }
    if (borderDecorChanged) {
      payload.borderColor = borderColor;
      payload.memberProfileColor = borderColor; // DTO 매핑 대비
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

        // 성공 시 캐시 표시만 먼저 갱신(최종은 리다이렉트/리로드에서 다시 맞춰짐)
        if (typeof res.newCashBalance !== 'undefined') {
          const newCash = parseInt(res.newCashBalance, 10) || 0;
          $('#cashRaw').val(newCash);
          $('#cashDisplay').val(formatWon(newCash).replace('원원', '원')); // 안전
        }

        // 원본도 갱신(다음 계산/중복 차감 방지)
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

  $('#modalYesBtn').on('click', function () {
    if ($('#saveBtn').hasClass('disabled-btn')) return;

    const $yes = $('#modalYesBtn');
    $yes.prop('disabled', true);

    const token = ($('#temporaryProfileImageToken').val() || '').trim();
    const newNickname = ($('#nicknameInput').val() || '').trim();

    const nickChanged = editMode && (newNickname !== originalNickname);
    const profileSubmitNeeded = editMode && (
      nickChanged || (profileChanged && token.length > 0)
    );

    applyDecorationIfNeeded(function (r) {
      if (r && r.failed) {
        $yes.prop('disabled', false);
        return;
      }

      if (profileSubmitNeeded) {
        // 꾸미기(있다면) → 그 다음 프로필/닉네임(폼 submit)
        $('#mypageForm').submit();
        return;
      }

      // 꾸미기만 변경한 경우: 화면 갱신
      hideConfirmModal();
      alert('꾸미기가 적용되었습니다.');
      location.reload();
    });
  });

  /* =========================
     Init state
  ========================= */
  // 초기(보기 모드): 꾸미기 컨트롤 잠금 + 현재 값 미리보기 반영
  setDecorControlsEnabled(false);
  applyNicknamePreview();
  applyBorderPreview();
  syncPresetSelected('nickname', getCurrentNickColor());
  syncPresetSelected('border', getCurrentBorderColor());

  updateCostAndButtons();
});
