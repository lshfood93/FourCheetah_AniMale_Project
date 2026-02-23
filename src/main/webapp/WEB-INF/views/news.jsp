<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%-- 공통 컨텍스트 경로
     링크/폼 action/정적 리소스(css, js, 이미지) 경로를 전부 ctx 기준으로 맞추기 위해
     페이지 최상단에서 먼저 선언해 둔다. --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 뉴스</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<!-- 템플릿 공통 CSS (경로는 모두 ctx 기준으로 통일) -->
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">
<link rel="stylesheet" href="${ctx}/css/plyr.css">
<link rel="stylesheet" href="${ctx}/css/nice-select.css">
<link rel="stylesheet" href="${ctx}/css/owl.carousel.min.css">
<link rel="stylesheet" href="${ctx}/css/slicknav.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* =========================================================
   NEWS 목록 페이지 전용 커스텀 스타일
   - scope: .news-page
   - 카드/타이틀/페이지네이션을 뉴스 화면 톤에 맞게 보정
   - 검색 UI의 기본 스타일은 공용 CSS를 최대한 유지
   - 뉴스 페이지에서만 검색 영역 폭 흔들림(버튼 유무에 따른 레이아웃 변화) 보정
========================================================= */

/* =========================
   빠르게 조정할 값(페이지 톤 미세조절용)
   여기 변수만 만져도 타이틀/검색 폭 느낌을 바로 바꿀 수 있게 분리
========================= */
.news-page{
  --news-title-size: 28px;     /* '뉴스' 메인 타이틀 크기 */
  --news-sub-gap: 6px;         /* 메인 타이틀과 서브문장 간격 */
  --news-underline-w: 50px;    /* 타이틀 아래 언더라인 길이 */
  --news-underline-h: 2px;     /* 타이틀 아래 언더라인 두께 */

  --news-search-max: 320px;    /* 데스크탑 기준 검색박스 목표 폭 */
  --news-search-min: 320px;    /* 버튼이 같이 보여도 최소 유지할 폭(너무 찌그러짐 방지) */
}

/* 뉴스 카드 영역 안쪽 row/col 거터만 따로 정리
   타이틀 영역(.product__page__title)의 row 간격에는 영향 안 주려고 범위를 news-card-area로 제한 */
.news-page .news-card-area .row{ margin-left:-6px; margin-right:-6px; }
.news-page .news-card-area [class*='col-']{ padding-left:6px; padding-right:6px; }

/* -------------------------
   뉴스 카드(목록 아이템)
------------------------- */
.news-page .blog__item{
  height: 580px;
  display: block;
  position: relative;

  margin: 0 0 12px 0 !important;
  border-radius: 14px;
  overflow: hidden;

  border: none !important;
  box-shadow: inset 0 0 0 1px rgba(255,255,255,0.08);

  background-color: rgba(255,255,255,0.03);
  background-clip: padding-box;
  transform: translateZ(0);

  text-decoration: none !important;
  color: inherit !important;

  transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
}
.news-page .blog__item.small__item{ height: 285px; }

/* 카드 위에 얹는 어두운 베이스 오버레이
   텍스트 가독성 확보용 + hover 때 톤 변화 주기 쉽게 분리 */
.news-page .blog__item::before{
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(11, 12, 42, 0.10);
  z-index: 1;
  pointer-events: none;
}

/* 카드 하단으로 갈수록 더 어두워지는 그라데이션
   제목 텍스트가 카드 하단에 올라가므로 하단 대비를 확실히 잡아준다. */
.news-page .blog__item::after{
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    180deg,
    rgba(0,0,0,0.00) 30%,
    rgba(0,0,0,0.45) 65%,
    rgba(0,0,0,0.78) 100%
  );
  z-index: 2;
  pointer-events: none;
}
.news-page .blog__item::before,
.news-page .blog__item::after{ border-radius: inherit; }

/* 카드 hover 피드백
   살짝 뜨는 느낌 + 붉은 톤 외곽선으로 뉴스 카드임을 강조 */
