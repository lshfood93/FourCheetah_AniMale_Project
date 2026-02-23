<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%-- 이 페이지 안에서는 컨텍스트 경로를 자주 쓰니까 맨 위에서 ctx로 한번 빼두고 계속 재사용 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 애니 수정</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<%-- 정적 리소스 경로가 프로젝트 루트 기준으로 안정적으로 잡히게 ctx 사용 --%>
<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<!-- CSS -->
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* =========================================================
   Anime Edit Page (페이지 내부 전용 스타일)
   ---------------------------------------------------------
   이 파일은 '수정 폼 화면'에만 필요한 스타일을 한곳에 모아둔 버전.
   나중에 다시 볼 때 포인트는 아래 3개:
   1) 템플릿 기본 스타일 위에 화면용 UI만 덮어쓴다.
   2) 미리보기 영역은 이미지 비율 유지(contain) 중심으로 안전하게.
   3) 폼/버튼/파일선택 UI를 동일 톤(글래스)으로 맞춘다.
========================================================= */

/* 애니 수정 페이지에서는 헤더 검색 아이콘이 필요 없어서 강제로 숨김 */
.header__right__icons .icon_search { display: none !important; }

/* 템플릿 기본 spad 값에만 의존하면 페이지마다 체감 여백이 달라보일 수 있어서
   수정 화면은 상하 여백을 여기서 명시적으로 고정 */
.anime-details.spad{
  padding-top: 120px;
  padding-bottom: 120px;
}

/* 메인 카드(글래스 UI)
   - 배경/블러/테두리/그림자로 한 덩어리 카드 느낌
   - overflow hidden으로 pseudo 요소 번짐이 카드 밖으로 안 나가게 막음 */
.anime-edit-card{
  position: relative;
  border-radius: 22px;
  padding: 34px;
  background: rgba(255,255,255,0.06);
  border: 1px solid rgba(255,255,255,0.10);
  backdrop-filter: blur(18px) saturate(140%);
  -webkit-backdrop-filter: blur(18px) saturate(140%);
  box-shadow: 0 18px 60px rgba(0,0,0,0.45);
  overflow: hidden;
}

/* 카드 상단 왼쪽 쪽에 들어가는 은은한 하이라이트(빛 반사 느낌) */
.anime-edit-card::before{
  content:"";
  position:absolute;
  top:-55%;
  left:-35%;
  width:70%;
  height:110%;
  transform: rotate(18deg);
  background: radial-gradient(circle at 28% 28%,
    rgba(255,255,255,0.20),
    rgba(255,255,255,0.00) 62%);
  pointer-events:none;
  opacity: .55;
  filter: blur(4px);
  z-index: 0;
}

/* 카드 외곽 라인 강조용 얇은 그라데이션 보더 오버레이
   mask-composite로 내부는 비우고 테두리만 남기는 방식 */
.anime-edit-card::after{
  content:"";
  position:absolute;
  inset:0;
  border-radius: 22px;
  padding: 1px;
  background: linear-gradient(135deg,
    rgba(255,255,255,0.35),
    rgba(255,255,255,0.08),
    rgba(120,190,255,0.18),
    rgba(255,255,255,0.10));
  -webkit-mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  pointer-events:none;
  opacity: .80;
  z-index: 0;
}

/* 카드 내부 실제 콘텐츠(텍스트/폼/버튼)가 pseudo 배경보다 위로 올라오도록 z-index 정리 */
.anime-edit-card *{ position: relative; z-index: 1; }

/* 화면 타이틀(관리자 수정 안내) */
.anime__details__title h3{
  color:#fff;
  font-weight: 900;
  letter-spacing: -0.02em;
}
.anime__details__title span{
  color: rgba(255,255,255,0.75);
}

/* 썸네일 미리보기 박스
   - 이미지 자체는 background-image로 넣고
   - contain으로 비율 유지(잘림 방지)
   - 파일 선택 전/실패 시 fallback 텍스트 표시 */
.preview-box{
  height: 440px;
  border-radius: 16px;
  border: 1px solid rgba(255,255,255,0.12);
  background: rgba(0,0,0,0.18);
  overflow: hidden;
  display:flex;
  align-items:center;
  justify-content:center;

  /* 큰 이미지가 들어와도 찌그러지거나 잘리지 않게 비율 유지 우선 */
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
}
.preview-fallback{
  color: rgba(255,255,255,0.75);
  font-size: 13px;
  text-align:center;
  padding: 0 12px;
}

