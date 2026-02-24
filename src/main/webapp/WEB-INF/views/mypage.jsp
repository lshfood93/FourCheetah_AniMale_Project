<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<%-- 현재 앱 컨텍스트 경로를 공통으로 잡아둠
     (정적 리소스, 링크, form action 전부 여기 기준으로 맞추기 위해) --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 로그인 안 된 상태에서 마이페이지 접근하면 바로 로그인 페이지로 보냄
     마이페이지는 세션(memberId) 있는 사용자만 들어오게 막는 1차 가드 역할 --%>
<c:if test="${empty sessionScope.memberId}">
	<c:redirect url="${ctx}/login" />
</c:if>

<%-- =========================================================
   프로필 이미지 경로 보정
   ---------------------------------------------------------
   DB에 저장 형식이 섞여 있어서 여기서 한 번 정리해둠.

   1) 값이 비어있음
      -> 기본 프로필 이미지 사용

   2) '/...' 로 시작함 (신버전)
      -> DB에 경로까지 저장된 상태라서 ctx만 앞에 붙이면 됨

   3) 파일명만 저장됨 (구버전)
      -> '/uploads/profile/' 경로를 여기서 붙여서 완성

   이렇게 한 번 profileSrc로 통일해두면 아래 img src 쪽에서 분기 안 해도 됨.
   ========================================================= --%>
<c:choose>
	<c:when test="${empty memberData.memberProfileImage}">
		<c:set var="profileSrc" value="${ctx}/img/profile-default.jpg" />
	</c:when>
	<c:when test="${fn:startsWith(memberData.memberProfileImage, '/')}">
		<%-- 신버전: 이미 /uploads/profile/... 형태로 들어있는 경우 --%>
		<c:set var="profileSrc" value="${ctx}${memberData.memberProfileImage}" />
	</c:when>
	<c:otherwise>
		<%-- 구버전: 파일명만 저장된 경우라 업로드 경로를 붙여서 사용 --%>
		<c:set var="profileSrc" value="${ctx}/uploads/profile/${memberData.memberProfileImage}" />
	</c:otherwise>
</c:choose>

<%-- 캐시 값이 null이면 화면/계산에서 불편하니까 0으로 안전하게 맞춤 --%>
<c:set var="cashSafe" value="${empty memberData.memberCash ? 0 : memberData.memberCash}" />

<%-- 화면 표시용 캐시 포맷(천단위 콤마) --%>
<fmt:formatNumber value="${cashSafe}" type="number" var="cashFmt" />

<%-- 꾸미기 초기값 세팅
     null 그대로 넘기면 JS 비교나 스타일 적용에서 분기 늘어나서
     빈 문자열로 통일해 둠 --%>
<c:set var="nickColorInit" value="${empty memberData.memberNicknameColor ? '' : memberData.memberNicknameColor}" />
<c:set var="borderColorInit" value="${empty memberData.memberProfileColor ? '' : memberData.memberProfileColor}" />

<%-- 프로필 테두리 미리보기용 스타일 값
     값이 없으면 transparent로 넣어서 CSS 변수 적용 시 깨지지 않게 처리 --%>
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

