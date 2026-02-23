<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%-- 공통 컨텍스트 경로
     정적 리소스(css/js/img), 링크, form action 경로를 한 기준으로 맞추기 위한 값.
     프로젝트 경로가 바뀌어도 여기 ctx 기준으로 쓰면 상대경로 깨짐을 줄일 수 있다. --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="ie=edge">
<title>ANIMale | 뉴스 상세</title>

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link
	href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap"
	rel="stylesheet">
<link
	href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap"
	rel="stylesheet">

<!-- 상대경로 대신 ctx 기준으로 불러와서 상세/목록/하위경로 진입 시 CSS 경로 깨짐 방지 -->
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/plyr.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/owl.carousel.min.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/slicknav.min.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* News Detail */

.blog-details.spad{
  background: radial-gradient(1200px 520px at 30% 10%, rgba(70,90,255,.08), rgba(0,0,0,0)),
              radial-gradient(900px 420px at 85% 0%, rgba(180,120,255,.06), rgba(0,0,0,0));
}

.news-wrap { margin-top: 6px; }

.news-article{
  position: relative;
  border-radius: 22px;

  /* 상세 카드 기본 톤(반투명 + 글래스 느낌)
     별도 박스를 많이 겹치지 않고 본문 전체를 하나의 카드로 보이게 맞춘다. */
  background: rgba(255,255,255,0.035);
  border: 1px solid rgba(255,255,255,0.10);
  backdrop-filter: blur(18px) saturate(120%);
  -webkit-backdrop-filter: blur(18px) saturate(140%);
  box-shadow: 0 18px 60px rgba(0,0,0,0.45);

  overflow: hidden;
}

/* 카드 상단 대각 광택 효과
   pseudo 요소로 처리해서 실제 컨텐츠 레이아웃에는 영향 없이 분위기만 추가 */
.news-article::before{
  content:"";
  position:absolute;
  top:-55%;
  left:-35%;
  width:70%;
  height:110%;
  transform: rotate(18deg);
  background: radial-gradient(circle at 28% 28%,
    rgba(255,255,255,0.22),
    rgba(255,255,255,0.00) 62%);
  pointer-events:none;
  opacity:.28;
  filter: blur(4px);
  z-index:0;
}

/* 카드 외곽 보더를 단색 대신 그라데이션으로 표현
   실제 border를 쓰는 대신 마스크 기법으로 내부 컨텐츠 영역과 분리 */
