<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<%-- 공통 컨텍스트 경로
     페이지 안의 정적 리소스(script/css/img), form action, 링크를 전부 같은 기준으로 맞추기 위해 사용.
     나중에 컨텍스트 경로가 바뀌어도 여기 값만 믿고 따라가면 되게 만드는 용도. --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 작성 화면 타입 결정
     - 우선순위: URL 파라미터(param.type) -> requestScope.type
     - 이유: 컨트롤러에서 넘겨준 값으로도 동작하고, 직접 쿼리스트링으로 들어와도 동일하게 처리되게 맞춤 --%>
<c:set var="typeRaw" value="${empty param.type ? requestScope.type : param.type}" />
<c:set var="type" value="${fn:toUpperCase(typeRaw)}" />

<%-- header/include 쪽에서 편집/작성 페이지 스타일 분기할 때 사용할 수 있게 유지하는 플래그 --%>
<c:set var="isEditPage" value="true" />

<%-- 게시판 카테고리 결정
     - 파라미터명은 boardCategory로 통일
     - 값 없으면 ANIME 기본값 사용
     - 대소문자 섞여 들어와도 비교 안정적으로 하려고 대문자화 --%>
<c:set var="boardCategoryRaw" value="${empty param.boardCategory ? requestScope.boardCategory : param.boardCategory}" />
<c:set var="boardCategory" value="${empty boardCategoryRaw ? 'ANIME' : fn:toUpperCase(boardCategoryRaw)}" />

<%-- header active 메뉴 하이라이트용 값
     header.jsp가 기대하는 값과 여기 값을 맞춰야 메뉴 강조가 정확히 들어감 --%>
<c:if test="${type eq 'NEWS'}">
	<c:set var="activeMenu" value="NEWS" />
</c:if>
<c:if test="${type eq 'BOARD'}">
	<c:set var="activeMenu" value="COMMUNITY" />
</c:if>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 작성</title>

<!-- CKEditor 5 커스텀 빌드 -->
<script src="${ctx}/js/ckeditor.js?v=20260102_6"></script>

<link rel="icon" type="image/png" href="${ctx}/favicon.png">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* 상단 검색 UI 숨김 (작성 화면에서는 검색보다 입력 집중이 우선) */
.header__right .search-switch, .search-model, .fa-search {
	display: none !important;
}

/* 뉴스 썸네일 미리보기 박스
   업로드 전/후 레이아웃이 흔들리지 않게 고정 비율(3:4)로 유지 */
.preview-box {
	aspect-ratio: 3/4;
	background: #1e1e30;
	border-radius: 16px;
	border: 1px solid rgba(255, 255, 255, .15);
	display: flex;
	align-items: center;
	justify-content: center;
	overflow: hidden;
}

.preview-img {
	width: 100%;
	height: 100%;
	object-fit: contain;
	display: none;
}

/* 작성 폼 기본 스타일 */
.admin-form label {
	color: #fff !important;
	font-weight: 600;
}

.admin-form .form-control {
	background: #fff;
	border-radius: 8px;
}

/* 파일 input 기본 UI 대신 커스텀 버튼 사용 */
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

.thumb-file {
	display: none;
}

.thumb-filename {
	color: rgba(255, 255, 255, .85);
	font-size: 14px;
	vertical-align: middle;
}

/* CKEditor 편집영역 글자색 강제 지정
   테마 영향으로 흰 글자 들어가서 입력 내용이 안 보이는 상황 방지 */
.ck-editor__editable, .ck-editor__editable *, .ck-content, .ck-content * {
	color: #000 !important;
}

.ck-editor__editable.ck-placeholder::before {
	color: #888 !important;
}

/* 하단 액션 버튼 */
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

.form-actions {
	display: flex;
	justify-content: flex-end;
	gap: 10px;
	margin-top: 24px;
}

/* 접근 권한 없을 때 안내 박스 */
.access-deny-box {
	background: rgba(0, 0, 0, .25);
	border: 1px solid rgba(255, 255, 255, .15);
	border-radius: 12px;
	padding: 22px;
	color: #fff;
}

.preview-help {
	color: rgba(255, 255, 255, .75);
	font-size: 13px;
	margin-top: 10px;
}

/* 관련 애니 검색 드롭다운 영역 */
.related-wrap {
	margin-top: 24px;
	position: relative;
}

/* 검색 결과 목록
   position:absolute로 입력창 바로 아래에 뜨게 하고,
   z-index를 높여서 다른 섹션 위로 자연스럽게 뜨게 함 */
.anime-search-result {
	position: absolute;
	top: calc(100% + 6px);
	left: 0;
	right: 0;
	background: rgba(20, 20, 35, .98);
	border: 1px solid rgba(255, 255, 255, .12);
	border-radius: 12px;
	box-shadow: 0 12px 30px rgba(0, 0, 0, .35);
	max-height: 280px;
	overflow: auto;
	display: none;
	z-index: 9999;
	padding: 6px;
	backdrop-filter: blur(6px);
}

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

.anime-search-result li:hover, .anime-search-result li.is-active {
	background: rgba(229, 54, 55, .18);
	outline: 1px solid rgba(229, 54, 55, .25);
}

/* 로딩/에러/결과없음 같은 힌트 문구 전용 아이템 */
.anime-search-result li.is-hint {
	cursor: default;
	background: transparent !important;
	outline: none !important;
}

.anime-search-hint {
	padding: 10px 12px;
	color: rgba(255, 255, 255, .7);
	font-size: 13px;
}

.anime-thumb {
	width: 34px;
	height: 46px;
	border-radius: 8px;
	object-fit: cover;
	background: rgba(255, 255, 255, .08);
	border: 1px solid rgba(255, 255, 255, .12);
	flex: 0 0 auto;
}

