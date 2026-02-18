<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<<<<<<< HEAD
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
=======
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<c:set var="isLogin" value="${not empty sessionScope.memberId}" />
<c:set var="sessionMemberId" value="${sessionScope.memberId}" />
<c:set var="sessionMemberRole" value="${sessionScope.memberRole}" />

<<<<<<< HEAD
=======
<%-- 삭제된 게시글 체크 --%>
<c:set var="isDeleted" value="${boardData.boardStatus eq '내용삭제'}" />

>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ANIMale | 게시글 상세 보기</title>

<link rel="icon" type="image/png"
	href="<%=request.getContextPath()%>/favicon.png">

<!-- Css Styles -->
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css"
	type="text/css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css"
	type="text/css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css"
	type="text/css">
<link rel="stylesheet" href="${ctx}/css/nice-select.css" type="text/css">
<link rel="stylesheet" href="${ctx}/css/slicknav.min.css"
	type="text/css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* =========================
   Board Detail
========================= */
.header__right__icons .icon_search {
	display: none !important;
}

/* spad 위에 헤더 겹침 방지 느낌 */
.product.spad.bd-detail-wrap {
	padding-top: 120px;
}

/* 글래스 카드 */
.bd-card {
	position: relative;
	border-radius: 22px;
	padding: 28px;
	background: rgba(255, 255, 255, 0.06);
	border: 1px solid rgba(255, 255, 255, 0.10);
	backdrop-filter: blur(18px) saturate(140%);
	-webkit-backdrop-filter: blur(18px) saturate(140%);
	box-shadow: 0 18px 60px rgba(0, 0, 0, 0.45);
	/* 드롭다운 (정렬) 안 잘리게 */
	overflow: visible;
}

.bd-card::before {
	content: "";
	position: absolute;
	top: -55%;
	left: -35%;
	width: 70%;
	height: 110%;
	transform: rotate(18deg);
	background: radial-gradient(circle at 28% 28%, rgba(255, 255, 255, 0.22),
		rgba(255, 255, 255, 0.00) 62%);
	pointer-events: none;
	opacity: .50; /* 과한 광택 줄이기 */
	filter: blur(4px); /* 경계 부드럽게 */
	z-index: 0;
}