.news-article::after{
  content:"";
  position:absolute;
  inset:0;
  border-radius: 22px;
  padding: 1px;
  background: linear-gradient(135deg,
    rgba(255,255,255,0.35),
    rgba(255,255,255,0.08),
    rgba(120,190,255,0.18),
    rgba(255,255,255,0.10)
  );
  -webkit-mask:
    linear-gradient(#000 0 0) content-box,
    linear-gradient(#000 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  pointer-events:none;
  opacity:.65;
  z-index:0;
}

/* 카드 내부 실제 내용은 pseudo 장식보다 위 레이어에 오도록 고정 */
.news-article > *{
  position: relative;
  z-index: 1;
}

/* 상단 바(목록/수정/삭제 버튼 영역)
   sticky로 두어 긴 본문에서도 주요 액션 접근성을 유지 */
.news-topbar{
  padding: 14px 16px;
  display:flex;
  justify-content:space-between;
  align-items:center;
  gap:12px;

  border-bottom: 1px solid rgba(255,255,255,.10);
  background: rgba(255,255,255,.03);
  backdrop-filter: blur(12px) saturate(120%);
  -webkit-backdrop-filter: blur(12px) saturate(140%);

  position: sticky;
  top: var(--news-sticky-top, 0px);
  z-index: 50;
}

.news-crumb{
  display:flex;
  align-items:center;
  gap:8px;
  font-size:14px;
  font-weight: 500;
  letter-spacing: .2px;
  color: rgba(255,255,255,.75);
}
.news-crumb a{
  color: rgba(255,255,255,.90);
  text-decoration:none;
}
.news-crumb a:hover{ color:#fff; }

.news-topbar-actions{
  display:flex;
  align-items:center;
  justify-content:flex-end;
  gap:10px;
  flex-wrap:wrap;
}

/* 공통 pill 버튼 톤
   링크(a)와 button을 같은 스타일로 맞추기 위해 클래스 기반으로 통일 */
.pill-btn{
  display:inline-flex;
  align-items:center;
  justify-content:center;
  gap:8px;
  padding: 10px 16px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 800;
  letter-spacing: -0.01em;
  line-height: 1;
  cursor:pointer;
  white-space: nowrap;
  user-select: none;
  text-decoration: none !important;

  border: 1px solid rgba(255,255,255,0.13);
  background: rgba(255,255,255,0.06);
  color:#fff !important;

  backdrop-filter: blur(12px) saturate(140%);
  -webkit-backdrop-filter: blur(12px) saturate(140%);

  transition: transform .18s ease, box-shadow .18s ease,
              background .18s ease, border-color .18s ease, opacity .18s ease;
}
.pill-btn:hover{
  transform: translateY(-1px);
  box-shadow: 0 12px 28px rgba(0,0,0,0.35);
  border-color: rgba(255,255,255,0.26);
  background: rgba(255,255,255,0.12);
}
.pill-btn:active{
  transform: translateY(0);
  box-shadow:none;
}
.pill-btn:focus-visible{
  outline: none;
  box-shadow: 0 0 0 3px rgba(140,200,255,0.35);
}

/* 삭제 버튼만 위험 액션으로 눈에 띄게 분리 */
.pill-btn--danger{
  background: linear-gradient(135deg,
    rgba(255,90,120,0.35),
    rgba(255,255,255,0.06));
  border-color: rgba(255,90,120,0.35);
}
.pill-btn--danger:hover{
  background: linear-gradient(135deg,
    rgba(255,90,120,0.55),
    rgba(255,255,255,0.10));
  border-color: rgba(255,90,120,0.70);
}

.inline-form{ display:inline; margin:0; }

/* 링크 버튼(a) 상태별 색상 강제 고정
   템플릿 기본 a:hover/a:visited 색이 먹어서 파란색으로 바뀌는 문제 방지 */
.news-topbar-actions .pill-btn,
.news-topbar-actions .pill-btn:visited,
.news-topbar-actions .pill-btn:hover,
.news-topbar-actions .pill-btn:focus,
.news-topbar-actions .pill-btn:active{
  color:#fff !important;
  text-decoration:none !important;
}
.news-topbar-actions .pill-btn i{ color: inherit !important; }

/* 커버(썸네일 히어로 영역)
   background-image로 깔고, 텍스트는 오버레이 레이어 위에 배치 */
.news-cover{
  position: relative;
  min-height: 360px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  isolation: isolate;
}
@media (max-width: 991px){
  .news-cover{ min-height: 290px; }
}

/* 커버 오버레이
   이미지 위에 텍스트 대비를 확보하기 위한 밝기/그라데이션 레이어 */
.news-cover::before{
  content:"";
  position:absolute;
  inset:0;
  background:
    radial-gradient(1100px 420px at 20% 10%, rgba(255,255,255,.10), rgba(0,0,0,0)),
    linear-gradient(180deg, rgba(0,0,0,.10), rgba(0,0,0,.78));
  z-index:0;
}
.news-cover::after{
  content:"";
  position:absolute;
  left:0; right:0; bottom:0;
  height:65%;
  background: linear-gradient(180deg, rgba(0,0,0,0), rgba(0,0,0,.78));
  z-index:0;
}

.news-cover__content{
  position:absolute;
  left:18px; right:18px; bottom:18px;
  z-index:1;
  display:flex;
  flex-direction:column;
  gap:8px;
  max-width:980px;
}
.news-cover__meta{
  font-size:13px;
  color: rgba(255,255,255,.80);
  letter-spacing:.2px;
}
.news-cover__title{
  margin:0;
  font-size:36px;
  line-height:1.18;
  color:#fff;
  font-weight:900;
  text-shadow: 0 10px 24px rgba(0,0,0,.45);
}
@media (max-width: 991px){
  .news-cover__title{ font-size: 26px; }
}

/* 본문 영역 배경
   본문 자체는 CKEditor HTML을 그대로 출력하되, 바깥 패널에서 톤만 잡아준다. */
.news-body{
  padding: 34px 18px 44px;
  background: linear-gradient(
    180deg,
    rgba(255,255,255,0.075),
    rgba(255,255,255,0.045)
  );
}

@media (max-width: 991px){
  .news-body{ padding: 26px 14px 34px; }
}

#newsContent.news-prose{
  padding: 0 10px;
  max-width: 920px;
  margin: 0 auto;

  /* 내부 카드 제거: 에디터에서 들어온 HTML 자체를 자연스럽게 보이게 */
  padding: 0;
  border: 0;
  background: transparent;
  box-shadow: none;
  border-radius: 0;

  color: rgba(255,255,255,.92);
  font-size: 15.5px;
  line-height: 2.05;
  overflow-wrap: anywhere;
}

#newsContent.news-prose p,
#newsContent.news-prose p *{
  color: rgba(255,255,255,.92) !important;
}

/* 템플릿/에디터 기본 text-shadow가 남아 글자 번져보이는 현상 방지 */
#newsContent.news-prose,
#newsContent.news-prose *{
  text-shadow: none !important;
}

