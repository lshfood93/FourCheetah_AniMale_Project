<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 1) 로그인 세션 없으면 로그인 페이지로 --%>
<c:if test="${empty sessionScope.memberId}">
	<c:redirect url="${ctx}/login" />
</c:if>

<%-- =========================================================
   프로필 이미지 경로 보정
   ---------------------------------------------------------
   DB에 두 가지 형태가 혼재함:
   - 구버전: 'mX_abc123.png'         (파일명만)
   - 신버전: '/uploads/profile/...'  (경로 포함)
   -> startsWith('/')로 판단해서 경로 보정
   ========================================================= --%>
<c:choose>
	<c:when test="${empty memberData.memberProfileImage}">
		<c:set var="profileSrc" value="${ctx}/img/profile-default.jpg" />
	</c:when>
	<c:when test="${fn:startsWith(memberData.memberProfileImage, '/')}">
		<%-- 신버전: 이미 /uploads/profile/... 형태 --%>
		<c:set var="profileSrc" value="${ctx}${memberData.memberProfileImage}" />
	</c:when>
	<c:otherwise>
		<%-- 구버전: 파일명만 있음 -> 경로 붙여줌 --%>
		<c:set var="profileSrc" value="${ctx}/uploads/profile/${memberData.memberProfileImage}" />
	</c:otherwise>
</c:choose>

<c:set var="cashSafe" value="${empty memberData.memberCash ? 0 : memberData.memberCash}" />
<fmt:formatNumber value="${cashSafe}" type="number" var="cashFmt" />

<c:set var="nickColorInit" value="${empty memberData.memberNicknameColor ? '' : memberData.memberNicknameColor}" />
<c:set var="borderColorInit" value="${empty memberData.memberProfileColor ? '' : memberData.memberProfileColor}" />
<c:set var="borderColorStyle" value="${empty borderColorInit ? 'transparent' : borderColorInit}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 마이페이지</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<!-- ✅ mypage 전용 분리 CSS -->
<link rel="stylesheet" href="${ctx}/css/mypage.css">
</head>

