<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<%-- 
  공통 contextPath를 먼저 꺼내 둔다.
  이 페이지는 정적 리소스(css/js/favicon)와 form action, ajax/fetch 경로가 많아서
  ${ctx} 기준으로 통일해두면 경로 중복/누락을 줄이기 쉽다.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 
  수정 페이지 진입 타입 결정용 값.
  우선순위:
  1) URL 파라미터 param.type
  2) 없으면 requestScope.type (컨트롤러/액션이 넘긴 값)
  즉, 직접 파라미터로 들어오든 서버에서 모델로 넘기든 둘 다 대응하려는 구조.
--%>
<c:set var="typeRaw"
	value="${empty param.type ? requestScope.type : param.type}" />

<%-- 
  타입 문자열 대소문자 흔들림 방지.
  아래 비교문에서 'news', 'News', 'NEWS' 혼용 때문에 조건 누락되는 걸 막기 위해
  대문자로 정규화해서 비교 기준을 하나로 맞춘다.
--%>
<c:set var="type" value="${fn:toUpperCase(typeRaw)}" />

<%-- 
  header.jsp 등 공통 include에서 현재 페이지가 '수정 페이지'임을 감지하는 용도로 사용 가능.
  (예: 특정 UI 숨김, 스타일 분기, active 처리 보조 등)
--%>
<c:set var="isEditPage" value="true" />

<%-- 
  상단 메뉴 active 상태를 타입에 맞게 통일한다.
  NEWS 수정이면 NEWS 메뉴, BOARD 수정이면 COMMUNITY 메뉴를 활성화.
  (헤더에서 기대하는 activeMenu 값 규칙에 맞춰 대문자 기준으로 맞춤)
--%>
<c:if test="${type eq 'NEWS'}">
	<c:set var="activeMenu" value="NEWS" />
</c:if>
<c:if test="${type eq 'BOARD'}">
	<c:set var="activeMenu" value="COMMUNITY" />
</c:if>

<%-- 
  핵심 바인딩 정리:
  서버에서 NEWS 수정일 때는 newsData, BOARD 수정일 때는 boardData를 넘기고 있으므로
  JSP 내부에서는 이를 post 라는 공통 이름으로 통일해서 사용한다.
  
  장점:
  - 아래 폼/UI 코드가 타입별 DTO 이름에 덜 의존함
  - 화면 템플릿 재사용/가독성 향상
--%>
<c:choose>
	<c:when test="${type eq 'NEWS'}">
		<c:set var="post" value="${requestScope.newsData}" />
	</c:when>
	<c:when test="${type eq 'BOARD'}">
		<c:set var="post" value="${requestScope.boardData}" />
	</c:when>
</c:choose>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 수정</title>

<%-- 
  CKEditor 5 커스텀 빌드 로드.
  뉴스/게시글 수정 본문 textarea를 에디터로 바꿔주는 핵심 스크립트.
  버전 쿼리스트링은 캐시 무효화(브라우저가 이전 파일을 계속 쓰는 문제 방지) 용도.
--%>
<script src="${ctx}/js/ckeditor.js?v=20260102_6"></script>

<%-- 파비콘/아이콘/공통 스타일 경로도 ctx 기준으로 통일 --%>
<link rel="icon" type="image/png" href="${ctx}/favicon.png">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">

<link
	href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap"
	rel="stylesheet">
<link
	href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap"
	rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* 
  수정 페이지에서는 상단 검색 UI가 불필요하고 레이아웃도 어수선해질 수 있어서 숨김 처리.
  공통 헤더를 그대로 쓰되 이 페이지에서만 필요한 최소 UI만 남기는 목적.
*/
.header__right .search-switch, .search-model, .fa-search {
	display: none !important;
}

/* 
  뉴스 썸네일 미리보기 박스
  - 고정 비율(3:4) 유지
  - 이미지가 없어도 박스 형태는 유지
  - FileReader로 선택한 이미지가 즉시 들어오는 자리
*/
.preview-box {
	aspect-ratio: 3/4;
	background: #1e1e30;
	border-radius: 16px;
	border: 1px solid rgba(255, 255, 255, 0.15);
	display: flex;
	align-items: center;
	justify-content: center;
	overflow: hidden;
}

/* 
  실제 미리보기 이미지 요소
  처음에는 숨겨두고(이미지 없을 수 있으므로),
  기존 썸네일/새 파일 선택 시 JS에서 src 지정 + display:block 처리
*/
.preview-img {
	width: 100%;
	height: 100%;
	object-fit: contain;
	display: none;
}

/* 
  관리자 수정 폼 라벨/입력 기본 스타일
  공통 dark 배경 위에서 폼 가독성을 확보하기 위해 label은 흰색,
  입력창은 흰 배경으로 대비를 줌.
*/
.admin-form label {
	color: #ffffff !important;
	font-weight: 600;
}

.admin-form .form-control {
	background: #fff;
	border-radius: 8px;
}