@media (max-width: 991px){
  #newsContent.news-prose{
    font-size: 15px;
    line-height: 2.0;
  }
}

/* 첫 문단은 리드 문단처럼 조금 더 강조해서 읽기 시작점 명확하게 */
#newsContent.news-prose p:first-of-type{
  font-size: 16.5px;
  line-height: 2.1;
  color: rgba(255,255,255,.95) !important;
}

#newsContent.news-prose p{ margin: 0 0 16px; }
#newsContent.news-prose p:last-child{
  margin-bottom: 10px !important;
}

/* 제목 계층 */
#newsContent.news-prose h1,
#newsContent.news-prose h2,
#newsContent.news-prose h3{
  margin: 24px 0 12px;
  color:#fff;
  font-weight: 900;
  line-height: 1.25;
}
#newsContent.news-prose h4,
#newsContent.news-prose h5,
#newsContent.news-prose h6{
  margin: 18px 0 10px;
  color: rgba(255,255,255,.95);
  font-weight: 800;
}

/* 구분선 */
#newsContent.news-prose hr{
  border:none;
  height:1px;
  margin: 22px 0;
  background: linear-gradient(90deg,
    rgba(255,255,255,0),
    rgba(255,255,255,.16),
    rgba(255,255,255,0)
  );
}

/* 링크 */
#newsContent.news-prose a{
  color:#fff;
  text-decoration: underline;
  text-underline-offset: 3px;
}
#newsContent.news-prose a:hover{ opacity:.9; }

/* 인용문 */
#newsContent.news-prose blockquote{
  margin: 18px 0;
  padding: 12px 14px;
  border-radius: 12px;
  border-left: 3px solid rgba(255,255,255,.22);
  background: rgba(255,255,255,.05);
  color: rgba(255,255,255,.92);
}

/* 목록 */
#newsContent.news-prose ul,
#newsContent.news-prose ol{ margin: 10px 0 16px 22px; }
#newsContent.news-prose li{
  margin: 6px 0;
  color: rgba(255,255,255,.92);
}

/* code/pre */
#newsContent.news-prose code{
  padding: 2px 6px;
  border-radius: 8px;
  background: rgba(0,0,0,.22);
  font-size: .95em;
}
#newsContent.news-prose pre{
  margin: 16px 0;
  padding: 14px 14px;
  border-radius: 14px;
  background: rgba(0,0,0,.25);
  overflow:auto;
}

/* CKEditor 이미지/figure 기본 스타일 보정
   뉴스 본문에서는 이미지를 깔끔하게 보여주기 위해 라운드/그림자 제거 */
#newsContent.news-prose img{
  max-width: 100%;
  height: auto;
  display: block;
  margin: 18px auto;

  border: 0;
  box-shadow: none;
  background: transparent;

  /* 직각으로 통일 */
  border-radius: 0 !important;

  cursor: zoom-in;
}

#newsContent.news-prose figure{
  margin: 18px 0;
  padding: 0;
  border: 0;
  background: transparent;
}
#newsContent.news-prose figure.image{ padding:0; border:0; background:transparent; }

#newsContent.news-prose figure.image figcaption{
  margin-top: 10px;
  font-size: 12px;
  line-height: 1.6;
  color: rgba(255,255,255,.72);
  text-align: center;
  opacity: .95;
}