.anime-meta {
	display: flex;
	flex-direction: column;
	min-width: 0;
	flex: 1;
}

.anime-title {
	font-weight: 700;
	font-size: 14px;
	line-height: 1.1;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.anime-sub {
	display: flex;
	gap: 6px;
	margin-top: 6px;
	flex-wrap: wrap;
}

.anime-sub .badge {
	font-size: 12px;
	padding: 2px 8px;
	border-radius: 999px;
	background: rgba(255, 255, 255, .10);
	color: rgba(255, 255, 255, .9);
	border: 1px solid rgba(255, 255, 255, .10);
}

/* CKEditor 편집영역/이미지 캡션 표시 보정
   템플릿 기본 스타일과 충돌 날 때 줄높이/여백이 깨지는 현상 방지 */
.ck-editor__editable {
	min-height: 200px !important;
	max-height: 600px;
	overflow-y: auto;
}

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

/* 관련 애니 선택 상태 표시(입력창 오른쪽 아이콘) */
.anime-input-wrap {
	position: relative;
}

.anime-input-wrap .form-control {
	padding-right: 44px;
}

.anime-select-state {
	position: absolute;
	right: 12px;
	top: 50%;
	transform: translateY(-50%);
	width: 22px;
	height: 22px;
	border-radius: 999px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 13px;
	font-weight: 800;
	background: rgba(255, 255, 255, .14);
	border: 1px solid rgba(255, 255, 255, .14);
	color: rgba(255, 255, 255, .9);
	pointer-events: none;
}

/* 기본 상태: 아직 선택 안 됨 */
#relatedWrap .anime-select-state::before {
	content: "…";
}

/* 선택 완료 상태 */
#relatedWrap.is-picked .anime-select-state {
	background: rgba(80, 200, 120, .18);
	border-color: rgba(80, 200, 120, .35);
}

#relatedWrap.is-picked .anime-select-state::before {
	content: "✓";
}

/* 경고 상태(텍스트만 입력하고 선택 안 한 경우) */
#relatedWrap.is-invalid .anime-select-state {
	background: rgba(229, 54, 55, .16);
	border-color: rgba(229, 54, 55, .30);
}

#relatedWrap.is-invalid .anime-select-state::before {
	content: "!";
}

.anime-select-warn {
	margin-top: 8px;
	padding: 10px 12px;
	border-radius: 10px;
	background: rgba(229, 54, 55, .14);
	border: 1px solid rgba(229, 54, 55, .22);
	color: rgba(255, 255, 255, .92);
	font-size: 13px;
	line-height: 1.35;
	white-space: pre-line;
}

/* 선택 완료 카드 */
.anime-selected-card {
	margin-top: 10px;
	padding: 12px;
	border-radius: 12px;
	background: rgba(255, 255, 255, .06);
	border: 1px solid rgba(255, 255, 255, .14);
	display: flex;
	align-items: center;
	gap: 12px;
	color: rgba(255, 255, 255, .92);
}

.anime-selected-card .anime-thumb {
	width: 42px;
	height: 58px;
	border-radius: 10px;
}

.anime-selected-card .anime-title {
	color: rgba(255, 255, 255, .95) !important;
}

.anime-selected-card .anime-sub .badge {
	color: rgba(255, 255, 255, .92);
}

.picked-pill {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	margin-left: 8px;
	padding: 2px 8px;
	border-radius: 999px;
	font-size: 12px;
	background: rgba(80, 200, 120, .18);
	border: 1px solid rgba(80, 200, 120, .30);
	color: #fff;
}

.anime-clear-btn {
	margin-left: auto;
	background: rgba(229, 54, 55, .16);
	border: 1px solid rgba(229, 54, 55, .28);
	color: #fff;
	padding: 7px 10px;
	border-radius: 999px;
	font-size: 12px;
	cursor: pointer;
}

.anime-clear-btn:hover {
	background: rgba(229, 54, 55, .24);
}
</style>
</head>

<body>
<%@ include file="/WEB-INF/common/header.jsp" %>