/* 
  기본 file input은 스타일링이 어려워서 숨기고,
  label을 버튼처럼 꾸며 클릭 시 file input을 대신 트리거하는 구조로 사용.
*/
.thumb-btn {
	background: #e53637;
	color: #fff;
	padding: 8px 16px;
	border-radius: 6px;
	cursor: pointer;
	font-size: 14px;
	display: inline-block;
	margin-right: 12px;
}

/* 실제 파일 input은 숨김 */
.thumb-file {
	display: none;
}

/* 선택한 파일명 표시 영역 */
.thumb-filename {
	color: rgba(255, 255, 255, 0.85);
	font-size: 14px;
	vertical-align: middle;
}

/* 
  썸네일 되돌리기 버튼
  새 파일을 골랐다가 취소하고 '원래 썸네일'로 되돌릴 때 사용.
*/
.thumb-reset-btn {
	background: #2b2b3c;
	color: #fff;
	padding: 8px 14px;
	border-radius: 6px;
	border: 1px solid rgba(255, 255, 255, 0.18);
	cursor: pointer;
	font-size: 13px;
	display: inline-block;
}

.thumb-reset-btn:hover {
	background: #35354a;
}

/* 
  CKEditor 편집 영역 글자색 강제 지정
  다크 테마 페이지 위에 올라가도 에디터 내부 본문은 흰 바탕 기준으로 읽기 쉽게 검정 글자로 유지.
*/
.ck-editor__editable, .ck-editor__editable * {
	color: #000 !important;
}

.ck-content, .ck-content * {
	color: #000 !important;
}

/* placeholder는 본문 텍스트와 구분되도록 회색 */
.ck-editor__editable.ck-placeholder::before {
	color: #888 !important;
}

/* 저장/취소 버튼 스타일 */
.btn-submit {
	background: #e53637;
	color: #fff;
	padding: 10px 24px;
	border-radius: 6px;
	border: none;
}

.btn-cancel {
	background: #444;
	color: #fff;
	padding: 10px 24px;
	border-radius: 6px;
}

/* 버튼 묶음 우측 정렬 */
.form-actions {
	display: flex;
	justify-content: flex-end;
	gap: 10px;
	margin-top: 24px;
}

/* 권한 부족/잘못된 접근 안내 박스 */
.access-deny-box {
	background: rgba(0, 0, 0, 0.25);
	border: 1px solid rgba(255, 255, 255, 0.15);
	border-radius: 12px;
	padding: 22px;
	color: #fff;
}

/* 썸네일 미리보기 보조 설명 */
.preview-help {
	color: rgba(255, 255, 255, 0.75);
	font-size: 13px;
	margin-top: 10px;
}

/* 
  관련 애니 검색 입력 + 드롭다운 묶음
  드롭다운(.anime-search-result)을 absolute로 띄우기 위해 래퍼를 relative로 설정.
*/
.related-wrap {
	margin-top: 24px;
	position: relative;
}

/* 
  관련 애니 자동완성 결과 드롭다운
  - 입력창 바로 아래에 떠야 하므로 absolute
  - z-index 높여 다른 요소 위로 표시
  - 내부 스크롤 지원
*/
.anime-search-result {
	position: absolute;
	top: calc(100% + 6px);
	left: 0;
	right: 0;
	background: rgba(20, 20, 35, 0.98);
	border: 1px solid rgba(255, 255, 255, 0.12);
	border-radius: 12px;
	box-shadow: 0 12px 30px rgba(0, 0, 0, 0.35);
	max-height: 280px;
	overflow: auto;
	display: none;
	z-index: 9999;
	padding: 6px;
	backdrop-filter: blur(6px);
}

/* 결과 항목 1개 스타일 */
.anime-search-result li {
	padding: 10px 12px;
	border-radius: 10px;
	cursor: pointer;
	color: #fff;
	display: flex;
	align-items: center;
	gap: 10px;
	user-select: none;
}

/* 마우스 hover / 키보드 active 선택 상태 */
.anime-search-result li:hover, .anime-search-result li.is-active {
	background: rgba(229, 54, 55, 0.18);
	outline: 1px solid rgba(229, 54, 55, 0.25);
}

/* 힌트용 항목(검색중/결과없음 등)은 클릭 대상이 아니므로 별도 스타일 */
.anime-search-result li.is-hint {
	cursor: default;
	background: transparent !important;
	outline: none !important;
}

/* 검색 상태 문구(검색 중..., 결과 없음 등) */
.anime-search-hint {
	padding: 10px 12px;
	color: rgba(255, 255, 255, 0.7);
	font-size: 13px;
}

/* 결과 아이템 썸네일 */
.anime-thumb {
	width: 34px;
	height: 46px;
	border-radius: 8px;
	object-fit: cover;
	background: rgba(255, 255, 255, 0.08);
	border: 1px solid rgba(255, 255, 255, 0.12);
	flex: 0 0 auto;
}

