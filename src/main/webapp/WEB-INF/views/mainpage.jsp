<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<c:if test="${empty activeMenu}">
	<c:set var="activeMenu" value="HOME" />
</c:if>

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

<!-- Google Font -->
<link
	href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap"
	rel="stylesheet">
<link
	href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap"
	rel="stylesheet">

<!-- Css -->
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css"
	type="text/css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css"
	type="text/css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css"
	type="text/css">
<link rel="stylesheet" href="${ctx}/css/plyr.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/owl.carousel.min.css"
	type="text/css">
<link rel="stylesheet" href="${ctx}/css/slicknav.min.css"
	type="text/css">
<link rel="stylesheet" href="${ctx}/css/style.css" type="text/css">

<style>
/* 배너 높이 고정: 배경이미지/슬라이더가 안 보이는 문제 방지 */
.hero__slider .hero__items.set-bg {
	display: block;
	height: 520px;
	padding: 200px 0 40px;
}
/* a로 감싸도 템플릿처럼 보이게 */
.hero__items.set-bg {
	background-size: cover;
	background-position: center;
	background-repeat: no-repeat;
}
  /* 플로팅 버튼 */
  #aiChatFab {
    position: fixed;
    right: 22px;
    bottom: 22px;
    width: 56px;
    height: 56px;
    border-radius: 50%;
    background: #111;
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    box-shadow: 0 10px 25px rgba(0,0,0,0.2);
    z-index: 9999;
    user-select: none;
    font-size: 22px;
  }

#aiChatFab {
  position: fixed;
  right: 22px;
  bottom: 22px;
  width: 60px;              /* 취향대로 56~72 */
  height: 60px;
  border-radius: 50%;
  overflow: hidden;         /* ✅ 원형 크롭 */
  cursor: pointer;
  z-index: 9999;
  box-shadow: 0 10px 25px rgba(0,0,0,0.2);
  background: transparent;  /* PNG면 굳이 배경 없어도 됨 */
}

#aiChatFab img {
  width: 100%;
  height: 100%;
  object-fit: cover;        /* ✅ 빈 공간 없이 채우기 */
  display: block;
}

#aiChatFab:hover {
  transform: translateY(-2px);
  transition: transform .15s ease;
}
  /* 챗봇 패널 */
  #aiChatPanel {
    position: fixed;
    right: 22px;
    bottom: 90px;
    width: 360px;
    height: 520px;
    background: #fff;
    border-radius: 14px;
    box-shadow: 0 20px 45px rgba(0,0,0,0.25);
    z-index: 9999;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  #aiChatPanel.hidden { display: none; }