.news-page .blog__item:hover{
  transform: translateY(-3px);
  box-shadow:
    inset 0 0 0 1px rgba(229,54,55,0.22),
    0 18px 42px rgba(0,0,0,0.38);
}
.news-page .blog__item:hover::before{
  background: rgba(11, 12, 42, 0.40);
}

/* 카드 텍스트 오버레이
   제목을 카드 하단 중앙에 올리고, 큰 카드/작은 카드 padding 차이만 별도 조정 */
.news-page .blog__item__text{
  position: absolute;
  left: 0;
  bottom: 25px;
  width: 100%;
  text-align: center;
  padding: 0 105px;
  z-index: 3;
}
.news-page .blog__item.small__item .blog__item__text{ padding: 0 30px; }

/* 제목 줄수 제한
   작은 카드는 2줄, 큰 카드는 3줄까지 허용해서 카드 높이별 균형 맞춤 */
.news-page .blog__item__text h4{
  margin: 0;
  color: #fff;
  text-shadow: 0 10px 30px rgba(0,0,0,0.55);
  font-weight: 900;
  letter-spacing: 0.2px;

  display: -webkit-box;
  -webkit-box-orient: vertical;
  overflow: hidden;
  -webkit-line-clamp: 2;
}
.news-page .blog__item:not(.small__item) .blog__item__text h4{
  -webkit-line-clamp: 3;
}

/* 카드 상단의 NEWS 배지
   별도 마크업 추가 없이 pseudo 요소로 처리해서 구조를 단순하게 유지 */
.news-page .blog__item__text::before{
  content: 'NEWS';
  display: inline-flex;
  align-items: center;
  padding: 5px 12px;
  border-radius: 999px;
  background: rgba(229,54,55,0.92);
  color: #fff;
  font-size: 11px;
  font-weight: 900;
  letter-spacing: 0.6px;
  margin-bottom: 12px;
}

/* -------------------------
   페이지네이션
------------------------- */
.news-page .product__pagination{
  margin-top: 25px;
  text-align: center;
}
.news-page .product__pagination a{
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 44px;
  height: 44px;
  padding: 0 14px;
  margin: 0 4px 8px 4px;
  border-radius: 10px;
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(11,12,42,0.55);
  color: rgba(255,255,255,0.85);
  transition: all .15s ease;
  text-decoration: none !important;
}
.news-page .product__pagination a:hover{
  transform: translateY(-1px);
  background: rgba(255,255,255,0.08);
  color: #fff;
}
.news-page .product__pagination a.current-page{
  background: rgba(255,255,255,0.18);
  border-color: rgba(255,255,255,0.25);
  color: #fff;
  font-weight: 900;
}

/* =========================================================
   뉴스 타이틀 영역(미니멀 커스텀)
   템플릿 기본 section-title 장식은 지우고 뉴스 페이지 전용 스타일 적용
========================================================= */
.news-page .product__page__title .section-title::before,
.news-page .product__page__title .section-title::after{
  content: none !important;
}

.news-page .product__page__title .section-title h4{
  position: relative;
  display: inline-block;
  margin: 0 !important;

  padding-left: 0 !important;
  text-transform: none !important;

  padding: 0 0 12px 0 !important;

  background: none !important;
  border: 0 !important;
  box-shadow: none !important;

  color: #fff;
  font-size: var(--news-title-size);
  font-weight: 900;
  letter-spacing: -0.6px;
  line-height: 1.05;
  text-shadow: 0 12px 28px rgba(0,0,0,0.35);
}

/* 타이틀 위에 작은 NEWS 라벨 표시 */
.news-page .product__page__title .section-title h4::before{
  content: 'NEWS';
  position: absolute;
  left: 0;
  top: -18px;

  font-size: 11px;
  font-weight: 800;
  letter-spacing: 1.6px;
  color: rgba(255,255,255,0.55);
}