/* 관리자 폼 공통 스타일
   같은 페이지 안 입력 요소 톤을 통일해서 "한 화면"처럼 보이게 맞춤 */
.admin-form label{
  color:#fff;
  font-weight: 800;
  margin-bottom: 8px;
  display:block;
}
.admin-form .form-control{
  border-radius: 12px;
  height: 46px;
  line-height: 46px;
  background: rgba(255,255,255,0.06);
  border: 1px solid rgba(255,255,255,0.14);
  color:#fff;
}

/* 포커스 시 어디를 입력 중인지 확실히 보이게 블루 계열 글로우 */
.admin-form .form-control:focus{
  outline: none;
  box-shadow: 0 0 0 3px rgba(140,200,255,0.25);
  border-color: rgba(140,200,255,0.35);
}
.admin-form .form-control::placeholder{
  color: rgba(255,255,255,0.55);
}

/* 줄거리 textarea는 단일 input 규격(height:46px) 적용되면 안 되므로 별도 재정의 */
.admin-form textarea.form-control{
  height: 200px;
  line-height: 1.7;
  padding-top: 12px;
  padding-bottom: 12px;
  resize: vertical;
}

/* select의 option은 브라우저 기본 배경색 때문에 밝게 떠보일 수 있어서 다크톤 강제 */
.admin-form select.form-control option{
  background: #0b0c2a;
  color:#fff;
}

/* 입력 보조 설명 텍스트 */
.help{
  color: rgba(255,255,255,0.70);
  font-size: 12px;
  margin-top: 8px;
}

/* 버튼 공통(글래스 스타일)
   - submit / 취소 / 파일선택 / 되돌리기 모두 같은 계열로 통일
   - 클래스 조합(ad-btn + 변형 클래스) 방식 */
.ad-btn{
  display:inline-flex;
  align-items:center;
  justify-content:center;
  gap: 8px;
  padding: 10px 16px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 900;
  letter-spacing: -0.01em;
  text-decoration:none !important;
  user-select:none;
  border: 1px solid rgba(255,255,255,0.16);
  background: rgba(255,255,255,0.08);
  color:#fff !important;
  transition: transform .18s ease, box-shadow .18s ease, background .18s ease, border-color .18s ease;
  backdrop-filter: blur(12px) saturate(140%);
  -webkit-backdrop-filter: blur(12px) saturate(140%);
}
.ad-btn:hover{
  transform: translateY(-1px);
  box-shadow: 0 12px 28px rgba(0,0,0,0.35);
  border-color: rgba(255,255,255,0.26);
  background: rgba(255,255,255,0.12);
}

/* 주요 액션 버튼(수정 완료) */
.ad-btn--primary{
  background: linear-gradient(135deg, rgba(120,190,255,0.45), rgba(255,255,255,0.08));
  border-color: rgba(120,190,255,0.35);
}

/* 보조 버튼(취소/되돌리기/파일선택) */
.ad-btn--ghost{
  background: rgba(255,255,255,0.06);
  border-color: rgba(255,255,255,0.14);
  opacity: .95;
}

/* 하단 액션 버튼 영역
   기본은 오른쪽 정렬, 모바일에서는 아래 미디어쿼리에서 왼쪽 정렬로 변경 */
.form-actions{
  display:flex;
  justify-content:flex-end;
  gap: 10px;
  margin-top: 18px;
  flex-wrap: wrap;
}

/* 파일 선택 UI 커스텀
   실제 input[type=file]는 숨기고 label/button 스타일로 대신 조작 */
.file-row{
  display:flex;
  align-items:center;
  gap: 12px;
  flex-wrap: wrap;
}

/* 실제 파일 input은 화면 밖으로 빼서 숨김(접근은 label for로 처리) */
.file-input{
  position:absolute;
  left:-9999px;
  width:1px;
  height:1px;
  opacity:0;
}
.file-btn{ padding: 10px 16px; }