#aiChatPanel .card,
#aiChatPanel .card * {
  color: #111 !important;
}
#aiChatPanel .card .meta {
  color: #555 !important;
}
#aiChatPanel .card .reason {
  color: #222 !important;
}
  .ai-header {
    padding: 12px 12px;
    background: #111;
    color: #fff;
    display:flex;
    align-items:center;
    justify-content: space-between;
  }

  .ai-title { font-weight: 700; }

  .ai-actions button {
    margin-left: 6px;
    padding: 6px 8px;
    border: 0;
    border-radius: 8px;
    cursor: pointer;
  }

  .ai-body {
    padding: 12px;
    flex: 1;
    overflow: auto;
    background: #f7f7f7;
    font-size: 14px;
  }

  .msg { margin: 8px 0; display:flex; }
  .msg.user { justify-content: flex-end; }
  .bubble {
    max-width: 80%;
    padding: 10px 12px;
    border-radius: 12px;
    line-height: 1.35;
  }
  .msg.user .bubble { background: #111; color: #fff; }
  .msg.bot .bubble { background: #fff; border: 1px solid #eee; }

  .ai-cards {
    padding: 10px 12px;
    border-top: 1px solid #eee;
    background: #fff;
    max-height: 180px;
    overflow: auto;
  }

  .card {
    border: 1px solid #eee;
    border-radius: 10px;
    padding: 10px;
    margin-bottom: 10px;
    display:flex;
    gap: 10px;
  }
  .thumb {
    width: 72px;
    height: 96px;
    border-radius: 8px;
    background: #ddd;
    object-fit: cover;
  }
  .card h4 {
    margin: 0 0 4px 0;
    font-size: 14px;
  }
  .card .meta { font-size: 12px; color: #666; }
  .card .reason { font-size: 12px; margin-top: 6px; }

  .ai-footer {
    padding: 10px 12px;
    display:flex;
    gap: 8px;
    border-top: 1px solid #eee;
    background: #fff;
  }
  .ai-footer input {
    flex:1;
    padding: 10px;
    border-radius: 10px;
    border: 1px solid #ddd;
    outline: none;
  }
  .ai-footer button {
    padding: 10px 12px;
    border-radius: 10px;
    border: 0;
    background: #111;
    color: #fff;
    cursor: pointer;
  }

  .ai-footer2 {
    padding: 8px 12px 12px;
    display:flex;
    gap: 8px;
    background: #fff;
  }
  .ai-footer2 button {
    flex: 1;
    padding: 10px 12px;
    border-radius: 10px;
    border: 1px solid #ddd;
    cursor: pointer;
    background: #fff;
  }
</style>
</head>

<body>

	<%-- Preloader --%>
	<div id="preloder">
		<div class="loader"></div>
	</div>

	<%-- 공통 헤더 --%>
	<jsp:include page="/WEB-INF/common/header.jsp" />

	<!-- Hero Section Begin -->
	<section class="hero">
		<div class="container">
			<div class="hero__slider owl-carousel">

				<c:choose>
					<c:when test="${empty mainBannerNewsList}">
						<div class="hero__items set-bg"
							data-setbg="${ctx}/img/hero/hero-1.jpg">
							<div class="row">
								<div class="col-lg-6">
									<div class="hero__text">
										<div class="label">News</div>
										<h2>표시할 뉴스가 없습니다.</h2>
										<p>최신 뉴스가 등록되면 이 영역에 배너로 노출됩니다.</p>
										<a href="${ctx}/newsList" class="hero__ctaLink"> <span>뉴스
												보러가기</span> <i class="fa fa-angle-right"></i>
										</a>
									</div>
								</div>
							</div>
						</div>
					</c:when>

					<c:otherwise>
						<c:forEach var="n" items="${mainBannerNewsList}" varStatus="st">
							<c:if test="${st.count <= 3}">

								<%-- 썸네일 경로 (NEWS_THUMBNAIL_URL) --%>
								<c:set var="bannerImg" value="${n.newsThumbnailUrl}" />

								<%-- 없으면 기본 배너 --%>
								<c:if test="${empty bannerImg}">
									<c:set var="bannerImg" value="${ctx}/img/hero/hero-1.jpg" />
								</c:if>

								<%-- 경로 정규화: http / ctx / / / 상대경로 --%>
								<c:choose>
									<c:when test="${fn:startsWith(bannerImg,'http')}">
										<%-- 그대로 사용 --%>
									</c:when>

									<c:when test="${fn:startsWith(bannerImg, ctx)}">
										<%-- 이미 ctx 포함 --%>
									</c:when>

									<c:when test="${fn:startsWith(bannerImg,'/')}">
										<c:set var="bannerImg" value="${ctx}${bannerImg}" />
									</c:when>

									<c:otherwise>
										<c:set var="bannerImg" value="${ctx}/${bannerImg}" />
									</c:otherwise>
								</c:choose>

								<%-- 템플릿은 div지만 클릭 이동 위해 a로 감싸도 OK --%>
								<a href="${ctx}/newsDetail?newsId=${n.newsId}"
									class="hero__items set-bg" data-setbg="${bannerImg}"
									style="text-decoration: none;">
									<div class="row">
										<div class="col-lg-6">
											<div class="hero__text">
												<div class="label">News</div>
												<h2>
													<c:out value="${n.newsTitle}" />
												</h2>
												<p>자세히 보려면 클릭하세요.</p>

												<!-- CTA 버튼 (중첩 a 방지: span으로 처리) -->
												<div class="hero__cta-wrap">
													<span class="hero__cta"> 뉴스 보러가기 <i
														class="fa fa-angle-right"></i>
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
	<!-- Hero Section End -->

	<!-- Product Section Begin -->
	<%-- 구분감 + 메인 전용 스타일 적용을 위해 home-anime-section 클래스 추가 --%>
	<section class="product spad home-anime-section">
		<div class="container">

			<%-- 제목 + View All 우측 정렬 --%>
			<div class="row">
				<div class="col-12">
					<div class="home-section-head">
						<div class="section-title">
							<h4>최신 애니 리스트</h4>
							<p class="section-sub">이번 분기 신작 · 인기작을 한 번에 확인하세요</p>
						</div>

						<a href="${ctx}/animeList" class="btn-viewall"> View All<span
							class="arrow_right"></span>
						</a>
					</div>
				</div>
			</div>

			<div class="row">
				<c:choose>
					<c:when test="${empty mainAnimeList}">
						<div class="col-lg-12">
							<p style="color: #999; margin-top: 10px;">표시할 애니가 없습니다.</p>
						</div>
					</c:when>

					<c:otherwise>
						<c:forEach var="a" items="${mainAnimeList}" varStatus="st">
							<c:if test="${st.count <= 12}">

								<c:set var="thumbPath" value="${a.animeThumbnailUrl}" />

								<%-- 없으면 샘플 --%>
								<c:if test="${empty thumbPath}">
									<c:set var="thumbPath"
										value="${ctx}/images/anisample/bleach.jpg" />
								</c:if>

								<%-- 경로 정규화 --%>
								<c:choose>
									<c:when test="${fn:startsWith(thumbPath,'http')}">
										<%-- 그대로 --%>
									</c:when>

									<c:when test="${fn:startsWith(thumbPath, ctx)}">
										<%-- ctx 포함 --%>
									</c:when>

									<c:when test="${fn:startsWith(thumbPath,'/')}">
										<c:set var="thumbPath" value="${ctx}${thumbPath}" />
									</c:when>

									<c:otherwise>
										<c:set var="thumbPath" value="${ctx}/${thumbPath}" />
									</c:otherwise>
								</c:choose>

								<div class="col-lg-3 col-md-4 col-sm-6">
									<div class="product__item">

										<a href="${ctx}/animeDetail?animeId=${a.animeId}"
											style="display: block;">
											<div class="product__item__pic set-bg"
												data-setbg="${thumbPath}"></div>
										</a>

										<div class="product__item__text">
											<%-- 메타 UI (년도/분기) 가독성 개선용 클래스 적용 --%>
											<ul class="anime-meta">
												<li><c:choose>
														<c:when test="${empty a.animeYear}">연도 미정</c:when>
														<c:otherwise>
															<c:out value="${a.animeYear}" />년</c:otherwise>
													</c:choose></li>
												<li class="badge-q"><c:choose>
														<c:when test="${empty a.animeQuarter}">분기 미정</c:when>
														<c:otherwise>
															<c:out value="${a.animeQuarter}" />
														</c:otherwise>
													</c:choose></li>
											</ul>

											<h5 class="anime-title" style="margin-bottom: 0;">
												<a href="${ctx}/animeDetail?animeId=${a.animeId}"
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
	<!-- Product Section End -->
	
	
	<!-- 1) 챗봇 플로팅 버튼 -->
<div id="aiChatFab" title="AI 추천 챗봇">
    <img src="/assets/images/chatbot/marine.jpg" alt="AI Chatbot" />
</div>

<!--  2) 챗봇 패널 -->
<div id="aiChatPanel" class="hidden">
  <div class="ai-header">
    <div class="ai-title">AI 추천 챗봇</div>
    <div class="ai-actions">
      <button id="aiResetBtn" type="button">새 대화</button>
      <button id="aiCloseBtn" type="button">닫기</button>
    </div>
  </div>

  <div id="aiChatBody" class="ai-body"></div>

  <div id="aiCards" class="ai-cards"></div>

  <div class="ai-footer">
    <input id="aiInput" type="text" placeholder="예: 판타지 액션 성장물 추천해줘" maxlength="500" />
    <button id="aiSendBtn" type="button">전송</button>
  </div>

  <div class="ai-footer2">
    <button id="aiMoreBtn" type="button">더 추천</button>
    <button id="aiChangeBtn" type="button">조건 바꾸기</button>
  </div>
</div>

	<%-- 공통 푸터 --%>
	<%@ include file="/WEB-INF/common/footer.jsp"%>

	<!-- Js Plugins (순서 중요) -->
	<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
	<script src="${ctx}/js/bootstrap.min.js"></script>

	<script src="${ctx}/js/player.js"></script>
	<script src="${ctx}/js/jquery.nice-select.min.js"></script>
	<script src="${ctx}/js/mixitup.min.js"></script>
	<script src="${ctx}/js/jquery.slicknav.js"></script>
	<script src="${ctx}/js/owl.carousel.min.js"></script>

	<script src="${ctx}/js/main.js"></script>
	

	<!-- 안전장치: main.js가 중간에 멈춰도 hero 슬라이더는 강제 초기화 -->
	<script>
    (function () {
      if (!window.jQuery || !jQuery.fn || !jQuery.fn.owlCarousel) return;

      // set-bg 보정
      jQuery(".set-bg").each(function () {
        var bg = jQuery(this).data("setbg");
        if (bg) jQuery(this).css("background-image", "url(" + bg + ")");
      });

      // hero 슬라이더 보정 (중복 초기화 방지)
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
    
    const fab = document.getElementById('aiChatFab');
    const panel = document.getElementById('aiChatPanel');
    const body = document.getElementById('aiChatBody');
    const cards = document.getElementById('aiCards');

    const input = document.getElementById('aiInput');
    const btnSend = document.getElementById('aiSendBtn');
    const btnMore = document.getElementById('aiMoreBtn');
    const btnReset = document.getElementById('aiResetBtn');
    const btnClose = document.getElementById('aiCloseBtn');
    const btnChange = document.getElementById('aiChangeBtn');

    function appendMsg(role, text) {
      const wrap = document.createElement('div');
      wrap.className = 'msg ' + (role === 'user' ? 'user' : 'bot');

      const bubble = document.createElement('div');
      bubble.className = 'bubble';
      bubble.textContent = text;

      wrap.appendChild(bubble);
      body.appendChild(wrap);
      body.scrollTop = body.scrollHeight;
    }

    function renderCards(list) {
      cards.innerHTML = '';
      if (!list || list.length === 0) return;

      list.forEach(a => {
        const div = document.createElement('div');
        div.className = 'card';

        const img = document.createElement('img');
        img.className = 'thumb';
        img.src = a.thumbnailUrl || '';
        img.alt = a.title || 'thumbnail';

        const right = document.createElement('div');
        const title = document.createElement('h4');
        title.textContent = a.title + ' (#' + a.animeId + ')';

        const meta = document.createElement('div');
        meta.className = 'meta';
        meta.textContent = 'genres: ' + (a.genres ? a.genres.join(', ') : '');

        const reason = document.createElement('div');
        reason.className = 'reason';
        reason.textContent = a.reason || '';

        right.appendChild(title);
        right.appendChild(meta);
        right.appendChild(reason);

        div.appendChild(img);
        div.appendChild(right);

        cards.appendChild(div);
      });
    }

    async function api(url, method, bodyObj) {
      const opt = { method, headers: { 'Content-Type': 'application/json' } };
      if (bodyObj) opt.body = JSON.stringify(bodyObj);

      const res = await fetch(url, opt);
      const text = await res.text();

      let data;
      try { data = JSON.parse(text); } catch { data = { message: text }; }

      if (!res.ok) throw data;
      return data;
    }

    async function openChat() {
      // 패널 열기
      panel.classList.remove('hidden');

      // 초기 메시지 호출
      try {
        const data = await api('/api/ai-chat/open', 'GET');
        body.innerHTML = '';
        cards.innerHTML = '';

        appendMsg('bot', data.welcomeMessage || '안녕하세요!');
        appendMsg('bot', data.initialPrompt || '원하는 조건을 입력해주세요!');
      } catch (e) {
        // 로그인 필요 같은 케이스
        appendMsg('bot', e.message || '챗봇을 열 수 없어요.');
      }
    }

    async function sendMessage(isChange) {
      const msg = input.value.trim();
      if (!msg) return;

      appendMsg('user', msg);
      input.value = '';

      try {
        const url = isChange ? '/api/ai-chat/change-condition' : '/api/ai-chat/message';
        const data = await api(url, 'POST', { userMessage: msg });

        if (data.errorMessage) {
          appendMsg('bot', data.errorMessage);
          return;
        }
        renderCards(data.recommendedAnimes);
        appendMsg('bot', '추천 3개 가져왔어! 더 추천도 가능해 🙂');
      } catch (e) {
        appendMsg('bot', e.message || '추천 요청에 실패했어. 잠시 후 다시 시도해줘.');
      }
    }

    async function moreRecommend() {
      try {
        const data = await api('/api/ai-chat/more', 'POST');
        if (data.errorMessage) {
          appendMsg('bot', data.errorMessage);
          return;
        }
        renderCards(data.recommendedAnimes);
        appendMsg('bot', '추가 추천도 가져왔어!');
      } catch (e) {
        appendMsg('bot', e.message || '추가 추천에 실패했어.');
      }
    }

    async function resetChat() {
      try {
        const data = await api('/api/ai-chat/reset', 'POST');
        body.innerHTML = '';
        cards.innerHTML = '';
        appendMsg('bot', data.welcomeMessage || '초기화했어!');
        appendMsg('bot', data.initialPrompt || '조건을 입력해줘!');
      } catch (e) {
        appendMsg('bot', e.message || '초기화에 실패했어.');
      }
    }

    // 이벤트 연결
    fab.addEventListener('click', openChat);
    btnClose.addEventListener('click', () => panel.classList.add('hidden'));
    btnSend.addEventListener('click', () => sendMessage(false));
    btnMore.addEventListener('click', moreRecommend);
    btnReset.addEventListener('click', resetChat);
    btnChange.addEventListener('click', () => sendMessage(true));

    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') sendMessage(false);
    });
  </script>

</body>
</html>