.bd-card::after {
	content: "";
	position: absolute;
	inset: 0;
	border-radius: 22px;
	padding: 1px;
	background: linear-gradient(135deg, rgba(255, 255, 255, 0.35),
		rgba(255, 255, 255, 0.08), rgba(120, 190, 255, 0.18),
		rgba(255, 255, 255, 0.10));
	-webkit-mask: linear-gradient(#000 0 0) content-box,
		linear-gradient(#000 0 0);
	-webkit-mask-composite: xor;
	mask-composite: exclude;
	pointer-events: none;
	opacity: .85;
	z-index: 0;
}

/* 카드 내용은 pseudo 위로 */
.bd-card>* {
	position: relative;
	z-index: 1;
}

/* 상단 바 */
.bd-topbar {
	display: flex;
	justify-content: space-between;
	align-items: center;
	gap: 12px;
	flex-wrap: wrap;
	margin-bottom: 14px;
}

.bd-chip {
	display: inline-flex;
	align-items: center;
	gap: 8px;
	padding: 7px 14px;
	border-radius: 999px;
	font-size: 13px;
	font-weight: 800;
	background: rgba(255, 255, 255, 0.10);
	border: 1px solid rgba(255, 255, 255, 0.10);
	color: #fff;
}

.meta {
	color: rgba(255, 255, 255, 0.75);
	font-size: 13px;
}

/* 버튼 */
.btn-sm2 {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 8px;
	padding: 10px 16px;
	border-radius: 999px;
	font-size: 14px;
	font-weight: 800;
	letter-spacing: -0.01em;
	text-decoration: none !important;
	user-select: none;
	border: 1px solid rgba(255, 255, 255, 0.16);
	background: rgba(255, 255, 255, 0.08);
	color: #fff !important;
	transition: transform .18s ease, box-shadow .18s ease, background .18s
		ease, border-color .18s ease, opacity .18s ease;
	backdrop-filter: blur(12px) saturate(140%);
	-webkit-backdrop-filter: blur(12px) saturate(140%);
	cursor: pointer;
}

.btn-sm2:hover {
	transform: translateY(-1px);
	box-shadow: 0 12px 28px rgba(0, 0, 0, 0.35);
	border-color: rgba(255, 255, 255, 0.26);
	background: rgba(255, 255, 255, 0.12);
}

.btn-sm2:active {
	transform: translateY(0);
	box-shadow: none;
}

.btn-sm2:focus-visible {
	outline: none;
	box-shadow: 0 0 0 3px rgba(140, 200, 255, 0.35);
}

.btn-sm2.btn-primary2 {
	background: linear-gradient(135deg, rgba(120, 190, 255, 0.45),
		rgba(255, 255, 255, 0.08));
	border-color: rgba(120, 190, 255, 0.35);
}

.btn-sm2.btn-danger2 {
	background: linear-gradient(135deg, rgba(255, 90, 120, 0.35),
		rgba(255, 255, 255, 0.06));
	border-color: rgba(255, 90, 120, 0.35);
}

.btn-sm2.btn-ghost2 {
	background: rgba(255, 255, 255, 0.06);
	border-color: rgba(255, 255, 255, 0.14);
	opacity: .95;
}

/* 테이블 */
.bd-table {
	width: 100%;
	margin: 0;
	border: 0;
	color: #fff;
}

.bd-table th, .bd-table td {
	border-top: 1px solid rgba(255, 255, 255, 0.10) !important;
	border-bottom: 0 !important;
	border-left: 0 !important;
	border-right: 0 !important;
	padding: 16px 12px;
	vertical-align: top;
}

.bd-table tr:first-child th, .bd-table tr:first-child td {
	border-top: 0 !important;
}

.bd-table th {
	width: 90px;
	color: rgba(255, 255, 255, 0.75);
	font-weight: 800;
	letter-spacing: -0.02em;
}

.bd-title-row {
	display: flex;
	justify-content: space-between;
	align-items: flex-start;
	gap: 12px;
	flex-wrap: wrap;
}

.bd-title {
	font-weight: 900;
	font-size: 20px;
	line-height: 1.35;
	letter-spacing: -0.02em;
	color: #fff;
}

.bd-title-meta {
	display: flex;
	align-items: center;
	gap: 12px;
	white-space: nowrap;
	font-size: 13px;
	color: rgba(255, 255, 255, 0.80);
}

.bd-divider {
	opacity: .35;
}

.bd-content-box {
	width: 100%;
	border-radius: 16px;
	padding: 18px 18px;
	min-height: 260px;
	background: rgba(0, 0, 0, 0.20);
	border: 1px solid rgba(255, 255, 255, 0.10);
}

.bd-content-box .bd-content {
	white-space: pre-wrap;
	word-break: break-word;
	line-height: 1.9;
	color: rgba(255, 255, 255, 0.92);
}

/* 액션 행 */
.bd-actions {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 10px;
	flex-wrap: wrap;
}

.bd-actions-left, .bd-actions-right {
	display: flex;
	gap: 10px;
	flex-wrap: wrap;
	align-items: center;
}

<<<<<<< HEAD
/* Auth Bar (로그인 안했을 때) */
.auth-bar {
	padding: 10px 0;
	border-bottom: 1px solid rgba(255, 255, 255, 0.10);
	background: rgba(255, 255, 255, 0.04);
	backdrop-filter: blur(10px);
	-webkit-backdrop-filter: blur(10px);
}

.auth-bar__menu {
	margin: 0;
	padding: 0;
	list-style: none;
	display: flex;
	gap: 12px;
	justify-content: flex-end;
	align-items: center;
	flex-wrap: wrap;
}

.auth-bar__menu a {
	font-size: 13px;
	color: rgba(255, 255, 255, 0.9);
	text-decoration: none;
}

.auth-bar__menu a:hover {
	color: #fff;
	text-decoration: underline;
}

=======
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
/* 댓글 헤더 */
.bd-replies-head {
	display: flex;
	justify-content: space-between;
	align-items: center;
	gap: 12px;
	flex-wrap: wrap;
	margin-bottom: 12px;
	/* 드롭다운이 버튼에 안 가리도록 최상단 */
	position: relative;
	z-index: 50;
}

.bd-replies-title {
	margin: 0;
	color: #fff;
	font-weight: 900;
	letter-spacing: -0.02em;
}

.bd-textarea {
	flex: 1;
	min-width: 260px;
	border-radius: 14px;
	padding: 12px 14px;
	border: 1px solid rgba(255, 255, 255, .15);
	background: rgba(0, 0, 0, .22);
	color: #fff;
	outline: none;
}

.bd-textarea::placeholder {
	color: rgba(255, 255, 255, .60);
}

.bd-helpbox {
	padding: 12px 14px;
	border: 1px solid rgba(255, 255, 255, .10);
	border-radius: 14px;
	background: rgba(0, 0, 0, .18);
}

/* nice-select 글래스 + z-index */
.nice-select {
	background: rgba(255, 255, 255, 0.08) !important;
	border: 1px solid rgba(255, 255, 255, 0.16) !important;
	color: #fff !important;
	border-radius: 999px !important;
	height: 42px !important;
	line-height: 40px !important;
	padding-left: 16px !important;
	padding-right: 36px !important;
	backdrop-filter: blur(10px);
	-webkit-backdrop-filter: blur(10px);
	position: relative;
	z-index: 60;
}

.nice-select.open {
	z-index: 9999 !important;
}

.nice-select.open .list {
	z-index: 9999 !important;
}

.nice-select:after {
	border-bottom: 2px solid rgba(255, 255, 255, 0.65) !important;
	border-right: 2px solid rgba(255, 255, 255, 0.65) !important;
	right: 14px !important;
}

.nice-select .list {
	background: rgba(10, 10, 35, 0.92) !important;
	border: 1px solid rgba(255, 255, 255, 0.14) !important;
	border-radius: 14px !important;
	overflow: hidden;
}

.nice-select .option {
	color: rgba(255, 255, 255, 0.92) !important;
}

.nice-select .option:hover, .nice-select .option.focus, .nice-select .option.selected
	{
	background: rgba(255, 255, 255, 0.08) !important;
}

/* 댓글 아이템 */
.reply-item {
	background: rgba(255, 255, 255, .06);
	border: 1px solid rgba(255, 255, 255, .14);
	border-radius: 16px;
	padding: 14px 16px;
	margin-bottom: 10px;
	box-shadow: 0 10px 28px rgba(0, 0, 0, .22);
}

.reply-head {
	display: flex;
	justify-content: space-between;
	align-items: flex-start;
	gap: 12px;
}

.reply-writer {
	flex: 1;
	min-width: 0;
}

.reply-nick {
	font-weight: 900;
	color: rgba(255, 255, 255, .92);
}

.reply-actions {
	flex: 0 0 auto;
	white-space: nowrap;
}

.reply-actions a {
	margin-left: 10px;
	font-size: 12px;
	color: rgba(255, 255, 255, .88);
	text-decoration: none;
}

.reply-actions a:hover {
	text-decoration: underline;
}

.reply-content {
	margin-top: 8px;
	color: rgba(255, 255, 255, .95);
	line-height: 1.8;
	font-size: 14px;
	white-space: pre-wrap;
	word-break: break-word;
}

/* 인라인 댓글 수정 input */
.reply-item input.reply-inline-input {
	background: rgba(0, 0, 0, .22) !important;
	color: #fff !important;
	border: 1px solid rgba(255, 255, 255, .15) !important;
	border-radius: 999px;
	padding: 10px 14px;
	height: 44px;
	outline: none;
	box-sizing: border-box;
}

.reply-item input.reply-inline-input::placeholder {
	color: rgba(255, 255, 255, .65);
}

.reply-edit textarea.replyEditText {
	width: 100%;
	border-radius: 14px;
	padding: 12px 14px;
	border: 1px solid rgba(255, 255, 255, .15);
	background: rgba(0, 0, 0, .22);
	color: #fff;
}

.reply-edit-actions {
	display: flex;
	justify-content: flex-end;
	gap: 8px;
	margin-top: 8px;
}

/* 모달 */
.modal-content {
	background: rgba(20, 20, 45, 0.92);
	color: #fff;
	border: 1px solid rgba(255, 255, 255, .14);
	border-radius: 16px;
}

.modal-header, .modal-footer {
	border-color: rgba(255, 255, 255, .10);
}

/* LIKE UI (서블릿 isLiked=0/1 기준) */
#btnLikeToggle .fa-heart {
	transition: .14s;
	color: rgba(255, 255, 255, .50);
}

#btnLikeToggle.liked .fa-heart {
	color: #ff4b4b;
	transform: scale(1.08);
}