<%-- 마이페이지 화면에서만 쓰는 전용 스타일
     공통 style.css와 분리해둬서 다른 페이지 영향 최소화 --%>
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

	<%-- 공통 헤더 include --%>
	<%@ include file="/WEB-INF/common/header.jsp"%>

	<%-- 서버에서 전달한 안내 메시지(경고/실패/알림)를 상단에 출력
	     c:out으로 출력해서 문자열 그대로 보여주고 HTML 해석은 막음 --%>
	<c:if test="${not empty msg}">
		<div class="container" style="margin-top: 18px;">
			<div class="alert alert-warning" style="border-radius: 14px;"><c:out value="${msg}" /></div>
		</div>
	</c:if>
	
	<div class="container mypage-title">
		<h1 class="mypage-title__h1">마이페이지</h1>
	</div>

	<section class="spad mypage-spad">
		<div class="container">
			<div class="row">

				<%-- =========================
				     왼쪽 영역
				     - 프로필 미리보기/업로드
				     - 사이드 메뉴(비번변경, 내글, 탈퇴)
				     ========================= --%>
				<div class="col-12 col-lg-4 mypage-col-left">
					<div class="login-box-clean mypage-side-card text-center">

						<%-- 프로필 이미지 래퍼
						     CSS 변수(--profile-border-color)로 현재 테두리색 바로 반영
						     처음엔 is-loading 상태로 시작해서 JS에서 로딩 완료 후 클래스 정리하는 흐름 --%>
						<div class="profile-img-wrap is-loading" id="profileWrap"
							style="--profile-border-color: ${borderColorStyle};">
							<img id="profilePreview" alt="프로필 이미지"
								data-real-src="<c:out value='${profileSrc}'/>"
								data-initial-src="<c:out value='${profileSrc}'/>"
								data-default-src="<c:out value='${ctx}/img/profile-default.jpg'/>"
								src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==">

							<%-- 실제 이미지 로딩 전 표시할 로더 UI
							     src는 1x1 투명 gif로 먼저 넣어두고 JS에서 data-real-src로 교체 --%>
							<div class="profile-loader" role="status" aria-live="polite">
								<div class="loader-bar" aria-hidden="true"></div>
								<div class="loader-text">이미지 불러오는 중</div>
							</div>
						</div>

						<%-- 파일 input은 숨기고 label을 버튼처럼 사용
						     초기에는 수정모드가 아니므로 disabled 스타일로 시작 --%>
						<label id="profileBtnLabel" class="mypage-btn profile-btn disabled-btn">
							<span class="btn-text">프로필 사진 변경</span>
							<input type="file" id="profileInput" accept="image/*" hidden>
						</label>

						<%-- 프로필 사진 변경 비용 안내
						     실제 변경 감지되었을 때 JS에서 표시/숨김 제어 --%>
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
								<%-- 탈퇴는 GET 링크가 아니라 POST form으로 처리
								     실수 클릭 방지용 confirm 1차 확인 포함 --%>
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

				<%-- =========================
				     오른쪽 영역
				     - 내 정보 표시/수정
				     - 닉네임/프로필/꾸미기 비용 계산
				     ========================= --%>
				<div class="col-12 col-lg-8 mypage-col-right">
					<div class="login-box-clean mypage-right-card">
						<h5 style="margin-bottom: 24px;">내 정보</h5>

						<%-- 메인 수정 폼
						     프로필 이미지 토큰, 꾸미기 색상 값, 최종 저장값까지 같이 전송 --%>
						<form id="mypageForm" action="${ctx}/member/profile" method="post">
							<%-- 프로필 업로드를 먼저 비동기로 처리했을 때 서버가 발급한 임시 토큰 저장용 --%>
							<input type="hidden" id="temporaryProfileImageToken"
								name="temporaryProfileImageToken" value="" />

							<%-- 수정 전 원본값
							     JS에서 변경 여부 판단(비용 계산/저장 버튼 활성화)할 때 비교 기준으로 사용 --%>
							<input type="hidden" id="originNicknameColor" value="${nickColorInit}">
							<input type="hidden" id="originBorderColor" value="${borderColorInit}">

							<%-- 현재 선택값(최종 서버 바인딩용)
							     꾸미기 UI에서 선택/변경할 때 이 hidden 값이 같이 바뀌고 submit 시 서버로 전달됨 --%>
							<input type="hidden" id="nicknameColorInput" name="memberNicknameColor" value="${nickColorInit}">
							<input type="hidden" id="borderColorInput" name="memberProfileColor" value="${borderColorInit}">

							<%-- 아이디: 식별값이라 읽기 전용
							     수정 대상이 아니므로 readonly input으로만 표시 --%>
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
									<input id="idInput" type="text" value="<c:out value='${memberData.memberName}'/>" readonly>
								</div>
							</div>

							<%-- 이메일: 현재 화면에서는 표시 전용(readonly)
							     나중에 이메일 수정 기능 붙이면 이 구간만 편집 가능 상태로 바꾸면 됨 --%>
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
									<input id="emailInput" type="email" value="<c:out value='${memberData.memberEmail}'/>" readonly>
								</div>
							</div>

							<%-- 닉네임 + 중복확인 버튼
							     수정모드 전에는 readonly/disabled 상태로 두고,
							     수정모드 진입 시 JS에서 입력/중복확인 버튼을 활성화하는 구조 --%>
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
										<input id="nicknameInput" name="memberNickname" type="text" value="<c:out value='${memberData.memberNickname}'/>" readonly>
									</div>
								</div>

								<button id="nickCheckBtn" class="nick-check-btn disabled-btn"
									type="button">중복 확인</button>
							</div>

							<%-- 닉네임 검증/중복확인 결과 메시지 출력 영역 (성공/실패 문구 공용) --%>
							<div class="msg-area" id="nicknameMsg"></div>

							<%-- 닉네임 변경 비용 안내
							     닉네임이 실제로 바뀐 경우에만 JS에서 노출하는 용도 --%>
							<div class="msg-area msg-info" id="nickCostMsg" style="display: none;">
								※ 닉네임 변경 시 <b>300원</b>이 차감됩니다.
							</div>

							<%-- =========================
							     꾸미기 섹션
							     - 닉네임 색상
							     - 프로필 테두리 색상
							     둘 다 비용 계산과 연결됨
							     ========================= --%>
							<div class="decorate-wrap" id="decorateWrap">
								<div class="decorate-headline">꾸미기</div>

								<%-- 닉네임 꾸미기 카드
								     프리셋 버튼 + color picker + 미리보기로 구성 --%>
								<div class="decorate-card" id="decorNickCard" data-kind="nickname">
									<div class="decorate-top">
										<div class="decorate-name">닉네임 꾸미기</div>
										<div class="decorate-price">200원</div>
									</div>

									<div class="decorate-body">
										<%-- 프리셋 색상 목록
										     data-kind / data-color 기준으로 JS가 선택 처리 --%>
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

										<%-- 커스텀 색상 입력
										     color picker에서 고른 값을 '커스텀 적용' 버튼으로 반영하는 흐름 --%>
										<div class="decorate-custom">
											<input type="color" id="nickColorPicker" class="color-picker" value="#e53637" disabled>
											<button type="button" class="mini-btn custom-apply" data-kind="nickname" disabled>커스텀 적용</button>
										</div>

										<%-- 닉네임 색상 미리보기
										     실제 입력값 바꾸기 전에 사용자 눈으로 확인하는 영역 --%>
										<div class="decorate-preview">
											<span class="preview-label">미리보기</span>
											<span id="nickDecorPreview" class="preview-nickname"><c:out value="${memberData.memberNickname}" /></span>
										</div>
									</div>
								</div>

								<%-- 프로필 테두리 꾸미기 카드
								     닉네임 꾸미기와 같은 패턴으로 구성 (프리셋/커스텀/미리보기) --%>
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

										<%-- 테두리는 색상칩(스와치) 형태로 현재 선택값만 간단히 보여줌 --%>
										<div class="decorate-preview">
											<span class="preview-label">현재 선택</span>
											<span id="borderDecorSwatch" class="preview-swatch"></span>
										</div>
									</div>
								</div>

								<%-- 꾸미기 항목 비용 안내
								     닉네임/테두리 각각 변경 여부에 따라 총액 계산할 때 참고용 안내 --%>
								<div class="msg-area msg-info" id="decorCostMsg" style="display:none;">
									※ 꾸미기 변경 시 항목당 <b>200원</b>이 차감됩니다.
								</div>
							</div>

							<%-- 보유 캐시 표시
							     화면 표시용(cashDisplay)과 계산용 원본값(cashRaw)을 분리해둠 --%>
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

							<%-- 비용 계산 요약 박스
							     수정모드에서 실제 변경사항이 생기면 JS에서 노출하고,
							     항목별 비용/총액/차감 후 잔액/부족 경고까지 여기서 한 번에 보여줌 --%>
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

							<%-- 기본 보기 모드 버튼 영역
							     - 내 정보 수정: 수정모드 진입
							     - 캐시 충전: 별도 페이지 이동 --%>
							<div class="row" style="margin-top: 30px;" id="viewActions">
								<div class="col-md-6">
									<button id="editBtn" type="button" class="mypage-btn">내 정보 수정</button>
								</div>
								<div class="col-md-6">
									<a href="${ctx}/cash/charge" class="mypage-btn primary-red">캐시 충전</a>
								</div>
							</div>

							<%-- 수정 모드 버튼 영역
							     처음에는 숨김 상태, 수정모드 진입 시 viewActions와 교체 표시 --%>
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

	<%-- 공통 푸터 include --%>
	<%@ include file="/WEB-INF/common/footer.jsp"%>

	<%-- 수정 완료 전 최종 확인 모달
	     비용 요약을 한 번 더 보여주고 사용자가 직접 확인/취소 선택하도록 함 --%>
	<div id="modalBackdrop" class="modal-backdrop-custom">
		<div class="modal-box" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
			<div class="modal-title" id="modalTitle">정말 수정하시겠습니까?</div>
			<div class="modal-desc">수정 완료 시 캐시가 차감되며 되돌릴 수 없습니다.</div>

			<%-- 모달 안 비용 요약
			     본문 costBox 값과 동일 내용을 최종 확인용으로 다시 보여주는 영역 --%>
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

	<%-- 공통 라이브러리 스크립트 --%>
	<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
	<script src="${ctx}/js/bootstrap.min.js"></script>

	<%-- 마이페이지 전용 동작 스크립트
	     수정모드 전환, 닉네임 체크, 비용 계산, 모달 제어 등 여기서 처리 --%>
	<script src="${ctx}/js/mypage.js"></script>

</body>
</html>