<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%-- =========================================================
   ornably.jsp (발표용 정적 목업 페이지)
   ---------------------------------------------------------
   목적:
   - 우리팀 헤더 Shop 메뉴 클릭 시 이동하는 소개용 페이지
   - 옆팀 Ornably React 프로젝트 HomePage.jsx 레이아웃/분위기 참고
   - JS 기능 없이 디자인/구성만 시연

   참고한 HomePage 구조:
   - 시즌 이벤트(Hero)
   - 카테고리
   - 신상품
   - 인기상품

   특징:
   - 완전 정적 페이지 (JS 없음)
   - 헤더/푸터 없음
   - 밝은 톤 / 라운드 카드 / 보라 포인트 중심
   ========================================================= --%>

<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>Ornably | 홈 소개 목업</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <%-- 필요 없으면 favicon 줄은 지워도 됨 --%>
  <link rel="icon" type="image/png" href="${ctx}/favicon.png">

  <style>
    /* =========================================================
       Ornably Home Mock (Static / CSS-only)
       - HomePage.jsx 분위기 참고 (white card + violet accent)
       ========================================================= */

    :root{
      --bg: #f9fafb;            /* Tailwind bg-gray-50 느낌 */
      --card: #ffffff;
      --line: #e5e7eb;          /* gray-200 */
      --line-soft: #eef0f3;
      --text: #111827;          /* gray-900 */
      --text-sub: #6b7280;      /* gray-500 */
      --text-muted: #9ca3af;    /* gray-400 */
      --violet: #7c3aed;        /* violet-600 */
      --violet-50: #f5f3ff;
      --violet-100: #ede9fe;
      --violet-200: #ddd6fe;
      --shadow-sm: 0 1px 2px rgba(17,24,39,0.05);
      --shadow-md: 0 8px 24px rgba(17,24,39,0.06);
      --radius-xl: 20px;
      --radius-2xl: 24px;
      --radius-3xl: 28px;
      --max-w: 1200px;
    }

    * { box-sizing: border-box; }

    html, body {
      margin: 0;
      padding: 0;
      background: var(--bg);
      color: var(--text);
      font-family: 'Pretendard', 'Apple SD Gothic Neo', 'Malgun Gothic', sans-serif;
      line-height: 1.45;
    }

    a {
      color: inherit;
      text-decoration: none;
    }

    .ornably-page {
      min-height: 100vh;
      background: var(--bg);
    }

    .container {
      width: 100%;
      max-width: var(--max-w);
      margin: 0 auto;
      padding: 32px 20px 40px;
    }

    /* =========================================================
       공통 카드/섹션
       ========================================================= */
    .soft-card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: var(--radius-3xl);
      box-shadow: var(--shadow-sm);
    }

    .section {
      margin-top: 28px;
    }

    .section-header {
      display: flex;
      align-items: flex-end;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 14px;
    }

    .section-title-wrap {
      min-width: 0;
    }

    .section-title {
      margin: 0;
      font-size: 20px;
      line-height: 1.2;
      font-weight: 700;
      letter-spacing: -0.02em;
      color: var(--text);
    }

    .section-subtitle {
      margin: 6px 0 0;
      font-size: 13px;
      color: var(--text-sub);
    }

    .section-link {
      flex-shrink: 0;
      font-size: 14px;
      font-weight: 600;
      color: #374151;
      white-space: nowrap;
    }

    .section-link:hover {
      color: var(--text);
    }

    /* =========================================================
       Pill
       ========================================================= */
    .pill-row {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .pill {
      display: inline-flex;
      align-items: center;
      border-radius: 999px;
      border: 1px solid var(--line);
      background: #fff;
      padding: 6px 10px;
      font-size: 12px;
      font-weight: 600;
      line-height: 1;
      color: #4b5563;
    }

    .pill.violet {
      border-color: var(--violet-200);
      background: var(--violet-50);
      color: #6d28d9;
    }

    .pill.dark {
      border-color: transparent;
      background: rgba(17,24,39,0.86);
      color: #fff;
    }

    /* =========================================================
       Hero (시즌 이벤트)
       - HomePage HeroCarousel 카드 분위기 참고
       ========================================================= */
    .hero-wrap.soft-card {
      padding: 18px;
    }

    .hero-inner {
      margin-top: 12px;
      border: 1px solid var(--line);
      border-radius: var(--radius-3xl);
      background: linear-gradient(135deg, var(--violet-50) 0%, #ffffff 55%, #ffffff 100%);
      overflow: hidden;
    }

    .hero-grid {
      display: grid;
      grid-template-columns: 1.08fr 0.92fr;
      gap: 0;
      align-items: stretch;
    }

    .hero-left {
      padding: 28px 30px;
      display: flex;
      flex-direction: column;
      justify-content: center;
    }

    .hero-title {
      margin: 12px 0 0;
      font-size: 28px;
      line-height: 1.25;
      font-weight: 700;
      letter-spacing: -0.02em;
      color: #111827;
    }

    .hero-desc {
      margin: 10px 0 0;
      font-size: 14px;
      color: #4b5563;
      line-height: 1.6;
      white-space: pre-line;
    }

    .hero-cta-row {
      margin-top: 18px;
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }

    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      height: 42px;
      padding: 0 16px;
      border-radius: 14px;
      border: 1px solid var(--line);
      background: #fff;
      color: #111827;
      font-size: 14px;
      font-weight: 600;
    }

    .btn.primary {
      border-color: var(--violet-200);
      background: var(--violet);
      color: #fff;
      box-shadow: 0 8px 20px rgba(124,58,237,.18);
    }

    .hero-right {
      padding: 22px 22px 22px 6px;
      display: flex;
      align-items: center;
    }

    .hero-visual {
      width: 100%;
      min-height: 260px;
      border-radius: 22px;
      border: 1px solid #ffffff;
      background:
        radial-gradient(circle at 20% 18%, rgba(255,255,255,0.95) 0 12%, transparent 13%),
        radial-gradient(circle at 72% 22%, rgba(255,255,255,0.9) 0 10%, transparent 11%),
        radial-gradient(circle at 82% 70%, rgba(255,255,255,0.7) 0 9%, transparent 10%),
        linear-gradient(135deg, #c4b5fd 0%, #a78bfa 30%, #f5f3ff 100%);
      position: relative;
      overflow: hidden;
      box-shadow: inset 0 0 0 1px rgba(255,255,255,.65);
    }

    .hero-ornament {
      position: absolute;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 50%;
      color: #fff;
      text-shadow: 0 1px 2px rgba(0,0,0,.16);
      box-shadow: 0 12px 24px rgba(76,29,149,.14);
      border: 1px solid rgba(255,255,255,.55);
      backdrop-filter: blur(3px);
      font-size: 26px;
    }

    .hero-ornament.o1 {
      width: 110px; height: 110px;
      left: 14%;
      top: 18%;
      background: radial-gradient(circle at 30% 25%, #fca5a5, #ef4444 70%);
    }

    .hero-ornament.o2 {
      width: 130px; height: 130px;
      right: 16%;
      top: 16%;
      background: radial-gradient(circle at 32% 24%, #fef08a, #eab308 72%);
      font-size: 30px;
    }

    .hero-ornament.o3 {
      width: 150px; height: 150px;
      left: 38%;
      bottom: 14%;
      background: radial-gradient(circle at 30% 25%, #a7f3d0, #10b981 72%);
      font-size: 34px;
    }

    .hero-ribbon {
      position: absolute;
      left: -6%;
      right: -6%;
      bottom: 18px;
      height: 56px;
      border-radius: 999px;
      background: rgba(255,255,255,.65);
      border: 1px solid rgba(255,255,255,.7);
      box-shadow: 0 8px 20px rgba(76,29,149,.08);
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 16px;
      color: #5b21b6;
      font-size: 13px;
      font-weight: 700;
    }

    .hero-ribbon .dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: #a78bfa;
      box-shadow: 0 0 0 4px rgba(167,139,250,.18);
    }

    .hero-dots {
      margin-top: 12px;
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 0 8px 2px;
    }

    .hero-dots span {
      display: inline-block;
      height: 8px;
      border-radius: 999px;
      background: #d1d5db;
    }

    .hero-dots span.active {
      width: 26px;
      background: var(--violet);
    }

    .hero-dots span.dot {
      width: 8px;
    }

    /* =========================================================
       카테고리 카드 (HomePage CategoryCards 느낌)
       ========================================================= */
    .category-grid {
      display: grid;
      grid-template-columns: repeat(6, minmax(0,1fr));
      gap: 12px;
    }

    .category-card {
      display: block;
      border-radius: 18px;
      border: 1px solid var(--line);
      background: #fff;
      box-shadow: var(--shadow-sm);
      padding: 14px;
      transition: transform .15s ease, box-shadow .15s ease;
    }

    .category-card:hover {
      transform: translateY(-2px);
      box-shadow: var(--shadow-md);
    }

    .category-flex {
      display: flex;
      align-items: flex-start;
      gap: 10px;
      min-width: 0;
    }

    .category-icon {
      width: 44px;
      height: 44px;
      border-radius: 16px;
      border: 1px solid var(--violet-100);
      background: var(--violet-50);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 18px;
      flex-shrink: 0;
    }

    .category-name {
      margin: 0;
      font-size: 14px;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -0.01em;
    }

    .category-desc {
      margin: 3px 0 0;
      font-size: 12px;
      color: var(--text-sub);
      line-height: 1.35;
    }

    /* =========================================================
       상품 카드 (HomePage ItemCardV2 느낌)
       ========================================================= */
    .product-grid {
      display: grid;
      grid-template-columns: repeat(4, minmax(0,1fr));
      gap: 16px;
    }

    .product-card {
      border-radius: var(--radius-3xl);
      border: 1px solid var(--line);
      background: #fff;
      box-shadow: var(--shadow-sm);
      overflow: hidden;
      display: flex;
      flex-direction: column;
      min-height: 100%;
      transition: box-shadow .15s ease, transform .15s ease;
    }

    .product-card:hover {
      transform: translateY(-2px);
      box-shadow: var(--shadow-md);
    }

    .product-image {
      position: relative;
      aspect-ratio: 4 / 3;
      background: #f3f4f6;
      overflow: hidden;
      border-bottom: 1px solid var(--line-soft);
    }

    .product-image::before {
      content: '';
      position: absolute;
      inset: 0;
      opacity: .95;
    }

    .product-image.theme-violet::before {
      background: linear-gradient(135deg, #e9d5ff 0%, #c4b5fd 40%, #f5f3ff 100%);
    }
    .product-image.theme-green::before {
      background: linear-gradient(135deg, #bbf7d0 0%, #6ee7b7 42%, #ecfdf5 100%);
    }
    .product-image.theme-gold::before {
      background: linear-gradient(135deg, #fde68a 0%, #fbbf24 42%, #fffbeb 100%);
    }
    .product-image.theme-rose::before {
      background: linear-gradient(135deg, #fecdd3 0%, #fb7185 42%, #fff1f2 100%);
    }

    .product-image-art {
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      flex-direction: column;
      color: rgba(17,24,39,.85);
      text-align: center;
      padding: 12px;
      font-weight: 700;
    }

    .product-emoji {
      font-size: 38px;
      line-height: 1;
      filter: drop-shadow(0 4px 10px rgba(255,255,255,.65));
    }

    .product-art-label {
      font-size: 13px;
      font-weight: 700;
      color: rgba(17,24,39,.78);
      background: rgba(255,255,255,.62);
      border: 1px solid rgba(255,255,255,.9);
      border-radius: 999px;
      padding: 6px 10px;
    }

    .product-badges {
      position: absolute;
      top: 12px;
      left: 12px;
      display: flex;
      gap: 6px;
      flex-wrap: wrap;
      z-index: 1;
    }

    .product-body {
      padding: 16px;
      display: flex;
      flex-direction: column;
      flex: 1;
    }

    .product-name {
      margin: 0;
      font-size: 15px;
      line-height: 1.45;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -0.01em;
      min-height: 44px;
    }

    .product-meta {
      margin-top: 8px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
      font-size: 12px;
      color: #4b5563;
    }

    .product-meta .left {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      min-width: 0;
    }

    .product-meta .category {
      color: var(--text-sub);
      white-space: nowrap;
    }

    .price-wrap {
      margin-top: 12px;
    }

    .price-main {
      margin: 0;
      font-size: 17px;
      font-weight: 700;
      letter-spacing: -0.02em;
      color: var(--text);
    }

    .price-origin {
      margin: 4px 0 0;
      font-size: 12px;
      color: var(--text-muted);
      text-decoration: line-through;
      min-height: 16px;
    }

    .card-actions {
      margin-top: auto;
      padding-top: 14px;
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
    }

    .ghost-btn,
    .violet-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      height: 40px;
      border-radius: 16px;
      border: 1px solid var(--line);
      background: #fff;
      color: #1f2937;
      font-size: 13px;
      font-weight: 700;
    }

    .violet-btn {
      border-color: var(--violet-200);
      background: var(--violet-50);
      color: #6d28d9;
    }

    /* =========================================================
       중간 배너 (발표용 소개 카드)
       ========================================================= */
    .promo-card {
      border-radius: var(--radius-3xl);
      border: 1px solid var(--line);
      background: linear-gradient(135deg, #ffffff 0%, #faf5ff 38%, #eef2ff 100%);
      box-shadow: var(--shadow-sm);
      padding: 18px;
      overflow: hidden;
      position: relative;
    }

    .promo-card::after {
      content: '';
      position: absolute;
      width: 220px;
      height: 220px;
      right: -50px;
      top: -70px;
      border-radius: 50%;
      background: radial-gradient(circle, rgba(124,58,237,.14), rgba(124,58,237,0));
      pointer-events: none;
    }

    .promo-grid {
      display: grid;
      grid-template-columns: 1.1fr 0.9fr;
      gap: 14px;
      align-items: center;
    }

    .promo-title {
      margin: 0;
      font-size: 20px;
      font-weight: 700;
      letter-spacing: -0.02em;
      color: var(--text);
    }

    .promo-desc {
      margin: 8px 0 0;
      font-size: 14px;
      color: #4b5563;
      line-height: 1.55;
    }

    .promo-tags {
      margin-top: 12px;
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .promo-right {
      border: 1px solid var(--line);
      background: rgba(255,255,255,.7);
      border-radius: 18px;
      padding: 14px;
    }

    .promo-list {
      margin: 0;
      padding: 0;
      list-style: none;
      display: grid;
      gap: 8px;
    }

    .promo-list li {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      border: 1px solid var(--line-soft);
      background: #fff;
      border-radius: 12px;
      padding: 10px 12px;
      font-size: 13px;
    }

    .promo-list .k {
      color: var(--text-sub);
      font-weight: 600;
    }

    .promo-list .v {
      color: var(--text);
      font-weight: 700;
      white-space: nowrap;
    }

    /* =========================================================
       하단 메모
       ========================================================= */
    .page-note {
      margin-top: 18px;
      text-align: center;
      font-size: 12px;
      color: var(--text-sub);
    }

    /* =========================================================
       반응형
       ========================================================= */
    @media (max-width: 1100px) {
      .category-grid {
        grid-template-columns: repeat(3, minmax(0,1fr));
      }
      .product-grid {
        grid-template-columns: repeat(2, minmax(0,1fr));
      }
      .hero-grid {
        grid-template-columns: 1fr;
      }
      .hero-right {
        padding: 0 20px 20px;
      }
      .promo-grid {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 640px) {
      .container {
        padding: 20px 14px 28px;
      }
      .hero-wrap.soft-card {
        padding: 14px;
      }
      .hero-left {
        padding: 20px;
      }
      .hero-title {
        font-size: 22px;
      }
      .section-title {
        font-size: 18px;
      }
      .category-grid {
        grid-template-columns: repeat(2, minmax(0,1fr));
      }
      .product-grid {
        grid-template-columns: 1fr;
      }
      .section-header {
        align-items: flex-start;
        flex-direction: column;
      }
      .section-link {
        font-size: 13px;
      }
    }
  </style>
</head>

<body>
<div class="ornably-page">
  <div class="container">

    <%-- =========================================================
         상단 소개 배지 (발표할 때 "목업" 표기용)
         ========================================================= --%>
    <div class="pill-row" style="margin-bottom: 10px;">
      <span class="pill violet">✨ Ornably Home Mock</span>
      <span class="pill">발표용 정적 페이지</span>
      <span class="pill">React HomePage 레이아웃 참고</span>
    </div>

    <%-- =========================================================
         Hero / 시즌 이벤트
         - HomePage HeroCarousel 첫 카드 느낌만 정적으로 표현
         ========================================================= --%>
    <section class="hero-wrap soft-card">
      <div class="section-header" style="margin-bottom: 0;">
        <div class="section-title-wrap">
          <h2 class="section-title">시즌 이벤트</h2>
          <p class="section-subtitle">최대 할인 이벤트를 확인해보세요</p>
        </div>
      </div>

      <div class="hero-inner">
        <div class="hero-grid">
          <div class="hero-left">
            <div class="pill-row">
              <span class="pill violet">✨ 최대 30%</span>
              <span class="pill">2026-02-01 ~ 2026-02-28</span>
            </div>

            <h3 class="hero-title">오너블리 윈터 데코 페어</h3>

            <p class="hero-desc">트리, 전구, 오너먼트, 리스를 한 번에 모아보는 시즌 컬렉션.
발표에서는 이 영역을 '홈 메인 이벤트 배너'로 소개하면 됩니다.</p>

            <div class="hero-cta-row">
              <span class="btn primary">이벤트 보러가기</span>
              <span class="btn">카테고리 둘러보기</span>
            </div>
          </div>

          <div class="hero-right">
            <div class="hero-visual" aria-hidden="true">
              <div class="hero-ornament o1">🔴</div>
              <div class="hero-ornament o2">⭐</div>
              <div class="hero-ornament o3">🎄</div>

              <div class="hero-ribbon">
                <span>SEASONAL DECOR</span>
                <span class="dot"></span>
                <span>ORNABLY</span>
                <span class="dot"></span>
                <span>LIMITED EVENT</span>
              </div>
            </div>
          </div>
        </div>

        <%-- 캐러셀 도트 "모양만" 표현 (JS 없음) --%>
        <div class="hero-dots">
          <span class="active"></span>
          <span class="dot"></span>
          <span class="dot"></span>
        </div>
      </div>
    </section>

    <%-- =========================================================
         카테고리
         - HomePage CategoryCards 구조 참고
         ========================================================= --%>
    <section class="section">
      <div class="section-header">
        <div class="section-title-wrap">
          <h2 class="section-title">카테고리</h2>
          <p class="section-subtitle">원하는 분위기로 빠르게 이동</p>
        </div>
        <a href="#" class="section-link">전체보기 →</a>
      </div>

      <div class="category-grid">
        <a href="#" class="category-card">
          <div class="category-flex">
            <div class="category-icon">🎄</div>
            <div>
              <p class="category-name">트리</p>
              <p class="category-desc">미니 / 대형 / 테마</p>
            </div>
          </div>
        </a>

        <a href="#" class="category-card">
          <div class="category-flex">
            <div class="category-icon">💡</div>
            <div>
              <p class="category-name">전구</p>
              <p class="category-desc">LED · 웜/쿨</p>
            </div>
          </div>
        </a>

        <a href="#" class="category-card">
          <div class="category-flex">
            <div class="category-icon">🟣</div>
            <div>
              <p class="category-name">볼</p>
              <p class="category-desc">유리 / 메탈 / 펄</p>
            </div>
          </div>
        </a>

        <a href="#" class="category-card">
          <div class="category-flex">
            <div class="category-icon">🧸</div>
            <div>
              <p class="category-name">피규어</p>
              <p class="category-desc">캐릭터 / 인형</p>
            </div>
          </div>
        </a>

        <a href="#" class="category-card">
          <div class="category-flex">
            <div class="category-icon">🌿</div>
            <div>
              <p class="category-name">리스</p>
              <p class="category-desc">현관 / 벽 / 테이블</p>
            </div>
          </div>
        </a>

        <a href="#" class="category-card">
          <div class="category-flex">
            <div class="category-icon">🎁</div>
            <div>
              <p class="category-name">기타</p>
              <p class="category-desc">리본 / 소품 / 세트</p>
            </div>
          </div>
        </a>
      </div>
    </section>

    <%-- =========================================================
         신상품
         - HomePage ItemCardV2 느낌 (밝은 카드 + badge + 가격)
         ========================================================= --%>
    <section class="section">
      <div class="section-header">
        <div class="section-title-wrap">
          <h2 class="section-title">신상품</h2>
          <p class="section-subtitle">방금 도착한 NEW 컬렉션</p>
        </div>
        <a href="#" class="section-link">더보기 →</a>
      </div>

      <div class="product-grid">
        <%-- 카드 1 --%>
        <article class="product-card">
          <div class="product-image theme-violet">
            <div class="product-badges">
              <span class="pill dark">NEW</span>
              <span class="pill violet">15% OFF</span>
            </div>
            <div class="product-image-art">
              <div class="product-emoji">🎄</div>
              <div class="product-art-label">트리 컬렉션</div>
            </div>
          </div>
          <div class="product-body">
            <h3 class="product-name">스노우 글로우 트리 150cm</h3>
            <div class="product-meta">
              <span class="left">⭐ <strong>4.8</strong></span>
              <span class="category">트리</span>
            </div>
            <div class="price-wrap">
              <p class="price-main">75,650원</p>
              <p class="price-origin">89,000원</p>
            </div>
            <div class="card-actions">
              <span class="ghost-btn">찜</span>
              <span class="violet-btn">담기</span>
            </div>
          </div>
        </article>

        <%-- 카드 2 --%>
        <article class="product-card">
          <div class="product-image theme-gold">
            <div class="product-badges">
              <span class="pill dark">NEW</span>
              <span class="pill violet">20% OFF</span>
            </div>
            <div class="product-image-art">
              <div class="product-emoji">💡</div>
              <div class="product-art-label">라이트 컬렉션</div>
            </div>
          </div>
          <div class="product-body">
            <h3 class="product-name">웜 LED 스트링 라이트 10m</h3>
            <div class="product-meta">
              <span class="left">⭐ <strong>4.6</strong></span>
              <span class="category">전구</span>
            </div>
            <div class="price-wrap">
              <p class="price-main">19,200원</p>
              <p class="price-origin">24,000원</p>
            </div>
            <div class="card-actions">
              <span class="ghost-btn">찜</span>
              <span class="violet-btn">담기</span>
            </div>
          </div>
        </article>

        <%-- 카드 3 --%>
        <article class="product-card">
          <div class="product-image theme-rose">
            <div class="product-badges">
              <span class="pill dark">NEW</span>
              <span class="pill violet">10% OFF</span>
            </div>
            <div class="product-image-art">
              <div class="product-emoji">🔴</div>
              <div class="product-art-label">볼 오너먼트</div>
            </div>
          </div>
          <div class="product-body">
            <h3 class="product-name">글래스 볼 오너먼트 세트 (12입)</h3>
            <div class="product-meta">
              <span class="left">⭐ <strong>4.5</strong></span>
              <span class="category">볼</span>
            </div>
            <div class="price-wrap">
              <p class="price-main">28,800원</p>
              <p class="price-origin">32,000원</p>
            </div>
            <div class="card-actions">
              <span class="ghost-btn">찜</span>
              <span class="violet-btn">담기</span>
            </div>
          </div>
        </article>

        <%-- 카드 4 --%>
        <article class="product-card">
          <div class="product-image theme-green">
            <div class="product-badges">
              <span class="pill dark">NEW</span>
              <span class="pill violet">18% OFF</span>
            </div>
            <div class="product-image-art">
              <div class="product-emoji">🌿</div>
              <div class="product-art-label">리스 컬렉션</div>
            </div>
          </div>
          <div class="product-body">
            <h3 class="product-name">내추럴 리스 35cm</h3>
            <div class="product-meta">
              <span class="left">⭐ <strong>4.4</strong></span>
              <span class="category">리스</span>
            </div>
            <div class="price-wrap">
              <p class="price-main">31,160원</p>
              <p class="price-origin">38,000원</p>
            </div>
            <div class="card-actions">
              <span class="ghost-btn">찜</span>
              <span class="violet-btn">담기</span>
            </div>
          </div>
        </article>
      </div>
    </section>

    <%-- =========================================================
         중간 프로모션 배너 (발표 설명용)
         ========================================================= --%>
    <section class="section">
      <div class="promo-card">
        <div class="promo-grid">
          <div>
            <div class="pill-row">
              <span class="pill violet">🎁 GIFT CURATION</span>
              <span class="pill">발표용 소개 섹션</span>
            </div>
            <h3 class="promo-title" style="margin-top: 12px;">선물 추천 & 시즌 데코 큐레이션</h3>
            <p class="promo-desc">
              오너블리 홈 화면 중간 배너 느낌으로 구성한 소개 카드입니다.
              발표에서는 '이벤트/기획전/추천 섹션이 들어갈 수 있는 영역'이라고 설명하면 자연스럽습니다.
            </p>
            <div class="promo-tags">
              <span class="pill">트리 세트</span>
              <span class="pill">포토존 조명</span>
              <span class="pill">선물 포장 소품</span>
            </div>
          </div>

          <div class="promo-right">
            <ul class="promo-list">
              <li><span class="k">추천 테마</span><span class="v">Warm Gold</span></li>
              <li><span class="k">대표 구성</span><span class="v">트리 + 라이트 + 볼</span></li>
              <li><span class="k">시즌 혜택</span><span class="v">최대 30% 할인</span></li>
              <li><span class="k">배송 안내</span><span class="v">빠른 발송 가능</span></li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <%-- =========================================================
         인기상품
         ========================================================= --%>
    <section class="section">
      <div class="section-header">
        <div class="section-title-wrap">
          <h2 class="section-title">인기상품</h2>
          <p class="section-subtitle">지금 가장 많이 찾는 아이템</p>
        </div>
        <a href="#" class="section-link">더보기 →</a>
      </div>

      <div class="product-grid">
        <%-- 카드 1 --%>
        <article class="product-card">
          <div class="product-image theme-gold">
            <div class="product-badges">
              <span class="pill dark">HOT</span>
              <span class="pill violet">8% OFF</span>
            </div>
            <div class="product-image-art">
              <div class="product-emoji">⭐</div>
              <div class="product-art-label">포인트 오브제</div>
            </div>
          </div>
          <div class="product-body">
            <h3 class="product-name">스타 탑 라이트 오브제</h3>
            <div class="product-meta">
              <span class="left">⭐ <strong>4.9</strong></span>
              <span class="category">전구</span>
            </div>
            <div class="price-wrap">
              <p class="price-main">28,520원</p>
              <p class="price-origin">31,000원</p>
            </div>
            <div class="card-actions">
              <span class="ghost-btn">찜</span>
              <span class="violet-btn">담기</span>
            </div>
          </div>
        </article>

        <%-- 카드 2 --%>
        <article class="product-card">
          <div class="product-image theme-violet">
            <div class="product-badges">
              <span class="pill dark">HOT</span>
              <span class="pill violet">7% OFF</span>
            </div>
            <div class="product-image-art">
              <div class="product-emoji">🎅</div>
              <div class="product-art-label">피규어 컬렉션</div>
            </div>
          </div>
          <div class="product-body">
            <h3 class="product-name">화이트 세라믹 산타 피규어</h3>
            <div class="product-meta">
              <span class="left">⭐ <strong>4.7</strong></span>
              <span class="category">피규어</span>
            </div>
            <div class="price-wrap">
              <p class="price-main">39,060원</p>
              <p class="price-origin">42,000원</p>
            </div>
            <div class="card-actions">
              <span class="ghost-btn">찜</span>
              <span class="violet-btn">담기</span>
            </div>
          </div>
        </article>

        <%-- 카드 3 --%>
        <article class="product-card">
          <div class="product-image theme-rose">
            <div class="product-badges">
              <span class="pill dark">HOT</span>
              <span class="pill violet">25% OFF</span>
            </div>
            <div class="product-image-art">
              <div class="product-emoji">🩷</div>
              <div class="product-art-label">핑크 시리즈</div>
            </div>
          </div>
          <div class="product-body">
            <h3 class="product-name">핑크 글리터 볼 세트 (8입)</h3>
            <div class="product-meta">
              <span class="left">⭐ <strong>4.8</strong></span>
              <span class="category">볼</span>
            </div>
            <div class="price-wrap">
              <p class="price-main">21,000원</p>
              <p class="price-origin">28,000원</p>
            </div>
            <div class="card-actions">
              <span class="ghost-btn">찜</span>
              <span class="violet-btn">담기</span>
            </div>
          </div>
        </article>

        <%-- 카드 4 --%>
        <article class="product-card">
          <div class="product-image theme-green">
            <div class="product-badges">
              <span class="pill dark">HOT</span>
              <span class="pill violet">12% OFF</span>
            </div>
            <div class="product-image-art">
              <div class="product-emoji">🌲</div>
              <div class="product-art-label">시그니처 트리</div>
            </div>
          </div>
          <div class="product-body">
            <h3 class="product-name">샴페인 골드 트리 180cm</h3>
            <div class="product-meta">
              <span class="left">⭐ <strong>4.9</strong></span>
              <span class="category">트리</span>
            </div>
            <div class="price-wrap">
              <p class="price-main">113,520원</p>
              <p class="price-origin">129,000원</p>
            </div>
            <div class="card-actions">
              <span class="ghost-btn">찜</span>
              <span class="violet-btn">담기</span>
            </div>
          </div>
        </article>
      </div>
    </section>

    <p class="page-note">
      ※ 이 페이지는 발표용 정적 목업입니다. 실제 API/장바구니/주문 기능은 연결하지 않았습니다.
    </p>

  </div>
</div>
</body>
</html>