<body class="mypage-page"
	data-ctx="${ctx}"
	data-url-profile-upload="${ctx}/member/profile/upload"
	data-url-nick-check="${ctx}/MemberNickNameCheck"
	data-url-apply-decoration="${ctx}/member/apply-decoration"
	data-cost-nick="300"
	data-cost-profile="500"
	data-cost-nick-decor="200"
	data-cost-border-decor="200">

	<%@ include file="/WEB-INF/common/header.jsp"%>

	<c:if test="${not empty msg}">
		<div class="container" style="margin-top: 18px;">
			<div class="alert alert-warning" style="border-radius: 14px;">${msg}</div>
		</div>
	</c:if>

	<div class="container mypage-title">
		<h1 class="mypage-title__h1">마이페이지</h1>
	</div>

	<section class="spad mypage-spad">
		<div class="container">
			<div class="row">

				<!-- LEFT -->
				<div class="col-12 col-lg-4 mypage-col-left">
					<div class="login-box-clean mypage-side-card text-center">

						<div class="profile-img-wrap is-loading" id="profileWrap"
							style="--profile-border-color: ${borderColorStyle};">
							<img id="profilePreview" alt="프로필 이미지"
								data-real-src="${profileSrc}"
								data-initial-src="${profileSrc}"
								data-default-src="${ctx}/img/profile-default.jpg"
								src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==">

							<div class="profile-loader" role="status" aria-live="polite">
								<div class="loader-bar" aria-hidden="true"></div>
								<div class="loader-text">이미지 불러오는 중</div>
							</div>
						</div>

						<label id="profileBtnLabel" class="mypage-btn profile-btn disabled-btn">
							<span class="btn-text">프로필 사진 변경</span>
							<input type="file" id="profileInput" accept="image/*" hidden>
						</label>

						<div class="msg-area msg-info cost-hint" id="profileCostMsg"
							style="margin-top: 10px; display: none;">
							<span class="cost-hint__text">
								※ 프로필 사진 변경 시 <b>500원</b> 이 차감됩니다.
							</span>
						</div>
					</div>

					<div class="login-box-clean mypage-side-card" style="margin-top: 20px;">
						<ul class="side-menu">
							<li class="menu-item">
								<a class="menu-link ${activeMenu eq 'PW' ? 'is-active' : ''}"
									href="${ctx}/changePasswordPage">
									<i class="fa fa-lock"></i><span>비밀번호 변경</span>
								</a>
							</li>

							<li class="menu-item">
								<a class="menu-link ${activeMenu eq 'MYPOST' ? 'is-active' : ''}"
									href="${ctx}/myPostPage">
									<i class="fa fa-pencil-square-o"></i><span>내 글 보기</span>
								</a>
							</li>

							<li class="menu-item">
								<form action="${ctx}/member/withdraw" method="post"
									style="margin: 0;"
									onsubmit="return confirm('정말 탈퇴하시겠습니까?\n탈퇴 후에는 복구할 수 없습니다.');">
									<button type="submit" class="menu-btn danger">
										<i class="fa fa-sign-out"></i><span>회원 탈퇴</span>
									</button>
								</form>
							</li>
						</ul>
					</div>
				</div>

				<!-- RIGHT -->
				<div class="col-12 col-lg-8 mypage-col-right">
					<div class="login-box-clean mypage-right-card">
						<h5 style="margin-bottom: 24px;">내 정보</h5>

						<form id="mypageForm" action="${ctx}/member/profile" method="post">
							<input type="hidden" id="temporaryProfileImageToken"
								name="temporaryProfileImageToken" value="" />

							<!-- ✅ 원본 값(프론트 비교용) -->
							<input type="hidden" id="originNicknameColor" value="${nickColorInit}">
							<input type="hidden" id="originBorderColor" value="${borderColorInit}">

							<!-- ✅ 현재 선택값(서버 바인딩용) -->
							<input type="hidden" id="nicknameColorInput" name="memberNicknameColor" value="${nickColorInit}">
							<input type="hidden" id="borderColorInput" name="memberProfileColor" value="${borderColorInit}">

							<!-- 아이디 -->
							<div class="split-pill" id="idPill">
								<div class="split-label">
									<span class="split-icon" aria-hidden="true">
										<svg viewBox="0 0 24 24">
											<path d="M20 21a8 8 0 0 0-16 0"></path>
											<circle cx="12" cy="8" r="4"></circle>
										</svg>
									</span>
									<span class="split-text">아이디</span>
								</div>
								<div class="split-value">
									<input id="idInput" type="text" value="${memberData.memberName}" readonly>
								</div>
							</div>

							<!-- 이메일 -->
							<div class="split-pill" id="emailPill">
								<div class="split-label">
									<span class="split-icon" aria-hidden="true">
										<svg viewBox="0 0 24 24">
											<path d="M4 6h16v12H4z"></path>
											<path d="m4 7 8 6 8-6"></path>
										</svg>
									</span>
									<span class="split-text">이메일</span>
								</div>
								<div class="split-value">
									<input id="emailInput" type="email" value="${memberData.memberEmail}" readonly>
								</div>
							</div>

							<!-- 닉네임 + 중복확인 -->
							<div class="split-row">
								<div class="split-pill split-pill--editable" id="nicknamePill">
									<div class="split-label">
										<span class="split-icon" aria-hidden="true">
											<svg viewBox="0 0 24 24">
												<rect x="3" y="5" width="18" height="14" rx="2"></rect>
												<circle cx="8.5" cy="12" r="2"></circle>
												<path d="M13 11h6"></path>
												<path d="M13 14h6"></path>
											</svg>
										</span>
										<span class="split-text">닉네임</span>
									</div>
									<div class="split-value">
										<input id="nicknameInput" name="memberNickname" type="text"
											value="${memberData.memberNickname}" readonly>
									</div>
								</div>

								<button id="nickCheckBtn" class="nick-check-btn disabled-btn"
									type="button">중복 확인</button>
							</div>

							<div class="msg-area" id="nicknameMsg"></div>

							<div class="msg-area msg-info" id="nickCostMsg" style="display: none;">
								※ 닉네임 변경 시 <b>300원</b>이 차감됩니다.
							</div>

							<!-- ✅ 꾸미기 섹션 -->
							<div class="decorate-wrap" id="decorateWrap">
								<div class="decorate-headline">꾸미기</div>

								<!-- 닉네임 꾸미기 -->
								<div class="decorate-card" id="decorNickCard" data-kind="nickname">
									<div class="decorate-top">
										<div class="decorate-name">닉네임 꾸미기</div>
										<div class="decorate-price">200원</div>
									</div>

									<div class="decorate-body">
										<div class="decorate-presets" data-kind="nickname">
											<button type="button" class="color-chip chip-none" data-color="" disabled>기본</button>
											<button type="button" class="color-chip" data-color="#e53637" style="--chip:#e53637" title="빨강" disabled></button>
											<button type="button" class="color-chip" data-color="#ff8a00" style="--chip:#ff8a00" title="주황" disabled></button>
											<button type="button" class="color-chip" data-color="#ffc107" style="--chip:#ffc107" title="노랑" disabled></button>
											<button type="button" class="color-chip" data-color="#25d366" style="--chip:#25d366" title="초록" disabled></button>
											<button type="button" class="color-chip" data-color="#3b82f6" style="--chip:#3b82f6" title="파랑" disabled></button>
											<button type="button" class="color-chip" data-color="#1e3a8a" style="--chip:#1e3a8a" title="남색" disabled></button>
											<button type="button" class="color-chip" data-color="#a855f7" style="--chip:#a855f7" title="보라" disabled></button>
										</div>

										<div class="decorate-custom">
											<input type="color" id="nickColorPicker" class="color-picker" value="#e53637" disabled>
											<button type="button" class="mini-btn custom-apply" data-kind="nickname" disabled>커스텀 적용</button>
										</div>

										<div class="decorate-preview">
											<span class="preview-label">미리보기</span>
											<span id="nickDecorPreview" class="preview-nickname">${memberData.memberNickname}</span>
										</div>
									</div>
								</div>

								<!-- 프로필 테두리 -->
								<div class="decorate-card" id="decorBorderCard" data-kind="border">
									<div class="decorate-top">
										<div class="decorate-name">프로필 테두리</div>
										<div class="decorate-price">200원</div>
									</div>

									<div class="decorate-body">
										<div class="decorate-presets" data-kind="border">
											<button type="button" class="color-chip chip-none" data-color="" disabled>기본</button>
											<button type="button" class="color-chip" data-color="#e53637" style="--chip:#e53637" title="빨강" disabled></button>
											<button type="button" class="color-chip" data-color="#ff8a00" style="--chip:#ff8a00" title="주황" disabled></button>
											<button type="button" class="color-chip" data-color="#ffc107" style="--chip:#ffc107" title="노랑" disabled></button>
											<button type="button" class="color-chip" data-color="#25d366" style="--chip:#25d366" title="초록" disabled></button>
											<button type="button" class="color-chip" data-color="#3b82f6" style="--chip:#3b82f6" title="파랑" disabled></button>
											<button type="button" class="color-chip" data-color="#1e3a8a" style="--chip:#1e3a8a" title="남색" disabled></button>
											<button type="button" class="color-chip" data-color="#a855f7" style="--chip:#a855f7" title="보라" disabled></button>
										</div>

										<div class="decorate-custom">
											<input type="color" id="borderColorPicker" class="color-picker" value="#e53637" disabled>
											<button type="button" class="mini-btn custom-apply" data-kind="border" disabled>커스텀 적용</button>
										</div>

										<div class="decorate-preview">
											<span class="preview-label">현재 선택</span>
											<span id="borderDecorSwatch" class="preview-swatch"></span>
										</div>
									</div>
								</div>

								<div class="msg-area msg-info" id="decorCostMsg" style="display:none;">
									※ 꾸미기 변경 시 항목당 <b>200원</b>이 차감됩니다.
								</div>
							</div>

							<!-- 보유 캐시 -->
							<div class="split-pill" id="cashPill">
								<div class="split-label">
									<span class="split-icon" aria-hidden="true">
										<svg viewBox="0 0 24 24">
											<path d="M4 7h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z"></path>
											<path d="M2 11h20"></path>
											<path d="M16 15h4"></path>
										</svg>
									</span>
									<span class="split-text">보유 캐시</span>
								</div>
								<div class="split-value">
									<input id="cashDisplay" type="text" value="${cashFmt}원" readonly>
									<input type="hidden" id="cashRaw" value="${cashSafe}">
								</div>
							</div>

							<!-- 비용 안내 박스 -->
							<div class="cost-box" id="costBox" style="display: none;">
								<div class="cost-row">
									<div class="label">닉네임 변경</div>
									<div class="value" id="costNick">0원</div>
								</div>
								<div class="cost-row">
									<div class="label">프로필 사진 변경</div>
									<div class="value" id="costProfile">0원</div>
								</div>
								<div class="cost-row">
									<div class="label">닉네임 꾸미기</div>
									<div class="value" id="costNickDecor">0원</div>
								</div>
								<div class="cost-row">
									<div class="label">프로필 테두리</div>
									<div class="value" id="costBorderDecor">0원</div>
								</div>
								<div class="cost-row">
									<div class="label">총 차감 캐시</div>
									<div class="value" id="costTotal">0원</div>
								</div>
								<div class="cost-row">
									<div class="label">차감 후 보유 캐시</div>
									<div class="value" id="cashAfter">-</div>
								</div>
								<div class="msg-area msg-error" id="cashWarn"
									style="display: none; margin-top: 10px;">보유 캐시를 확인해주세요.</div>
							</div>

							<div class="row" style="margin-top: 30px;" id="viewActions">
								<div class="col-md-6">
									<button id="editBtn" type="button" class="mypage-btn">내 정보 수정</button>
								</div>
								<div class="col-md-6">
									<a href="${ctx}/cash/charge" class="mypage-btn primary-red">캐시 충전</a>
								</div>
							</div>

							<div class="edit-actions" id="editActions" style="display: none;">
								<button id="saveBtn" type="button"
									class="mypage-btn primary-red disabled-btn">수정 완료</button>
								<button id="cancelBtn" type="button" class="mypage-btn">취소</button>
							</div>

						</form>
					</div>
				</div>

			</div>
		</div>
	</section>

	<%@ include file="/WEB-INF/common/footer.jsp"%>

	<!-- 확인 모달 -->
	<div id="modalBackdrop" class="modal-backdrop-custom">
		<div class="modal-box" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
			<div class="modal-title" id="modalTitle">정말 수정하시겠습니까?</div>
			<div class="modal-desc">수정 완료 시 캐시가 차감되며 되돌릴 수 없습니다.</div>

			<div class="modal-cost">
				<div class="row">
					<div class="l">닉네임 변경</div>
					<div class="r" id="mCostNick">0원</div>
				</div>
				<div class="row">
					<div class="l">프로필 사진 변경</div>
					<div class="r" id="mCostProfile">0원</div>
				</div>
				<div class="row">
					<div class="l">닉네임 꾸미기</div>
					<div class="r" id="mCostNickDecor">0원</div>
				</div>
				<div class="row">
					<div class="l">프로필 테두리</div>
					<div class="r" id="mCostBorderDecor">0원</div>
				</div>
				<div class="row"
					style="border-top: 1px solid rgba(255, 255, 255, 0.08); margin-top: 6px; padding-top: 10px;">
					<div class="l">총 차감 캐시</div>
					<div class="r" id="mCostTotal">0원</div>
				</div>
			</div>

			<div class="modal-actions">
				<button id="modalYesBtn" class="modal-btn yes" type="button">확인</button>
				<button id="modalNoBtn" class="modal-btn" type="button">취소</button>
			</div>
		</div>
	</div>

	<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
	<script src="${ctx}/js/bootstrap.min.js"></script>

	<!-- ✅ mypage 전용 분리 JS -->
	<script src="${ctx}/js/mypage.js"></script>

</body>
</html>