/* CKEditor 정렬 클래스 대응
   에디터에서 좌/우/중앙 정렬된 이미지를 상세 페이지에서도 의도대로 보여주기 */
#newsContent.news-prose figure.image.image-style-align-left{
  float:left;
  max-width:46%;
  margin: 8px 16px 12px 0;
}
#newsContent.news-prose figure.image.image-style-align-right{
  float:right;
  max-width:46%;
  margin: 8px 0 12px 16px;
}
#newsContent.news-prose figure.image.image-style-align-center{
  margin-left:auto;
  margin-right:auto;
  max-width:92%;
}

/* float 이미지 뒤 본문 흐름 정리 */
#newsContent.news-prose::after{
  content:"";
  display:block;
  clear:both;
}
@media (max-width: 991px){
  #newsContent.news-prose figure.image.image-style-align-left,
  #newsContent.news-prose figure.image.image-style-align-right{
    float:none;
    max-width:100%;
    margin: 14px 0;
  }
}

/* 테이블 스타일 */
#newsContent.news-prose table{
  width:100%;
  border-collapse: collapse;
  margin: 16px 0;
  overflow: hidden;
  border-radius: 12px;
  border: 1px solid rgba(255,255,255,.10);
  background: rgba(0,0,0,.10);
}
#newsContent.news-prose th,
#newsContent.news-prose td{
  padding: 10px 12px;
  border-bottom: 1px solid rgba(255,255,255,.08);
}
#newsContent.news-prose th{
  background: rgba(255,255,255,.06);
  color: rgba(255,255,255,.92);
}

/* 관련 애니 영역
   본문과 분리되지만 전체 카드 톤은 유지하도록 하단 섹션처럼 처리 */
.news-related{
  padding: 16px;
  border-top: 1px solid rgba(255,255,255,.10);
  background: rgba(255,255,255,.04);
  backdrop-filter: blur(12px) saturate(140%);
  -webkit-backdrop-filter: blur(12px) saturate(140%);
}

.related-anime-box{
  padding: 14px;
  border-radius: 16px;
  border: 1px solid rgba(255,255,255,.10);
  background: rgba(0,0,0,.20);
}

.news-related .meta{
  color: rgba(255,255,255,.75) !important;
  font-size: 12px;
}

/* 읽기 진행바
   긴 뉴스에서 현재 읽은 위치를 시각적으로 보여주기 위한 상단 고정 바 */
.reading-progress{
  position: fixed;
  left: 0;
  right: 0;
  top: var(--news-sticky-top, 0px);
  height: 3px;
  z-index: 9999;
  pointer-events: none;
}
.reading-progress__bar{
  height: 100%;
  width: 100%;
  transform-origin: 0 50%;
  transform: scaleX(0);
  background: rgba(255,255,255,.72);
  box-shadow: 0 6px 16px rgba(0,0,0,.25);
}
@media (prefers-reduced-motion: reduce){
  .pill-btn{ transition: none; }
}

/* 이미지 라이트박스
   본문 이미지를 클릭했을 때 원본 확인용 오버레이 */
.img-lightbox{
  position: fixed;
  inset: 0;
  z-index: 10000;
  display: none;
  align-items: center;
  justify-content: center;
  padding: 18px;
  background: rgba(0,0,0,.72);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}
.img-lightbox.is-open{ display: flex; }

.img-lightbox__panel{
  max-width: min(980px, 92vw);
  max-height: 86vh;
  width: 100%;
  display: grid;
  gap: 10px;
}
.img-lightbox__img{
  width: 100%;
  max-height: 78vh;
  object-fit: contain;

  /* 라이트박스에서도 직각 스타일 유지 */
  border-radius: 0 !important;

  background: rgba(0,0,0,.20);
}
.img-lightbox__cap{
  font-size: 12px;
  line-height: 1.6;
  color: rgba(255,255,255,.78);
  text-align: center;
}
.img-lightbox__close{
  position: absolute;
  top: calc(var(--news-sticky-top, 0px) + 10px);
  right: 12px;
  border: 1px solid rgba(255,255,255,.18);
  background: rgba(0,0,0,.35);
  color: #fff;
  border-radius: 999px;
  padding: 8px 12px;
  cursor: pointer;
}
.img-lightbox__close:hover{
  background: rgba(255,255,255,.10);
  border-color: rgba(255,255,255,.28);
}
</style>