/* 버튼 전체도 확실히 변화 */
#btnLikeToggle.liked {
	background: linear-gradient(135deg, rgba(255, 90, 120, 0.45),
		rgba(255, 255, 255, 0.08));
	border-color: rgba(255, 90, 120, 0.55);
	box-shadow: 0 14px 34px rgba(255, 75, 75, 0.18);
}

#btnLikeToggle.liked:hover {
	background: linear-gradient(135deg, rgba(255, 90, 120, 0.55),
		rgba(255, 255, 255, 0.10));
	border-color: rgba(255, 90, 120, 0.70);
}

#btnLikeToggle.liked #likeLabel {
	color: #fff;
}

/* 기본 카드는 다시 클립 */
.bd-card {
	overflow: hidden;
}

/* 댓글 카드만 드롭다운 때문에 overflow 풀기 */
.bd-card--replies {
	overflow: visible;
}

/* 댓글 카드에서 대각 광택은 꺼서 깔끔하게 */
.bd-card--replies::before {
	display: none;
}
/* 댓글 헤더/작성폼 확실히 분리 */
.bd-replies-head {
	margin-bottom: 16px;
}

.bd-replies-compose {
	margin-top: 6px;
}

/* 폼이 항상 아래에서 자연스럽게 줄바꿈되게 */
#replyForm {
	width: 100%;
}

/* 화면이 좁아지면 작성 버튼을 아래로 내려서 겹침 제거 */
@media ( max-width : 768px) {
	.bd-replies-head {
		flex-direction: column;
		align-items: flex-start;
		gap: 10px;
	}
	.bd-replies-head>div {
		width: 100%;
		display: flex;
		justify-content: flex-end;
	}
	#replyForm {
		flex-direction: column;
		align-items: stretch;
	}
	#replyForm button {
		width: 100%;
	}
}

/* =========================================
   본문 큰 이미지/미디어로 레이아웃 깨짐 방지
   - table 폭이 이미지에 의해 늘어나는 현상 차단
   - CKEditor 이미지/figure 포함 대응
========================================= */

/* 1) 테이블이 내용 폭에 끌려가지 않게 고정 레이아웃 */
.bd-table {
	table-layout: fixed;
	width: 100%;
}

/* 2) 본문 박스는 라운드 안쪽으로 클립 (이미지가 삐져나오지 않게) */
.bd-content-box {
	overflow: hidden;
}

/* 3) 본문 안의 모든 이미지/비디오/iframe이 박스 폭을 넘지 못하게 */
.bd-content img, .bd-content video {
	max-width: 100% !important;
	height: auto !important;
	display: block;
	margin: 12px auto;
	border-radius: 0 !important; /* 직각 이미지 유지 */
}

/* 4) CKEditor가 figure로 감싸는 케이스 대응 */
.bd-content figure, .bd-content .image {
	max-width: 100% !important;
	margin: 12px 0;
}

.bd-content figure img {
	max-width: 100% !important;
	height: auto !important;
}

/* 5) iframe도 반응형 */
.bd-content iframe {
	width: 100% !important;
	max-width: 100% !important;
	aspect-ratio: 16/9;
	height: auto !important;
	border: 0;
	display: block;
	margin: 12px 0;
}
<<<<<<< HEAD
=======
/* 신고 모달 중앙 정렬 */
#reportModal .modal-dialog {
	position: fixed;
	top: 50%;
	left: 50%;
	transform: translate(-50%, -50%);
	margin: 0;
	max-width: 500px;
	width: 90%;
}

#reportModal.modal {
	display: none;
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	overflow: auto;
	background-color: rgba(0, 0, 0, 0.7);
	z-index: 9999;
}

