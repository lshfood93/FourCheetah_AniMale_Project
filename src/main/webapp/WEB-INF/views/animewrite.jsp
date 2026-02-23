<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- 
  이 페이지에서도 header.jsp에서 ctx를 쓸 수 있게 request scope로 내려둔다.
  include된 JSP는 같은 request를 공유하니까 여기서 한 번만 잡아두면 편하다.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<%-- 
  관리자 전용 화면이라 JSP에서도 한 번 더 막아둔다.
  실제 권한 차단 1순위는 컨트롤러지만, 화면 단에서도 방어막을 두면 실수 방지에 좋다.
  세션에 role이 없거나 ADMIN이 아니면 메인으로 보낸다.
--%>
<c:if test="${empty sessionScope.memberRole or sessionScope.memberRole ne 'ADMIN'}">
  <c:redirect url="${ctx}/mainPage" />
</c:if>

<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="description" content="ANIMale - Anime Create Page">
  <meta name="keywords" content="Anime, ANIMale, admin, create">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">

  <title>ANIMale | 애니 생성 페이지</title>

  <link rel="icon" type="image/png" href="${ctx}/favicon.png"><%-- favicon도 컨텍스트 경로 기준으로 맞춘다 --%>

  <!-- Google Font -->
  <link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

  <!-- Css Styles -->
  <%-- 
    템플릿 리소스는 전부 ctx 기준 절대경로로 통일.
    상대경로(css/...)로 두면 /admin/... 같은 하위 경로에서 404 나는 경우가 생긴다.
  --%>
  <link rel="stylesheet" href="${ctx}/css/bootstrap.min.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/font-awesome.min.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/elegant-icons.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/plyr.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/owl.carousel.min.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/slicknav.min.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/style.css" type="text/css">

  <%-- 
    페이지 전용 스타일.
    예전에 style이 head 밖에 있으면 HTML 구조가 애매해져서 여기로 모아두는 쪽이 안전하다.
    템플릿 기본 룩은 유지하고, 생성 폼에 필요한 최소 보정만 넣는다.
  --%>
  <style>
    .auth-bar{
      padding:10px 0;
      border-bottom:1px solid rgba(255,255,255,.10);
      background:rgba(0,0,0,.15);
    }

    .auth-bar__menu{
      margin:0;
      padding:0;
      list-style:none;
      display:flex;
      gap:16px;
      justify-content:flex-end;
      align-items:center;
    }

    .auth-bar__menu a{
      font-size:13px;
      color:rgba(255,255,255,.9);
    }
    .auth-bar__menu a:hover{ color:#fff; }

    .header__right .auth-links{
      display:flex;
      align-items:center;
      gap:10px;
      justify-content:flex-end;
      flex-wrap:nowrap;
    }

    .header__right .auth-icon{
      width:34px;
      height:34px;
      display:inline-flex;
      align-items:center;
      justify-content:center;
      border-radius:10px;
      border:1px solid rgba(255,255,255,.15);
      background:rgba(255,255,255,.06);
      color:#fff;
    }
    .header__right .auth-icon:hover{ background:rgba(255,255,255,.12); }

    .header__right .auth-link{
      display:inline-flex;
      align-items:center;
      padding:6px 10px;
      border-radius:10px;
      font-size:13px;
      color:#fff;
      border:1px solid rgba(255,255,255,.15);
      background:rgba(255,255,255,.06);
      white-space:nowrap;
    }
    .header__right .auth-link:hover{ background:rgba(255,255,255,.12); }

    .header__right .auth-link--outline{
      background:transparent;
      border-color:rgba(255,255,255,.25);
    }

    .header__right .auth-link--muted{
      background:transparent;
      border-color:transparent;
      color:rgba(255,255,255,.75);
      text-decoration:underline;
    }
    .header__right .auth-link--muted:hover{ color:#fff; }

    /* 생성 페이지 폼용 최소 보정 (템플릿 느낌 유지하면서 입력 UX만 정리) */
    .admin-form .form-control,
    .admin-form select.form-control,
    .admin-form textarea.form-control{
      border-radius:8px;
      height:46px;
      line-height:46px; /* input/select 높이와 텍스트 세로 정렬감 맞추기 */
    }

    .admin-form textarea.form-control{
      height:180px;
      resize:vertical;
    }

    .admin-form .help{
      color:rgba(255,255,255,0.88) !important;
      font-size:12px;
      opacity:0.85;
      margin-top:6px;
    }

    /* 템플릿에서 a 태그 기준으로 잡힌 버튼 스타일을 button에도 자연스럽게 먹게 맞춤 */
    .anime__details__btn .watch-btn,
    .anime__details__btn .follow-btn{
      border:none;
      cursor:pointer;
    }

    /* 등록 버튼(watch-btn) 오른쪽 아이콘 영역 색이 따로 놀지 않게 전체를 동일한 빨간색으로 통일 */
    .anime__details__btn .watch-btn,
    .anime__details__btn .watch-btn span,
    .anime__details__btn .watch-btn i{
      background:#e53637 !important;
      color:#fff !important;
    }

    /* 템플릿 기본 분리선/아이콘 영역 스타일이 남아 있으면 제거해서 한 덩어리 버튼처럼 보이게 처리 */
    .anime__details__btn .watch-btn i{ border-left:none !important; }

    .anime__details__btn .watch-btn[disabled]{
      opacity:0.55;
      cursor:not-allowed;
    }

    /* 파일 선택 전 썸네일 미리보기 기본 박스 */
    .preview-fallback{
      background:#2a2a2a;
      display:flex;
      align-items:center;
      justify-content:center;
      color:rgba(255,255,255,0.8);
      height:440px;
      border-radius:10px;
    }

    .admin-form label{ color:#fff !important; }

    /* 썸네일 박스 바로 아래 도움말 색 고정 (템플릿 영향으로 흐려지는 것 방지) */
    #thumbBox + .help{ color:rgba(255,255,255,0.85) !important; }

    #thumbBox{
      height:440px;
      background:rgba(255,255,255,.03);
      border:1px solid rgba(255,255,255,.12);
    }

    #anime_quarter{
      height:46px;
      line-height:46px; /* select 높이 맞췄을 때 텍스트가 위아래로 치우치지 않게 보정 */
      padding-top:10px;
      padding-bottom:10px;
    }
  </style>
</head>

<body>

  <%-- header.jsp에서 requestScope.ctx를 그대로 사용할 수 있게 위에서 미리 세팅해둔 상태 --%>
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <!-- Auth Bar Begin -->
  <section class="auth-bar">
    <div class="container">
      <c:choose>

        <%-- 
          원칙적으로 이 화면까지 오기 전에 ADMIN 체크로 걸러지지만,
          세션 만료/예외 상황까지 생각해서 링크 경로는 안전하게 ctx 기준으로 맞춘다.
        --%>
        <c:when test="${empty sessionScope.memberId}">
          <ul class="auth-bar__menu">
            <li><a href="${ctx}/login">로그인</a></li>
            <li><a href="${ctx}/joinPage">회원가입</a></li>
            <li><a href="${ctx}/findPasswordPage">비밀번호 찾기</a></li>
          </ul>
        </c:when>

        <c:when test="${sessionScope.memberRole eq 'ADMIN'}">
          <span style="margin-right:10px; color:rgba(255,255,255,.8); font-size:13px;">
            <c:out value="${sessionScope.memberName}" />
          </span>

          <%-- 관리자 링크도 전부 ctx 기준으로 통일해서 배포 경로 바뀌어도 깨지지 않게 유지 --%>
          <a href="${ctx}/adminPage" style="margin-right:10px; color:#fff; font-size:14px;">관리자페이지</a>
          <a href="${ctx}/logout" style="color:#fff; font-size:14px;">로그아웃</a>
        </c:when>

        <c:otherwise>
          <span style="margin-right:10px; color:rgba(255,255,255,.8); font-size:13px;">
            <c:out value="${sessionScope.memberName}" />님
          </span>

          <%-- 일반 사용자용 링크 분기 (혹시 화면 재사용/예외 흐름이 생겨도 경로는 동일 규칙 유지) --%>
          <a href="${ctx}/myPage" style="margin-right:10px; color:#fff; font-size:14px;">마이페이지</a>
          <a href="${ctx}/logout" style="color:#fff; font-size:14px;">로그아웃</a>
        </c:otherwise>

      </c:choose>
    </div>
  </section>
  <!-- Auth Bar End -->

  <!-- Breadcrumb Begin -->
  <div class="breadcrumb-option">
    <div class="container">
      <div class="row">
        <div class="col-lg-12">
          <div class="breadcrumb__links">
            <%-- 브레드크럼 링크도 모두 ctx 기준으로 맞춰서 하위 경로 접근 시 경로 꼬임 방지 --%>
            <a href="${ctx}/mainPage"><i class="fa fa-home"></i> 홈</a>
            <a href="${ctx}/adminPage">관리자</a>
            <span>애니 추가</span>
          </div>
        </div>
      </div>
    </div>
  </div>
  <!-- Breadcrumb End -->

  <!-- Anime Section Begin -->
  <section class="anime-details spad">
    <div class="container">

      <div class="anime__details__content">
        <div class="row">

          <!-- LEFT: 썸네일 미리보기 (템플릿 좌측 비주얼 영역 구조 재사용) -->
          <div class="col-lg-3">
            <div id="thumbBox"
                 class="anime__details__pic set-bg"
                 data-setbg="${ctx}/img/anime/details-pic.jpg"
                 style="border-radius:10px;"></div>

            <div class="help">이미지 파일을 선택하면 좌측 미리보기에 즉시 반영됩니다.</div>
          </div>

          <!-- RIGHT: 입력 폼 영역 -->
          <div class="col-lg-9">
            <div class="anime__details__text">

              <div class="anime__details__title">
                <h3>애니 생성 (관리자)</h3>
                <span>필수 항목을 입력한 뒤 등록을 완료하세요.</span>
              </div>

              <%-- 서버 검증 실패 등으로 에러 메시지가 내려오면 화면 상단에 바로 표시 --%>
              <c:if test="${not empty errorMsg}">
                <div class="alert alert-danger" style="margin-top:16px;">
                  ${errorMsg}
                </div>
              </c:if>

              <div class="admin-form" style="margin-top:18px;">
                <%-- 
                  등록 폼 동작 메모
                  - POST /animeWrite 로 전송
                  - enctype은 파일 업로드 때문에 multipart/form-data 사용
                  - 성공 후 이동 경로는 컨트롤러 정책(예: 상세페이지 redirect)에 따름
                --%>
                <form id="animeWriteForm"
                      action="${ctx}/animeWrite"
                      method="post"
                      enctype="multipart/form-data">

                  <div class="row">

                    <!-- anime_title: 사용자에게 보여줄 제목 -->
                    <div class="col-lg-12">
                      <div class="form-group" style="margin-bottom:16px;">
                        <label style="display:block; margin-bottom:8px;">
                          애니 제목 <span style="color:#ff5b5b;">*</span>
                        </label>
                        <input type="text"
                               class="form-control"
                               name="animeTitle"
                               id="anime_title"
                               placeholder="예) Fate/stay night: Unlimited Blade Works"
                               maxlength="200"
                               required>
                      </div>
                    </div>

                    <!-- original_title: 원제(일본어/영문 등 원본 표기 저장용) -->
                    <div class="col-lg-12">
                      <div class="form-group" style="margin-bottom:16px;">
                        <label style="display:block; margin-bottom:8px;">
                          오리지널 제목 <span style="color:#ff5b5b;">*</span>
                        </label>
                        <input type="text"
                               class="form-control"
                               name="originalTitle"
                               id="original_title"
                               placeholder="예) フェイト／ステイナイト"
                               maxlength="200"
                               required>
                      </div>
                    </div>

                    <!-- anime_year: 방영 연도 -->
                    <div class="col-lg-6 col-md-6">
                      <div class="form-group" style="margin-bottom:16px;">
                        <label style="display:block; margin-bottom:8px;">
                          방영년도 <span style="color:#ff5b5b;">*</span>
                        </label>
                        <input type="number"
                               class="form-control"
                               name="animeYear"
                               id="anime_year"
                               placeholder="예) 2024"
                               min="1960"
                               max="2100"
                               required>
                      </div>
                    </div>

                    <!-- anime_quarter: 방영 분기 -->
                    <div class="col-lg-6 col-md-6">
                      <div class="form-group" style="margin-bottom:16px;">
                        <label style="display:block; margin-bottom:8px;">
                          방영분기 <span style="color:#ff5b5b;">*</span>
                        </label>
                        <select class="form-control"
                                name="animeQuarter"
                                id="anime_quarter"
                                required>
                          <option value="">분기 선택</option>
                          <option value="1분기">1분기 (1~3월)</option>
                          <option value="2분기">2분기 (4~6월)</option>
                          <option value="3분기">3분기 (7~9월)</option>
                          <option value="4분기">4분기 (10~12월)</option>
                        </select>
                      </div>
                    </div>

                    <!-- thumbFile: 업로드할 썸네일 이미지 파일 -->
                    <div class="col-lg-12">
                      <div class="form-group" style="margin-bottom:16px;">
                        <label style="display:block; margin-bottom:8px;">
                          썸네일 이미지 <span style="color:#ff5b5b;">*</span>
                        </label>
                        <input type="file"
                               class="form-control"
                               name="thumbFile"
                               id="thumbFile"
                               accept="image/*"
                               required>

                        <div class="help">
                          이미지 파일을 선택하면 좌측 미리보기로 즉시 반영되고, 등록 시 서버에 저장 후 URL만 DB에 저장됩니다.
                        </div>
                      </div>
                    </div>

                    <!-- anime_story: 작품 소개/줄거리 -->
                    <div class="col-lg-12">
                      <div class="form-group" style="margin-bottom:16px;">
                        <label style="display:block; margin-bottom:8px;">
                          상세 줄거리 <span style="color:#ff5b5b;">*</span>
                        </label>
                        <textarea class="form-control"
                                  name="animeStory"
                                  id="anime_story"
                                  placeholder="작품의 핵심 줄거리를 작성하세요."
                                  maxlength="4000"
                                  required></textarea>
                      </div>
                    </div>

                  </div>

                  <!-- 버튼 영역: 템플릿 버튼 영역 클래스 재사용 -->
                  <div class="anime__details__btn" style="margin-top:10px;">
                    <button type="submit" id="submitBtn" class="watch-btn" disabled>
                      <span>등록 완료</span>
                      <i class="fa fa-check"></i>
                    </button>

                    <%-- 목록으로 돌아가는 링크도 ctx 기준으로 유지 --%>
                    <a href="${ctx}/animeList" class="follow-btn" style="margin-left:10px;">
                      <i class="fa fa-times"></i>
                      등록 취소
                    </a>
                  </div>

                </form>
              </div>

            </div>
          </div>

        </div>
      </div>

    </div>
  </section>
  <!-- Anime Section End -->

  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <!-- Js Plugins -->
  <%-- 
    JS 파일도 CSS와 같은 이유로 ctx 기준 절대경로 사용.
    페이지 경로 깊이에 따라 상대경로가 틀어지는 문제를 미리 막는다.
  --%>
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/player.js"></script>
  <script src="${ctx}/js/jquery.nice-select.min.js"></script>
  <script src="${ctx}/js/mixitup.min.js"></script>
  <script src="${ctx}/js/jquery.slicknav.js"></script>
  <script src="${ctx}/js/owl.carousel.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <!-- 페이지 전용 JS: 필수값 검사 + 썸네일 미리보기 -->
  <script>
    (function () {
      // 폼 요소 참조를 한 번만 잡아두고 재사용
      var titleEl = document.getElementById('anime_title');
      var yearEl = document.getElementById('anime_year');
      var originalTitleEl = document.getElementById('original_title');
      var quarterEl = document.getElementById('anime_quarter');
      var storyEl = document.getElementById('anime_story');
      var fileEl = document.getElementById('thumbFile');
      var submitBtn = document.getElementById('submitBtn');
      var thumbBox = document.getElementById('thumbBox');
      var formEl = document.getElementById('animeWriteForm');

      // 공백만 입력한 경우를 막기 위해 trim 기준으로 값 확인
      function trimVal(el) {
        return (el && el.value) ? String(el.value).trim() : '';
      }

      // 버튼 활성화 조건을 한 군데에서 관리
      // required가 있어도 UX상 미리 버튼 상태를 보여주기 위해 별도 체크함
      function validateForm() {
        var titleOk = trimVal(titleEl).length > 0;
        var yearOk = trimVal(yearEl).length > 0;
        var originalTitleOk = trimVal(originalTitleEl).length > 0;
        var quarterOk = trimVal(quarterEl).length > 0;
        var storyOk = trimVal(storyEl).length > 0;
        var fileOk = !!(fileEl && fileEl.files && fileEl.files.length > 0);

        if (submitBtn) submitBtn.disabled = !(titleOk && yearOk && originalTitleOk && quarterOk && storyOk && fileOk);
      }

      if (fileEl) {
        fileEl.addEventListener('change', function () {
          // 파일 선택이 취소된 경우도 있으니 먼저 null 체크
          var file = (fileEl.files && fileEl.files[0]) ? fileEl.files[0] : null;
          if (!file) { validateForm(); return; }

          // 선택한 이미지를 서버 업로드 전에 브라우저에서 바로 미리보기
          var reader = new FileReader();
          reader.onload = function (e) {
            if (!thumbBox) return;
            thumbBox.style.backgroundImage = 'url(' + e.target.result + ')';
            thumbBox.style.backgroundSize = 'cover';
            thumbBox.style.backgroundPosition = 'center';
          };
          reader.readAsDataURL(file);

          // 파일 선택 상태도 필수 검증 조건에 포함되므로 같이 재검사
          validateForm();
        });
      }

      // 입력/변경 이벤트마다 버튼 상태 갱신
      // input: 타이핑 중 실시간 반영
      // change: select/file 등 변경 반영
      var events = ['input', 'change'];
      for (var i = 0; i < events.length; i++) {
        var evt = events[i];
        if (titleEl) titleEl.addEventListener(evt, validateForm);
        if (yearEl) yearEl.addEventListener(evt, validateForm);
        if (originalTitleEl) originalTitleEl.addEventListener(evt, validateForm);
        if (quarterEl) quarterEl.addEventListener(evt, validateForm);
        if (storyEl) storyEl.addEventListener(evt, validateForm);
      }

      <%-- 
        버튼 disabled만 믿지 않고 submit 시점에도 한 번 더 검증한다.
        엔터키 제출이나 브라우저 동작 차이로 우회되는 상황을 줄이기 위한 마지막 체크.
      --%>
      if (formEl) {
        formEl.addEventListener('submit', function (e) {
          validateForm();
          if (submitBtn && submitBtn.disabled) {
            e.preventDefault();
            alert('필수 항목을 모두 입력해주세요.');
            return false;
          }
        });
      }

      // 초기 진입 시점에도 버튼 상태 맞춰두기 (기본 disabled 유지 확인용)
      validateForm();
    })();
  </script>

</body>
</html>