/* 긴 파일명 들어와도 레이아웃 안 깨지게 말줄임 처리 */
.file-name{
  color: rgba(255,255,255,0.78);
  font-size: 13px;
  max-width: 420px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* 되돌리기 버튼은 보조 액션 느낌으로 살짝 톤 다운 */
.file-reset{ opacity: .92; }

/* 반응형 보정
   태블릿 이하에서는 카드 패딩/미리보기 높이/버튼 정렬을 조금 완화 */
@media (max-width: 991px){
  .anime-edit-card{ padding: 24px; }
  .preview-box{ height: 360px; }
  .form-actions{ justify-content:flex-start; }
}
</style>
</head>

<body>

  <%-- 공통 헤더 포함 --%>
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <section class="anime-details spad">
    <div class="container">

      <div class="anime-edit-card">

        <%-- 직접 URL 접근 등으로 animeData 없이 들어온 경우를 먼저 방어.
             폼 자체를 렌더링하지 않고 안내 메시지로 끝내서 NPE성 화면 깨짐 방지 --%>
        <c:if test="${empty animeData}">
          <div class="alert alert-danger" style="border-radius:14px; margin:0;">
            수정할 애니 데이터(animeData)가 없습니다. 접근 경로를 확인하세요.
          </div>
        </c:if>

        <%-- animeData가 있을 때만 수정 폼 렌더링 --%>
        <c:if test="${not empty animeData}">
          <div class="anime__details__content">
            <div class="row">

              <%-- LEFT: 썸네일 미리보기 영역
                   - 처음에는 기존 썸네일 표시
                   - 파일 선택하면 즉시 미리보기 교체
                   - 되돌리기 누르면 기존 썸네일로 복귀 --%>
              <div class="col-lg-3">
                <div id="thumbPreviewBox" class="preview-box">
                  <div id="thumbFallback" class="preview-fallback">썸네일 미리보기</div>
                </div>
                <div class="help">파일을 새로 선택하지 않으면 기존 썸네일을 그대로 유지합니다.</div>
              </div>

              <%-- RIGHT: 실제 수정 폼 영역 --%>
              <div class="col-lg-9">
                <div class="anime__details__text">

                  <div class="anime__details__title">
                    <h3>애니 수정 (관리자)</h3>
                    <span>기존 정보를 불러온 뒤 필요한 항목만 수정하세요.</span>
                  </div>

                  <form class="admin-form"
                        action="${ctx}/animeEdit"
                        method="post"
                        enctype="multipart/form-data"
                        style="margin-top: 18px;">

                    <%-- 수정 대상 식별용 PK.
                         서버에서 어떤 레코드를 수정할지 결정할 때 기준이 되는 값 --%>
                    <input type="hidden" name="animeId" value="${animeData.animeId}">

                    <%-- 기존 썸네일 URL 보관용 hidden.
                         파일을 새로 선택하지 않았을 때 서버에서 기존 이미지 유지 판단에 사용 --%>
                    <input type="hidden"
                           name="existingThumbUrl"
                           id="existingThumbUrl"
                           value="${animeData.animeThumbnailUrl}">

                    <div class="row">

                      <%-- anime_title: 화면 표시용 제목 --%>
                      <div class="col-lg-12">
                        <div class="form-group" style="margin-bottom: 16px;">
                          <label>애니 제목 <span style="color:#ff5b5b;">*</span></label>
                          <input type="text"
                                 class="form-control"
                                 name="animeTitle"
                                 id="anime_title"
                                 maxlength="200"
                                 required
                                 value="${animeData.animeTitle}">
                        </div>
                      </div>

                      <%-- original_title: 원제/오리지널 제목 --%>
                      <div class="col-lg-12">
                        <div class="form-group" style="margin-bottom: 16px;">
                          <label>오리지널 제목 <span style="color:#ff5b5b;">*</span></label>
                          <input type="text"
                                 class="form-control"
                                 name="originalTitle"
                                 id="original_title"
                                 maxlength="200"
                                 required
                                 value="${animeData.originalTitle}">
                        </div>
                      </div>

                      <%-- anime_year: 방영년도 --%>
                      <div class="col-lg-6 col-md-6">
                        <div class="form-group" style="margin-bottom: 16px;">
                          <label>방영년도 <span style="color:#ff5b5b;">*</span></label>
                          <input type="number"
                                 class="form-control"
                                 name="animeYear"
                                 id="anime_year"
                                 min="1960"
                                 max="2100"
                                 required
                                 value="${animeData.animeYear}">
                        </div>
                      </div>

                      <%-- anime_quarter: 방영분기
                           DB에 과거 데이터 형식이 섞여 있을 수 있어서(예: '1' / '1분기')
                           둘 다 selected 처리되게 조건식을 넓게 잡아둠 --%>
                      <div class="col-lg-6 col-md-6">
                        <div class="form-group" style="margin-bottom: 16px;">
                          <label>방영분기 <span style="color:#ff5b5b;">*</span></label>
                          <select class="form-control"
                                  name="animeQuarter"
                                  id="anime_quarter"
                                  required>
                            <option value="">분기 선택</option>

                            <%-- DB 값이 '1' 또는 '1분기'여도 1분기가 선택되도록 처리 --%>
                            <option value="1분기"
                              <c:if test="${animeData.animeQuarter eq '1' or animeData.animeQuarter eq '1분기'}">selected</c:if>>
                              1분기 (1~3월)
                            </option>
                            <option value="2분기"
                              <c:if test="${animeData.animeQuarter eq '2' or animeData.animeQuarter eq '2분기'}">selected</c:if>>
                              2분기 (4~6월)
                            </option>
                            <option value="3분기"
                              <c:if test="${animeData.animeQuarter eq '3' or animeData.animeQuarter eq '3분기'}">selected</c:if>>
                              3분기 (7~9월)
                            </option>
                            <option value="4분기"
                              <c:if test="${animeData.animeQuarter eq '4' or animeData.animeQuarter eq '4분기'}">selected</c:if>>
                              4분기 (10~12월)
                            </option>
                          </select>
                        </div>
                      </div>

                      <%-- thumbFile: 새 썸네일 업로드(선택 사항)
                           파일을 안 고르면 hidden existingThumbUrl 기준으로 기존 이미지 유지 --%>
                      <div class="col-lg-12">
                        <div class="form-group" style="margin-bottom: 16px;">
                          <label>썸네일 이미지 (선택)</label>

                          <div class="file-row">
                            <input type="file"
                                   name="thumbFile"
                                   id="thumbFile"
                                   class="file-input"
                                   accept="image/*">

                            <label for="thumbFile" class="ad-btn ad-btn--ghost file-btn">
                              <i class="fa fa-upload"></i> 파일 선택
                            </label>

                            <span id="thumbFileName" class="file-name">선택된 파일 없음</span>

                            <%-- 되돌리기 버튼은 서버 전송값을 바꾸는 게 아니라
                                 현재 화면의 파일 선택 상태/미리보기만 초기화하는 용도 --%>
                            <button type="button"
                                    id="thumbResetBtn"
                                    class="ad-btn ad-btn--ghost file-reset">
                              <i class="fa fa-undo"></i> 되돌리기
                            </button>
                          </div>

                          <div class="help">파일을 선택하면 좌측 미리보기에 반영됩니다. 선택하지 않으면 기존 썸네일 유지.</div>
                        </div>
                      </div>

                      <%-- anime_story: 상세 줄거리
                           textarea 내부 값은 태그 사이에 넣는 방식이라 개행도 함께 유지됨 --%>
                      <div class="col-lg-12">
                        <div class="form-group" style="margin-bottom: 16px;">
                          <label>상세 줄거리 <span style="color:#ff5b5b;">*</span></label>
                          <textarea class="form-control"
                                    name="animeStory"
                                    id="anime_story"
                                    maxlength="4000"
                                    required>${animeData.animeStory}</textarea>
                        </div>
                      </div>

                    </div>

                    <%-- 하단 액션 버튼 영역:
                         submit(수정 완료) / 상세로 복귀(취소) --%>
                    <div class="form-actions">
                      <button type="submit" class="ad-btn ad-btn--primary">
                        <i class="fa fa-check"></i> 수정 완료
                      </button>

                      <a class="ad-btn ad-btn--ghost"
                         href="${ctx}/animeDetail?animeId=${animeData.animeId}">
                        <i class="fa fa-times"></i> 취소
                      </a>
                    </div>

                  </form>

                </div>
              </div>

            </div>
          </div>
        </c:if>

      </div>
    </div>
  </section>

  <%-- 공통 푸터 포함 --%>
  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <%-- 공통 스크립트 로드 --%>
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <script>
  (function(){
    /* =========================================================
       썸네일 미리보기 전용 스크립트
       ---------------------------------------------------------
       이 스크립트의 역할은 서버 저장 로직이 아니라 "화면 UX 보조"다.
       흐름은 딱 3단계:
       1) 기존 썸네일 URL 표시
       2) 새 파일 선택 시 즉시 미리보기(DataURL)
       3) 되돌리기 클릭 시 파일 선택 해제 + 기존 미리보기 복구
    ========================================================= */

    /* JSP에서 내려준 ctx를 JS에서도 써서 상대/절대 경로를 안정적으로 맞춤 */
    const ctx = "${ctx}";

    /* hidden에 들어있는 기존 썸네일 URL(서버 데이터 원본) */
    const existing = document.getElementById("existingThumbUrl");

    /* 미리보기 박스/대체문구/파일입력/파일명표시/되돌리기 버튼 DOM 참조 */
    const box = document.getElementById("thumbPreviewBox");
    const fallback = document.getElementById("thumbFallback");
    const fileEl = document.getElementById("thumbFile");
    const fileNameEl = document.getElementById("thumbFileName");
    const resetBtn = document.getElementById("thumbResetBtn");

    function resolveUrl(u){
      /* DB에 저장된 썸네일 경로가 절대URL/컨텍스트포함경로/루트경로/상대경로로
         섞여 들어와도 브라우저가 실제로 열 수 있는 URL 형태로 통일하는 함수 */
      if(!u) return "";
      u = String(u).trim();
      if(!u) return "";

      // 절대 URL(http/https)이면 그대로 사용
      if(/^https?:\/\//i.test(u)) return u;

      // DB 값에 컨텍스트 경로가 이미 포함되어 있으면 중복으로 ctx를 붙이지 않음
      if(ctx && u.indexOf(ctx + "/") === 0) return u;

      // 루트 경로(/...) 형태면 ctx를 앞에 붙여서 프로젝트 기준 경로로 맞춤
      if(u.charAt(0) === "/") return ctx + u;

      // 상대경로면 ctx/상대경로 형태로 보정
      return ctx + "/" + u;
    }

    function applyBg(url){
      /* preview-box는 background-image 방식이라
         URL 있으면 배경 적용 + fallback 숨김
         URL 없으면 배경 제거 + fallback 표시 */
      if(!box) return;

      if(url){
        /* CSS url('...') 안에 작은따옴표가 깨지는 케이스 방지용 최소 이스케이프 */
        const safe = url.replace(/'/g, "\\'");
        box.style.backgroundImage = "url('" + safe + "')";
        if(fallback) fallback.style.display = "none";
      }else{
        box.style.backgroundImage = "none";
        if(fallback) fallback.style.display = "block";
      }
    }

    /* 페이지 진입 시점: 서버에 저장된 기존 썸네일을 먼저 보여줌 */
    const origin = existing ? resolveUrl(existing.value) : "";
    applyBg(origin);

    /* 새 파일 선택 시 브라우저에서만 미리보기 생성
       (아직 서버 업로드 전 단계이므로 FileReader + DataURL 사용) */
    if(fileEl){
      fileEl.addEventListener("change", function(){
        const f = fileEl.files && fileEl.files[0];

        /* 선택 취소/초기화 상태면 파일명 문구 초기화하고 기존 썸네일로 복귀 */
        if(!f){
          if(fileNameEl) fileNameEl.textContent = "선택된 파일 없음";
          applyBg(origin);
          return;
        }

        /* 파일명 표시(사용자가 지금 뭘 골랐는지 확인용) */
        if(fileNameEl) fileNameEl.textContent = f.name;

        /* FileReader 결과(DataURL)를 배경 이미지로 적용해서 즉시 미리보기 */
        const reader = new FileReader();
        reader.onload = function(e){ applyBg(e.target.result); };
        reader.readAsDataURL(f);
      });
    }

    /* 되돌리기:
       - file input 값 비우기
       - 파일명 문구 초기화
       - 미리보기는 기존 썸네일(origin)로 복구
       주의: 서버 DB 값을 바꾸는 동작은 여기서 하지 않음(화면 상태만 복구) */
    if(resetBtn){
      resetBtn.addEventListener("click", function(){
        if(fileEl) fileEl.value = "";
        if(fileNameEl) fileNameEl.textContent = "선택된 파일 없음";
        applyBg(origin);
      });
    }
  })();
  </script>

</body>
</html>