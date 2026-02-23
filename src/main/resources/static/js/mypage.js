/* =========================================================
   MyPage JS (Final)

   목적/정리
   - 마이페이지에서 "프로필 이미지", "닉네임", "꾸미기(닉색/테두리)" 수정 흐름을 제어한다.
   - 보기 모드에서는 편집 불가, "수정하기" 진입 시에만 입력/버튼을 활성화한다.

   비용 정책(수정 완료 시 최종 차감)
   - 프로필 사진 변경: 500
   - 닉네임 변경: 300
   - 프로필 테두리 꾸미기: 200
   - 닉네임 꾸미기: 200

   꾸미기 처리 규칙
   - 미리보기는 선택 즉시 화면에 반영(즉시 반영)
   - 실제 저장/차감은 "수정 완료"에서만 수행(서버 적용 요청 + 필요 시 폼 submit)
   ========================================================= */

/* =========================================================
   1) 프로필 이미지 로딩/재시도 로더
   ---------------------------------------------------------
   - DOMContentLoaded 타이밍 레이스나 이미지 캐시 때문에
     초기 로딩이 꼬일 수 있어서 "재시도 로딩" 루틴을 별도로 둔다.
   - data-real-src / data-initial-src / data-default-src 우선순위로
     최종 표시할 이미지를 결정하고, 일정 시간 동안 로딩 재시도한다.
   - 성공/실패와 관계없이 로더(is-loading) 상태를 정리한다.
   ========================================================= */
(function () {
  /* 캐시가 강하게 남는 환경에서 강제 새로 불러오려고 쿼리스트링을 붙인다. */
  function addCacheBust(url) {
    if (!url) return url;
    const sep = url.includes('?') ? '&' : '?';
    return url + sep + 'v=' + Date.now();
  }

  function initProfileLoader() {
    const wrap = document.getElementById('profileWrap');
    const img = document.getElementById('profilePreview');
    if (!wrap || !img) return;

    /* 서버가 제공한 "진짜 이미지" / 초기값 / 기본값을 data-*에서 꺼낸다. */
    const real = (img.dataset.realSrc || '').trim();
    const initial = (img.dataset.initialSrc || img.dataset.defaultSrc || '').trim();
    const fallback = (img.dataset.defaultSrc || initial || '').trim();

    /* 로딩 시작: UI에서 스피너/블러 같은 표시를 위해 is-loading 부여 */
    wrap.classList.add('is-loading');

    /* 표시할 최종 목표 URL 결정 (real > initial > fallback) */
    const target = real || initial || fallback;

    /* 아무 URL도 없으면 로딩 표시만 끄고 끝 */
    if (!target) {
      wrap.classList.remove('is-loading');
      return;
    }

    /* 재시도 파라미터: 일정 간격으로 다시 로딩 시도, 최대 대기 시간 제한 */
    const INTERVAL_MS = 250;
    const MAX_WAIT_MS = 15000;
    const startAt = Date.now();

    /* 실제 <img>에 넣기 전에 Image()로 프리로드해서 성공/실패를 판단한다. */
    function preload(url, onOk, onFail) {
      const pre = new Image();
      pre.onload = onOk;
      pre.onerror = onFail;
      pre.src = url;
    }

    /* 로딩 완료 처리: 실제 img에 src를 적용하고 로딩 UI 해제 */
    function done(src) {
      img.src = src;
      wrap.classList.remove('is-loading');
    }

    /* 재시도 루프: MAX_WAIT_MS까지 계속 시도, 넘으면 fallback로 마무리 */
    function tryLoad(urlToTry) {
      const elapsed = Date.now() - startAt;

      /* 시간 초과면 fallback(또는 마지막 시도 URL)로 강제 종료 */
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

      /* 캐시 무력화한 URL로 프리로드를 시도하고, 실패하면 INTERVAL_MS 후 재시도 */
      const testSrc = addCacheBust(urlToTry);
      preload(
        testSrc,
        function () { done(testSrc); },
        function () { setTimeout(function () { tryLoad(urlToTry); }, INTERVAL_MS); }
      );
    }

    tryLoad(target);
  }

  /* DOM이 아직 로딩 중이면 DOMContentLoaded에 붙이고, 아니면 즉시 실행 */
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initProfileLoader);
  } else {
    initProfileLoader();
  }
})();