</head>

<body>
	<div id="preloder">
		<div class="loader"></div>
	</div>

<%@ include file="/WEB-INF/common/header.jsp" %>

	<section class="blog-details spad">
		<div class="container news-wrap">
			<div class="row d-flex justify-content-center">
				<div class="col-lg-10">

					<%-- 목록 복귀 URL 구성용 파라미터 복원
					     상세 진입 경로에 따라 param 또는 requestScope에 값이 있을 수 있어서 둘 다 대응한다.
					     이렇게 해두면 목록으로 돌아갈 때 페이지/검색조건이 유지된다. --%>
					<c:set var="pageVal" value="${not empty param.page ? param.page : requestScope.page}" />
					<c:set var="conditionVal" value="${not empty param.condition ? param.condition : requestScope.condition}" />
					<c:set var="keywordVal" value="${not empty param.keyword ? param.keyword : requestScope.keyword}" />

					<%-- 목록 복귀 URL 생성
					     c:url + c:param 조합으로 만들면 컨텍스트 경로/URL 인코딩을 JSTL이 맡아줘서 안전하다. --%>
					<c:url var="backUrl" value="/newsList">
						<c:if test="${not empty pageVal}">
							<c:param name="page" value="${pageVal}" />
						</c:if>
						<c:if test="${not empty conditionVal}">
							<c:param name="condition" value="${conditionVal}" />
						</c:if>
						<c:if test="${not empty keywordVal}">
							<c:param name="keyword" value="${keywordVal}" />
						</c:if>
					</c:url>

					<%-- 뉴스 썸네일 URL 정규화
					     DB 저장값 형태가 여러 가지일 수 있어서(절대URL / ctx포함 / 루트상대 / 상대경로)
					     화면 출력 전에 한 번 정리해둔다.
					     커버 영역은 이 썸네일을 그대로 사용한다. --%>
					<c:set var="thumbRaw" value="${newsData.newsThumbnailUrl}" />
					<c:set var="thumbSrc" value="${thumbRaw}" />
					<c:if test="${not empty thumbRaw}">
						<c:choose>
							<c:when test="${fn:startsWith(thumbRaw,'http')}">
								<c:set var="thumbSrc" value="${thumbRaw}" />
							</c:when>

							<%-- DB값이 이미 /ANIMale/... 같은 ctx 포함 경로면 그대로 사용 --%>
							<c:when test="${fn:startsWith(thumbRaw, ctx)}">
								<c:set var="thumbSrc" value="${thumbRaw}" />
							</c:when>

							<c:when test="${fn:startsWith(thumbRaw,'/')}">
								<c:set var="thumbSrc" value="${ctx}${thumbRaw}" />
							</c:when>

							<c:otherwise>
								<c:set var="thumbSrc" value="${ctx}/${thumbRaw}" />
							</c:otherwise>
						</c:choose>
					</c:if>

					<%-- 커버 이미지는 뉴스 썸네일 기준으로 고정 --%>
					<c:set var="coverSrc" value="${thumbSrc}" />

					<div class="news-article">

						<!-- 상단 액션 바 (목록 / 관리자 수정·삭제) -->
						<div class="news-topbar">
							<div class="news-crumb">
								<a href="${backUrl}">NEWS</a>
								<span style="opacity: .6;">›</span>
								<span>DETAIL</span>
							</div>

							<div class="news-topbar-actions">
								<a class="pill-btn" href="${backUrl}">
									<i class="fa fa-list"></i> 뉴스 전체 목록
								</a>

								<c:if test="${sessionScope.memberRole eq 'ADMIN'}">
									<form action="${ctx}/newsEdit" method="get" class="inline-form">
										<input type="hidden" name="newsId" value="${newsData.newsId}">
										<input type="hidden" name="type" value="NEWS">
										<button type="submit" class="pill-btn">
											<i class="fa fa-pencil"></i> 수정
										</button>
									</form>

									<form id="deleteForm" action="${ctx}/newsDelete" method="post" class="inline-form">
										<input type="hidden" name="newsId" value="${newsData.newsId}">
										<input type="hidden" name="type" value="NEWS">
										<button type="button" class="pill-btn pill-btn--danger" onclick="confirmDelete();">
											<i class="fa fa-trash"></i> 삭제
										</button>
									</form>
								</c:if>
							</div>
						</div>

						<!-- 커버 히어로 영역 (배경=썸네일, 제목/메타 오버레이) -->
						<div class="news-cover"
							style="<c:if test='${not empty coverSrc}'>background-image:url('<c:out value='${coverSrc}'/>');</c:if>">
							<div class="news-cover__content">
								<div class="news-cover__meta">News - No.${newsData.newsId}</div>
								<h1 class="news-cover__title"><c:out value="${newsData.newsTitle}" /></h1>
							</div>
						</div>

						<!-- 본문 영역
						     newsContent는 CKEditor HTML을 그대로 출력(escapeXml=false)하고,
						     CSS/JS에서 표시 스타일/이미지 보정/라이트박스 기능을 붙인다. -->
						<div class="news-body">
							<div id="newsContent" class="news-prose" data-cover="<c:out value='${coverSrc}'/>">
								<c:out value="${newsData.newsContent}" escapeXml="false" />
							</div>
						</div>

						<!-- 관련 애니 섹션 -->
						<div class="news-related">
							<c:choose>
								<c:when test="${not empty newsData.animeId and newsData.animeId > 0}">
									<div class="related-anime-box">
										<div style="display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap;">
											<div>
												<div class="meta" style="margin-bottom: 6px;">관련 애니</div>
												<a href="${ctx}/animeDetail?animeId=${newsData.animeId}"
													style="font-weight: 800; font-size: 16px; color: #fff; text-decoration: underline;">
													<c:out value="${newsData.animeTitle}" default="관련 애니 보기" />
												</a>
												<c:if test="${not empty newsData.animeYear}">
													<span class="meta" style="margin-left: 10px;">
														(<c:out value="${newsData.animeYear}" /> / <c:out value="${newsData.animeQuarter}" />)
													</span>
												</c:if>
											</div>

											<%-- 관련 애니 썸네일 URL도 뉴스 썸네일과 같은 방식으로 정규화
											     ctx가 이미 포함된 저장값도 그대로 허용해서 중복 ctx 붙는 문제를 막는다. --%>
											<c:set var="aThumbRaw" value="${newsData.animeThumbnailUrl}" />
											<c:set var="aThumbSrc" value="" />
											<c:if test="${not empty aThumbRaw}">
												<c:choose>
													<c:when test="${fn:startsWith(aThumbRaw,'http')}">
														<c:set var="aThumbSrc" value="${aThumbRaw}" />
													</c:when>

													<c:when test="${fn:startsWith(aThumbRaw, ctx)}">
														<c:set var="aThumbSrc" value="${aThumbRaw}" />
													</c:when>

													<c:when test="${fn:startsWith(aThumbRaw,'/')}">
														<c:set var="aThumbSrc" value="${ctx}${aThumbRaw}" />
													</c:when>
													<c:otherwise>
														<c:set var="aThumbSrc" value="${ctx}/${aThumbRaw}" />
													</c:otherwise>
												</c:choose>
											</c:if>

											<c:if test="${not empty aThumbSrc}">
												<a href="${ctx}/animeDetail?animeId=${newsData.animeId}">
												<img src="<c:out value='${aThumbSrc}'/>" alt="관련 애니 썸네일"
													style="width: 64px; height: 64px; object-fit: cover; border-radius: 12px; border: 1px solid rgba(255, 255, 255, .12);"
													onerror="this.style.display='none';">
												</a>
											</c:if>
										</div>
									</div>
								</c:when>
								<c:otherwise>
									<div class="meta">관련 애니 정보가 없습니다.</div>
								</c:otherwise>
							</c:choose>
						</div>

					</div>
					<!-- /news-article -->

				</div>
			</div>
		</div>
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