/* 제목 + 메타(연도/분기) 영역 */
.anime-meta {
	display: flex;
	flex-direction: column;
	min-width: 0;
	flex: 1;
}

/* 제목이 길어도 한 줄 말줄임 처리 */
.anime-title {
	font-weight: 700;
	font-size: 14px;
	line-height: 1.1;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

/* 연도/분기 badge 묶음 */
.anime-sub {
	display: flex;
	gap: 6px;
	margin-top: 6px;
	flex-wrap: wrap;
}

/* badge 스타일 */
.anime-sub .badge {
	font-size: 12px;
	padding: 2px 8px;
	border-radius: 999px;
	background: rgba(255, 255, 255, 0.10);
	color: rgba(255, 255, 255, 0.9);
	border: 1px solid rgba(255, 255, 255, 0.10);
}

/* 
  CKEditor 편집 영역 높이 보정
  - 너무 작으면 본문 수정이 불편하므로 최소 높이 확보
  - 너무 길면 페이지 전체가 과도하게 길어지므로 최대 높이 + 내부 스크롤
*/
.ck-editor__editable {
	min-height: 200px !important;
	max-height: 600px;
	overflow-y: auto;
}

/* 
  CKEditor가 만드는 figure.image / figcaption 레이아웃 보정
  이미지 삽입 후 캡션 간격/크기/정렬이 페이지 스타일과 충돌하지 않도록 정리
*/
.ck-content figure.image {
	display: table;
	margin: 0;
	max-width: 100%;
}

.ck-content figure.image>img {
	display: block;
	max-width: 100%;
	height: auto;
}

.ck-content figure.image>figcaption {
	padding: 4px 0 !important;
	line-height: 1.2 !important;
	font-size: 13px !important;
	text-align: center;
	min-height: 0 !important;
	margin: 0 !important;
	color: #666 !important;
}
</style>
</head>

<body>
	<%@ include file="/WEB-INF/common/header.jsp"%>

	<c:choose>

		<%-- 
		  NEWS 수정 분기
		  권한 정책:
		  - 로그인 + ADMIN만 수정 가능
		--%>
		<c:when test="${type eq 'NEWS'}">
			<c:choose>
				<c:when test="${not empty sessionScope.memberId and sessionScope.memberRole eq 'ADMIN'}">

					<section class="anime-details spad">
						<div class="container">
							<div class="row">

								<%-- 좌측: 썸네일 미리보기 영역 --%>
								<div class="col-lg-3">
									<div class="preview-box">
										<img id="thumbPreviewImg" class="preview-img" alt="thumbnail preview">
									</div>
									<div class="preview-help">썸네일을 변경하면 즉시 반영됩니다.</div>
								</div>

								<%-- 우측: 실제 수정 폼 --%>
								<div class="col-lg-9">
									<h3 style="color: #fff;">뉴스 수정</h3>

									<form class="admin-form" method="post"
										action="${ctx}/newsEdit"
										enctype="multipart/form-data">

										<%-- 
										  수정 대상 뉴스 PK.
										  서버가 어떤 뉴스를 업데이트할지 식별하는 필수 hidden 값.
										--%>
										<input type="hidden" name="newsId" value="<c:out value='${post.newsId}'/>">
										
										<%-- 
										  관련 애니 ID hidden 값
										  - 처음에는 기존값 유지
										  - 자동완성 검색에서 항목 선택 시 JS가 이 값을 갱신
										  화면에는 제목을 보여주고, 실제 저장용 키는 animeId를 사용.
										--%>
										<input type="hidden" name="animeId" id="animeIdHidden"
											value="<c:out value='${post.animeId}'/>">
										
										<%-- 
										  기존 이미지 경로 보관용 hidden
										  새 파일 업로드가 없을 때 서버에서 기존 썸네일/이미지를 유지하는 판단에 사용.
										  (특히 thumb reset / 미선택 저장 시 유용)
										--%>
										<input type="hidden" name="existingThumbUrl" id="existingThumbUrl"
											value="<c:out value='${post.newsThumbnailUrl}'/>">
										<input type="hidden" name="existingImageUrl" id="existingImageUrl"
											value="<c:out value='${post.newsImageUrl}'/>">

										<div class="form-group">
										    <label>제목</label>
										    <input type="text" class="form-control" name="newsTitle" value="<c:out value='${post.newsTitle}'/>">
										</div>

										<div class="form-group">
											<label>썸네일</label><br>

											<%-- label 클릭으로 숨겨진 file input 선택창 열기 --%>
											<label class="thumb-btn" for="thumbFile">파일 선택</label>

											<%-- 선택된 파일명 표시 --%>
											<span class="thumb-filename" id="thumbFileName"></span>

											<%-- 새 파일 선택 후 원래 썸네일로 되돌릴 수 있는 버튼 (JS가 필요 시 노출) --%>
											<button type="button" id="thumbResetBtn" class="thumb-reset-btn" style="display: none;">되돌리기</button>

											<%-- 실제 업로드 input (숨김) --%>
											<input type="file" id="thumbFile" name="thumbFile" class="thumb-file" accept="image/*">
										</div>
										

										<div class="form-group">
											<label>상세 내용</label>
											<%-- 
											  CKEditor 대상 textarea.
											  본문은 c:out으로 출력해 HTML 이스케이프된 상태로 넣고,
											  JS에서 필요한 이미지 src 경로 보정 후 에디터 초기화.
											--%>
											<textarea id="editor" name="newsContent"><c:out value="${post.newsContent}" /></textarea>
										</div>
										
										<div class="related-wrap">
											<label style="color: #fff;">관련 애니</label>
											<%-- 
											  사용자에게는 제목 검색 입력 UI 제공.
											  실제 저장 값은 hidden animeId 이고, 이 입력창은 검색/선택용 표시값 역할.
											--%>
										<input type="text" id="animeSearchInput" class="form-control"
											placeholder="애니 제목을 입력하세요" autocomplete="off"
											value="<c:out value='${post.animeTitle}'/>">
											<ul id="animeSearchResult" class="anime-search-result"></ul>
										</div>

										<%-- 
										  취소 시 돌아갈 뉴스 상세 URL 생성.
										  c:url + c:param로 파라미터 인코딩/경로 결합을 안전하게 처리.
										--%>
										<c:url var="newsDetailUrl" value="/newsDetail">
											<c:param name="newsId" value="${post.newsId}" />
										</c:url>
										
										<div class="form-actions">
											<button type="submit" class="btn-submit">수정 완료</button>
											<a href="${newsDetailUrl}" class="btn-cancel">취소</a>
										</div>

									</form>
								</div>

							</div>
						</div>
					</section>

				</c:when>

				<c:otherwise>
					<%-- 관리자 권한이 아니면 접근 차단 안내 --%>
					<section class="anime-details spad">
						<div class="container">
							<div class="access-deny-box">
								<p>뉴스 작성/수정은 관리자만 가능합니다.</p>
							</div>
						</div>
					</section>
				</c:otherwise>
			</c:choose>
		</c:when>

		<%-- 
		  BOARD 수정 분기
		  권한 정책:
		  1) 로그인 필요
		  2) ADMIN 또는 본인 작성자만 수정 가능
		--%>
		<c:when test="${type eq 'BOARD'}">
			<c:choose>
				<c:when test="${not empty sessionScope.memberId}">

					<%-- 
					  수정 가능 여부 계산:
					  - 관리자면 가능
					  - 아니면 세션 사용자 ID와 게시글 작성자 ID가 같을 때만 가능
					--%>
					<c:set var="canEdit"
						value="${sessionScope.memberRole eq 'ADMIN' or sessionScope.memberId eq post.memberId}" />

					<c:choose>
						<c:when test="${canEdit}">

							<section class="anime-details spad">
								<div class="container">

									<form class="admin-form" method="post"
										action="${ctx}/boardEdit">

										<h3 style="color: #fff;">게시글 수정</h3>

										<%-- 
										  수정 대상 게시글 PK + 카테고리 유지값
										  카테고리는 서버에서 수정 후 리다이렉트/검증 시 필요한 경우를 대비해 함께 전송.
										--%>
										<input type="hidden" name="boardId" value="<c:out value='${post.boardId}'/>">
										<input type="hidden" name="boardCategory" value="<c:out value='${post.boardCategory}'/>">

										<div class="form-group">
											<label>게시글 제목</label>
											<input type="text" class="form-control" name="boardTitle" value="<c:out value='${post.boardTitle}'/>">
										</div>

										<div class="form-group">
											<label>텍스트 내용</label>
											<%-- BOARD용 CKEditor 대상 textarea --%>
											<textarea id="boardEditor" name="boardContent"><c:out value="${post.boardContent}" /></textarea>
										</div>

										<%-- 취소 시 게시글 상세로 복귀 --%>
										<c:url var="boardDetailUrl" value="/boardDetail">
											<c:param name="boardId" value="${post.boardId}" />
										</c:url>
										
										<div class="form-actions">
											<button type="submit" class="btn-submit">수정 완료</button>
											<a href="${boardDetailUrl}" class="btn-cancel">취소</a>
										</div>

									</form>

								</div>
							</section>

						</c:when>

						<c:otherwise>
							<%-- 로그인은 했지만 권한 없음 (관리자/작성자 아님) --%>
							<section class="anime-details spad">
								<div class="container">
									<div class="access-deny-box">
										<p>게시글 수정은 관리자 또는 본인 작성자만 가능합니다.</p>
									</div>
								</div>
							</section>
						</c:otherwise>
					</c:choose>

				</c:when>

				<c:otherwise>
					<%-- 비로그인 상태 접근 차단 --%>
					<section class="anime-details spad">
						<div class="container">
							<div class="access-deny-box">
								<p>게시글 수정은 로그인 후 가능합니다.</p>
							</div>
						</div>
					</section>
				</c:otherwise>
			</c:choose>
		</c:when>

		<c:otherwise>
			<%-- type 값이 NEWS/BOARD 둘 다 아닌 경우 --%>
			<section class="anime-details spad">
				<div class="container">
					<div class="access-deny-box">
						<p>잘못된 접근입니다.</p>
					</div>
				</div>
			</section>
		</c:otherwise>

	</c:choose>

	<%@ include file="/WEB-INF/common/footer.jsp"%>

	<%-- 공통 프론트 스크립트들도 ctx 기준으로 로드 --%>
	<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
	<script src="${ctx}/js/bootstrap.min.js"></script>
	<script src="${ctx}/js/player.js"></script>
	<script src="${ctx}/js/jquery.nice-select.min.js"></script>
	<script src="${ctx}/js/mixitup.min.js"></script>
	<script src="${ctx}/js/jquery.slicknav.js"></script>
	<script src="${ctx}/js/owl.carousel.min.js"></script>
	<script src="${ctx}/js/main.js"></script>

	<script>