#reportModal.modal.show {
	display: flex !important;
	align-items: center;
	justify-content: center;
}

/* 모달 애니메이션 제거 */
#reportModal .modal-dialog {
	transition: none !important;
}

/* 모달 내용 스크롤 */
#reportModal .modal-body {
	max-height: 400px;
	overflow-y: auto;
}

/* ============================================
   삭제된 게시글 - 버튼 비활성화 스타일
============================================ */
button:disabled, textarea:disabled {
	opacity: 0.5 !important;
	cursor: not-allowed !important;
	background: #555 !important;
	pointer-events: none;
}

button:disabled:hover, textarea:disabled:hover {
	background: #555 !important;
	transform: none !important;
}
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
</style>
</head>

<body>

	<jsp:include page="/WEB-INF/common/header.jsp" />

<<<<<<< HEAD
	<%-- Auth Bar (로그인 안 했을 때만) --%>
	<c:if test="${not isLogin}">
		<section class="auth-bar">
			<div class="container">
				<ul class="auth-bar__menu">
					<li><a href="login">로그인</a></li>
					<li><a href="joinPage">회원가입</a></li>
					<li><a href="findPasswordPage">비밀번호 찾기</a></li>
				</ul>
			</div>
		</section>
	</c:if>

=======
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
	<section class="product spad bd-detail-wrap">
		<div class="container">

			<%-- 상단 버튼/카테고리 --%>
			<div class="bd-topbar">
				<div class="bd-actions-left">
					<c:set var="curCategory"
						value="${not empty param.category ? param.category : boardData.boardCategory}" />

					<c:url var="boardListUrl" value="boardList">
						<c:param name="boardCategory" value="${curCategory}" />
					</c:url>

					<a href="${boardListUrl}" class="btn-sm2 btn-ghost2"><i
						class="fa fa-list"></i> 글 목록</a> <a href="boardWritePage"
						class="btn-sm2 btn-primary2"><i class="fa fa-pencil"></i> 글 작성</a>
				</div>

				<div class="bd-actions-right">
					<span class="bd-chip"><i class="fa fa-tag"></i> 카테고리: <b><c:out
								value="${boardData.boardCategory}" /></b></span>
				</div>
			</div>

			<%-- 게시글 상세 카드 --%>
			<div class="bd-card bd-card--post">

				<table class="table bd-table">
					<tbody>

						<tr>
							<th>제목</th>
							<td>
								<div class="bd-title-row">
									<div class="bd-title">
<<<<<<< HEAD
										<c:out value="${boardData.boardTitle}" />
=======
										<c:choose>
											<c:when test="${isDeleted}">
												<span style="color: #e53637; font-style: italic;"> <i
													class="fa fa-ban"></i> [삭제됨] 신고 요청으로 삭제된 게시글입니다
												</span>
											</c:when>
											<c:otherwise>
												<c:out value="${boardData.boardTitle}" />
											</c:otherwise>
										</c:choose>
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
									</div>

									<div class="bd-title-meta">
										<div>
											작성자: <b style="color: #fff;"><c:out
													value="${boardData.writerNickname}" /></b>
										</div>
										<span class="bd-divider">|</span>
										<div>
											조회수: <b style="color: #fff;"><c:out
													value="${boardData.boardViews}" /></b>
										</div>
									</div>
								</div>
							</td>
						</tr>

						<tr>
							<th>내용</th>
							<td>
								<div class="bd-content-box">
									<div class="bd-content">
<<<<<<< HEAD
										<c:out value="${boardData.boardContent}" escapeXml="false" />
=======
										<c:choose>
											<c:when test="${isDeleted}">
												<div
													style="background: rgba(229, 54, 55, 0.1); border: 2px solid #e53637; padding: 60px 40px; border-radius: 12px; text-align: center; margin: 20px 0;">
													<i class="fa fa-exclamation-triangle"
														style="font-size: 64px; color: #e53637; margin-bottom: 24px; display: block;"></i>
													<p
														style="color: #e53637; font-size: 20px; margin: 0 0 12px 0; font-weight: bold;">
														⚠️ 신고 요청으로 삭제된 게시글입니다</p>
													<p
														style="color: #aaa; font-size: 15px; margin: 0; line-height: 1.6;">
														이 게시글은 커뮤니티 가이드 위반으로 인해 내용이 삭제되었습니다.<br> 자세한 사항은
														관리자에게 문의해주세요.
													</p>
												</div>
											</c:when>
											<c:otherwise>
												<c:out value="${boardData.boardContent}" escapeXml="false" />
											</c:otherwise>
										</c:choose>
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
									</div>
								</div>
							</td>
						</tr>

						<tr>
							<th></th>
							<td>
								<div class="bd-actions">

									<%-- 수정/삭제: 작성자 or ADMIN --%>
									<div class="bd-actions-left">
										<c:if
											test="${isLogin and (sessionScope.memberId eq boardData.memberId or sessionScope.memberRole eq 'ADMIN')}">
											<c:url var="boardEditUrl" value="boardEditPage">
												<c:param name="type" value="BOARD" />
												<c:param name="boardId" value="${boardData.boardId}" />
											</c:url>

<<<<<<< HEAD
											<a href="${boardEditUrl}" class="btn-sm2 btn-primary2"><i
												class="fa fa-edit"></i> 수정</a>

