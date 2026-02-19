<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- ✅ ctx는 include(header.jsp)에서도 쓰일 수 있으니 request scope로 내려줌 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<%-- ✅ 관리자 전용 페이지: ADMIN 아니면 접근 차단(컨트롤러 차단이 1순위지만 JSP에서도 2중 안전장치) --%>
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

  <link rel="icon" type="image/png" href="${ctx}/favicon.png"><%-- ✅ ctx 적용 --%>

  <!-- Google Font -->
  <link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

  <!-- Css Styles -->
  <%-- ✅ 상대경로(css/..) -> ctx 기반 절대경로로 통일(서브경로에서 404 방지) --%>
  <link rel="stylesheet" href="${ctx}/css/bootstrap.min.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/font-awesome.min.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/elegant-icons.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/plyr.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/owl.carousel.min.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/slicknav.min.css" type="text/css">
  <link rel="stylesheet" href="${ctx}/css/style.css" type="text/css">

  <%-- ✅ 기존에 head 밖에 있던 style을 head 안으로 이동(HTML 구조 정상화) --%>
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

    /* 생성 페이지용 최소 보강 (템플릿 룩 &필 유지) */
    .admin-form .form-control,
    .admin-form select.form-control,
    .admin-form textarea.form-control{
      border-radius:8px;
      height:46px;
      line-height:46px; /* 핵심 */
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

    /* 템플릿의 watch-btn / follow-btn를 button에도 자연스럽게 적용 */
    .anime__details__btn .watch-btn,
    .anime__details__btn .follow-btn{
      border:none;
      cursor:pointer;
    }

    /* (A) watch-btn 오른쪽 흰 박스 제거: 아이콘 영역도 동일한 빨간색으로 통일 */
    .anime__details__btn .watch-btn,
    .anime__details__btn .watch-btn span,
    .anime__details__btn .watch-btn i{
      background:#e53637 !important;
      color:#fff !important;
    }

    /* 아이콘 영역에 들어가던 분리선/여백 느낌까지 제거(있을 경우) */
    .anime__details__btn .watch-btn i{ border-left:none !important; }

    .anime__details__btn .watch-btn[disabled]{
      opacity:0.55;
      cursor:not-allowed;
    }

    /* 썸네일 미리보기 영역 */
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

    /* 썸네일 아래 도움말 글자색 고정 */
    #thumbBox + .help{ color:rgba(255,255,255,0.85) !important; }

    #thumbBox{
      height:440px;
      background:rgba(255,255,255,.03);
      border:1px solid rgba(255,255,255,.12);
    }

    #anime_quarter{
      height:46px;
      line-height:46px; /* 핵심 */
      padding-top:10px;
      padding-bottom:10px;
    }
  </style>
</head>