/*
  JS에서도 contextPath를 한 번만 정의해서 재사용한다.
  pageContext.request.contextPath를 JS 문자열 안에 매번 직접 쓰지 않고
  ctx 상수로 통일하면 경로 처리 함수/업로드 URL/fetch URL 작성이 깔끔해진다.
*/
const ctx = '${ctx}';

/*
  HTML 이스케이프 유틸
  드롭다운 검색 결과를 innerHTML로 그릴 때 제목/문자열에 특수문자가 포함되더라도
  DOM 깨짐/XSS 위험을 줄이기 위해 문자열을 안전하게 변환한다.
*/
function esc(s){
  return String(s ?? '').replace(/[&<>"']/g, m => ({
    '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
  }[m]));
}

/*
  이미지/리소스 경로 정규화 유틸
  목적:
  - DB/서버에서 내려오는 경로 형식이 제각각일 수 있음
    (절대 URL, /upload/..., upload/..., ctx 포함 경로 등)
  - 화면 표시용 src에 넣기 전에 현재 앱 컨텍스트(ctx) 기준으로 보정
  
  처리 케이스:
  1) data: URL => 그대로 사용 (미리보기 FileReader 결과)
  2) http/https 절대 URL => 그대로 사용
  3) 이미 ctx가 붙은 경로 => 그대로 사용
  4) ctx 없는 절대/상대 경로 => ctx 붙여서 사용
*/
function resolvePath(url){
  if (!url) return '';
  const u = String(url).trim();
  if (!u) return '';

  if (/^data:/i.test(u)) return u;
  if (/^https?:\/\//i.test(u)) return u;

  if (ctx && (u === ctx || u.startsWith(ctx + '/'))) return u;

  const ctxNoSlash = ctx ? ctx.replace(/^\//,'') : '';
  if (ctxNoSlash && (u === ctxNoSlash || u.startsWith(ctxNoSlash + '/'))) return '/' + u;

  if (u.startsWith('/')) return ctx + u;
  return ctx + '/' + u;
}

/*
  기존 본문 HTML 안의 <img src="..."> 경로 보정
  배경:
  - 예전 데이터/환경에서 src가 upload/... 또는 /upload/... 형태로 저장됐을 수 있음
  - 수정 페이지에서 CKEditor에 그대로 넣으면 이미지가 안 뜰 수 있음
  
  그래서 에디터 초기화 전에 textarea 값(HTML 문자열) 안의 src를 ctx 기준으로 통일한다.
*/
function normalizeHtmlImageSrc(html){
  if (!html) return html;

  /* src="upload/..." -> src="{ctx}/upload/..." */
  html = html.replace(/src=(["'])(upload\/[^"']+)\1/gi, function(_, q, path){
    return 'src=' + q + (ctx + '/' + path) + q;
  });

  /* src="/upload/..." -> src="{ctx}/upload/..." */
  html = html.replace(/src=(["'])(\/upload\/[^"']+)\1/gi, function(_, q, path){
    return 'src=' + q + (ctx + path) + q;
  });

  /*
    src="animale/upload/..." 처럼 ctx의 슬래시(/) 없는 버전으로 저장된 경우 보정
    예: ctx='/animale' 일 때 'animale/upload/...' -> '/animale/upload/...'
  */
  const ctxNoSlash = ctx ? ctx.replace(/^\//,'') : '';
  if (ctxNoSlash) {
    const re = new RegExp('src=(["\'])(' + ctxNoSlash + '\\/upload\\/[^\\"\\\']+)\\1','gi');
    html = html.replace(re, function(_, q, path){
      return 'src=' + q + '/' + path + q;
    });
  }

  return html;
}

/*
  관련 애니 검색 API 응답 표준화
  백엔드/쿼리/매퍼에 따라 camelCase 또는 snake_case로 내려올 수 있으므로
  프론트에서는 하나의 구조(animeId, animeTitle, ...)로 통일해서 사용한다.
*/
function mapAnime(raw){
  const a = raw || {};
  return {
    animeId: (a.animeId ?? a.anime_id ?? ''),
    animeTitle: (a.animeTitle ?? a.anime_title ?? ''),
    animeThumbnailUrl: (a.animeThumbnailUrl ?? a.anime_thumbnail_url ?? ''),
    animeYear: (a.animeYear ?? a.anime_year ?? ''),
    animeQuarter: (a.animeQuarter ?? a.anime_quarter ?? '')
  };
}

document.addEventListener('DOMContentLoaded', function () {

  /*
    [1] textarea 내부 기존 HTML 본문 이미지 src 경로 보정
    NEWS/BOARD 각각 에디터 초기화 전에 먼저 처리해야,
    CKEditor가 로드된 순간 이미지가 정상 표시된다.
  */
  const newsTextArea = document.getElementById('editor');
  if (newsTextArea) newsTextArea.value = normalizeHtmlImageSrc(newsTextArea.value);

  const boardTextArea = document.getElementById('boardEditor');
  if (boardTextArea) boardTextArea.value = normalizeHtmlImageSrc(boardTextArea.value);

  /*
    [2] NEWS CKEditor 초기화
    이 페이지는 NEWS/BOARD 중 하나만 렌더될 수도 있으므로
    해당 요소가 있을 때만 에디터를 생성한다.
    
    simpleUpload.uploadUrl:
    에디터 본문 이미지 업로드 엔드포인트 (뉴스 타입 구분 포함)
  */
  const newsEditorEl = document.querySelector('#editor');
  if (newsEditorEl && window.ClassicEditor) {
    ClassicEditor.create(newsEditorEl, {
      simpleUpload: { uploadUrl: ctx + '/ContentImageUpload?type=news' }
    }).catch(error => console.error('[CKEditor NEWS 초기화 실패]', error));
  }

  /*
    [3] BOARD CKEditor 초기화
    뉴스와 동일한 구조지만 업로드 타입만 board로 분기.
  */
  const boardEditorEl = document.querySelector('#boardEditor');
  if (boardEditorEl && window.ClassicEditor) {
    ClassicEditor.create(boardEditorEl, {
      simpleUpload: { uploadUrl: ctx + '/ContentImageUpload?type=board' }
    }).catch(error => console.error('[CKEditor BOARD 초기화 실패]', error));
  }

  /*
    [4] 뉴스 썸네일 미리보기 관련 요소 참조
    BOARD 수정 화면에는 이 요소들이 없을 수 있으므로 null 체크 기반으로 동작.
  */
  const thumbInput = document.getElementById('thumbFile');
  const previewImg = document.getElementById('thumbPreviewImg');
  const fileNameEl = document.getElementById('thumbFileName');
  const existingThumbEl = document.getElementById('existingThumbUrl');
  const resetBtn = document.getElementById('thumbResetBtn');

  /*
    기존 썸네일 원본 경로 -> 화면 표시 가능한 경로로 보정
    (DB값이 상대/절대/ctx 포함 형태로 섞여 있어도 resolvePath로 통일)
  */
  const originalThumb = (existingThumbEl && existingThumbEl.value) ? existingThumbEl.value : '';
  const originalThumbFixed = originalThumb ? resolvePath(originalThumb) : '';

  /*
    수정 페이지 첫 진입 시 기존 썸네일이 있으면 미리보기 박스에 즉시 표시.
    이미지 로딩 실패(onerror) 시에는 이미지 요소를 숨겨 깨진 이미지 아이콘 노출을 방지.
  */
  if (previewImg && originalThumbFixed) {
    previewImg.src = originalThumbFixed;
    previewImg.style.display = 'block';
    previewImg.onerror = function () { this.style.display = 'none'; };

    /* 기존 썸네일이 있으면 되돌리기 버튼도 의미가 있으므로 표시 */
    if (resetBtn) resetBtn.style.display = 'inline-block';
  }

  /*
    새 썸네일 파일 선택 시 미리보기 갱신
    흐름:
    1) file input change
    2) 파일명 표시
    3) FileReader로 data URL 생성
    4) preview 이미지에 즉시 반영
  */
  if (thumbInput && previewImg) {
    thumbInput.addEventListener('change', function () {
      const file = this.files && this.files[0];
      if (!file) return;

      if (fileNameEl) fileNameEl.textContent = file.name;

      const reader = new FileReader();
      reader.onload = function (e) {
        previewImg.src = e.target.result;
        previewImg.style.display = 'block';

        /* 새 파일 미리보기는 로컬 data URL이므로 기존 onerror 핸들러 제거 */
        previewImg.onerror = null;

        if (resetBtn) resetBtn.style.display = 'inline-block';
      };
      reader.readAsDataURL(file);
    });
  }

  /*
    썸네일 '되돌리기' 버튼 동작
    목적:
    - 새로 고른 파일 선택을 취소하고
    - 원래 저장된 썸네일 미리보기 상태로 복귀
    
    주의:
    file input value를 비워야 실제 업로드 파일도 제거됨.
  */
  if (resetBtn && thumbInput && previewImg) {
    resetBtn.addEventListener('click', function(){
      thumbInput.value = '';
      if (fileNameEl) fileNameEl.textContent = '';

      if (originalThumbFixed) {
        previewImg.src = originalThumbFixed;
        previewImg.style.display = 'block';
        previewImg.onerror = function () { this.style.display = 'none'; };
      } else {
        /* 원래 썸네일 자체가 없던 케이스 */
        previewImg.removeAttribute('src');
        previewImg.style.display = 'none';
      }
    });
  }

  /*
    [5] 뉴스 관련 애니 검색 자동완성 요소 참조
    BOARD 수정 화면에서는 없을 수 있으므로 이후에도 존재 여부 체크하며 동작.
  */
  const input = document.getElementById('animeSearchInput');
  const resultBox = document.getElementById('animeSearchResult');
  const hiddenId = document.getElementById('animeIdHidden');

  /*
    자동완성 상태 변수
    - timer: 디바운스용 setTimeout 핸들
    - activeIndex: 키보드 방향키로 선택된 항목 인덱스
    - currentList: 현재 렌더된 결과 목록(정규화된 anime 객체 배열)
  */
  let timer = null;
  let activeIndex = -1;
  let currentList = [];

  /*
    드롭다운 숨김 + 상태 초기화
    검색어가 짧아졌을 때/밖 클릭/Escape/선택 완료 시 재사용.
  */
  function hideResult(){
    if (!resultBox) return;
    resultBox.style.display = 'none';
    resultBox.innerHTML = '';
    activeIndex = -1;
    currentList = [];
  }

  /* 결과 박스 표시 */
  function showResult(){
    if (!resultBox) return;
    resultBox.style.display = 'block';
  }

  /*
    드롭다운에 힌트 메시지 표시
    예: 검색 중..., 결과 없음, 오류 발생 등
    실제 결과 리스트와 동일한 박스에서 안내하기 위해 li 형태로 렌더링.
  */
  function renderHint(message){
    if (!resultBox) return;
    resultBox.innerHTML = '<li class="is-hint anime-search-hint">' + esc(message) + '</li>';
    showResult();
  }

  /*
    애니 선택 완료 처리
    - 사용자 입력창에는 제목 표시
    - 실제 저장용 hidden animeId에는 PK 저장
    - 드롭다운 닫기
  */
  function selectAnime(anime){
    if (!input || !hiddenId) return;
    input.value = anime.animeTitle;
    hiddenId.value = anime.animeId;
    hideResult();
  }

  /*
    키보드 내비게이션 active 항목 갱신
    - 기존 active 클래스 제거
    - 새 active 항목 지정
    - 결과 박스 스크롤 영역 밖에 있으면 자동 스크롤
  */
  function setActive(idx){
    if (!resultBox) return;
    const items = Array.from(resultBox.querySelectorAll('li[data-index]'));
    items.forEach(li => li.classList.remove('is-active'));
    activeIndex = idx;

    if (idx < 0) return;
    const target = resultBox.querySelector('li[data-index="' + idx + '"]');
    if (!target) return;
    target.classList.add('is-active');

    const top = target.offsetTop;
    const bottom = top + target.offsetHeight;

    /* 선택 항목이 보이지 않으면 드롭다운 내부 스크롤 위치 조정 */
    if (top < resultBox.scrollTop) resultBox.scrollTop = top - 6;
    if (bottom > resultBox.scrollTop + resultBox.clientHeight) {
      resultBox.scrollTop = bottom - resultBox.clientHeight + 6;
    }
  }

  /*
    문서 전체 클릭 이벤트:
    자동완성 박스 바깥을 클릭하면 드롭다운 닫기
    (입력창 또는 결과 박스 내부 클릭은 유지)
  */
  document.addEventListener('click', function(e) {
    if (!input || !resultBox) return;
    if (!resultBox.contains(e.target) && e.target !== input) hideResult();
  });

  /*
    뉴스 수정 화면에만 존재하는 자동완성 기능 본체
    input/resultBox 둘 다 있을 때만 이벤트를 바인딩한다.
  */
  if (input && resultBox) {

    /*
      입력창 포커스 시, 이전 검색 결과 DOM이 남아 있으면 다시 펼쳐 보여줌.
      (사용자가 다시 선택하거나 확인하기 편함)
    */
    input.addEventListener('focus', function(){
      if (resultBox.innerHTML.trim().length > 0) showResult();
    });

    /*
      입력 이벤트(자동완성 검색)
      동작 포인트:
      1) hidden animeId 초기화 (제목을 수정 중이면 기존 선택값은 더 이상 확정값이 아님)
      2) 디바운스 적용 (타이핑마다 즉시 요청 X)
      3) 2글자 미만이면 검색하지 않음
      4) fetch로 검색 API 호출 후 드롭다운 렌더
    */
    input.addEventListener('input', function () {
      const keyword = this.value.trim();

      <%-- 
        수정 페이지에서도 검색 입력을 시작하면 기존 관련 애니 선택을 다시 확인/선택하도록 유도하기 위해
        hidden animeId를 먼저 비운다.
        (보여지는 제목과 실제 저장될 animeId가 불일치하는 상태를 줄이려는 의도)
      --%>
      if (hiddenId) hiddenId.value = '';

      /* 이전 디바운스 타이머 제거 (마지막 입력 기준으로만 요청 보내기) */
      clearTimeout(timer);

      /* 검색어 너무 짧으면 결과 박스 닫기 */
      if (keyword.length < 2) {
        hideResult();
        return;
      }

      /* 요청 전 즉시 힌트 표시 */
      renderHint('검색 중...');

      /*
        디바운스(250ms):
        사용자가 타이핑하는 동안 불필요한 요청 폭주를 줄임.
      */
      timer = setTimeout(() => {
        fetch(ctx + '/newsAnimeSearch?keyword=' + encodeURIComponent(keyword))
          .then(res => res.json())
          .then(list => {
            resultBox.innerHTML = '';
            activeIndex = -1;

            if (!list || list.length === 0) {
              renderHint('검색 결과가 없습니다.');
              return;
            }

            /*
              응답 데이터를 프론트 표준 구조로 정규화하고,
              animeId 없는 비정상 항목은 제외.
            */
            currentList = list.map(mapAnime).filter(a => String(a.animeId).trim() !== '');

            if (currentList.length === 0) {
              renderHint('검색 결과 형식이 올바르지 않습니다.');
              return;
            }

            /*
              결과 항목 렌더링
              - innerHTML 문자열 조합 시 esc() 사용
              - 썸네일 경로는 resolvePath()로 보정
              - mousedown에서 선택 처리 (blur보다 먼저 잡기 위함)
            */
            currentList.forEach((anime, idx) => {
              const li = document.createElement('li');
              li.setAttribute('data-index', idx);

              const thumb = resolvePath(anime.animeThumbnailUrl);

              li.innerHTML =
                '<img class="anime-thumb" src="' + esc(thumb) + '" alt="">' +
                '<div class="anime-meta">' +
                  '<div class="anime-title">' + esc(anime.animeTitle) + '</div>' +
                  '<div class="anime-sub">' +
                    (anime.animeYear ? '<span class="badge">' + esc(anime.animeYear) + '</span>' : '') +
                    (anime.animeQuarter ? '<span class="badge">' + esc(anime.animeQuarter) + '</span>' : '') +
                  '</div>' +
                '</div>';

              /*
                mousedown을 쓰는 이유:
                click보다 먼저 실행되어 입력창 blur/드롭다운 닫힘보다 안정적으로 선택 처리 가능.
              */
              li.addEventListener('mousedown', function(ev){
                ev.preventDefault();
                selectAnime(anime);
              });

              /* 마우스로 훑을 때 active 상태도 함께 반영 */
              li.addEventListener('mouseenter', function(){ setActive(idx); });

              resultBox.appendChild(li);
            });

            showResult();

            /* 첫 번째 결과를 기본 active로 잡아 방향키/Enter UX 개선 */
            setActive(0);
          })
          .catch(() => {
            renderHint('검색 중 오류가 발생했습니다.');
          });
      }, 250);
    });

    /*
      자동완성 키보드 조작 지원
      - Escape: 닫기
      - ArrowDown/Up: active 이동
      - Enter: 현재 active 항목 선택
    */
    input.addEventListener('keydown', function(e) {
      if (resultBox.style.display !== 'block') return;

      const max = currentList.length - 1;

      if (e.key === 'Escape') {
        hideResult();
        return;
      }
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        if (max < 0) return;
        const next = (activeIndex < max) ? activeIndex + 1 : 0;
        setActive(next);
        return;
      }
      if (e.key === 'ArrowUp') {
        e.preventDefault();
        if (max < 0) return;
        const prev = (activeIndex > 0) ? activeIndex - 1 : max;
        setActive(prev);
        return;
      }
      if (e.key === 'Enter') {
        if (max < 0) return;
        e.preventDefault();

        /*
          activeIndex가 아직 없으면 첫 번째 항목 선택.
          키보드 사용자가 Enter만 눌러도 빠르게 선택 가능하게 함.
        */
        const pick = (activeIndex >= 0) ? activeIndex : 0;
        const anime = currentList[pick];
        if (anime) selectAnime(anime);
      }
    });
  }

});
</script>

</body>
</html>