=======
											<!-- 수정 버튼 -->
											<a href="${boardEditUrl}" class="btn-sm2 btn-primary2"
												<c:if test="${isDeleted}">
               onclick="event.preventDefault(); alert('삭제된 게시글은 수정할 수 없습니다.'); return false;"
               style="opacity:0.5; cursor:not-allowed; pointer-events:none;"
           </c:if>>
												<i class="fa fa-edit"></i> 수정
											</a>

											<!-- 삭제 버튼 -->
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
											<form action="boardDelete" method="post"
												style="display: inline;">
												<input type="hidden" name="boardId"
													value="${boardData.boardId}">
												<button type="submit" class="btn-sm2 btn-danger2"
<<<<<<< HEAD
													onclick="return confirm('정말 삭제하시겠습니까?');">
=======
													<c:if test="${isDeleted}">
                        disabled 
                        onclick="event.preventDefault(); alert('이미 삭제된 게시글입니다.'); return false;"
                        style="opacity:0.5; cursor:not-allowed;"
                    </c:if>
													<c:if test="${!isDeleted}">
                        onclick="return confirm('정말 삭제하시겠습니까?');"
                    </c:if>>
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
													<i class="fa fa-trash"></i> 삭제
												</button>
											</form>
										</c:if>
									</div>

									<%-- 좋아요/취소 --%>
									<div class="bd-actions-right">
										<button type="button" class="btn-sm2" id="btnLikeToggle"
											data-liked="${likedByMe ? 1 : 0}"
											<%-- 숫자(0/1)로 넣어둠 --%>
<<<<<<< HEAD
											data-board-id="${boardData.boardId}">
=======
											data-board-id="${boardData.boardId}"
											<c:if test="${isDeleted}">disabled title="삭제된 게시글입니다"</c:if>>
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
											<i class="fa fa-heart"></i> <span id="likeLabel"> <c:choose>
													<c:when test="${likedByMe}">좋아요 취소</c:when>
													<c:otherwise>좋아요</c:otherwise>
												</c:choose>
											</span> <span style="opacity: .95;">( <b id="likeCount"><c:out
														value="${likeCount}" /></b>)
											</span>
										</button>

										<button type="button" class="btn-sm2 btn-ghost2"
<<<<<<< HEAD
											id="btnLikeUsers" data-board-id="${boardData.boardId}">
											<i class="fa fa-users"></i> 좋아요 누른 사람
										</button>
=======
											id="btnLikeUsers" data-board-id="${boardData.boardId}"
											<c:if test="${isDeleted}">disabled title="삭제된 게시글입니다"</c:if>>
											<i class="fa fa-users"></i> 좋아요 누른 사람
										</button>

										<%-- 신고 버튼 (로그인 시에만 표시) --%>
										<c:if test="${isLogin}">
											<button type="button" class="btn-sm2 btn-danger2"
												id="btnReport" data-board-id="${boardData.boardId}"
												<c:if test="${isDeleted}">disabled title="삭제된 게시글입니다"</c:if>>
												<i class="fa fa-flag"></i> 신고
											</button>
										</c:if>

>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
									</div>

								</div>
							</td>
						</tr>

					</tbody>
				</table>

			</div>

			<%-- 댓글 영역 카드 --%>
			<div style="margin-top: 18px;" class="bd-card bd-card--replies">
				<div class="bd-replies-head">
					<h4 class="bd-replies-title">댓글</h4>
					<div>
						<select id="replySort">
							<option value="REPLY_LIST_RECENT" selected>최신순</option>
							<option value="REPLY_LIST_OLDEST">작성순</option>
						</select>
					</div>
				</div>

				<%-- 댓글 작성 --%>
				<div class="bd-replies-compose">
					<c:choose>
						<c:when test="${not isLogin}">
							<div class="meta bd-helpbox">
								댓글 작성은 로그인 후 가능합니다. <a href="${ctx}/login"
									style="text-decoration: underline; color: #fff;">로그인하기</a>
							</div>
						</c:when>
						<c:otherwise>
							<form id="replyForm" action="${ctx}/replyWrite" method="post"
								style="display: flex; gap: 10px; flex-wrap: wrap; align-items: flex-start;">
								<input type="hidden" name="boardId" value="${boardData.boardId}">
<<<<<<< HEAD
								<textarea name="replyContent" id="replyContent" rows="3"
									placeholder="댓글을 입력하세요" class="bd-textarea"></textarea>
								<button type="submit" class="btn-sm2 btn-primary2"
									style="height: 44px;">
									<i class="fa fa-comment"></i> 작성 완료
								</button>
=======
								<!-- ✅ 수정 (textarea는 활성화, 버튼만 비활성화) -->
								<textarea name="replyContent" id="replyContent" rows="3"
									placeholder="댓글을 입력하세요" class="bd-textarea"></textarea>

								<button type="submit" class="btn-sm2 btn-primary2"
									style="height: 44px;"
									<c:if test="${isDeleted}">disabled title="삭제된 게시글에는 댓글을 작성할 수 없습니다."</c:if>>
									<i class="fa fa-comment"></i> 작성 완료
								</button>