$(function () {
  /* =========================================================
     2) 공통 변수/상태
     ---------------------------------------------------------
     - URL과 비용은 body의 data-*에서 받아서 하드코딩을 피한다.
     - editMode(수정 모드) 여부로 입력 가능/불가능을 통제한다.
     ========================================================= */
  const body = document.body;

  /* 서버 엔드포인트(업로드/중복확인/꾸미기 적용) */
  const URL_PROFILE_UPLOAD = body.dataset.urlProfileUpload;
  const URL_NICK_CHECK = body.dataset.urlNickCheck;
  const URL_APPLY_DECOR = body.dataset.urlApplyDecoration;

  /* 비용(기본값은 서버 데이터가 없을 때 대비) */
  const COST_NICK = parseInt(body.dataset.costNick, 10) || 300;
  const COST_PROFILE = parseInt(body.dataset.costProfile, 10) || 500;
  const COST_NICK_DECOR = parseInt(body.dataset.costNickDecor, 10) || 200;
  const COST_BORDER_DECOR = parseInt(body.dataset.costBorderDecor, 10) || 200;

  /* 닉네임 정책: 2~12자, 한글/영문/숫자만 */
  const NICK_REGEX = /^[A-Za-z0-9가-힣]{2,12}$/;

  /* 화면 상태 플래그 */
  let editMode = false;          // 수정 모드 여부
  let nicknameChecked = false;   // 닉네임 중복 확인 통과 여부
  let profileChanged = false;    // 프로필 파일 업로드로 변경 발생 여부

  /* 원본 값(취소/원복/비용 계산의 기준) */
  const originalNickname = ($('#nicknameInput').val() || '').trim();
  const originalProfileSrc = ($('#profilePreview').data('initialSrc') || '').toString();

  /* 비교 용도로 소문자/공백 정규화 */
  function normalize(v) {
    return (v || '').toString().trim().toLowerCase();
  }

  /* 이미지 캐시 무력화용 쿼리 */
  function addCacheBust(url) {
    if (!url) return url;
    const sep = url.indexOf('?') >= 0 ? '&' : '?';
    return url + sep + 'v=' + Date.now();
  }

  /* 금액 표시(원 단위) */
  function formatWon(num) {
    return (num || 0).toLocaleString('ko-KR') + '원';
  }

  /* 서버가 내려준 "현재 적용값(원본)" */
  function getOriginNickColor() {
    return ($('#originNicknameColor').val() || '').toString();
  }
  function getOriginBorderColor() {
    return ($('#originBorderColor').val() || '').toString();
  }

  /* 사용자가 현재 화면에서 선택한 값(입력값) */
  function getCurrentNickColor() {
    return ($('#nicknameColorInput').val() || '').toString();
  }
  function getCurrentBorderColor() {
    return ($('#borderColorInput').val() || '').toString();
  }

  /* =========================================================
     3) 미리보기 적용(닉네임/테두리)
     ---------------------------------------------------------
     - "꾸미기"는 선택 즉시 프리뷰에 반영한다.
     - 다만 실제 차감/저장은 저장(confirm) 단계에서만 한다.
     ========================================================= */

  function applyNicknamePreview() {
    /* 현재 입력 닉네임(없으면 원래 닉네임으로 표시) */
    const color = (getCurrentNickColor() || '').toString().trim();
    const nick = ($('#nicknameInput').val() || '').trim() || originalNickname;

    const $preview = $('#nickDecorPreview');
    const $nickInput = $('#nicknameInput'); // 실제 입력칸에도 동일 스타일을 반영

    /* 텍스트는 항상 동기화 */
    $preview.text(nick);

    /* 색이 없으면 스타일 초기화까지만 하고 종료 */
    if (!color) return;

    /* 프리뷰 초기화 */
    $preview.removeClass('is-rainbow').css('color', '');

    /* 입력칸 초기화 */
    $nickInput.removeClass('is-rainbow').css('color', '');

    /* 단색 처리: 선택한 컬러를 그대로 적용 */
    $preview.css('color', color);
    $nickInput.css('color', color);
  }

  function applyBorderPreview() {
    /* 테두리 색(또는 특수 값 RAINBOW)을 가져온다 */
    const color = getCurrentBorderColor();
    const $wrap = $('#profileWrap');
    const $swatch = $('#borderDecorSwatch');

    /* 기존 테두리 상태/색을 먼저 초기화 */
    $wrap.removeClass('has-border border-rainbow');
    $wrap.css('--profile-border-color', 'transparent');

    /* 스와치도 초기화 */
    $swatch.removeClass('is-empty');
    $swatch.css('background', '');

    /* 아무 값도 없으면 "비어있음" 표시만 하고 끝 */
    if (!color) {
      $swatch.addClass('is-empty');
      return;
    }

    /* 무지개 테두리는 클래스 기반으로 처리 */
    if (color === 'RAINBOW') {
      $wrap.addClass('has-border border-rainbow');
      $swatch.css('background', 'linear-gradient(90deg,#ff4c4c,#ff8a00,#ffc107,#25d366,#3b82f6,#1e3a8a,#a855f7)');
      return;
    }

    /* 단색 테두리는 CSS 변수로 색을 넘긴다 */
    $wrap.addClass('has-border');
    $wrap.css('--profile-border-color', color);
    $swatch.css('background', color);
  }

  /* 프리셋(칩) 선택 상태를 현재 값과 동기화 */
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

    /* 프리셋에 없는 커스텀 색은 선택 표시 없이 둔다 */
    if (!matched && target) {
      // 필요하면 여기서 커스텀 배지 등을 추가할 수도 있음
    }
  }

  /* kind에 따라 hidden input 값을 세팅하고, 미리보기/프리셋/비용을 갱신 */
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

  /* 수정 모드에서만 꾸미기 컨트롤을 활성화/비활성화 */
  function setDecorControlsEnabled(enabled) {
    /* 프리셋 칩 */
    $('#decorateWrap .color-chip').prop('disabled', !enabled);
    /* 커스텀 컬러 피커 + 적용 버튼 */
    $('#nickColorPicker, #borderColorPicker').prop('disabled', !enabled);
    $('#decorateWrap .custom-apply').prop('disabled', !enabled);

    /* 비용 안내 메시지 토글 */
    if (enabled) $('#decorCostMsg').show();
    else $('#decorCostMsg').hide();
  }

  /* =========================================================
     4) 수정 모드 진입/종료
     ---------------------------------------------------------
     - 수정하기 클릭: UI 전환 + 입력 활성화 + 상태 초기화
     - 취소: 원복 후 보기 모드로 복귀
     ========================================================= */

  $('#editBtn').on('click', function () {
    editMode = true;
    $('body').addClass('mypage-editing');

    /* 보기/수정 액션 버튼 영역 전환 */
    $('#viewActions').hide();
    $('#editActions').show();

    /* 비용 박스 표시 */
    $('#costBox').show();

    /* 입력 활성화 */
    $('#nicknameInput').prop('readonly', false);
    $('#nickCheckBtn').removeClass('disabled-btn');
    $('#profileBtnLabel').removeClass('disabled-btn');

    /* 항목별 비용 안내 표시 */
    $('#nickCostMsg').show();
    $('#profileCostMsg').show();

    /* 수정 모드 시작 시 검증 상태 초기화 */
    nicknameChecked = false;
    profileChanged = false;
    $('#nicknameMsg').text('');

    /* 업로드 임시 토큰/파일 입력 초기화 */
    $('#temporaryProfileImageToken').val('');
    $('#profileInput').val('');

    /* 꾸미기 컨트롤 활성화 */
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
      /* 닉네임 원복 */
      $('#nicknameInput').val(originalNickname);

      /* 프로필 이미지 원복:
         - 기존 src에서 캐시 파라미터를 제거한 뒤
         - 캐시 무력화 파라미터를 다시 붙여서 로드 이벤트로 로더를 끈다. */
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

      /* 업로드 관련 값 초기화 */
      $('#temporaryProfileImageToken').val('');
      $('#profileInput').val('');

      /* 꾸미기 원복(원본 값으로 되돌림) */
      setDecorValue('nickname', getOriginNickColor());
      setDecorValue('border', getOriginBorderColor());
    }

    /* 보기 모드로 UI 잠금 */
    $('#nicknameInput').prop('readonly', true);
    $('#nickCheckBtn').addClass('disabled-btn').text('중복 확인');
    $('#profileBtnLabel').addClass('disabled-btn');

    /* 비용 안내/박스 숨김 */
    $('#nickCostMsg').hide();
    $('#profileCostMsg').hide();
    $('#costBox').hide();

    /* 버튼 영역 복귀 */
    $('#editActions').hide();
    $('#viewActions').show();

    /* 캐시 부족 경고/메시지 초기화 */
    $('#cashWarn').hide();
    $('#nicknameMsg').text('');

    nicknameChecked = false;
    profileChanged = false;

    /* 꾸미기 컨트롤 잠금 */
    setDecorControlsEnabled(false);

    updateCostAndButtons();
  }

  /* =========================================================
     5) 닉네임 변경 + 중복 확인
     ---------------------------------------------------------
     - 입력 중에는 프리뷰 동기화
     - 수정 모드일 때만 검증/중복확인 로직 동작
     - 닉네임이 바뀌면 기존 중복확인 상태를 무효 처리
     ========================================================= */

  $('#nicknameInput').on('input', function () {
    /* 입력 즉시 미리보기 반영 */
    applyNicknamePreview();

    /* 보기 모드에서는 검증 메시지/버튼 제어를 하지 않는다 */
    if (!editMode) return;

    const val = $('#nicknameInput').val().trim();

    /* 형식 검증(규칙 위반 시 즉시 안내) */
    if (val.length > 0 && !NICK_REGEX.test(val)) {
      $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
        .text('닉네임은 2~12자, 한글/영문/숫자만 사용할 수 있습니다.');
    } else {
      $('#nicknameMsg').text('');
    }

    /* 입력이 바뀌면 중복확인 상태는 다시 해야 한다 */
    nicknameChecked = false;
    $('#nickCheckBtn').text('중복 확인');

    updateCostAndButtons();
  });

  $('#nickCheckBtn').on('click', function () {
    if (!editMode) return;

    const nickname = $('#nicknameInput').val().trim();

    /* 1) 형식 검증 먼저 */
    if (!NICK_REGEX.test(nickname)) {
      $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
        .text('닉네임은 2~12자, 한글/영문/숫자만 사용할 수 있습니다.');
      nicknameChecked = false;
      updateCostAndButtons();
      return;
    }

    /* 2) 원본과 동일하면 의미 없는 요청이므로 차단 */
    if (nickname === originalNickname) {
      $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
        .text('현재 닉네임과 동일합니다.');
      nicknameChecked = false;
      updateCostAndButtons();
      return;
    }

    /* 3) 서버에 중복 확인 요청 */
    $.ajax({
      url: URL_NICK_CHECK,
      type: 'GET',
      dataType: 'json',
      data: { memberNickname: nickname },
      success: function (res) {
        /* 서버 응답 자체가 실패면 에러 처리 */
        if (!res || res.success !== true) {
          $('#nicknameMsg').removeClass('msg-ok').addClass('msg-error')
            .text((res && res.message) ? res.message : '중복확인에 실패했습니다.');
          nicknameChecked = false;
          $('#nickCheckBtn').text('중복 확인');
          updateCostAndButtons();
          return;
        }

        /* 사용 가능/불가능에 따라 메시지 + 상태 업데이트 */
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
     6) 프로필 업로드
     ---------------------------------------------------------
     - 수정 모드에서만 동작
     - 이미지 파일인지 검사
     - 업로드 성공 시: 임시 URL로 미리보기 변경 + 임시 토큰 저장
     - 최종 저장은 '수정 완료'에서 폼 submit 시 서버가 처리
     ========================================================= */

  $('#profileInput').on('change', function () {
    if (!editMode) return;

    const file = this.files[0];
    if (!file) return;

    /* 이미지가 아니면 즉시 차단 */
    if (!file.type || !file.type.startsWith('image/')) {
      alert('이미지 파일만 선택할 수 있습니다.');
      $(this).val('');
      return;
    }

    /* 업로드 중 로더 표시 */
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
        /* 서버가 SUCCESS가 아니면 업로드 실패 처리 */
        if (!res || res.result !== 'SUCCESS') {
          alert((res && res.errorMessage) ? res.errorMessage : '업로드에 실패했습니다.');
          $('#profileInput').val('');
          $('#profileWrap').removeClass('is-loading');
          return;
        }

        /* 성공: 임시 URL로 미리보기 교체(캐시 무력화 포함) */
        const tempUrl = addCacheBust(res.temporaryProfileImageUrl);

        const $img = $('#profilePreview');
        $img.off('load.__upload error.__upload');
        $img.on('load.__upload error.__upload', function () {
          $('#profileWrap').removeClass('is-loading');
          $img.off('load.__upload error.__upload');
        });
        $img.attr('src', tempUrl);

        /* 서버가 내려준 임시 토큰을 hidden input에 저장(최종 저장 때 사용) */
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
     7) 꾸미기 이벤트(프리셋/커스텀)
     ---------------------------------------------------------
     - 수정 모드에서만 클릭 가능
     - 선택 즉시 hidden input 값 세팅 + 프리뷰 갱신 + 비용 재계산
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
     8) 비용 계산 + 저장 버튼 활성화
     ---------------------------------------------------------
     - 현재 캐시와 변경 사항들을 비교해서 항목별 비용을 계산한다.
     - 저장 가능 조건:
       1) 수정 모드일 것
       2) 변경 사항이 하나 이상 있을 것
       3) 닉네임 변경 시: 형식 통과 + 중복확인 완료
       4) 프로필 변경 시: 임시 토큰이 존재
       5) 총 비용이 보유 캐시 이하
     ========================================================= */

  function updateCostAndButtons() {
    const currentCash = parseInt($('#cashRaw').val(), 10) || 0;

    const newNickname = $('#nicknameInput').val().trim();
    const token = $('#temporaryProfileImageToken').val().trim();

    /* 닉네임 변경 여부 */
    const nickChanged = editMode && (newNickname !== originalNickname);
    const nickCost = nickChanged ? COST_NICK : 0;

    /* 프로필 변경 여부(업로드 성공 + 토큰 존재) */
    const profileCost = (editMode && profileChanged && token.length > 0) ? COST_PROFILE : 0;

    /* 원본 꾸미기 값 vs 현재 선택 값 비교 */
    const originNickColor = getOriginNickColor();
    const originBorderColor = getOriginBorderColor();

    const nickColor = getCurrentNickColor();
    const borderColor = getCurrentBorderColor();

    const nickDecorChanged = editMode && (normalize(nickColor) !== normalize(originNickColor));
    const borderDecorChanged = editMode && (normalize(borderColor) !== normalize(originBorderColor));

    const nickDecorCost = nickDecorChanged ? COST_NICK_DECOR : 0;
    const borderDecorCost = borderDecorChanged ? COST_BORDER_DECOR : 0;

    /* 총 비용 및 차감 후 예상 캐시 */
    const totalCost = nickCost + profileCost + nickDecorCost + borderDecorCost;
    const cashAfter = currentCash - totalCost;

    /* 데스크톱 비용 UI 갱신 */
    $('#costNick').text(formatWon(nickCost));
    $('#costProfile').text(formatWon(profileCost));
    $('#costNickDecor').text(formatWon(nickDecorCost));
    $('#costBorderDecor').text(formatWon(borderDecorCost));
    $('#costTotal').text(formatWon(totalCost));
    $('#cashAfter').text(formatWon(Math.max(cashAfter, 0)));

    let canSave = true;

    /* 변경 사항이 하나도 없으면 저장 불가 */
    const hasAnyChange =
      nickChanged ||
      (profileChanged && token.length > 0) ||
      nickDecorChanged ||
      borderDecorChanged;

    if (!editMode || !hasAnyChange) canSave = false;

    /* 닉네임 변경이 있는 경우: 형식 + 중복확인 필수 */
    if (nickChanged) {
      if (!NICK_REGEX.test(newNickname)) canSave = false;
      if (!nicknameChecked) canSave = false;
    }

    /* 프로필 변경 플래그가 있는데 토큰이 없다면 업로드가 제대로 끝난 게 아니므로 저장 불가 */
    if (profileChanged && token.length === 0) canSave = false;

    /* 캐시 부족이면 저장 불가 + 경고 표시 */
    if (totalCost > currentCash) {
      canSave = false;
      $('#cashWarn').show();
    } else {
      $('#cashWarn').hide();
    }

    /* 저장 버튼 활성/비활성 토글 */
    if (editMode && canSave) $('#saveBtn').removeClass('disabled-btn');
    else $('#saveBtn').addClass('disabled-btn');

    /* 모바일 비용 UI 갱신 */
    $('#mCostNick').text(formatWon(nickCost));
    $('#mCostProfile').text(formatWon(profileCost));
    $('#mCostNickDecor').text(formatWon(nickDecorCost));
    $('#mCostBorderDecor').text(formatWon(borderDecorCost));
    $('#mCostTotal').text(formatWon(totalCost));
  }

  /* =========================================================
     9) 모달 + 저장(제출) 흐름
     ---------------------------------------------------------
     - saveBtn 클릭: 확인 모달을 띄운다.
     - "아니오": 모달 닫고 원복(exitEditMode)
     - "예": (1) 꾸미기 변경이 있으면 서버에 먼저 적용 요청
             (2) 그 다음 닉네임/프로필 변경이 있으면 폼 submit
             (3) 꾸미기만 바뀐 케이스면 reload로 갱신
     ========================================================= */

  $('#saveBtn').on('click', function () {
    if ($(this).hasClass('disabled-btn')) return;
    $('#modalBackdrop').css('display', 'flex');
  });

  function hideConfirmModal() {
    $('#modalBackdrop').hide();
  }

  /* 모달 박스 내부 클릭은 배경 클릭으로 전파되지 않게 막는다 */
  $('.modal-box').on('click', function (e) {
    e.stopPropagation();
  });

  /* 아니오: 취소 처리(원복 후 보기 모드) */
  $('#modalNoBtn').on('click', function () {
    hideConfirmModal();
    exitEditMode(true);
  });

  /* =========================================================
     꾸미기 서버 적용(필요 시)
     ---------------------------------------------------------
     - 변경이 없다면 바로 done() 호출
     - 변경이 있으면 POST로 적용 요청
     - 성공 시 캐시/원본 값을 갱신해서 중복 차감/재계산 오류를 막는다.
     ========================================================= */
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

    /* 서버 DTO 매핑 대비: 키를 2종류로 넣어두고 서버에서 필요한 것만 사용 */
    const payload = {};
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

        /* 서버가 새 캐시를 내려주면 hidden/표시값을 갱신 */
        if (typeof res.newCashBalance !== 'undefined') {
          const newCash = parseInt(res.newCashBalance, 10) || 0;
          $('#cashRaw').val(newCash);
          $('#cashDisplay').val(formatWon(newCash).replace('원원', '원'));
        }

        /* 적용된 값을 원본으로 업데이트해서 이후 계산에서 "변경 없음"으로 인식시키기 */
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

  /* 예: 최종 저장 처리 */
  $('#modalYesBtn').on('click', function () {
    if ($('#saveBtn').hasClass('disabled-btn')) return;

    const $yes = $('#modalYesBtn');
    $yes.prop('disabled', true);

    const token = ($('#temporaryProfileImageToken').val() || '').trim();
    const newNickname = ($('#nicknameInput').val() || '').trim();

    const nickChanged = editMode && (newNickname !== originalNickname);

    /* 폼 submit이 필요한 경우:
       - 닉네임 변경이 있거나
       - 프로필 변경(업로드+토큰)이 있는 경우 */
    const profileSubmitNeeded = editMode && (
      nickChanged || (profileChanged && token.length > 0)
    );

    /* 1) 꾸미기 먼저 적용하고, 2) 필요하면 폼 submit */
    applyDecorationIfNeeded(function (r) {
      if (r && r.failed) {
        $yes.prop('disabled', false);
        return;
      }

      if (profileSubmitNeeded) {
        /* 꾸미기(있다면) → 그 다음 프로필/닉네임(폼 submit) */
        $('#mypageForm').submit();
        return;
      }

      /* 꾸미기만 변경된 경우: 화면 새로고침으로 최신 상태 반영 */
      hideConfirmModal();
      alert('꾸미기가 적용되었습니다.');
      location.reload();
    });
  });

  /* =========================================================
     10) 초기 상태(보기 모드 세팅)
     ---------------------------------------------------------
     - 시작은 보기 모드이므로 컨트롤 잠금
     - 현재 저장된 값 기준으로 프리뷰/선택 표시를 맞춘다.
     ========================================================= */
  setDecorControlsEnabled(false);

  applyNicknamePreview();
  applyBorderPreview();

  syncPresetSelected('nickname', getCurrentNickColor());
  syncPresetSelected('border', getCurrentBorderColor());

  updateCostAndButtons();
});