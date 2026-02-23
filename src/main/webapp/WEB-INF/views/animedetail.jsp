<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%-- 
  현재 프로젝트 컨텍스트 경로.
  링크/CSS/JS/이미지 경로를 전부 ctx 기준으로 맞추면
  로컬/배포 환경에서 context path가 달라도 경로가 안 깨진다.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 애니 상세</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<%-- favicon도 ctx 기준으로 맞춰서 하위 경로 접근 시 404 방지 --%>
<link rel="icon" type="image/png" href="${ctx}/favicon.png">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">

<!-- Google Font -->
<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@400;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@400;600;700&display=swap" rel="stylesheet">

<!-- CSS -->
<%-- 템플릿/공통 스타일도 모두 ctx 기준 절대경로로 통일 --%>
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<style>
/* =========================
   Anime Detail 페이지 전용 스타일
   - 공통 템플릿을 최대한 유지하고
   - 상세 페이지에만 필요한 룩만 덮어쓴다.
   - 클래스 범위를 좁게 잡아서 다른 페이지 충돌을 줄이는 목적
========================= */

/* 헤더 우측 검색 아이콘은 상세 페이지에서는 숨김 */
.header__right__icons .icon_search { display:none !important; }

/* 페이지 전체 상하 여백 */
.anime-detail-wrap{ padding: 120px 0; }

/* 상세 카드 메인 박스
   - 글래스 느낌 + 그림자 + 라운드
   - before/after 가상요소로 광택/보더 효과 추가 */
.anime-detail-card{
  position: relative;
  border-radius: 22px;
  padding: 44px;
  background: rgba(255,255,255,0.06);
  border: 1px solid rgba(255,255,255,0.10);
  backdrop-filter: blur(18px) saturate(140%);
  -webkit-backdrop-filter: blur(18px) saturate(140%);
  box-shadow: 0 18px 60px rgba(0,0,0,0.45);
  overflow: hidden;
}

/* 카드 위쪽 광택 느낌 */
.anime-detail-card::before{
  content:"";
  position:absolute;
  top:-60%;
  left:-30%;
  width: 80%;
  height: 120%;
  transform: rotate(18deg);
  background: radial-gradient(circle at 30% 30%, rgba(255,255,255,0.20), rgba(255,255,255,0.00) 60%);
  pointer-events:none;
  filter: blur(2px);
  opacity: .9;
}

/* 카드 테두리 그라데이션 라인(실제 content 영역은 건드리지 않음) */
.anime-detail-card::after{
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
  opacity: .8;
}

/* 썸네일/정보 영역 row 정렬 기준 */
.anime-detail-row{ align-items:flex-start; }

/* 좌측 썸네일 카드 */
.anime-thumb{
  width:100%;
  max-width: 310px;
  border-radius: 18px;
  overflow:hidden;
  box-shadow: 0 18px 60px rgba(0,0,0,0.50);
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(0,0,0,0.18);
}

/* 이미지 비율 유지해서 박스 너비에 맞춤 */
.anime-thumb img{ width:100%; height:auto; display:block; }

/* 우측 텍스트 영역 여백 */
.anime-info{ padding-left: 30px; }

/* 제목 스타일 */
.anime-title{
  font-size: 36px;
  font-weight: 800;
  letter-spacing: -0.02em;
  color:#fff;
  line-height: 1.15;
}

/* 메타 정보 칩(년도/분기) 묶음 */
.meta-chips{
  margin-top: 18px;
  display:flex;
  gap:10px;
  flex-wrap: wrap;
}

/* 메타 개별 칩 */
.meta-chip{
  display:inline-flex;
  align-items:center;
  gap:8px;
  padding: 7px 14px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 700;
  background: rgba(255,255,255,0.10);
  border: 1px solid rgba(255,255,255,0.10);
  color:#fff;
}
.meta-chip i{ opacity:.9; }

/* 시놉시스 박스
   - 줄거리는 가독성이 중요해서 줄간격을 넉넉하게 둠 */
.anime-synopsis{
  margin-top: 22px;
  padding: 18px 18px;
  border-radius: 16px;
  background: rgba(0,0,0,0.20);
  border: 1px solid rgba(255,255,255,0.10);
  color: rgba(255,255,255,0.92);
  line-height: 1.95;
}

/* 버튼 묶음 영역
   - 관리자 버튼(수정/삭제) + 리스트 이동 버튼 정렬 */
.action-wrap{
  margin-top: 22px;
  display:flex;
  justify-content: flex-end;
  align-items:center;
  gap: 10px;
  flex-wrap: wrap;
}

