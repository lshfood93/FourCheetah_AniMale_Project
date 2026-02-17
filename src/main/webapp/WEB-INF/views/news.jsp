<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 뉴스</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<!-- 템플릿 CSS -->
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
   NEWS Page (커스텀) - FINAL
   - scope: .news-page
   - 카드/타이틀은 뉴스 전용
   - 검색바 룩앤필은 공용 CSS 유지
   - 단, 뉴스 페이지에서만 '폭 흔들림' 방지
========================================================= */

/* =========================
   quick tweak (여기만 만지면 됨)
========================= */
.news-page{
  --news-title-size: 28px;     /* '뉴스' 글자 크기 */
  --news-sub-gap: 6px;         /* '뉴스'와 서브문장 간격 */
  --news-underline-w: 50px;    /* 언더라인 길이 */
  --news-underline-h: 2px;     /* 언더라인 두께 */

  --news-search-max: 320px;    /* 검색박스 목표 폭(데스크탑) */
  --news-search-min: 320px;    /* 버튼 생겨도 이 정도는 유지(너무 짧아지는 것 방지) */
}

/* 카드 영역만 거터 통일(타이틀 row에는 영향 X) */
.news-page .news-card-area .row{ margin-left:-6px; margin-right:-6px; }
.news-page .news-card-area [class*='col-']{ padding-left:6px; padding-right:6px; }

/* -------------------------
   Cards
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

.news-page .blog__item::before{
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(11, 12, 42, 0.10);
  z-index: 1;
  pointer-events: none;
}
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

.news-page .blog__item:hover{
  transform: translateY(-3px);
  box-shadow:
    inset 0 0 0 1px rgba(229,54,55,0.22),
    0 18px 42px rgba(0,0,0,0.38);
}
.news-page .blog__item:hover::before{
  background: rgba(11, 12, 42, 0.40);
}

/* 카드 텍스트 오버레이 */
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

/* 카드 내 NEWS 배지 */
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
   Pagination
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
   NEWS 타이틀 섹션 (미니멀)
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

/* 모바일 타이틀 */
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
   검색 길이 흔들림 FIX (뉴스 페이지만)
   핵심:
   1) 데스크탑에서 우측 컬럼(col-lg-4)을 조금 넓혀서 공간 확보
   2) 검색박스는 목표 폭(max)까지는 고정적으로 보이게
   3) 버튼이 생기면 검색박스만 '적당히' 수축(너무 짧아지지 않게 min)
========================================================= */

/* 타이틀 row 세로 정렬은 가운데 */
.news-page .product__page__title .row{
  align-items: center !important;
}

@media (min-width: 992px){
  /* (중요) 뉴스만 부트스트랩 컬럼 비율 재조정: 검색 영역 폭 확보 */
  .news-page .product__page__title > .row > .col-lg-8{
    flex: 0 0 55%;
    max-width: 55%;
  }
  .news-page .product__page__title > .row > .col-lg-4{
    flex: 0 0 45%;
    max-width: 45%;
  }

  .news-page .news-search-row{
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 10px;
    flex-wrap: nowrap;
  }

  /* 검색박스: 평소엔 --news-search-max 정도로 유지, 버튼 생기면 --news-search-min까지 수축 */
  .news-page .news-search-box{
    flex: 0 1 var(--news-search-max);
    width: var(--news-search-max);
    max-width: var(--news-search-max);
    min-width: var(--news-search-min);
  }

  /* 공용에서 input min-width 때문에 수축이 막히는 경우가 있어 뉴스만 해제 */
  .news-page .news-search-box input[type='text']{
    min-width: 0;
  }

  .news-page .news-reset-btn,
  .news-page .news-admin-btn{
    white-space: nowrap;
  }
}

.news-page a.news-reset-btn:hover{
  text-decoration: none !important;
}

/* 모바일은 공용 CSS 흐름 유지: 자연스럽게 줄바꿈 허용 */
@media (max-width: 991px){
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

<c:set var="isSearch" value="${not empty keyword}" />
<c:set var="nlen" value="${empty newsList ? 0 : newsList.size()}" />

<!-- ✅ 애니리스트처럼 product-page + spad 구조로 상단 여백 확보 -->
<section class="product-page spad news-page">
  <div class="container">

    <!-- 제목 + 우측 검색/버튼 (애니리스트 구조 따라감) -->
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

    <!-- 카드 리스트 -->
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
                <%-- 검색 결과: 작은 카드만 (좌 6 / 우 나머지) --%>

                <div class="col-lg-6">
                  <div class="row">
                    <c:forEach var="news" items="${newsList}" begin="0" end="${nlen-1}" varStatus="st">
                      <c:if test="${st.index < 6}">

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

                        <c:url var="detailUrl" value="${ctx}/newsDetail">
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

                        <c:url var="detailUrl" value="${ctx}/newsDetail">
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
                <%-- 기본 목록: (왼쪽 BIG+SMALL+SMALL) + (오른쪽 SMALL+SMALL+BIG) 6개 단위 반복 --%>

                <c:forEach var="base" begin="0" end="${nlen-1}" step="6">
                  <div class="col-lg-12">
                    <div class="row">

                      <div class="col-lg-6">
                        <div class="row">

                          <c:set var="idx" value="${base}" />
                          <c:if test="${idx < nlen}">
                            <c:set var="news" value="${newsList[idx]}" />

                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <c:url var="detailUrl" value="${ctx}/newsDetail">
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

                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <c:url var="detailUrl" value="${ctx}/newsDetail">
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

                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <c:url var="detailUrl" value="${ctx}/newsDetail">
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

                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <c:url var="detailUrl" value="${ctx}/newsDetail">
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

                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <c:url var="detailUrl" value="${ctx}/newsDetail">
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

                            <c:set var="thumb" value="${empty news.newsThumbnailUrl ? '/img/normal-breadcrumb.jpg' : news.newsThumbnailUrl}" />
                            <c:choose>
                              <c:when test="${fn:startsWith(thumb,'http')}"></c:when>
                              <c:when test="${fn:startsWith(thumb, ctx)}"></c:when>
                              <c:when test="${fn:startsWith(thumb,'/')}"><c:set var="thumb" value="${ctx}${thumb}" /></c:when>
                              <c:otherwise><c:set var="thumb" value="${ctx}/${thumb}" /></c:otherwise>
                            </c:choose>

                            <c:url var="detailUrl" value="${ctx}/newsDetail">
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
                  <c:url var="prevUrl" value="${ctx}/newsList">
                    <c:param name="page" value="${startPage - 1}" />
                    <c:param name="condition" value="${condition}" />
                    <c:if test="${not empty keyword}">
                      <c:param name="keyword" value="${keyword}" />
                    </c:if>
                  </c:url>
                  <a href="${prevUrl}"><i class="fa fa-angle-double-left"></i></a>
                </c:if>

                <c:forEach var="p" begin="${startPage}" end="${endPage}">
                  <c:url var="pageUrl" value="${ctx}/newsList">
                    <c:param name="page" value="${p}" />
                    <c:param name="condition" value="${condition}" />
                    <c:if test="${not empty keyword}">
                      <c:param name="keyword" value="${keyword}" />
                    </c:if>
                  </c:url>
                  <a href="${pageUrl}" class="${p == page ? 'current-page' : ''}">${p}</a>
                </c:forEach>

                <c:if test="${hasNext}">
                  <c:url var="nextUrl" value="${ctx}/newsList">
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

<!-- set-bg 동작 필수 -->
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