>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
							</form>
						</c:otherwise>
					</c:choose>
				</div>

				<%-- 댓글 리스트 --%>
				<div id="replyListArea" style="margin-top: 14px;">
					<c:choose>
						<c:when test="${empty replyList}">
							<div class="meta" style="margin-top: 10px;">아직 댓글이 없습니다.</div>
						</c:when>
						<c:otherwise>
							<c:forEach var="r" items="${replyList}">
								<div class="reply-item" data-reply-id="${r.replyId}">
									<div class="reply-head">
										<div class="reply-writer">
											<span class="reply-nick"><c:out
													value="${r.writerNickname}" /></span> <span class="meta"
												style="margin-left: 8px;">(<c:out
													value="${r.memberId}" />)
											</span>
										</div>

										<div class="reply-actions">
											<c:if test="${isLogin}">
												<%-- 작성자면: 수정/삭제 둘 다 --%>
												<c:if test="${r.memberId eq sessionScope.memberId}">
													<a href="javascript:void(0);"
														onclick="editReply(${r.replyId}, ${boardData.boardId});">수정</a>
													<a href="javascript:void(0);"
														onclick="deleteReply(${r.replyId}, ${boardData.boardId});">삭제</a>
												</c:if>

												<%-- ADMIN이면: 삭제만 --%>
												<c:if
													test="${sessionScope.memberRole eq 'ADMIN' and r.memberId ne sessionScope.memberId}">
													<a href="javascript:void(0);"
														onclick="deleteReply(${r.replyId}, ${boardData.boardId});">삭제</a>
												</c:if>
											</c:if>
										</div>
									</div>

									<div class="reply-content" id="replyContent_${r.replyId}">
										<c:out value="${r.replyContent}" />
									</div>

									<div class="reply-edit"
										style="display: none; margin-top: 10px;">
										<textarea class="replyEditText" rows="3"></textarea>
										<div class="reply-edit-actions">
											<button type="button"
												class="btn-sm2 btn-primary2 btnReplySave">수정 저장</button>
											<button type="button"
												class="btn-sm2 btn-ghost2 btnReplyCancel">취소</button>
										</div>
									</div>
								</div>
							</c:forEach>
						</c:otherwise>
					</c:choose>
				</div>
			</div>

		</div>
	</section>

	<%-- 좋아요 사용자 모달 --%>
<<<<<<< HEAD
	<div class="modal fade" id="likeUsersModal" tabindex="-1" role="dialog"
=======
	<div class="modal" id="likeUsersModal" tabindex="-1" role="dialog"
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
		aria-hidden="true">
		<div class="modal-dialog modal-dialog-centered" role="document">
			<div class="modal-content">
				<div class="modal-header">
					<h5 class="modal-title">좋아요 누른 사람</h5>
					<button type="button" class="close" data-dismiss="modal"
						aria-label="Close" style="color: #fff;">
						<span aria-hidden="true" style="color: #fff;">&times;</span>
					</button>
				</div>
				<div class="modal-body" id="likeUsersBody">
					<div class="meta">불러오는 중...</div>
				</div>
				<div class="modal-footer">
					<button type="button" class="btn-sm2 btn-ghost2"
						data-dismiss="modal">닫기</button>
				</div>
			</div>
		</div>
	</div>

<<<<<<< HEAD
=======
	<%-- 신고 모달 --%>
	<div class="modal fade" id="reportModal" tabindex="-1" role="dialog">
		<div class="modal-dialog" role="document">
			<div class="modal-content"
				style="background: rgba(30, 30, 40, 0.98); color: #fff; border: 1px solid rgba(255, 255, 255, 0.2);">
				<div class="modal-header">
					<h5 class="modal-title">게시글 신고</h5>
					<button type="button" class="close" data-dismiss="modal"
						aria-label="Close" style="color: #fff;">
						<span aria-hidden="true" style="color: #fff;">&times;</span>
					</button>
				</div>
				<div class="modal-body">
					<p class="meta">신고 사유를 선택해주세요:</p>
					<div style="margin-top: 16px;">
						<label
							style="display: block; margin-bottom: 10px; cursor: pointer;">
							<input type="radio" name="reasonCode" value="SPAM"
							style="margin-right: 8px;"> <span>스팸/광고</span>
						</label> <label
							style="display: block; margin-bottom: 10px; cursor: pointer;">
							<input type="radio" name="reasonCode" value="ABUSE"
							style="margin-right: 8px;"> <span>욕설/비방</span>
						</label> <label
							style="display: block; margin-bottom: 10px; cursor: pointer;">
							<input type="radio" name="reasonCode" value="OBSCENE"
							style="margin-right: 8px;"> <span>음란물</span>
						</label> <label
							style="display: block; margin-bottom: 10px; cursor: pointer;">
							<input type="radio" name="reasonCode" value="ILLEGAL"
							style="margin-right: 8px;"> <span>불법 정보</span>
						</label> <label
							style="display: block; margin-bottom: 10px; cursor: pointer;">
							<input type="radio" name="reasonCode" value="ETC"
							style="margin-right: 8px;"> <span>기타</span>
						</label>
					</div>
				</div>
				<div class="modal-footer">
					<button type="button" class="btn-sm2 btn-ghost2"
						data-dismiss="modal">취소</button>
					<button type="button" class="btn-sm2 btn-danger2"
						id="btnSubmitReport">신고하기</button>
				</div>
			</div>
		</div>
	</div>

>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
	<%@ include file="/WEB-INF/common/footer.jsp"%>

	<!-- JS -->
	<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
	<script src="${ctx}/js/bootstrap.min.js"></script>
	<script src="${ctx}/js/player.js"></script>
	<script src="${ctx}/js/jquery.nice-select.min.js"></script>
	<script src="${ctx}/js/mixitup.min.js"></script>
	<script src="${ctx}/js/jquery.slicknav.js"></script>
	<script src="${ctx}/js/owl.carousel.min.js"></script>
	<script src="${ctx}/js/main.js"></script>

	<script>
  const ctx = "${ctx}";
  const isLogin = ${isLogin};
  const boardId = "${boardData.boardId}";

  const sessionMemberId = "${isLogin ? sessionScope.memberId : ''}";
  const sessionMemberRole = "${isLogin ? sessionScope.memberRole : ''}";

  const CONDITION_RECENT = "REPLY_LIST_RECENT";
  const CONDITION_OLDEST = "REPLY_LIST_OLDEST";

  // nice-select 초기화 (혹시 main.js에서 안 돌면 여기서 보장)
  try { $("#replySort").niceSelect(); } catch(e) {}

  // 좋아요 UI 초기 세팅 (data-liked: 0/1 기준)
