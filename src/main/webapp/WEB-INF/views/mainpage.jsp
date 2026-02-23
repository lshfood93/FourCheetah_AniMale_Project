<%@ page language="java" contentType="text/html; charset=UTF-8"
  pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<%-- 컨텍스트 경로 공통 변수
     정적 리소스(css/js/img)와 내부 링크를 모두 같은 기준으로 맞추기 위해 먼저 잡아둠 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- activeMenu가 안 내려온 경우 기본값 설정
     헤더 메뉴 활성화 표시가 비는 상황 방지용(메인 페이지 기본 HOME) --%>
<c:if test="${empty activeMenu}">
  <c:set var="activeMenu" value="HOME" />
</c:if>

<%-- 파라미터 없는 내부 링크도 c:url로 미리 생성
     이유:
     1) 컨텍스트 경로 자동 반영
     2) 링크 작성 방식 통일
     3) 나중에 경로 변경 시 찾기 쉬움 --%>
<c:url var="newsListUrl" value="/newsList" />
<c:url var="animeListUrl" value="/animeList" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="description" content="Anime Template">
<meta name="keywords" content="Anime, unica, creative, html">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="ie=edge">
<title>ANIMale</title>

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<%-- Google Font --%>
<link
  href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap"
  rel="stylesheet">
<link
  href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap"
  rel="stylesheet">

<%-- 공통 CSS (템플릿 + 플러그인 + 프로젝트 스타일) --%>
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/plyr.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/owl.carousel.min.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/slicknav.min.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/style.css" type="text/css">

<style>
/* ---------------------------------------------------------
   메인 히어로 배너 보정 스타일
   ---------------------------------------------------------
   템플릿/플러그인 초기화 타이밍 이슈가 있어도
   배너 영역 높이가 0처럼 보이거나 배경이 안 보이는 상황을 줄이기 위한 고정값 보정
--------------------------------------------------------- */

/* 배너 높이 고정: 배경이미지/슬라이더가 안 보이는 문제 방지 */
.hero__slider .hero__items.set-bg {
  display: block;
  height: 520px;
  padding: 200px 0 40px;
}

/* a 태그로 감싸도 템플릿의 배경 카드처럼 보이게 유지 */
.hero__items.set-bg {
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}
</style>
</head>