/* 공통 버튼 베이스(글래스 계열) */
.ad-btn{
  display:inline-flex;
  align-items:center;
  justify-content:center;
  gap:8px;
  padding: 10px 16px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 800;
  letter-spacing: -0.01em;
  text-decoration:none !important;
  user-select:none;
  border: 1px solid rgba(255,255,255,0.16);
  background: rgba(255,255,255,0.08);
  color:#fff !important;
  transition: transform .18s ease, box-shadow .18s ease, background .18s ease, border-color .18s ease, opacity .18s ease;
  backdrop-filter: blur(12px) saturate(140%);
  -webkit-backdrop-filter: blur(12px) saturate(140%);
}

/* hover/active/focus 상호작용 */
.ad-btn:hover{
  transform: translateY(-1px);
  box-shadow: 0 12px 28px rgba(0,0,0,0.35);
  border-color: rgba(255,255,255,0.26);
  background: rgba(255,255,255,0.12);
}
.ad-btn:active{ transform: translateY(0); box-shadow:none; }
.ad-btn:focus-visible{
  outline:none;
  box-shadow: 0 0 0 3px rgba(140,200,255,0.35);
}

/* 버튼 타입별 컬러 분기 */
.ad-btn--primary{
  background: linear-gradient(135deg, rgba(120,190,255,0.45), rgba(255,255,255,0.08));
  border-color: rgba(120,190,255,0.35);
}
.ad-btn--danger{
  background: linear-gradient(135deg, rgba(255,90,120,0.35), rgba(255,255,255,0.06));
  border-color: rgba(255,90,120,0.35);
}
.ad-btn--danger:hover{
  background: linear-gradient(135deg, rgba(255,90,120,0.45), rgba(255,255,255,0.08));
}
.ad-btn--ghost{
  background: rgba(255,255,255,0.06);
  border-color: rgba(255,255,255,0.14);
  opacity: .95;
}

/* 템플릿 기본 a:hover 스타일이 끼어들어 버튼 색/밑줄이 바뀌는 것 방지 */
.action-wrap .ad-btn,
.action-wrap .ad-btn:visited,
.action-wrap .ad-btn:hover,
.action-wrap .ad-btn:focus,
.action-wrap .ad-btn:active{
  color:#fff !important;
  text-decoration:none !important;
}

/* 태블릿/모바일 보정
   - 카드 패딩 축소
   - 우측 정보영역 왼쪽 패딩 제거
   - 버튼 정렬을 왼쪽으로 바꿔 터치 접근성 확보 */
@media (max-width: 991px){
  .anime-detail-card{ padding: 28px; }
  .anime-info{ padding-left: 0; margin-top: 20px; }
  .anime-thumb{ max-width: 100%; }
  .action-wrap{ justify-content: flex-start; }
}
</style>
</head>

<body>

<%-- 공통 헤더 include (상단 네비/로그인 영역 등 공통 UI) --%>
<jsp:include page="/WEB-INF/common/header.jsp" />