(function initLike(){
  const raw = $("#btnLikeToggle").attr("data-liked"); // "0" or "1"
  const liked = (String(raw) === "1");
  setLikeUI(liked);
  $("#likeLabel").text(liked ? "좋아요 취소" : "좋아요");
})();

  // 좋아요 토글 (서블릿: /BoardLikeToggle)
  // 응답: { result:"OK", isLiked:0/1, likeCnt:n }
<<<<<<< HEAD
  $("#btnLikeToggle").on("click", function () {
=======
$("#btnLikeToggle").off("click").on("click", function () {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
    if (!isLogin) {
      alert("로그인 후 이용 가능합니다.");
      return;
    }

    const bid = $(this).data("board-id");
    if (!bid) {
      alert("게시글 번호(boardId)가 없어 처리할 수 없습니다.");
      return;
    }

    $.ajax({
      url: ctx + "/BoardLikeToggle",
      type: "POST",
      dataType: "json",
      data: { boardId: bid },
      success: function (res) {
        if (!res || res.result !== "OK") {
          alert(res && res.msg ? res.msg : "처리에 실패했습니다.");
          return;
        }

        // 서블릿 기준: isLiked(0/1), likeCnt
        const liked = (Number(res.isLiked) === 1);
        const likeCnt = (res.likeCnt != null ? res.likeCnt : 0);

        // UI 반영
        setLikeUI(liked);
        $("#likeLabel").text(liked ? "좋아요 취소" : "좋아요");
        $("#likeCount").text(likeCnt);
      },
      error: function (xhr) {
        if (xhr.status === 401) {
          alert("로그인 후 이용 가능합니다.");
          location.href = ctx + "/loginPage";
          return;
        }
        // 서버가 JSON(msg) 내려줬다면 보여주기
        try{
          const j = xhr.responseJSON;
          if (j && j.msg) { alert(j.msg); return; }
        }catch(e){}
        alert("서버 통신 오류가 발생했습니다.");
      }
    });
  });

  // 좋아요 누른 사람 보기
<<<<<<< HEAD
  $("#btnLikeUsers").on("click", function () {
=======
$("#btnLikeUsers").off("click").on("click", function () {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
    $("#likeUsersBody").html('<div class="meta">불러오는 중...</div>');
    $("#likeUsersModal").modal("show");

    $.ajax({
      url: ctx + "/LikeMemberList",
      type: "GET",
      dataType: "json",
      data: { boardId: boardId },
      success: function (res) {
        if (!res || !res.ok) {
          $("#likeUsersBody").html('<div class="meta">' + (res && res.message ? res.message : "목록을 불러오지 못했습니다.") + '</div>');
          return;
        }

        const users = res.users || [];
        if (users.length === 0) {
          $("#likeUsersBody").html('<div class="meta">아직 좋아요를 누른 사용자가 없습니다.</div>');
          return;
        }

        let html = '<ul style="padding-left:18px; margin:0;">';
        users.forEach(u => {
          html += '<li style="margin-bottom:6px;">' + escapeHtml(u.memberNickname) + '</li>';
        });
        html += '</ul>';
        $("#likeUsersBody").html(html);
      },
      error: function () {
        $("#likeUsersBody").html('<div class="meta">서버 통신 오류가 발생했습니다.</div>');
      }
    });
  });

  // 댓글 작성 (ReplyWriteAction redirect → text로 받음)
<<<<<<< HEAD
  $("#replyForm").on("submit", function (e) {
=======
 $("#replyForm").off("submit").on("submit", function (e) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
    e.preventDefault();

    const content = $("#replyContent").val().trim();
    if (!content) {
      alert("댓글 내용을 입력하세요.");
      return;
    }

    $.ajax({
      url: ctx + "/replyWrite",
      type: "POST",
      dataType: "text",
      data: { boardId: boardId, replyContent: content },
      success: function () {
        $("#replyContent").val("");
        loadReplies($("#replySort").val());
      },
      error: function () {
        alert("서버 통신 오류가 발생했습니다.");
      }
    });
  });

  // 댓글 정렬
<<<<<<< HEAD
  $("#replySort").on("change", function () {
=======
$("#replySort").off("change").on("change", function () {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
    loadReplies(this.value);
  });

  function loadReplies(condition) {
    $.ajax({
      url: ctx + "/ReplyListOrder",
      type: "GET",
      dataType: "json",
      data: { boardId: boardId, condition: condition },
      success: function (res) {
        if (res && res.success === false) {
          alert(res.message || "댓글 목록을 불러오지 못했습니다.");
          renderReplies([]);
          return;
        }
        if (Array.isArray(res)) {
          renderReplies(res);
          return;
        }
        alert("댓글 목록을 불러오지 못했습니다.");
      },
      error: function () {
        alert("서버 통신 오류가 발생했습니다.");
      }
    });
  }

  loadReplies($("#replySort").val());

  function renderReplies(replies) {
	  if (!replies || replies.length === 0) {
	    $("#replyListArea").html('<div class="meta" style="margin-top:10px;">아직 댓글이 없습니다.</div>');
	    return;
	  }

	  let html = "";
	  replies.forEach(function (r) {
	    const replyId  = (r.replyId ?? "");
	    const memberId = (r.memberId ?? "");
	    const nickname = (r.writerNickname ?? "");
	    const content  = (r.replyContent ?? "");

	    // 권한 분리
	    const isWriter = (isLogin && String(memberId) === String(sessionMemberId));
	    const isAdmin  = (isLogin && String(sessionMemberRole) === "ADMIN");

	    // 작성자만 수정 가능
	    const canEdit = isWriter;

	    // 작성자 or ADMIN 삭제 가능
	    const canDelete = (isWriter || isAdmin);

	    html += ''
	      + '<div class="reply-item" data-reply-id="' + escapeHtml(replyId) + '">'
	      + '  <div class="reply-head">'
	      + '    <div class="reply-writer">'
	      + '      <span class="reply-nick">' + escapeHtml(nickname) + '</span>'
	      + '    </div>'
	      + '    <div class="reply-actions">'
	      + (canEdit
	          ? '<a href="javascript:void(0);" onclick="editReply(' + escapeHtml(replyId) + ',' + escapeHtml(boardId) + ');">수정</a>'
	          : '')
	      + (canDelete
	          ? '<a href="javascript:void(0);" onclick="deleteReply(' + escapeHtml(replyId) + ',' + escapeHtml(boardId) + ');">삭제</a>'
	          : '')
	      + '    </div>'
	      + '  </div>'
	      + '  <div class="reply-content" id="replyContent_' + escapeHtml(replyId) + '">' + escapeHtml(content) + '</div>'
	      + '  <div class="reply-edit" style="display:none; margin-top:10px;">'
	      + '    <textarea class="replyEditText" rows="3"></textarea>'
	      + '    <div class="reply-edit-actions">'
	      + '      <button type="button" class="btn-sm2 btn-primary2 btnReplySave">수정 저장</button>'
	      + '      <button type="button" class="btn-sm2 btn-ghost2 btnReplyCancel">취소</button>'
	      + '    </div>'
	      + '  </div>'
	      + '</div>';
	  });

	  $("#replyListArea").html(html);
	}

  // 수정/삭제 (redirect)
 function deleteReply(replyId, boardId) {
  if (!confirm("댓글을 삭제하시겠습니까?")) return;

  const form = document.createElement("form");
  form.method = "POST";
  form.action = ctx + "/replyDelete";

  const b = document.createElement("input");
  b.type = "hidden";
  b.name = "boardId";
  b.value = boardId;

  const r = document.createElement("input");
  r.type = "hidden";
  r.name = "replyId";
  r.value = replyId;

  form.appendChild(b);
  form.appendChild(r);
  document.body.appendChild(form);
  form.submit();
}

  function editReply(replyId, boardId) {
    const el = document.getElementById("replyContent_" + replyId);
    if (!el) return;

    const oldText = el.innerText;

    const esc = (s) => String(s)
      .replaceAll("&","&amp;")
      .replaceAll("<","&lt;")
      .replaceAll(">","&gt;")
      .replaceAll('"',"&quot;")
      .replaceAll("'","&#039;");

    el.innerHTML =
      '<form action="' + ctx + '/replyEdit" method="post" '
      + 'style="display:flex; gap:8px; align-items:center; flex-wrap:wrap;">'
      + '<input type="hidden" name="boardId" value="' + esc(boardId) + '">'
      + '<input type="hidden" name="replyId" value="' + esc(replyId) + '">'
      + '<input type="text" name="replyContent" required '
      + 'class="reply-inline-input" '
      + 'value="' + esc(oldText) + '" '
      + 'style="flex:1; min-width:240px;">'
      + '<button type="submit" class="btn-sm2 btn-primary2">저장</button>'
      + '</form>';
  }

  function escapeHtml(str) {
    if (str === null || str === undefined) return "";
    return String(str)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function setLikeUI(liked){
    $("#btnLikeToggle")
      .toggleClass("liked", !!liked)
      .attr("data-liked", liked ? "1" : "0");
  }
<<<<<<< HEAD
=======
  

// =========================================================
  // 신고 기능
  // =========================================================
  
  // 신고 버튼 클릭
  $("#btnReport").off("click").on("click", function() {
    if (!isLogin) {
      alert("로그인 후 이용 가능합니다.");
      return;
    }
    
    // 라디오 선택 초기화
    $('input[name="reasonCode"]').prop('checked', false);
    
    // 모달 표시
    $("#reportModal").modal("show");
  });

  // 신고 제출 (수정: #replySort → #btnSubmitReport)
  $("#btnSubmitReport").off("click").on("click", function() {
    const reasonCode = $('input[name="reasonCode"]:checked').val();
    
    if (!reasonCode) {
      alert("신고 사유를 선택해주세요.");
      return;
    }
    
    if (!confirm("이 게시글을 신고하시겠습니까?")) {
      return;
    }
    
    $.ajax({
      url: ctx + "/report/board",
      type: "POST",
      data: {
        boardId: boardId,
        reasonCode: reasonCode
      },
      dataType: "json",
      success: function(res) {
        if (res.ok) {
          alert(res.ok);
          $("#reportModal").modal("hide");
        } else if (res.fail) {
          alert(res.fail);
        } else {
          alert("신고 처리 중 오류가 발생했습니다.");
        }
      },
      error: function(xhr) {
        if (xhr.status === 401) {
          alert("로그인 후 이용 가능합니다.");
          location.href = ctx + "/loginPage";
          return;
        }
        alert("서버 통신 오류가 발생했습니다.");
      }
    });
  });
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
  </script>

</body>
</html>