/* 타이틀 밑 언더라인 */
.news-page .product__page__title .section-title h4::after{
  content: '';
  position: absolute;
  left: 0;
  bottom: 2px;

  width: var(--news-underline-w);
  height: var(--news-underline-h);
  border-radius: 999px;

  background: linear-gradient(
    90deg,
    rgba(229,54,55,0.95),
    rgba(229,54,55,0.00)
  );
  opacity: 0.9;
}

/* 타이틀 아래 설명 문장
   박스/보더 느낌 없이 가볍게 텍스트만 보이도록 정리 */
.news-page .news-subtitle{
  margin: var(--news-sub-gap) 0 0 !important;
  padding: 0 !important;

  display: block;
  max-width: 520px;

  background: none !important;
  border: 0 !important;
  border-radius: 0 !important;
  box-shadow: none !important;

  color: rgba(255,255,255,0.72);
  font-size: 14px;
  line-height: 1.55;
}

.news-page .news-subtitle::before,
.news-page .news-subtitle::after{
  content: none !important;
}

/* 모바일 타이틀/서브문장 크기 보정 */
@media (max-width: 991px){
  .news-page .product__page__title .section-title h4{
    font-size: 30px;
    padding-bottom: 10px !important;
  }
  .news-page .product__page__title .section-title h4::before{
    top: -16px;
    font-size: 10.5px;
  }
  .news-page .product__page__title .section-title h4::after{
    width: 48px;
  }
  .news-page .news-subtitle{
    font-size: 13px;
    max-width: 100%;
  }
}

/* =========================================================
   검색 영역 폭 흔들림 방지 (뉴스 페이지 전용)
   - 검색 상태일 때 '전체보기' 버튼이 생기고
   - 관리자일 때 '뉴스 작성' 버튼도 붙을 수 있어서
   검색 input 폭이 갑자기 줄어드는 현상을 데스크탑에서 고정폭 정책으로 완화
========================================================= */

/* 타이틀 row 세로 정렬만 보정(가운데 정렬) */
.news-page .product__page__title .row{
  align-items: center !important;
}

@media (min-width: 992px){
  /* 좌측(타이틀) / 우측(검색) 비율을 고정해 레이아웃 흔들림 감소 */
  .news-page .product__page__title > .row > .col-lg-8{
    flex: 0 0 55%;
    max-width: 55%;
  }
  .news-page .product__page__title > .row > .col-lg-4{
    flex: 0 0 45%;
    max-width: 45%;
  }

  /* 검색행: 한 줄 고정 + 우측 정렬 */
  .news-page .news-search-row{
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 10px;
    flex-wrap: nowrap;
  }

  /* 검색박스 자체 폭 정책 (최대/최소 동일하게 잡아 흔들림 방지) */
  .news-page .news-search-box{
    flex: 0 1 var(--news-search-max);
    width: var(--news-search-max);
    max-width: var(--news-search-max);
    min-width: var(--news-search-min);
  }

  /* input은 부모 박스 안에서 줄어들 수 있게 min-width 해제 */
  .news-page .news-search-box input[type='text']{
    min-width: 0;
  }

  /* 버튼 텍스트 줄바꿈 방지 */
  .news-page .news-reset-btn,
  .news-page .news-admin-btn{
    white-space: nowrap;
  }
}

/* 전체보기 버튼 hover 시 밑줄 생기는 템플릿 기본 a 스타일 방지 */
.news-page a.news-reset-btn:hover{
  text-decoration: none !important;
}

@media (max-width: 991px){
  /* 모바일에서는 자연스럽게 줄바꿈 허용 */
  .news-page .news-search-row{
    justify-content: flex-start;
    flex-wrap: wrap;
  }
  .news-page .news-search-box{
    flex: 1 1 100%;
    width: 100%;
    max-width: none;
    min-width: 0;
  }
}
</style>
</head>

<body>

<jsp:include page="/WEB-INF/common/header.jsp" />