<c:choose>

	<%-- NEWS 작성 화면
	     뉴스 작성은 관리자만 허용 --%>
	<c:when test="${type eq 'NEWS'}">
		<c:choose>
			<c:when test="${not empty sessionScope.memberId and sessionScope.memberRole eq 'ADMIN'}">

				<section class="anime-details spad">
					<div class="container">
						<div class="row">

							<div class="col-lg-3">
								<div class="preview-box">
									<img id="thumbPreviewImg" class="preview-img" alt="thumbnail preview">
								</div>
								<div class="preview-help">썸네일을 변경하면 즉시 반영됩니다.</div>
							</div>

							<div class="col-lg-9">
								<h3 style="color: #fff;">뉴스 작성</h3>

								<form class="admin-form" method="post"
									action="${ctx}/newsWrite"
									enctype="multipart/form-data">

									<%-- 관련 애니는 화면에 제목을 보여주고, 실제 저장값은 animeId(hidden)로 전송 --%>
									<input type="hidden" name="animeId" id="animeIdHidden">

									<div class="form-group">
										<label>제목</label>
										<input type="text" class="form-control" name="newsTitle">
									</div>

									<div class="form-group">
										<label>썸네일</label><br>
										<label class="thumb-btn" for="thumbFile">파일 선택</label>
										<span class="thumb-filename" id="thumbFileName"></span>
										<input type="file" id="thumbFile" name="thumbFile" class="thumb-file" accept="image/*">
									</div>

									<div class="form-group">
										<label>상세 내용</label>
										<textarea id="editor" name="newsContent"></textarea>
									</div>

									<%-- 관련 애니 검색/선택
									     중요 포인트:
									     텍스트만 입력했다고 저장되는 구조가 아니라,
									     반드시 목록 클릭으로 hidden animeId가 채워져야 '선택 완료'로 본다. --%>
									<div class="related-wrap" id="relatedWrap">
										<label style="color: #fff;">관련 애니</label>

										<div class="anime-input-wrap">
											<input type="text" id="animeSearchInput"
												class="form-control" placeholder="애니 제목을 입력하고 목록에서 선택하세요"
												autocomplete="off">
											<span id="animeSelectState" class="anime-select-state" aria-hidden="true"></span>
										</div>

										<%-- 제출 막힐 때(텍스트만 있고 선택 안 된 상태) 경고 표시 --%>
										<div id="animeSelectWarn" class="anime-select-warn" style="display: none;"></div>

										<%-- 자동완성 결과 리스트 --%>
										<ul id="animeSearchResult" class="anime-search-result"></ul>

										<%-- 선택 완료 후 요약 카드 --%>
										<div id="animeSelectedCard" class="anime-selected-card" style="display: none;"></div>
									</div>

									<div class="form-actions">
										<button type="submit" class="btn-submit">작성 완료</button>
										<a href="${ctx}/newsList" class="btn-cancel">취소</a>
									</div>

								</form>
							</div>

						</div>
					</div>
				</section>

			</c:when>

			<c:otherwise>
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

	<%-- BOARD 작성 화면
	     로그인 사용자만 허용 --%>
	<c:when test="${type eq 'BOARD'}">
		<c:choose>
			<c:when test="${not empty sessionScope.memberId}">

				<section class="anime-details spad">
					<div class="container">

						<form class="admin-form" method="post"
							action="${ctx}/boardWrite">

							<h3 style="color: #fff;">게시글 작성</h3>

							<%-- 작성 시작 시 확정된 카테고리 값을 그대로 전송
							     목록 복귀 링크에도 같은 값을 써서 흐름이 안 끊기게 맞춤 --%>
							<input type="hidden" name="boardCategory" value="${boardCategory}">

							<div class="form-group">
								<label>게시글 제목</label>
								<input type="text" class="form-control" name="boardTitle">
							</div>

							<div class="form-group">
								<label>텍스트 내용</label>
								<textarea id="boardEditor" name="boardContent"></textarea>
							</div>

							<div class="form-actions">
								<button type="submit" class="btn-submit">작성 완료</button>
								<a href="${ctx}/boardList?boardCategory=${boardCategory}" class="btn-cancel">취소</a>
								<%-- 취소해도 원래 보던 카테고리 목록으로 돌아가게 유지 --%>
							</div>

						</form>

					</div>
				</section>

			</c:when>

			<c:otherwise>
				<section class="anime-details spad">
					<div class="container">
						<div class="access-deny-box">
							<p>게시글 작성은 로그인 후 가능합니다.</p>
						</div>
					</div>
				</section>
			</c:otherwise>
		</c:choose>
	</c:when>

	<%-- type 값이 잘못 들어온 경우 보호 처리 --%>
	<c:otherwise>
		<section class="anime-details spad">
			<div class="container">
				<div class="access-deny-box">
					<p>잘못된 접근입니다.</p>
				</div>
			</div>
		</section>
	</c:otherwise>