<body>

  <%-- Preloader (템플릿 기본 로딩 UI) --%>
  <div id="preloder">
    <div class="loader"></div>
  </div>

  <%-- 공통 헤더 include
       activeMenu 값으로 현재 메뉴 활성 상태를 맞추는 구조 --%>
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <%-- =========================================================
       Hero Section (메인 뉴스 배너)
       ---------------------------------------------------------
       - mainBannerNewsList가 비면 기본 배너 + 안내 문구 표시
       - 값이 있으면 최대 3개까지 슬라이더로 노출
       - 배너 전체 클릭 시 뉴스 상세로 이동
     ========================================================= --%>
  <section class="hero">
    <div class="container">
      <div class="hero__slider owl-carousel">

        <c:choose>
          <c:when test="${empty mainBannerNewsList}">
            <%-- 배너 뉴스가 없을 때 보여주는 fallback 화면 --%>
            <div class="hero__items set-bg" data-setbg="${ctx}/img/hero/hero-1.jpg">
              <div class="row">
                <div class="col-lg-6">
                  <div class="hero__text">
                    <div class="label">News</div>
                    <h2>표시할 뉴스가 없습니다.</h2>
                    <p>최신 뉴스가 등록되면 이 영역에 배너로 노출됩니다.</p>

                    <%-- 뉴스 목록으로 이동 (c:url로 미리 만든 경로 사용) --%>
                    <a href="${newsListUrl}" class="hero__ctaLink">
                      <span>뉴스 보러가기</span>
                      <i class="fa fa-angle-right"></i>
                    </a>

                  </div>
                </div>
              </div>
            </div>
          </c:when>

          <c:otherwise>
            <%-- 배너 뉴스가 있으면 순회하면서 최대 3개까지만 노출
                 (메인 히어로 슬라이더는 너무 많으면 UX가 무거워져서 상한 고정) --%>
            <c:forEach var="n" items="${mainBannerNewsList}" varStatus="st">
              <c:if test="${st.count <= 3}">

                <%-- 뉴스 썸네일 원본값 (DB: NEWS_THUMBNAIL_URL) --%>
                <c:set var="bannerImg" value="${n.newsThumbnailUrl}" />

                <%-- 썸네일이 비어 있으면 기본 배너 이미지 사용 --%>
                <c:if test="${empty bannerImg}">
                  <c:set var="bannerImg" value="${ctx}/img/hero/hero-1.jpg" />
                </c:if>

                <%-- =========================================================
                     배너 이미지 경로 정규화
                     ---------------------------------------------------------
                     저장 형식이 섞여 있을 수 있어서 화면에서 한 번 정리함.
                     1) http(s) 시작         -> 외부 URL 그대로 사용
                     2) 이미 ctx 포함         -> 그대로 사용
                     3) /로 시작하는 내부경로 -> ctx 붙이기
                     4) 상대경로             -> ctx + "/" + 경로
                   ========================================================= --%>
                <c:choose>
                  <c:when test="${fn:startsWith(bannerImg,'http')}">
                    <%-- 외부 절대 URL: 그대로 사용 --%>
                  </c:when>

                  <c:when test="${fn:startsWith(bannerImg, ctx)}">
                    <%-- 이미 컨텍스트 경로 포함된 경우: 그대로 사용 --%>
                  </c:when>

                  <c:when test="${fn:startsWith(bannerImg,'/')}">
                    <c:set var="bannerImg" value="${ctx}${bannerImg}" />
                  </c:when>

                  <c:otherwise>
                    <c:set var="bannerImg" value="${ctx}/${bannerImg}" />
                  </c:otherwise>
                </c:choose>

                <%-- 뉴스 상세 링크 생성
                     파라미터(newsId) 포함 링크는 c:url + c:param으로 만드는 쪽이
                     컨텍스트/인코딩/가독성 측면에서 안정적임 --%>
                <c:url var="bannerDetailUrl" value="/newsDetail">
                  <c:param name="newsId" value="${n.newsId}" />
                </c:url>

                <%-- 템플릿 원형은 div 카드지만
                     배너 전체 클릭 UX를 위해 a 태그로 래핑해서 사용
                     (내부 CTA는 중첩 a 방지 때문에 span으로 처리) --%>
                <a href="${bannerDetailUrl}"
                   class="hero__items set-bg"
                   data-setbg="${bannerImg}"
                   style="text-decoration: none;">

                  <div class="row">
                    <div class="col-lg-6">
                      <div class="hero__text">
                        <div class="label">News</div>

                        <%-- 뉴스 제목은 화면 출력 시 c:out으로 escape 처리 --%>
                        <h2><c:out value="${n.newsTitle}" /></h2>

                        <p>자세히 보려면 클릭하세요.</p>

                        <%-- 배너 전체가 이미 a 태그라서 CTA는 클릭 유도용 span만 사용
                             (a 안에 a 중첩 금지) --%>
                        <div class="hero__cta-wrap">
                          <span class="hero__cta">
                            뉴스 보러가기 <i class="fa fa-angle-right"></i>
                          </span>
                        </div>

                      </div>
                    </div>
                  </div>

                </a>

              </c:if>
            </c:forEach>
          </c:otherwise>
        </c:choose>

      </div>
    </div>
  </section>

  <%-- =========================================================
       Product Section (메인 최신 애니 리스트)
       ---------------------------------------------------------
       - mainAnimeList 비면 안내 문구 표시
       - 값이 있으면 최대 12개 카드 노출
       - 썸네일 경로 정규화 후 set-bg로 카드 배경 적용
     ========================================================= --%>
  <section class="product spad home-anime-section">
    <div class="container">

      <%-- 섹션 제목 + 우측 View All 버튼
           메인 전용 헤더 스타일(home-section-head) 적용 --%>
      <div class="row">
        <div class="col-12">
          <div class="home-section-head">
            <div class="section-title">
              <h4>최신 애니 리스트</h4>
              <p class="section-sub">이번 분기 신작 · 인기작을 한 번에 확인하세요</p>
            </div>

            <%-- 애니 목록 전체 페이지 이동 --%>
            <a href="${animeListUrl}" class="btn-viewall">
              View All<span class="arrow_right"></span>
            </a>

          </div>
        </div>
      </div>

      <div class="row">
        <c:choose>
          <c:when test="${empty mainAnimeList}">
            <%-- 메인에 표시할 애니 데이터가 없을 때 fallback 문구 --%>
            <div class="col-lg-12">
              <p style="color: #999; margin-top: 10px;">표시할 애니가 없습니다.</p>
            </div>
          </c:when>

          <c:otherwise>
            <%-- 카드 개수는 최대 12개까지만 출력
                 (4 x 3 기준으로 메인에서 한 화면 구성 맞추기 쉬움) --%>
            <c:forEach var="a" items="${mainAnimeList}" varStatus="st">
              <c:if test="${st.count <= 12}">

                <%-- 애니 썸네일 원본값 --%>
                <c:set var="thumbPath" value="${a.animeThumbnailUrl}" />

                <%-- 썸네일 없으면 기본 샘플 이미지 사용 --%>
                <c:if test="${empty thumbPath}">
                  <c:set var="thumbPath" value="${ctx}/images/anisample/bleach.jpg" />
                </c:if>

                <%-- =========================================================
                     썸네일 경로 정규화
                     ---------------------------------------------------------
                     배너 이미지와 같은 이유로 저장 형식이 섞일 수 있어서
                     화면 출력 직전에 공통 규칙으로 보정함.
                   ========================================================= --%>
                <c:choose>
                  <c:when test="${fn:startsWith(thumbPath,'http')}">
                    <%-- 외부 절대 URL: 그대로 사용 --%>
                  </c:when>

                  <c:when test="${fn:startsWith(thumbPath, ctx)}">
                    <%-- 이미 ctx 포함된 내부 경로: 그대로 사용 --%>
                  </c:when>

                  <c:when test="${fn:startsWith(thumbPath,'/')}">
                    <c:set var="thumbPath" value="${ctx}${thumbPath}" />
                  </c:when>

                  <c:otherwise>
                    <c:set var="thumbPath" value="${ctx}/${thumbPath}" />
                  </c:otherwise>
                </c:choose>

                <%-- 애니 상세 링크 생성 (한 번 만들어 썸네일/제목 링크에서 재사용) --%>
                <c:url var="animeDetailUrl" value="/animeDetail">
                  <c:param name="animeId" value="${a.animeId}" />
                </c:url>

                <div class="col-lg-3 col-md-4 col-sm-6">
                  <div class="product__item">

                    <%-- 썸네일 클릭 시 상세 이동
                         set-bg 클래스는 아래 JS(main.js/보정 스크립트)가 background-image 적용 --%>
                    <a href="${animeDetailUrl}" style="display: block;">
                      <div class="product__item__pic set-bg" data-setbg="${thumbPath}"></div>
                    </a>

                    <div class="product__item__text">
                      <%-- 메타 정보(연도/분기)
                           값이 비어있을 수 있어서 문구 fallback 처리 --%>
                      <ul class="anime-meta">
                        <li>
                          <c:choose>
                            <c:when test="${empty a.animeYear}">연도 미정</c:when>
                            <c:otherwise><c:out value="${a.animeYear}" />년</c:otherwise>
                          </c:choose>
                        </li>
                        <li class="badge-q">
                          <c:choose>
                            <c:when test="${empty a.animeQuarter}">분기 미정</c:when>
                            <c:otherwise><c:out value="${a.animeQuarter}" /></c:otherwise>
                          </c:choose>
                        </li>
                      </ul>

                      <%-- 제목 링크
                           2줄까지만 보이도록 line clamp 적용해서 카드 높이 균형 유지 --%>
                      <h5 class="anime-title" style="margin-bottom: 0;">
                        <a href="${animeDetailUrl}"
                           style="display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">
                          <c:out value="${a.animeTitle}" />
                        </a>
                      </h5>
                    </div>

                  </div>
                </div>

              </c:if>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </div>

    </div>
  </section>

  <%-- 공통 푸터 include --%>
  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <%-- =========================================================
       JS Plugins
       ---------------------------------------------------------
       순서 중요:
       - jQuery 먼저
       - Bootstrap / 플러그인들
       - 마지막에 main.js
     ========================================================= --%>
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>

  <script src="${ctx}/js/player.js"></script>
  <script src="${ctx}/js/jquery.nice-select.min.js"></script>
  <script src="${ctx}/js/mixitup.min.js"></script>
  <script src="${ctx}/js/jquery.slicknav.js"></script>
  <script src="${ctx}/js/owl.carousel.min.js"></script>

  <script src="${ctx}/js/main.js"></script>

  <%-- =========================================================
       안전장치 스크립트
       ---------------------------------------------------------
       목적:
       1) main.js가 중간 에러로 멈췄을 때도 set-bg 배경이미지 적용
       2) hero 슬라이더가 초기화 안 된 경우 한 번 더 강제 초기화

       포인트:
       - owlCarousel 플러그인 존재 여부 먼저 확인
       - owl-loaded 클래스 기준으로 중복 초기화 방지
     ========================================================= --%>
  <script>
    (function () {
      if (!window.jQuery || !jQuery.fn || !jQuery.fn.owlCarousel) return;

      // set-bg 보정:
      // data-setbg 값을 읽어서 background-image를 직접 넣어준다.
      // (main.js의 set-bg 처리 구간이 실행되지 못했을 때 대비)
      jQuery(".set-bg").each(function () {
        var bg = jQuery(this).data("setbg");
        if (bg) jQuery(this).css("background-image", "url(" + bg + ")");
      });

      // hero 슬라이더 보정:
      // owl가 아직 로드되지 않은 경우에만 초기화해서 중복 실행을 막는다.
      var $slider = jQuery(".hero__slider");
      if ($slider.length && !$slider.hasClass("owl-loaded")) {
        $slider.owlCarousel({
          items: 1,
          loop: true,
          nav: true,
          dots: true,
          autoplay: true,
          autoplayTimeout: 5000,
          smartSpeed: 1200
        });
      }
    })();
  </script>

</body>
</html>