<script>
document.addEventListener("DOMContentLoaded", function () {
  const box = document.getElementById("newsContent");
  if (!box) return;

  /*
    JSP에서 계산한 ctx/cover 값을 JS에서도 그대로 사용한다.
    - ctx: 본문 이미지 src 보정용
    - cover: 본문 안 중복 커버 이미지 제거 비교용
  */
  const ctx = "<c:out value='${ctx}'/>";
  const cover = (box.dataset.cover || "").trim();

  /*
    sticky top 기준값 계산
    상단 헤더가 fixed일 때만 그 높이를 읽어서
    - sticky topbar 위치
    - 읽기 진행바 위치
    와 겹치지 않게 맞춘다.
  */
  function computeStickyTop(){
    const header = document.querySelector(".header") || document.querySelector("header");
    if (!header) return 0;

    const cs = window.getComputedStyle(header);
    const isFixed = cs.position === "fixed";
    if (!isFixed) return 0;

    return Math.round(header.getBoundingClientRect().height);
  }

  /*
    계산한 값을 CSS 변수(--news-sticky-top)로 내려서
    CSS sticky 요소와 JS 생성 요소(진행바/라이트박스 닫기 버튼)가 같은 기준을 쓰게 한다.
  */
  function setStickyTopVar(){
    const top = computeStickyTop();
    document.documentElement.style.setProperty("--news-sticky-top", top + "px");
    return top;
  }

  let headerOffset = setStickyTopVar();

  /*
    본문 이미지 src 경로 보정
    저장 시점/버전 차이로 src 형태가 제각각일 수 있어서 출력 전에 한 번 정리한다.

    그대로 두는 경우:
    - http/https 절대URL
    - data: URL (에디터/붙여넣기 이미지)
    - 이미 ctx가 붙은 경로

    보정하는 경우:
    - /upload/...
    - upload/...
    - ANIMale/upload/... (ctx 앞 슬래시가 빠진 저장값)
  */
  const ctxNoSlash = ctx ? ctx.replace(/^\//,'') : "";
  box.querySelectorAll("img").forEach(img => {
    const raw = (img.getAttribute("src") || "").trim();
    if (!raw) return;

    if (/^https?:\/\//i.test(raw)) return;
    if (/^data:/i.test(raw)) return;
    if (raw.startsWith(ctx + "/")) return;

    // "ANIMale/upload/..."처럼 ctx 문자열만 저장되고 앞 슬래시가 빠진 경우 보정
    if (ctxNoSlash && (raw === ctxNoSlash || raw.startsWith(ctxNoSlash + "/"))) {
      img.setAttribute("src", "/" + raw);
      return;
    }

    if (raw.startsWith("/upload/")) {
      img.setAttribute("src", ctx + raw);
      return;
    }
    if (raw.startsWith("upload/")) {
      img.setAttribute("src", ctx + "/" + raw);
      return;
    }
  });

  /*
    커버 중복 제거
    뉴스 상세 상단 커버에서 이미 썸네일을 보여주고 있는데,
    본문 첫 이미지로 같은 썸네일이 또 들어있는 경우가 있어서 중복 노출을 줄인다.

    단, 본문 이미지가 1장뿐이면 기사 구성 자체일 수 있으므로
    이미지가 2장 이상일 때만 제거 로직을 적용한다.
  */
  if (cover) {
    const norm = (u) => {
      try { return new URL(u, window.location.href).pathname; }
      catch (e) { return (u || "").split("?")[0]; }
    };

    const coverPath = norm(cover);
    const imgs = Array.from(box.querySelectorAll("img"));

    if (imgs.length > 1) {
      imgs.forEach(img => {
        const src = (img.getAttribute("src") || "").trim();
        if (!src) return;
        if (norm(src) === coverPath) {
          const fig = img.closest ? img.closest("figure") : null;
          (fig || img).remove();
        }
      });
    }
  }

  /*
    이미지 라이트박스 생성
    본문 이미지 클릭 시 확대해서 볼 수 있게 오버레이 UI를 동적으로 만든다.
    페이지에 이미 마크업을 고정 배치하지 않는 이유는, 뉴스 상세가 아닌 화면 재사용 가능성과
    초기 HTML 복잡도 감소 때문이다.
  */
  const lightbox = (function createLightbox(){
    const el = document.createElement("div");
    el.className = "img-lightbox";
    el.setAttribute("aria-hidden", "true");
    el.innerHTML = `
      <button type="button" class="img-lightbox__close" aria-label="닫기 (ESC)">닫기 ✕</button>
      <div class="img-lightbox__panel" role="dialog" aria-modal="true">
        <img class="img-lightbox__img" alt="">
        <div class="img-lightbox__cap"></div>
      </div>
    `;
    document.body.appendChild(el);

    const imgEl = el.querySelector(".img-lightbox__img");
    const capEl = el.querySelector(".img-lightbox__cap");
    const closeBtn = el.querySelector(".img-lightbox__close");

    function open(src, caption){
      imgEl.src = src;
      capEl.textContent = caption || "";
      el.classList.add("is-open");
      el.setAttribute("aria-hidden", "false");
      document.documentElement.style.overflow = "hidden";
    }

    function close(){
      el.classList.remove("is-open");
      el.setAttribute("aria-hidden", "true");
      imgEl.src = "";
      capEl.textContent = "";
      document.documentElement.style.overflow = "";
    }

    closeBtn.addEventListener("click", close);

    // 배경 클릭 시 닫기 (이미지/패널 클릭은 유지)
    el.addEventListener("click", (e) => {
      if (e.target === el) close();
    });

    // ESC 닫기 지원
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && el.classList.contains("is-open")) close();
    });

    return { open, close };
  })();

  /*
    본문 이미지 클릭 이벤트 위임
    개별 img마다 핸들러를 달지 않고 newsContent 컨테이너 하나에 위임해서
    에디터 HTML 구조가 바뀌어도 대응하기 쉽게 만든다.
  */
  box.addEventListener("click", (e) => {
    const img = e.target && e.target.tagName === "IMG" ? e.target : null;
    if (!img) return;

    const src = (img.getAttribute("src") || "").trim();
    if (!src) return;

    // figcaption 우선, 없으면 alt 텍스트를 캡션으로 사용
    let caption = "";
    const fig = img.closest ? img.closest("figure") : null;
    if (fig) {
      const fc = fig.querySelector("figcaption");
      if (fc && fc.textContent) caption = fc.textContent.trim();
    }
    if (!caption) caption = (img.getAttribute("alt") || "").trim();

    lightbox.open(src, caption);
  });

  /*
    읽기 진행바 생성
    뉴스 본문(box) 기준으로 현재 스크롤 위치를 퍼센트로 계산해서 scaleX로 표시한다.
    requestAnimationFrame을 사용해 scroll 이벤트 과호출에 의한 렌더링 부담을 줄인다.
  */
  const progress = (function createProgress(){
    let wrap = document.querySelector(".reading-progress");
    if (!wrap) {
      wrap = document.createElement("div");
      wrap.className = "reading-progress";
      wrap.innerHTML = `<div class="reading-progress__bar"></div>`;
      document.body.appendChild(wrap);
    }
    const bar = wrap.querySelector(".reading-progress__bar");

    function clamp(n, min, max){ return Math.max(min, Math.min(max, n)); }

    function update(){
      headerOffset = setStickyTopVar();

      const rect = box.getBoundingClientRect();
      const boxTop = window.pageYOffset + rect.top;
      const boxHeight = box.offsetHeight;

      const start = boxTop - headerOffset - 12;
      const end = (boxTop + boxHeight) - headerOffset - window.innerHeight + 12;

      let p = 0;
      if (end <= start) p = 1;
      else p = clamp((window.pageYOffset - start) / (end - start), 0, 1);

      bar.style.transform = `scaleX(${p})`;
    }

    // scroll 시 rAF로 한 프레임에 한 번만 update 실행
    let ticking = false;
    function onScroll(){
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        ticking = false;
        update();
      });
    }

    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", () => { update(); }, { passive: true });

    update();
    return { update };
  })();

  // 이미지/폰트 로딩 완료 후 높이 변동 반영용 1회 추가 업데이트
  window.addEventListener("load", () => progress.update(), { passive: true });
});

/*
  삭제 확인 함수
  삭제 버튼은 type="button"이라서 여기서 확인 후에만 실제 form submit 되게 만든다.
  (실수 클릭으로 바로 삭제 요청 나가는 것 방지)
*/
function confirmDelete() {
  if (confirm("정말로 이 뉴스를 삭제하시겠습니까? 삭제 후 복구할 수 없습니다.")) {
    document.getElementById("deleteForm").submit();
  }
}
</script>
</body>
</html>