<body>

  <%-- header.jsp는 request scope ctx 사용 가능 --%>
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <!-- Auth Bar Begin -->
  <section class="auth-bar">
    <div class="container">
      <c:choose>

        <%-- ✅ 이 페이지는 ADMIN만 접근 가능하지만, 혹시 세션이 풀렸을 때를 대비해 링크도 ctx 적용 --%>
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

          <%-- ✅ 절대경로(/adminPage) -> ctx 기반으로 통일 --%>
          <a href="${ctx}/adminPage" style="margin-right:10px; color:#fff; font-size:14px;">관리자페이지</a>
          <a href="${ctx}/logout" style="color:#fff; font-size:14px;">로그아웃</a>
        </c:when>

        <c:otherwise>
          <span style="margin-right:10px; color:rgba(255,255,255,.8); font-size:13px;">
            <c:out value="${sessionScope.memberName}" />님
          </span>

          <%-- ✅ 절대경로(/myPage,/logout) -> ctx 기반으로 통일 --%>
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
            <%-- ✅ href="/mainPage" 같은 절대경로 -> ctx 기반으로 통일 --%>
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

          <!-- LEFT: 썸네일 미리보기 (템플릿 구조 유지) -->
          <div class="col-lg-3">
            <div id="thumbBox"
                 class="anime__details__pic set-bg"
                 data-setbg="${ctx}/img/anime/details-pic.jpg"
                 style="border-radius:10px;"></div>

            <div class="help">이미지 파일을 선택하면 좌측 미리보기에 즉시 반영됩니다.</div>
          </div>

          <!-- RIGHT: 폼 영역 -->
          <div class="col-lg-9">
            <div class="anime__details__text">

              <div class="anime__details__title">
                <h3>애니 생성 (관리자)</h3>
                <span>필수 항목을 입력한 뒤 등록을 완료하세요.</span>
              </div>

              <%-- 서버에서 에러 메시지를 내려주는 경우 표시(선택) --%>
              <c:if test="${not empty errorMsg}">
                <div class="alert alert-danger" style="margin-top:16px;">
                  ${errorMsg}
                </div>
              </c:if>

              <div class="admin-form" style="margin-top:18px;">
                <%--
                  Submit 서비스 형태
                  - action은 /animeWrite로 통일 (POST에서 insert 처리)
                  - 성공 시: /animeDetail?animeId=... 로 redirect(프로젝트 정책에 맞게)
                --%>
                <form id="animeWriteForm"
                      action="${ctx}/animeWrite"
                      method="post"
                      enctype="multipart/form-data">

                  <div class="row">

                    <!-- anime_title -->
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

                    <!-- original_title -->
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

                    <!-- anime_year -->
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

                    <!-- anime_quarter -->
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

                    <!-- anime_thumbnail_file -->
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

                    <!-- anime_story -->
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

                  <!-- 버튼 영역: 템플릿의 anime__details__btn 영역 활용 -->
                  <div class="anime__details__btn" style="margin-top:10px;">
                    <button type="submit" id="submitBtn" class="watch-btn" disabled>
                      <span>등록 완료</span>
                      <i class="fa fa-check"></i>
                    </button>

                    <%-- ✅ 절대경로(/animeList) -> ctx 기반으로 통일 --%>
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
  <%-- ✅ 상대경로(js/..) -> ctx 기반 절대경로로 통일(서브경로에서 404 방지) --%>
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/player.js"></script>
  <script src="${ctx}/js/jquery.nice-select.min.js"></script>
  <script src="${ctx}/js/mixitup.min.js"></script>
  <script src="${ctx}/js/jquery.slicknav.js"></script>
  <script src="${ctx}/js/owl.carousel.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <!-- 페이지 전용 JS: 버튼 활성화 + 썸네일 미리보기 -->
  <script>
    (function () {
      var titleEl = document.getElementById('anime_title');
      var yearEl = document.getElementById('anime_year');
      var originalTitleEl = document.getElementById('original_title');
      var quarterEl = document.getElementById('anime_quarter');
      var storyEl = document.getElementById('anime_story');
      var fileEl = document.getElementById('thumbFile');
      var submitBtn = document.getElementById('submitBtn');
      var thumbBox = document.getElementById('thumbBox');
      var formEl = document.getElementById('animeWriteForm');

      function trimVal(el) {
        return (el && el.value) ? String(el.value).trim() : '';
      }

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
          var file = (fileEl.files && fileEl.files[0]) ? fileEl.files[0] : null;
          if (!file) { validateForm(); return; }

          var reader = new FileReader();
          reader.onload = function (e) {
            if (!thumbBox) return;
            thumbBox.style.backgroundImage = 'url(' + e.target.result + ')';
            thumbBox.style.backgroundSize = 'cover';
            thumbBox.style.backgroundPosition = 'center';
          };
          reader.readAsDataURL(file);

          validateForm();
        });
      }

      // 입력 변화마다 검증
      var events = ['input', 'change'];
      for (var i = 0; i < events.length; i++) {
        var evt = events[i];
        if (titleEl) titleEl.addEventListener(evt, validateForm);
        if (yearEl) yearEl.addEventListener(evt, validateForm);
        if (originalTitleEl) originalTitleEl.addEventListener(evt, validateForm);
        if (quarterEl) quarterEl.addEventListener(evt, validateForm);
        if (storyEl) storyEl.addEventListener(evt, validateForm);
      }

      <%-- ✅ 엔터 제출/예외 제출 방지: submit에서도 한 번 더 검증 --%>
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

      validateForm();
    })();
  </script>

</body>
</html>