<%-- 검색 여부 / 뉴스 개수
     아래에서 empty 체크를 계속 반복하지 않으려고 미리 boolean/숫자 형태로 꺼내둔다. --%>
<c:set var="isSearch" value="${not empty keyword}" />
<c:set var="nlen" value="${empty newsList ? 0 : newsList.size()}" />

<section class="product-page spad news-page">
  <div class="container">

    <div class="product__page__title">
      <div class="row align-items-end">
        <div class="col-lg-8">
          <div class="section-title">
            <h4>뉴스</h4>
          </div>
          <p class="news-subtitle">지금 뜨는 애니 뉴스, 빠르게 모아보기</p>
        </div>

        <div class="col-lg-4">
          <form action="${ctx}/newsList" method="get">
            <div class="news-search-row">

              <div class="news-search-box">
                <select name="condition">
                  <option value="NEWS_SEARCH_TITLE" <c:if test="${condition eq 'NEWS_SEARCH_TITLE'}">selected</c:if>>제목</option>
                  <option value="NEWS_SEARCH_CONTENT" <c:if test="${condition eq 'NEWS_SEARCH_CONTENT'}">selected</c:if>>내용</option>
                </select>

                <input type="text" name="keyword" value="<c:out value='${keyword}'/>" placeholder="검색어를 입력하세요">

                <button type="submit" class="news-search-btn" aria-label="검색">
                  <i class="fa fa-search"></i>
                </button>
              </div>

              <c:if test="${isSearch}">
                <a href="${ctx}/newsList" class="news-reset-btn">전체보기</a>
              </c:if>

              <c:if test="${not empty sessionScope.memberId and fn:toUpperCase(sessionScope.memberRole) eq 'ADMIN'}">
                <a href="${ctx}/newsWrite" class="news-admin-btn">뉴스 작성</a>
              </c:if>

            </div>
          </form>
        </div>
      </div>
    </div><!-- /.product__page__title -->

    <div class="news-card-area">

      <c:choose>
        <c:when test="${nlen == 0}">
          <div class="row">
            <div class="col-lg-12">
              <p style="color:#b7b7b7; text-align:center; padding:40px 0;">
                <c:choose>
                  <c:when test="${isSearch}">검색 결과가 없습니다.</c:when>
                  <c:otherwise>등록된 뉴스가 없습니다.</c:otherwise>
                </c:choose>
              </p>
            </div>
          </div>
        </c:when>

        <c:otherwise>
          <div class="row">

            <c:choose>
              <c:when test="${isSearch}">
                <%-- 검색 결과 레이아웃
                     검색 시에는 전부 작은 카드로 통일해서 정보 밀도를 높이고,
                     좌측 6개 / 우측 나머지로 나눠 보여준다. --%>

                <div class="col-lg-6">
                  <div class="row">
                    <c:forEach var="news" items="${newsList}" begin="0" end="${nlen-1}" varStatus="st">
                      <c:if test="${st.index < 6}">

                        <%-- 썸네일 경로 정규화
                             DB 값이 절대URL / ctx포함 / 루트상대 / 상대경로 중 어떤 형태로 와도
                             화면에서는 정상 출력되도록 한 번 정리한다.
                             썸네일이 비어 있으면 기본 이미지 사용. --%>
                        <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                        <c:choose>
                          <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                          <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                          <c:when test="${fn:startsWith(thumb,'/')}">
                            <c:set var="thumb" value="${ctx}${thumb}" />
                          </c:when>
                          <c:otherwise>
                            <c:set var="thumb" value="${ctx}/${thumb}" />
                          </c:otherwise>
                        </c:choose>

                        <%-- 뉴스 상세 URL 생성
                             c:url에는 ctx를 직접 붙이지 않고 매핑 경로(/newsDetail)만 넣는다.
                             이렇게 해야 컨텍스트 경로가 중복으로 붙는 문제를 막고,
                             page/condition/keyword 파라미터도 안전하게 이어갈 수 있다. --%>
                        <c:url var="detailUrl" value="/newsDetail">
                          <c:param name="newsId" value="${news.newsId}" />
                          <c:param name="page" value="${page}" />
                          <c:param name="condition" value="${condition}" />
                          <c:if test="${not empty keyword}">
                            <c:param name="keyword" value="${keyword}" />
                          </c:if>
                        </c:url>

                        <div class="col-lg-6 col-md-6 col-sm-6">
                          <a href="${detailUrl}" class="blog__item small__item set-bg" data-setbg="${thumb}">
                            <div class="blog__item__text">
                              <h4><c:out value="${news.newsTitle}" /></h4>
                            </div>
                          </a>
                        </div>

                      </c:if>
                    </c:forEach>
                  </div>
                </div>

                <div class="col-lg-6">
                  <div class="row">
                    <c:forEach var="news" items="${newsList}" begin="0" end="${nlen-1}" varStatus="st">
                      <c:if test="${st.index >= 6}">

                        <%-- 썸네일 경로 정규화(우측 컬럼도 동일 규칙 적용) --%>
                        <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                        <c:choose>
                          <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                          <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                          <c:when test="${fn:startsWith(thumb,'/')}">
                            <c:set var="thumb" value="${ctx}${thumb}" />
                          </c:when>
                          <c:otherwise>
                            <c:set var="thumb" value="${ctx}/${thumb}" />
                          </c:otherwise>
                        </c:choose>

                        <%-- 뉴스 상세 URL 생성(동일 규칙)
                             c:url + c:param으로 목록 상태(page/검색조건) 유지 --%>
                        <c:url var="detailUrl" value="/newsDetail">
                          <c:param name="newsId" value="${news.newsId}" />
                          <c:param name="page" value="${page}" />
                          <c:param name="condition" value="${condition}" />
                          <c:if test="${not empty keyword}">
                            <c:param name="keyword" value="${keyword}" />
                          </c:if>
                        </c:url>

                        <div class="col-lg-6 col-md-6 col-sm-6">
                          <a href="${detailUrl}" class="blog__item small__item set-bg" data-setbg="${thumb}">
                            <div class="blog__item__text">
                              <h4><c:out value="${news.newsTitle}" /></h4>
                            </div>
                          </a>
                        </div>

                      </c:if>
                    </c:forEach>
                  </div>
                </div>

              </c:when>

              <c:otherwise>
                <%-- 기본 목록 레이아웃(검색 아닐 때)
                     6개를 한 묶음으로 보고
                     (왼쪽 BIG + SMALL + SMALL) + (오른쪽 SMALL + SMALL + BIG)
                     패턴을 반복해서 카드 리듬감을 만든다. --%>

                <c:forEach var="base" begin="0" end="${nlen-1}" step="6">
                  <div class="col-lg-12">
                    <div class="row">

                      <div class="col-lg-6">
                        <div class="row">

                          <c:set var="idx" value="${base}" />
                          <c:if test="${idx < nlen}">
                            <c:set var="news" value="${newsList[idx]}" />

                            <%-- 1번 카드(좌측 BIG) 썸네일 경로 정규화 --%>
                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <%-- 상세 URL 생성
                                 c:url은 매핑 경로만 넣고, 현재 목록 상태(page/condition/keyword)를 함께 전달한다. --%>
                            <c:url var="detailUrl" value="/newsDetail">
                              <c:param name="newsId" value="${news.newsId}" />
                              <c:param name="page" value="${page}" />
                              <c:param name="condition" value="${condition}" />
                              <c:if test="${not empty keyword}">
                                <c:param name="keyword" value="${keyword}" />
                              </c:if>
                            </c:url>

                            <div class="col-lg-12">
                              <a href="${detailUrl}" class="blog__item set-bg" data-setbg="${thumb}">
                                <div class="blog__item__text">
                                  <h4><c:out value="${news.newsTitle}" /></h4>
                                </div>
                              </a>
                            </div>
                          </c:if>

                          <c:set var="idx" value="${base + 1}" />
                          <c:if test="${idx < nlen}">
                            <c:set var="news" value="${newsList[idx]}" />

                            <%-- 2번 카드(좌측 SMALL) 썸네일 경로 정규화 --%>
                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <%-- 상세 URL 생성(동일 규칙) --%>
                            <c:url var="detailUrl" value="/newsDetail">
                              <c:param name="newsId" value="${news.newsId}" />
                              <c:param name="page" value="${page}" />
                              <c:param name="condition" value="${condition}" />
                              <c:if test="${not empty keyword}">
                                <c:param name="keyword" value="${keyword}" />
                              </c:if>
                            </c:url>

                            <div class="col-lg-6 col-md-6 col-sm-6">
                              <a href="${detailUrl}" class="blog__item small__item set-bg" data-setbg="${thumb}">
                                <div class="blog__item__text">
                                  <h4><c:out value="${news.newsTitle}" /></h4>
                                </div>
                              </a>
                            </div>
                          </c:if>

                          <c:set var="idx" value="${base + 2}" />
                          <c:if test="${idx < nlen}">
                            <c:set var="news" value="${newsList[idx]}" />

                            <%-- 3번 카드(좌측 SMALL) 썸네일 경로 정규화 --%>
                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <%-- 상세 URL 생성(동일 규칙) --%>
                            <c:url var="detailUrl" value="/newsDetail">
                              <c:param name="newsId" value="${news.newsId}" />
                              <c:param name="page" value="${page}" />
                              <c:param name="condition" value="${condition}" />
                              <c:if test="${not empty keyword}">
                                <c:param name="keyword" value="${keyword}" />
                              </c:if>
                            </c:url>

                            <div class="col-lg-6 col-md-6 col-sm-6">
                              <a href="${detailUrl}" class="blog__item small__item set-bg" data-setbg="${thumb}">
                                <div class="blog__item__text">
                                  <h4><c:out value="${news.newsTitle}" /></h4>
                                </div>
                              </a>
                            </div>
                          </c:if>

                        </div>
                      </div>

                      <div class="col-lg-6">
                        <div class="row">

                          <c:set var="idx" value="${base + 3}" />
                          <c:if test="${idx < nlen}">
                            <c:set var="news" value="${newsList[idx]}" />

                            <%-- 4번 카드(우측 SMALL) 썸네일 경로 정규화 --%>
                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <%-- 상세 URL 생성(동일 규칙) --%>
                            <c:url var="detailUrl" value="/newsDetail">
                              <c:param name="newsId" value="${news.newsId}" />
                              <c:param name="page" value="${page}" />
                              <c:param name="condition" value="${condition}" />
                              <c:if test="${not empty keyword}">
                                <c:param name="keyword" value="${keyword}" />
                              </c:if>
                            </c:url>

                            <div class="col-lg-6 col-md-6 col-sm-6">
                              <a href="${detailUrl}" class="blog__item small__item set-bg" data-setbg="${thumb}">
                                <div class="blog__item__text">
                                  <h4><c:out value="${news.newsTitle}" /></h4>
                                </div>
                              </a>
                            </div>
                          </c:if>

                          <c:set var="idx" value="${base + 4}" />
                          <c:if test="${idx < nlen}">
                            <c:set var="news" value="${newsList[idx]}" />

                            <%-- 5번 카드(우측 SMALL) 썸네일 경로 정규화 --%>
                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <%-- 상세 URL 생성(동일 규칙) --%>
                            <c:url var="detailUrl" value="/newsDetail">
                              <c:param name="newsId" value="${news.newsId}" />
                              <c:param name="page" value="${page}" />
                              <c:param name="condition" value="${condition}" />
                              <c:if test="${not empty keyword}">
                                <c:param name="keyword" value="${keyword}" />
                              </c:if>
                            </c:url>

                            <div class="col-lg-6 col-md-6 col-sm-6">
                              <a href="${detailUrl}" class="blog__item small__item set-bg" data-setbg="${thumb}">
                                <div class="blog__item__text">
                                  <h4><c:out value="${news.newsTitle}" /></h4>
                                </div>
                              </a>
                            </div>
                          </c:if>

                          <c:set var="idx" value="${base + 5}" />
                          <c:if test="${idx < nlen}">
                            <c:set var="news" value="${newsList[idx]}" />

                            <%-- 6번 카드(우측 BIG) 썸네일 경로 정규화 --%>
                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <%-- 상세 URL 생성(동일 규칙) --%>
                            <c:url var="detailUrl" value="/newsDetail">
                              <c:param name="newsId" value="${news.newsId}" />
                              <c:param name="page" value="${page}" />
                              <c:param name="condition" value="${condition}" />
                              <c:if test="${not empty keyword}">
                                <c:param name="keyword" value="${keyword}" />
                              </c:if>
                            </c:url>

                            <div class="col-lg-12">
                              <a href="${detailUrl}" class="blog__item set-bg" data-setbg="${thumb}">
                                <div class="blog__item__text">
                                  <h4><c:out value="${news.newsTitle}" /></h4>
                                </div>
                              </a>
                            </div>
                          </c:if>

                        </div>
                      </div>

                    </div>
                  </div>
                </c:forEach>

              </c:otherwise>
            </c:choose>

            <!-- pagination -->
            <div class="col-lg-12">
              <div class="product__pagination">

                <c:if test="${hasPrev}">
                  <%-- 이전 페이지 묶음 이동 URL
                       c:url에는 매핑 경로만 넣고, condition/keyword를 그대로 이어서
                       검색 중 페이지 이동 시 검색 상태가 유지되게 한다. --%>
                  <c:url var="prevUrl" value="/newsList">
                    <c:param name="page" value="${startPage - 1}" />
                    <c:param name="condition" value="${condition}" />
                    <c:if test="${not empty keyword}">
                      <c:param name="keyword" value="${keyword}" />
                    </c:if>
                  </c:url>
                  <a href="${prevUrl}"><i class="fa fa-angle-double-left"></i></a>
                </c:if>

                <c:forEach var="p" begin="${startPage}" end="${endPage}">
                  <%-- 개별 페이지 번호 URL
                       현재 condition/keyword를 함께 전달해서 페이지 번호 클릭 후에도 목록 상태 유지 --%>
                  <c:url var="pageUrl" value="/newsList">
                    <c:param name="page" value="${p}" />
                    <c:param name="condition" value="${condition}" />
                    <c:if test="${not empty keyword}">
                      <c:param name="keyword" value="${keyword}" />
                    </c:if>
                  </c:url>
                  <a href="${pageUrl}" class="${p == page ? 'current-page' : ''}">${p}</a>
                </c:forEach>

                <c:if test="${hasNext}">
                  <%-- 다음 페이지 묶음 이동 URL (검색 조건 유지) --%>
                  <c:url var="nextUrl" value="/newsList">
                    <c:param name="page" value="${endPage + 1}" />
                    <c:param name="condition" value="${condition}" />
                    <c:if test="${not empty keyword}">
                      <c:param name="keyword" value="${keyword}" />
                    </c:if>
                  </c:url>
                  <a href="${nextUrl}"><i class="fa fa-angle-double-right"></i></a>
                </c:if>

              </div>
            </div>

          </div><!-- /.row -->
        </c:otherwise>
      </c:choose>

    </div><!-- /.news-card-area -->

  </div><!-- /.container -->
</section>

<%@ include file="/WEB-INF/common/footer.jsp" %>

<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
<script src="${ctx}/js/bootstrap.min.js"></script>
<script src="${ctx}/js/player.js"></script>
<script src="${ctx}/js/jquery.nice-select.min.js"></script>
<script src="${ctx}/js/mixitup.min.js"></script>
<script src="${ctx}/js/jquery.slicknav.js"></script>
<script src="${ctx}/js/owl.carousel.min.js"></script>
<script src="${ctx}/js/main.js"></script>

</body>
</html>