<section class="anime-detail-wrap">
  <div class="container">

    <%-- 
      방어 분기 1: animeData가 비어있는 경우
      컨트롤러에서 정상적으로 모델을 못 내려줬거나 잘못된 접근 경로일 수 있다.
      이 경우 에러 문구 + 리스트 복귀 버튼만 보여준다.
    --%>
    <c:if test="${empty animeData}">
      <div class="anime-detail-card">
        <div class="alert alert-danger" style="border-radius:14px; margin:0;">
          애니 데이터(animeData)가 없습니다. 접근 경로를 확인하세요.
        </div>
        <div class="action-wrap" style="margin-top:18px;">
          <a href="${ctx}/animeList" class="ad-btn ad-btn--ghost">애니 리스트로</a>
        </div>
      </div>
    </c:if>

    <%-- 
      방어 분기 2: animeData가 있는 정상 상세 화면
      실제 상세 정보 렌더링은 이 블록에서만 수행한다.
    --%>
    <c:if test="${not empty animeData}">
      <div class="anime-detail-card">
        <div class="row anime-detail-row">

          <div class="col-lg-4">
            <div class="anime-thumb">

              <%-- 
                썸네일 URL 정규화 처리
                DB에 저장된 값 형태가 제각각일 수 있어서(img 경로/절대URL/ctx 포함 경로 등)
                화면에서 안전하게 최종 src를 만들기 위해 단계별로 분기한다.
              --%>
              <c:set var="thumbRaw" value="${animeData.animeThumbnailUrl}" />

              <c:choose>
                <%-- 1) 썸네일 값이 비어있으면 기본 이미지 사용 --%>
                <c:when test="${empty thumbRaw}">
                  <c:set var="thumbSrc" value="${ctx}/img/anime/details-pic.jpg" />
                </c:when>

                <%-- 2) 이미 외부 절대 URL(http/https)이면 그대로 사용 --%>
                <c:when test="${fn:startsWith(thumbRaw, 'http://') or fn:startsWith(thumbRaw, 'https://')}">
                  <c:set var="thumbSrc" value="${thumbRaw}" />
                </c:when>

                <%-- 
                  3) DB 값에 이미 ctx까지 포함되어 저장된 경우
                     예: /animale/uploads/xxx.jpg 형태가 아니라 /animale/... 전체가 들어있는 케이스
                     여기서 ctx를 또 붙이면 중복되므로 그대로 사용
                --%>
                <c:when test="${fn:startsWith(thumbRaw, ctx)}">
                  <c:set var="thumbSrc" value="${thumbRaw}" />
                </c:when>

                <%-- 
                  4) /로 시작하는 서버 내부 절대경로면 ctx + raw
                     예: /uploads/anime/aaa.jpg -> /animale/uploads/anime/aaa.jpg
                --%>
                <c:when test="${fn:startsWith(thumbRaw, '/')}">
                  <c:set var="thumbSrc" value="${ctx}${thumbRaw}" />
                </c:when>

                <%-- 
                  5) 그 외는 상대경로로 보고 ctx/raw 형태로 보정
                     예: uploads/anime/aaa.jpg -> /animale/uploads/anime/aaa.jpg
                --%>
                <c:otherwise>
                  <c:set var="thumbSrc" value="${ctx}/${thumbRaw}" />
                </c:otherwise>
              </c:choose>

              <%-- 최종 정규화된 썸네일 src로 렌더링 --%>
              <img src="${thumbSrc}" alt="${animeData.animeTitle}">
            </div>
          </div>

          <div class="col-lg-8">
            <div class="anime-info">

              <%-- 제목 표시 --%>
              <div class="anime-title">${animeData.animeTitle}</div>

              <%-- 메타 정보 칩 (방영년도 / 방영분기) --%>
              <div class="meta-chips">
                <span class="meta-chip"><i class="fa fa-calendar"></i> 방영년도 ${animeData.animeYear}</span>
                <span class="meta-chip"><i class="fa fa-tag"></i> 방영분기 ${animeData.animeQuarter}</span>
              </div>

              <%-- 줄거리/상세 설명 영역 --%>
              <div class="anime-synopsis">
                ${animeData.animeStory}
              </div>

              <div class="action-wrap">

                <%-- 
                  관리자에게만 수정/삭제 버튼 노출
                  toUpperCase를 쓰는 이유:
                  세션 값이 admin/ADMIN 등 대소문자 차이로 들어와도 비교를 안정적으로 하기 위해서
                --%>
                <c:if test="${fn:toUpperCase(sessionScope.memberRole) eq 'ADMIN'}">
                  <a href="${ctx}/animeEdit?animeId=${animeData.animeId}" class="ad-btn ad-btn--primary">
                    <i class="fa fa-pencil"></i> 수정
                  </a>

                  <%-- 
                    삭제는 GET이 아니라 POST 유지
                    단순 링크 클릭으로 삭제되지 않게 하고, 서버 쪽 삭제 매핑 정책과 맞춘다.
                  --%>
                  <form action="${ctx}/animeDelete" method="post" style="display:inline;">
                    <input type="hidden" name="animeId" value="${animeData.animeId}">
                    <button type="submit" class="ad-btn ad-btn--danger"
                            onclick="return confirm('정말 삭제하시겠습니까?');">
                      <i class="fa fa-trash"></i> 삭제
                    </button>
                  </form>
                </c:if>

                <%-- 누구나 볼 수 있는 리스트 복귀 버튼 --%>
                <a href="${ctx}/animeList" class="ad-btn ad-btn--ghost">
                  애니 전체페이지로 <i class="fa fa-angle-right"></i>
                </a>

              </div>

            </div>
          </div>

        </div>
      </div>
    </c:if>

  </div>
</section>

<%-- 공통 푸터 include --%>
<%@ include file="/WEB-INF/common/footer.jsp"%>

<%-- 페이지 하단 JS 로드 (렌더링 이후 로드해서 초기 표시 체감에 유리) --%>
<script src="${ctx}/js/jquery-3.3.1.min.js"></script>
<script src="${ctx}/js/bootstrap.min.js"></script>
<script src="${ctx}/js/main.js"></script>

</body>
</html>