</c:choose>

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
(function(){
  'use strict';

  /*
    이 파일 안에서 JS가 직접 URL 만들 때도 JSP와 같은 기준(ctx)을 쓰게 맞춘다.
    이렇게 해두면 /animale, /app 같은 컨텍스트가 바뀌어도 경로 깨질 일이 줄어든다.
  */
  var ctx = '${ctx}';

  /*
    썸네일 URL 정리 함수

    서버에서 들어오는 값이 매번 같은 형태가 아닐 수 있어서 여기서 한 번 정규화한다.
    - null/빈문자열           -> 기본 이미지
    - http/https 절대 URL     -> 그대로 사용
    - /images/... 형태        -> ctx 붙여서 사용
    - images/... 상대경로      -> ctx + '/' 붙여서 사용

    목적:
    화면 렌더 코드(renderList/renderSelectedCard) 쪽을 단순하게 유지하기 위해서.
  */
  function resolveThumb(url){
    var fallback = ctx + '/images/anisample/bleach.jpg';
    if (!url) return fallback;
    var u = String(url).trim();
    if (!u) return fallback;
    if (/^https?:\/\//i.test(u)) return u;
    if (u.charAt(0) === '/') return ctx + u;
    return ctx + '/' + u;
  }

  /*
    텍스트 escape 함수 (innerHTML 넣기 전 최소 방어)

    자동완성 목록/선택 카드 렌더링에서 문자열을 innerHTML로 조립하기 때문에,
    제목 등에 특수문자가 들어왔을 때 HTML로 해석되지 않게 막는다.

    여기서 막는 건 "클라이언트 렌더링 안전성"이고,
    저장/출력 XSS 방어 전체는 서버/템플릿 단에서도 같이 가야 한다.
  */
  function esc(s){
    var str = (s === null || s === undefined) ? '' : String(s);
    return str.replace(/[&<>"']/g, function(m){
      return ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;','\'':'&#39;'}[m]);
    });
  }

  /*
    관련 애니 검색 디버그 모드
    URL에 ?rel_debug=1 붙이면 콘솔 로그가 나오게 해둔 옵션.
    평소엔 조용히 돌고, 검색 중복/깜빡임 이슈 볼 때만 켜서 확인한다.
  */
  function hasRelDebug(){
    return (location.search.indexOf('rel_debug=1') >= 0);
  }

  /*
    한글 자모(조합 중간 단계)인지 대략 판별

    한글 IME 입력할 때 조합 중간에도 input 이벤트가 계속 발생해서
    너무 이른 검색 요청이 나갈 수 있다.
    그래서 '조합 중 + 마지막 글자가 자모 상태'면 검색을 잠깐 미룬다.
  */
  function endsWithJamo(text){
    if (!text) return false;
    var ch = text.charCodeAt(text.length - 1);
    return (ch >= 0x3131 && ch <= 0x318E);
  }

  document.addEventListener('DOMContentLoaded', function(){

    // =========================================================
    // 1) CKEditor 초기화
    // =========================================================
    // NEWS 작성 textarea (#editor)용 에디터
    // 화면에 해당 요소가 있을 때만 초기화해서 BOARD 화면에서도 오류 없이 재사용되게 한다.
    var newsEditorEl = document.querySelector('#editor');
    if (newsEditorEl && window.ClassicEditor) {
      ClassicEditor.create(newsEditorEl, {
        simpleUpload: { uploadUrl: ctx + '/ContentImageUpload?type=news' }
      }).catch(function(error){
        console.error('[CKEditor NEWS 초기화 실패]', error);
      });
    }

    // BOARD 작성 textarea (#boardEditor)용 에디터
    var boardEditorEl = document.querySelector('#boardEditor');
    if (boardEditorEl && window.ClassicEditor) {
      ClassicEditor.create(boardEditorEl, {
        simpleUpload: { uploadUrl: ctx + '/ContentImageUpload?type=board' }
      }).catch(function(error){
        console.error('[CKEditor BOARD 초기화 실패]', error);
      });
    }

    // =========================================================
    // 2) 뉴스 썸네일 파일 선택 시 미리보기
    // =========================================================
    var thumbInput = document.getElementById('thumbFile');
    var previewImg = document.getElementById('thumbPreviewImg');
    var fileNameEl = document.getElementById('thumbFileName');

    // NEWS 화면에만 존재하는 요소라 null 체크 후 바인딩
    if (thumbInput && previewImg) {
      thumbInput.addEventListener('change', function(){
        var file = this.files && this.files[0];
        if (!file) return;

        // 파일명 표시(사용자 확인용)
        if (fileNameEl) fileNameEl.textContent = file.name;

        // 실제 업로드 전에 로컬 미리보기
        var reader = new FileReader();
        reader.onload = function(e){
          previewImg.src = e.target.result;
          previewImg.style.display = 'block';
        };
        reader.readAsDataURL(file);
      });
    }

    // =========================================================
    // 3) 관련 애니 자동완성 UI (NEWS 전용)
    // =========================================================
    var input        = document.getElementById('animeSearchInput');
    var resultBox    = document.getElementById('animeSearchResult');
    var hiddenId     = document.getElementById('animeIdHidden');
    var relatedWrap  = document.getElementById('relatedWrap');
    var selectedCard = document.getElementById('animeSelectedCard');
    var warnEl       = document.getElementById('animeSelectWarn');

    /*
      BOARD 작성 화면에는 관련 애니 UI 자체가 없으므로 여기서 종료.
      이 페이지를 NEWS/BOARD 공용으로 쓰기 때문에 이런 조기 종료가 중요하다.
    */
    if (!input || !resultBox) return;

    /*
      같은 input에 이벤트가 중복으로 걸리는 상황 방지

      보통은 한 번만 실행되지만,
      include 재실행/스크립트 중복 로드/페이지 구조 변경 시 중복 바인딩이 생기면
      fetch가 두 번씩 나가고 목록이 깜빡이는 원인이 된다.
    */
    if (input.dataset.relAnimeBound === '1') return;
    input.dataset.relAnimeBound = '1';

    // 디버그 로그용 식별자 (여러 탭/새로고침 상황에서 로그 구분 편하게)
    var REL_DBG = hasRelDebug();
    var REL_ID  = Math.random().toString(16).slice(2, 7);
    function dbg(tag, extra){
      if (!REL_DBG) return;
      try { console.log('REL-ANIME[' + REL_ID + '] ' + tag, extra || ''); } catch(e) {}
    }

    // -------------------------
    // 검색 요청 관련 상태값
    // -------------------------
    var timer = null;              // debounce 타이머 ID
    var abortCtrl = null;          // 현재 fetch 취소용 controller
    var scheduledKeyword = '';     // setTimeout으로 예약된 키워드
    var inflight = false;          // fetch 진행 중 여부
    var inflightKeyword = '';      // 지금 요청 중인 키워드(중복요청 방지용)
    var lastSentAt = 0;            // 마지막 요청 시각 (ms)

    // -------------------------
    // 결과 목록/키보드 탐색 상태값
    // -------------------------
    var currentList = [];          // 현재 렌더된 검색 결과 배열
    var activeIndex = -1;          // ↑↓ 키보드 탐색 중 활성 아이템 인덱스

    // -------------------------
    // 입력값 추적 상태값
    // -------------------------
    var lastValue = input.value || ''; // 마지막으로 처리한 입력 raw 값
    var lastQuery = '';                // 마지막으로 서버에 보낸 trim된 검색어

    // -------------------------
    // 사용자 입력 흐름 제어용 상태값
    // -------------------------
    var composing = false;         // 한글 IME 조합 중 여부
    var hoveringResult = false;    // 마우스가 결과 목록 위에 올라가 있는지
    var pickingFromList = false;   // 목록 클릭으로 선택 처리 중인지
    var ignoreInputOnce = false;   // 선택 직후 발생하는 input 이벤트 1회 무시용

    // 현재 선택된 애니 제목 (입력창 내용이 바뀌었을 때 선택 해제 판단 기준)
    var pickedTitle = '';

    /*
      선택 직후 잠깐 락을 거는 이유
      - 목록 클릭으로 selectAnime() 실행
      - input.value가 바뀌면서 input 이벤트 연쇄
      - 바로 재검색이 걸리면 드롭다운이 다시 뜨거나 깜빡일 수 있음
      => 짧은 시간 동안 검색 흐름을 잠깐 막아서 UX 안정화
    */
    var lockUntil = 0;

    /*
      hover/선택 중에는 화면을 즉시 갈아끼우지 않고 임시 보관하는 값들

      이유:
      사용자가 마우스로 결과를 고르는 중인데 목록이 새 요청 응답으로 바뀌면
      클릭 대상이 밀려서 오동작하기 쉬움.
      그래서 그 순간 들어온 결과는 stash 해두고, 포인터가 빠져나갈 때 반영.
    */
    var pendingKeyword = '';
    var stashedList = null;
    var stashedQuery = '';

    function nowTs(){
      return (window.performance && performance.now) ? performance.now() : Date.now();
    }
    function isLocked(){ return nowTs() < lockUntil; }

    // 잠금 시간 연장 (디버그 로그 함께 남김)
    function lock(ms){
      lockUntil = nowTs() + ms;
      dbg('LOCK', { ms: ms });
    }

    /*
      debounce 타이머만 취소
      - 아직 서버로 나가지 않은 예약 요청만 제거
      - 이미 진행 중(fetch)인 요청은 건드리지 않음
    */
    function cancelTimerOnly(){
      if (timer) { clearTimeout(timer); timer = null; }
      scheduledKeyword = '';
    }

    /*
      진행 중인 fetch만 취소
      - 새로운 키워드가 들어왔을 때 오래된 응답이 늦게 도착해서 화면 덮어쓰는 문제 방지
    */
    function abortRequestOnly(){
      if (abortCtrl) { try { abortCtrl.abort(); } catch(e){} }
      abortCtrl = null;
      inflight = false;
      inflightKeyword = '';
    }

    // 예약 요청 + 진행 중 요청 전체 정리
    function cancelPending(){
      cancelTimerOnly();
      abortRequestOnly();
    }

    function showResult(){
      resultBox.style.display = 'block';
    }

    /*
      결과 목록 닫기 + 내부 상태 초기화

      단순히 display:none만 하면 이전 결과/currentList/activeIndex가 남아 있어서
      다시 열었을 때 키보드 탐색 인덱스나 클릭 대상이 꼬일 수 있으니 같이 비운다.
    */
    function hideResult(){
      resultBox.style.display = 'none';
      resultBox.innerHTML = '';
      currentList = [];
      activeIndex = -1;
      hoveringResult = false;
    }

    /*
      로딩중/결과없음/에러 같은 힌트 렌더
      이때 currentList를 비워두는 이유는 Enter 키로 잘못 선택되는 걸 막기 위해서.
    */
    function renderHint(message){
      currentList = [];
      activeIndex = -1;
      resultBox.innerHTML = '<li class="is-hint anime-search-hint">' + esc(message) + '</li>';
      showResult();
    }

    /*
      선택 상태 UI 토글
      - is-picked: 선택 완료
      - is-invalid: 경고 상태
      선택 완료로 바꿀 때는 이전 경고 상태를 같이 제거해서 상태 충돌을 막는다.
    */
    function setPickedUI(on){
      if (!relatedWrap) return;
      relatedWrap.classList.toggle('is-picked', !!on);
      relatedWrap.classList.remove('is-invalid');
    }

    // 제출 막힘 경고 표시
    function showWarn(msg){
      if (!warnEl || !relatedWrap) return;
      warnEl.textContent = msg;
      warnEl.style.display = 'block';
      relatedWrap.classList.add('is-invalid');
    }

    // 경고 숨김 + 상태 클래스 정리
    function hideWarn(){
      if (!warnEl || !relatedWrap) return;
      warnEl.style.display = 'none';
      warnEl.textContent = '';
      relatedWrap.classList.remove('is-invalid');
    }

    /*
      현재 선택된 관련 애니 초기화

      화면에 제목이 남아 있어도 hidden animeId가 없으면 서버 입장에선 "선택 안 됨" 상태라서,
      선택 해제 시에는 hidden + 카드 + 상태 클래스를 같이 정리해줘야 상태가 맞다.
    */
    function clearPickedUI(){
      if (hiddenId) hiddenId.value = '';
      pickedTitle = '';
      if (selectedCard){
        selectedCard.style.display = 'none';
        selectedCard.innerHTML = '';
      }
      setPickedUI(false);
      hideWarn();
    }

    /*
      선택 완료 카드 렌더

      사용자에게 '내가 뭘 선택했는지'를 명확히 보여줘서
      단순 텍스트 입력 상태와 실제 선택 완료 상태를 구분하기 쉽게 만든다.
    */
    function renderSelectedCard(anime){
      if (!selectedCard) return;

      var thumb = resolveThumb(anime.animeThumbnailUrl);
      selectedCard.innerHTML =
        '<img class="anime-thumb" src="' + thumb + '" alt="">' +
        '<div class="anime-meta">' +
          '<div class="anime-title">' + esc(anime.animeTitle) +
            '<span class="picked-pill">선택됨</span>' +
          '</div>' +
          '<div class="anime-sub">' +
            (anime.animeYear ? '<span class="badge">' + esc(anime.animeYear) + '</span>' : '') +
            (anime.animeQuarter ? '<span class="badge">' + esc(anime.animeQuarter) + '</span>' : '') +
          '</div>' +
        '</div>' +
        '<button type="button" class="anime-clear-btn" id="animeClearBtn">선택 해제</button>';

      selectedCard.style.display = 'flex';
    }

    /*
      목록에서 애니 선택 확정

      핵심 처리:
      1) input에는 사람이 읽는 제목 표시
      2) hiddenId에는 실제 저장할 animeId 저장
      3) 선택 직후 발생하는 input/fetch 연쇄는 잠깐 차단해서 깜빡임 방지
    */
    function selectAnime(anime){
      if (!hiddenId) return;

      // 지금은 "목록에서 선택 중"이라는 상태를 먼저 켠다.
      // (pointerdown/input/fetch 응답 등 이벤트가 이어서 들어와도 안정적으로 막기 위해)
      pickingFromList = true;
      lock(700);
      ignoreInputOnce = true;

      // 이전에 예약되었거나 진행 중이던 검색 흐름은 여기서 끊는다.
      cancelPending();
      pendingKeyword = '';
      stashedList = null;
      stashedQuery = '';

      // 화면 표시값(제목) + 서버 전송값(ID) 동시 확정
      input.value = anime.animeTitle;
      lastValue = input.value;
      hiddenId.value = anime.animeId;
      pickedTitle = anime.animeTitle;

      // 선택 완료 UI 반영
      renderSelectedCard(anime);
      setPickedUI(true);
      hideWarn();
      hideResult();

      // 이벤트 한 사이클 끝난 뒤 선택 중 플래그 해제
      setTimeout(function(){ pickingFromList = false; }, 0);
    }

    /*
      키보드 활성 항목 변경(↑/↓) + 목록 스크롤 보정
      activeIndex만 바꾸면 화면 밖으로 나가는 경우가 있어서 scrollTop도 함께 맞춘다.
    */
    function setActive(idx){
      var items = resultBox.querySelectorAll('li[data-index]');
      for (var i=0; i<items.length; i++) items[i].classList.remove('is-active');

      activeIndex = idx;
      if (idx < 0) return;

      var target = resultBox.querySelector('li[data-index="' + idx + '"]');
      if (!target) return;
      target.classList.add('is-active');

      var top = target.offsetTop;
      var bottom = top + target.offsetHeight;
      if (top < resultBox.scrollTop) resultBox.scrollTop = top - 6;
      if (bottom > resultBox.scrollTop + resultBox.clientHeight) {
        resultBox.scrollTop = bottom - resultBox.clientHeight + 6;
      }
    }

    /*
      검색 결과 목록 렌더

      여기서는 서버 응답 데이터를 그대로 믿고 쓰지 않고,
      표시용 텍스트는 esc(), 이미지 URL은 resolveThumb()를 거쳐서 화면에 넣는다.
    */
    function renderList(list, keyword){
      resultBox.innerHTML = '';
      currentList = [];
      activeIndex = -1;

      if (!list || list.length === 0){
        renderHint('검색 결과가 없습니다.');
        return;
      }

      currentList = list;
      for (var i=0; i<list.length; i++){
        var anime = list[i];
        var li = document.createElement('li');
        li.setAttribute('data-index', String(i));

        var thumb = resolveThumb(anime.animeThumbnailUrl);
        li.innerHTML =
          '<img class="anime-thumb" src="' + thumb + '" alt="">' +
          '<div class="anime-meta">' +
            '<div class="anime-title">' + esc(anime.animeTitle) + '</div>' +
            '<div class="anime-sub">' +
              (anime.animeYear ? '<span class="badge">' + esc(anime.animeYear) + '</span>' : '') +
              (anime.animeQuarter ? '<span class="badge">' + esc(anime.animeQuarter) + '</span>' : '') +
            '</div>' +
          '</div>';

        resultBox.appendChild(li);
      }

      showResult();

      // 첫 항목을 기본 활성화해두면 Enter로 바로 선택 가능해서 키보드 UX가 좋아짐
      setActive(0);
    }

    /*
      실제 서버 검색 요청(fetch)

      이 함수가 가장 꼬이기 쉬운 구간이라
      중복 요청 방지 / 오래된 응답 무시 / hover 중 렌더 보류 / 선택 상태 보호
      를 여러 겹으로 걸어둔 상태.
    */
    function doFetch(keyword){

      /*
        전역 중복 요청 가드
        같은 키워드가 아주 짧은 시간에 반복 들어오는 경우(중복 바인딩/이벤트 연쇄) 방지.
        전역(window)에 두는 이유는 같은 페이지 내 재초기화 상황에서도 가드가 유지되게 하려는 목적.
      */
      window.__REL_ANIME_GUARD__ = window.__REL_ANIME_GUARD__ || { k: '', t: 0 };
      var g = window.__REL_ANIME_GUARD__;
      var tnow = Date.now();
      if (g.k === keyword && (tnow - g.t) < 1200) return;
      g.k = keyword;
      g.t = tnow;

      // 같은 쿼리를 너무 짧은 간격으로 다시 보내는 것 방지
      var now = Date.now();
      if (keyword === lastQuery && (now - lastSentAt) < 1000) return;

      // 이미 같은 키워드 요청이 진행 중이면 새로 보낼 필요 없음
      if (inflight && inflightKeyword === keyword) return;

      /*
        다른 키워드 요청이 진행 중이면 이전 요청 취소
        이유: 이전 응답이 늦게 도착해서 최신 결과를 덮어쓰는 레이스 컨디션 방지
      */
      if (inflight && inflightKeyword !== keyword){
        if (abortCtrl) { try { abortCtrl.abort(); } catch(e){} }
        abortCtrl = null;
        inflight = false;
        inflightKeyword = '';
      }

      cancelPending();

      /*
        결과 목록 위에 포인터가 올라간 상태면 지금 화면을 갈아끼우지 않는다.
        사용자가 클릭하려는 순간 항목이 바뀌면 잘못 선택되기 쉬움.
      */
      if (hoveringResult){
        pendingKeyword = keyword;
        return;
      }

      // 이미 관련 애니를 선택 완료한 상태면 검색 요청 자체를 막음
      if (hiddenId && String(hiddenId.value || '').trim().length > 0) return;

      // 같은 쿼리 결과가 이미 화면에 떠 있으면 재렌더링 생략
      if (keyword === lastQuery && currentList.length > 0 && resultBox.style.display === 'block') return;

      // 아직 목록이 안 떠있으면 로딩 힌트 먼저 보여주기
      if (resultBox.style.display !== 'block' || currentList.length === 0){
        renderHint('검색 중...');
      }

      abortCtrl = new AbortController();
      inflight = true;
      inflightKeyword = keyword;

      lastQuery = keyword;
      lastSentAt = now;

      // 응답 도착 시점에 최신 요청인지 비교하기 위한 로컬 보관값
      var myQuery = keyword;
      var localCtrl = abortCtrl;

      fetch(ctx + '/newsAnimeSearch?keyword=' + encodeURIComponent(keyword), { signal: localCtrl.signal })
        .then(function(res){ return res.json(); })
        .then(function(list){

          /*
            요청 후 사용자가 더 입력해서 lastQuery가 바뀐 경우
            늦게 도착한 이전 응답은 버린다. (오래된 결과 덮어쓰기 방지)
          */
          if (myQuery !== lastQuery) return;

          // 응답 도착 전에 이미 항목 선택이 끝난 경우도 반영하지 않음
          if (hiddenId && String(hiddenId.value || '').trim().length > 0) return;

          /*
            아래 상태에서는 즉시 렌더하지 않고 stash에 저장
            - hoveringResult: 사용자가 목록을 보고 있음
            - pickingFromList: 클릭 선택 처리 중
            - isLocked(): 선택 직후 안정화 구간
          */
          if (hoveringResult || pickingFromList || isLocked()){
            stashedList = list || [];
            stashedQuery = myQuery;
            return;
          }

          renderList(list || [], myQuery);
        })
        .catch(function(err){
          // abort는 정상 흐름이라 에러 처리로 보지 않음
          if (err && err.name === 'AbortError') return;

          console.error('[NewsAnimeSearch 오류]', err);
          renderHint('검색 중 오류가 발생했습니다.');
        })
        .finally(function(){
          /*
            여러 요청이 빠르게 바뀌는 상황에서 finally가 늦게 실행될 수 있으므로,
            내가 시작한 요청(localCtrl)과 현재 abortCtrl이 같은 경우에만 상태 해제.
          */
          if (abortCtrl === localCtrl){
            abortCtrl = null;
            inflight = false;
            inflightKeyword = '';
          }
        });
    }

    /*
      debounce 예약 함수

      input 이벤트마다 바로 fetch하지 않고 250ms 기다렸다가 호출.
      이유:
      - 서버 요청 과다 방지
      - 한글 입력 중 조합 흐름 안정화
      - UX상 목록 깜빡임 감소
    */
    function scheduleSearch(keyword){
      var gg = window.__REL_ANIME_GUARD__;
      if (gg && gg.k === keyword && (Date.now() - gg.t) < 1200) return;

      if (timer && scheduledKeyword === keyword) return;
      if (inflight && inflightKeyword === keyword) return;

      cancelTimerOnly();
      scheduledKeyword = keyword;

      timer = setTimeout(function(){
        scheduledKeyword = '';
        doFetch(keyword);
      }, 250);
    }

    /*
      입력값 변경 처리 공통 함수

      input 이벤트에서 직접 모든 로직을 다 처리하면 조건이 많아질수록 읽기 힘들어져서
      한 곳으로 모아둔 함수.
      여기서 검색 시작/취소/선택 해제 여부를 정리한다.
    */
    function handleValueChanged(force){
      var raw = input.value || '';
      var keyword = raw.trim();

      // 선택 직후 잠금 구간 or 목록 선택 처리 중에는 재검색 흐름을 막고 값만 기록
      if (isLocked() || pickingFromList){
        lastValue = raw;
        return;
      }

      /*
        selectAnime()에서 input.value를 코드로 바꾼 직후에도 input 이벤트가 들어올 수 있다.
        그 1회는 의도된 값 세팅이므로 검색/초기화 로직을 태우지 않기 위해 무시한다.
      */
      if (ignoreInputOnce){
        ignoreInputOnce = false;
        lastValue = raw;
        return;
      }

      // 실질적으로 값이 안 바뀌었으면 재처리하지 않음
      if (!force && raw === lastValue) return;
      lastValue = raw;

      /*
        이미 선택된 상태에서 입력창 텍스트를 수정하면
        hidden animeId와 표시 텍스트가 불일치할 수 있으므로 선택 상태를 해제한다.
        (예: '나루토' 선택해놓고 텍스트를 '원피스'로 바꿨는데 ID는 그대로 남는 문제 방지)
      */
      var picked = hiddenId && String(hiddenId.value || '').trim().length > 0;
      if (picked && pickedTitle && keyword !== pickedTitle){
        clearPickedUI();
      }

      /*
        2글자 미만이면 원칙적으로 검색 안 함.
        다만 방금 직전에 검색을 보낸 상태에서 바로 지운 경우에는
        목록이 급하게 닫히며 깜빡이는 느낌을 줄이기 위해 아주 짧게 유지하는 예외 처리.
      */
      if (keyword.length < 2 && lastQuery && lastQuery.length >= 2 && (Date.now() - lastSentAt) < 1500) return;

      // 검색 최소 길이 미만이면 검색 관련 상태 정리 후 목록 닫기
      if (keyword.length < 2){
        lastQuery = '';
        pendingKeyword = '';
        stashedList = null;
        stashedQuery = '';
        cancelPending();
        hideResult();
        return;
      }

      // 결과 목록 hover 중에는 바로 검색하지 않고 보류 (클릭 안정성 우선)
      if (hoveringResult && !force){
        pendingKeyword = keyword;
        return;
      }

      // 한글 조합 중 자모 단계에서는 검색 유예
      if (!force && composing && endsWithJamo(keyword)) return;

      scheduleSearch(keyword);
    }

    /*
      포커스 시 이전 결과가 남아 있으면 다시 보여준다.
      사용자가 입력창을 다시 눌렀을 때 굳이 다시 타이핑하지 않아도 목록 확인 가능.
    */
    input.addEventListener('focus', function(){
      if (resultBox.innerHTML && resultBox.innerHTML.trim().length > 0) showResult();
    });

    // 한글 IME 조합 상태 추적
    input.addEventListener('compositionstart', function(){ composing = true; });
    input.addEventListener('compositionend', function(){ composing = false; });

    /*
      input 이벤트
      e.isComposing도 같이 확인해서 브라우저별 IME 동작 차이를 조금 더 흡수
    */
    input.addEventListener('input', function(e){
      var isComp = !!(e && e.isComposing);
      if (isComp) composing = true;
      handleValueChanged(false);
    });

    // 결과 목록 위에 포인터 올라가면 "목록 보호 모드"로 봄
    resultBox.addEventListener('pointerenter', function(){ hoveringResult = true; });

    resultBox.addEventListener('pointerleave', function(){
      hoveringResult = false;

      /*
        hover 중 들어온 최신 결과가 stash에 있으면 먼저 반영
        (사용자가 목록에서 손 뗀 시점에 화면 업데이트)
      */
      if (stashedList !== null){
        var q = stashedQuery;
        var list = stashedList;
        stashedList = null;
        stashedQuery = '';
        renderList(list, q);
        return;
      }

      // 보류 중인 검색어가 있으면 이 시점에 검색 재개
      if (pendingKeyword){
        var k = pendingKeyword;
        pendingKeyword = '';
        scheduleSearch(k);
      }
    });

    /*
      결과 목록 선택은 click보다 pointerdown에서 처리

      이유:
      click은 blur/DOM변경/외부 클릭 처리 순서와 충돌해서 선택이 씹히는 경우가 있다.
      pointerdown에서 먼저 잡으면 선택 안정성이 좋다.
    */
    resultBox.addEventListener('pointerdown', function(ev){
      var li = ev.target.closest('li[data-index]');
      if (!li) return;

      ev.preventDefault();
      ev.stopPropagation();

      var idx = parseInt(li.getAttribute('data-index'), 10);
      var anime = currentList && currentList[idx];
      if (anime) selectAnime(anime);
    }, true);

    // 마우스 hover 위치에 맞춰 activeIndex 동기화 (키보드/마우스 상태 일치)
    resultBox.addEventListener('mouseover', function(ev){
      var li = ev.target.closest('li[data-index]');
      if (!li) return;
      var idx = parseInt(li.getAttribute('data-index'), 10);
      if (!isNaN(idx)) setActive(idx);
    });

    // 입력창/결과박스 밖을 클릭하면 드롭다운 닫기
    document.addEventListener('click', function(e){
      if (!resultBox.contains(e.target) && e.target !== input) hideResult();
    });

    /*
      키보드 조작
      - Escape: 닫기
      - ArrowUp/Down: 항목 이동
      - Enter: 선택 확정
    */
    input.addEventListener('keydown', function(e){
      if (resultBox.style.display !== 'block') return;
      var max = currentList.length - 1;

      if (e.key === 'Escape') { hideResult(); return; }

      if (e.key === 'ArrowDown'){
        e.preventDefault();
        if (max < 0) return;
        setActive(activeIndex < max ? activeIndex + 1 : 0);
        return;
      }

      if (e.key === 'ArrowUp'){
        e.preventDefault();
        if (max < 0) return;
        setActive(activeIndex > 0 ? activeIndex - 1 : max);
        return;
      }

      if (e.key === 'Enter'){
        if (max < 0) return;
        e.preventDefault();
        var pick = (activeIndex >= 0) ? activeIndex : 0;
        var anime = currentList[pick];
        if (anime) selectAnime(anime);
      }
    });

    /*
      제출 전 검증 (핵심 UX 포인트)
      관련 애니 입력칸은 '텍스트 입력'과 '선택 완료(hiddenId 존재)'가 다르다.

      즉,
      - input에 글자 있음 + hiddenId 없음  => 미완료 상태 (제출 막아야 함)
      - input에 글자 있음 + hiddenId 있음  => 선택 완료 상태
    */
    var form = input.closest('form');
    if (form){
      form.addEventListener('submit', function(e){
        var hasText = input.value.trim().length > 0;
        var picked = hiddenId && String(hiddenId.value || '').trim().length > 0;

        if (hasText && !picked){
          e.preventDefault();
          showWarn('⚠️ 목록에서 애니를 클릭해서 "선택"해야 저장됩니다.\n(지금은 텍스트만 입력된 상태예요)');
          input.focus();
        }
      });
    }

    /*
      선택 해제 버튼은 renderSelectedCard()에서 동적으로 만들어진다.
      그래서 직접 바인딩이 아니라 document 이벤트 위임으로 처리.
    */
    document.addEventListener('click', function(e){
      var btn = e.target && e.target.closest('#animeClearBtn');
      if (!btn) return;

      clearPickedUI();

      // 화면값/검색상태도 같이 초기화해서 다시 처음부터 검색 가능하게 맞춤
      input.value = '';
      lastValue = '';
      lastQuery = '';
      hideResult();
      input.focus();
    });

  });
})();
</script>

</body>
</html>