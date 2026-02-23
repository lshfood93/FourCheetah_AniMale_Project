<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>

<%-- 
  프로젝트 컨텍스트 경로.
  이 파일 안의 링크/폼 action/정적 리소스 경로를 전부 ctx 기준으로 맞추면
  로컬/배포 환경에서 context path가 달라도 경로가 안정적으로 유지된다.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- 
  관리자 페이지 좌측 메뉴에서 사용하는 이동 경로를 먼저 변수로 정리해둔다.
  하드코딩된 문자열을 여기로 모아두면 나중에 매핑 바뀌었을 때 수정 포인트가 줄어든다.
--%>
<c:set var="urlNewsManage" value="${ctx}/newsList"/>
<c:set var="urlAnimeListManage" value="${ctx}/animeList"/>
<c:set var="urlMyPosts" value="${ctx}/myPostPage" />
<c:set var="urlChangePasswordPage" value="${ctx}/changePasswordPage"/>

<%-- 
  게시글 관리 링크는 category 파라미터가 없으면 컨트롤러에서 처리 불가(또는 튕김)라서
  현재 보장되는 카테고리(ANIME)로 강제 링크를 만들어 둔다.
--%>
<c:set var="urlBoardManageAnime" value="${ctx}/boardList?boardCategory=ANIME"/>

<%-- 
  로그인 체크.
  세션에 memberId가 없으면 비로그인 상태로 보고 로그인 페이지로 보낸다.
  (관리자 체크보다 먼저 로그인 여부부터 거르는 흐름)
--%>
<c:if test="${empty sessionScope.memberId}">
  <c:redirect url="${ctx}/login" />
</c:if>

<%-- 
  관리자 권한 체크.
  role이 비어있거나 ADMIN이 아니면 메인으로 보낸다.
  컨트롤러에서 1차로 막는 게 우선이지만, JSP에서도 2차 안전장치로 막아둔다.
--%>
<c:if test="${empty sessionScope.memberRole or sessionScope.memberRole ne 'ADMIN'}">
  <c:redirect url="${ctx}/mainPage" />
</c:if>

<%-- 
  adminPage 화면은 memberData를 기준으로 렌더링하는 영역이 많아서
  memberData가 비어 있으면 현재 화면 렌더 대신 controller를 다시 타도록 유도한다.
  (직접 접근/모델 누락/예외 흐름 대비)
--%>
<c:if test="${empty memberData}">
  <c:redirect url="${ctx}/adminPage" />
</c:if>

<%-- 
  activeMenu가 안 내려온 경우 기본값 지정.
  좌측 메뉴 하이라이트나 공통 헤더/사이드 상태 표시용으로 쓰는 값이라
  비어있으면 ADMIN으로 기본 세팅해둔다.
--%>
<c:if test="${empty activeMenu}">
  <c:set var="activeMenu" value="ADMIN" />
</c:if>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 관리자 페이지</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<%-- favicon도 ctx 기준으로 로드해서 하위 경로 접근 시 404 방지 --%>
<link rel="icon" type="image/png" href="${ctx}/favicon.png">

<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<%-- 공통 템플릿 스타일들 (ctx 기준으로 통일) --%>
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">

<%-- 
  기본 confirm/alert 대신 SweetAlert2를 쓰기 위해 CDN 로드.
  이 페이지에서는 저장 확인/로그아웃 확인/업로드 경고 등에 사용한다.
--%>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<style>
/* =========================
   관리자 마이페이지 전용 레이아웃/스타일
   - 공통 템플릿을 최대한 유지하면서
   - 이 페이지에서만 필요한 UI를 덮어쓴다.
   - 클래스 범위를 좁게 잡아 다른 페이지 영향 최소화
   ========================= */

/* 상단 타이틀 영역 */
.mypage-title{ margin-top: 24px; text-align: center; }
.mypage-title__h1{ font-weight: 800; margin: 0; }

/* 본문 섹션 여백 */
.mypage-spad{ padding-top: 60px; padding-bottom: 80px; }

/* 공통 카드(좌/우 패널) 느낌 */
.login-box-clean{
  background: rgba(255, 255, 255, 0.02);
  border-radius: 18px;
  padding: 28px;
  box-shadow: 0 10px 28px rgba(0,0,0,0.22);
}

/* =========================
   공통 버튼 스타일
   - 좌측 메뉴 버튼/수정 버튼 등에 공통적으로 사용
   ========================= */
.mypage-btn{
  display: block;
  width: 100%;
  text-align: center;
  padding: 14px 18px;
  border-radius: 999px;
  font-weight: 600;
  color: #fff;
  background: rgba(255, 255, 255, 0.08);
  border: none;
  transition: .2s;
  position: relative;
  overflow: hidden;
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.28);
  transform: translateY(0);
}
.mypage-btn:hover{ background: rgba(255, 255, 255, 0.12); transform: translateY(-1px); }
.mypage-btn:active{ transform: translateY(0); }

/* 버튼 광택 스윕 효과 */
.mypage-btn::after{
  content: "";
  position: absolute; top: -40%; left: -60%;
  width: 60%; height: 180%;
  background: linear-gradient(90deg,
    rgba(255,255,255,0) 0%,
    rgba(255,255,255,0.16) 50%,
    rgba(255,255,255,0) 100%);
  transform: skewX(-18deg);
  transition: left .45s ease;
  pointer-events: none;
}
.mypage-btn:hover::after{ left: 120%; }

/* 강조 버튼(저장 완료 등) */
.primary-red{
  background: linear-gradient(135deg, #ff4c4c 0%, #e53637 55%, #c92c2d 100%) !important;
  color: #fff !important;
}
.primary-red:hover{ filter: brightness(1.04); }

/* 비활성화 버튼 공통 상태 */
.disabled-btn{ opacity: 0.45; pointer-events: none; }

/* =========================
   프로필 이미지 로더 / 스켈레톤 / 오버레이
   ========================= */

/* 
  profileWrap을 오버레이 기준점으로 강제한다.
  로딩 오버레이가 아래로 밀려 내려가는 현상이 있었어서
  absolute 기준이 이 박스로 정확히 잡히도록 relative를 준다.
*/
#profileWrap{
  position: relative !important;
}

/* 
  profileWrap 바로 아래에 붙는 로더 오버레이.
  다른 스타일 우선순위에 밀리지 않게 !important로 고정해둔 상태.
*/
#profileWrap > .profile-loader{
  position: absolute !important;
  inset: 0 !important;
  z-index: 50 !important;

  /* 로더 중앙 정렬 */
  display: none !important;
  align-items: center !important;
  justify-content: center !important;
  flex-direction: column !important;
  gap: 10px !important;

  /* 반투명 오버레이 + 블러 */
  background: rgba(11, 12, 42, .80) !important;
  backdrop-filter: blur(4px) !important;
  -webkit-backdrop-filter: blur(4px) !important;

  /* 혹시 외부 스타일이 margin/transform을 넣어 위치 밀리는 것 방지 */
  margin: 0 !important;
  transform: none !important;
}

/* wrap에 is-loading이 붙으면 로더 표시 */
#profileWrap.is-loading > .profile-loader{
  display: flex !important;
}

/* 프로필 이미지 표시 박스(정사각형) */
.profile-img-wrap{
  width: 256px; height: 256px;
  margin: 0 auto 16px;
  border-radius: 18px;
  position: relative;
  background: #0b0c2a;
  overflow: hidden; /* 기본 상태에서는 이미지/오버레이 내부 클리핑 */
}

/* 실제 프로필 이미지 */
.profile-img-wrap img{
  width: 100%; height: 100%;
  object-fit: cover;
  object-position: center;
  display: block;
  opacity: 1;
  transition: opacity .2s ease;
}

/* 
  로딩 중 스켈레톤 배경.
  이미지 로드 전 텅 빈 박스처럼 보이지 않게 shimmer 효과를 준다.
*/
.profile-img-wrap.is-loading{
  background: linear-gradient(110deg,
    rgba(255,255,255,.03) 20%,
    rgba(255,255,255,.07) 40%,
    rgba(255,255,255,.03) 60%), #0b0c2a;
  background-size: 220% 100%;
  animation: skeletonShimmer 1.15s ease-in-out infinite;
}
.profile-img-wrap.is-loading img{ opacity: 0; }

/* 기본 로더 오버레이(프로필 박스 내부에서 쓰는 버전) */
.profile-loader{
  position: absolute; inset: 0;
  display: none;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  gap: 10px;
  background: rgba(11, 12, 42, .80);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
}
.profile-img-wrap.is-loading .profile-loader{ display: flex; }

/* 로더 원형 스피너 바깥쪽 */
.loader-bar{ width: 54px; height: 54px; border-radius: 999px; position: relative; }
.loader-bar::before{
  content:""; position:absolute; inset:0; border-radius:999px;
  border: 5px solid rgba(255,255,255,.14);
  border-top-color: rgba(255,255,255,.90);
  border-right-color: rgba(229,54,55,.85);
  animation: spin .9s linear infinite;
}

/* 로더 원형 스피너 안쪽 맥박 */
.loader-bar::after{
  content:""; position:absolute; inset:13px; border-radius:999px;
  background: rgba(255,255,255,.07);
  box-shadow: 0 0 18px rgba(255,255,255,.08);
  animation: pulse 1.1s ease-in-out infinite;
}

/* 로더 텍스트 */
.loader-text{
  font-size: 12px;
  font-weight: 900;
  color: rgba(255,255,255,.78);
  animation: textPulse 1.2s ease-in-out infinite;
}

/* 
  keyframes는 예전에 줄바꿈/붙여넣기 과정에서 깨진 적이 있어서
  현재 형태로 유지하는 쪽이 안전하다.
*/
@keyframes spin { to { transform: rotate(360deg); } }
@keyframes pulse{ 0%,100%{ transform: scale(.98); opacity:.75; } 50%{ transform: scale(1.03); opacity:1; } }
@keyframes textPulse{ 0%,100%{ opacity:.65; } 50%{ opacity:1; } }
@keyframes skeletonShimmer{ 0%{ background-position:120% 0; } 100%{ background-position:-80% 0; } }

/* 프로필 변경 버튼(라벨 + hidden file input 구조) */
.mypage-btn.profile-btn{
  width: 256px !important;
  padding: 14px 18px !important;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: auto;
  margin-right: auto;
  cursor: pointer;
}
.mypage-btn.profile-btn .btn-text{ font-size: 16px; font-weight: 600; }

/* 닉네임 중복확인/검증 메시지 영역 */
.msg-area{ margin-top: 10px; font-size: 13px; line-height: 1.35; }
.msg-ok{ color: #25d366; font-weight: 800; }
.msg-error{ color: #ff4c4c; font-weight: 800; }
.msg-info{ color: rgba(255,255,255,0.75); }

/* =========================
   입력 행 UI (split-pill)
   - 좌측 라벨/아이콘
   - 우측 값 영역
   ========================= */
:root{
  --accent: 229, 54, 55;
  --hud-bg: rgba(255,255,255,0.030);
  --hud-border: rgba(255,255,255,0.095);
}

/* 한 줄짜리 정보/입력 박스 */
.split-pill{
  height: 52px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  overflow: hidden;
  background: var(--hud-bg);
  border: 1px solid var(--hud-border);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  box-shadow: 0 12px 28px rgba(0,0,0,0.22), inset 0 1px 0 rgba(255,255,255,0.05);
  margin-bottom: 14px;
}

/* 좌측 라벨 영역 */
.split-label{
  width: 154px;
  display:flex;
  align-items:center;
  gap: 12px;
  padding: 0 14px 0 16px;
  position: relative;
}

/* 라벨/값 사이 구분선 */
.split-label::after{
  content:"";
  position:absolute;
  right: 0; top: 10px; bottom: 10px;
  width: 1px;
  background: rgba(255,255,255,0.06);
}

/* 라벨 아이콘 배지 */
.split-label .split-icon{
  width: 34px; height: 34px;
  border-radius: 12px;
  display:flex; align-items:center; justify-content:center;
  background: rgba(255,255,255,0.035);
  border: 1px solid rgba(var(--accent),0.22);
}

/* SVG 아이콘 스타일 */
.split-label svg{ width: 16px; height: 16px; stroke: rgba(var(--accent),0.90); stroke-width: 2; fill: none; }

/* 라벨 텍스트 */
.split-label .split-text{
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.45px;
  color: rgba(255,255,255,0.58);
  white-space: nowrap;
}

/* 우측 값 영역 */
.split-value{ flex: 1; display:flex; align-items:center; padding: 0 18px; }

/* 우측 input 공통 */
.split-value input{
  width: 100%; height: 52px;
  border: 0; outline: 0;
  background: transparent;
  padding-left: 12px;
  font-size: 14.5px;
  font-weight: 620;
  color: rgba(255,255,255,0.90);
}

/* 닉네임 줄처럼 오른쪽에 버튼이 붙는 2열 구조 */
.split-row{
  display: grid;
  grid-template-columns: 1fr 128px;
  gap: 12px;
  align-items: center;
  margin-bottom: 14px;
}
.split-row .split-pill{ margin-bottom: 0; }

/* =========================
   닉네임 중복확인 버튼
   ========================= */
.nick-check-btn{
  height: 52px;
  border-radius: 16px;
  font-weight: 800;
  letter-spacing: .2px;

  background: linear-gradient(135deg,
    rgba(255,76,76,0.18) 0%,
    rgba(229,54,55,0.10) 55%,
    rgba(201,44,45,0.08) 100%);
  border: 1px solid rgba(var(--accent),0.28);
  color: rgba(255,255,255,0.92);

  display:flex;
  align-items:center;
  justify-content:center;
  transition: .18s ease;
  box-shadow:
    0 12px 24px rgba(0,0,0,0.18),
    inset 0 1px 0 rgba(255,255,255,0.06);
}
.nick-check-btn:hover{
  filter: brightness(1.05);
  border-color: rgba(var(--accent),0.36);
}
.nick-check-btn.disabled-btn{
  opacity: .45;
  pointer-events:none;
}

/* 메시지가 비어있을 땐 영역 자체 숨김(레이아웃 깔끔하게) */
#nicknameMsg:empty{ display:none; }

/* =========================
   좌측 메뉴 / 드롭다운
   ========================= */
.side-menu{
  list-style: none;
  padding-left: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

/* 메뉴 링크/버튼 공통 스타일 */
.side-menu .menu-link, .side-menu .menu-btn{
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 14px;
  border-radius: 14px;
  color: rgba(255,255,255,0.88);
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.06);
  font-weight: 600;
  transition: 0.18s ease;
}
.side-menu .menu-link i, .side-menu .menu-btn i{ width: 18px; text-align: center; opacity: 0.9; }
.side-menu .menu-link:hover, .side-menu .menu-btn:hover{
  background: rgba(255,255,255,0.06);
  border-color: rgba(255,255,255,0.10);
  transform: translateY(-1px);
}

/* 위험 동작 버튼(로그아웃) 색상 강조 */
.side-menu .menu-btn.danger{
  color: #ff6b6b;
  background: rgba(229, 54, 55, 0.06);
  border-color: rgba(229, 54, 55, 0.18);
}
.side-menu .menu-btn.danger:hover{
  background: rgba(229, 54, 55, 0.10);
  border-color: rgba(229, 54, 55, 0.26);
}

/* 게시글 관리 드롭다운 컨테이너 */
.side-dropdown{ position: relative; }

/* 드롭다운 화살표 아이콘 */
.side-dropdown .dd-icon{
  margin-left: auto;
  opacity: 0.9;
  transition: transform .18s ease;
}

/* 드롭다운 메뉴(기본 숨김) */
.side-dropdown-menu{
  list-style: none;
  margin: 8px 0 0 0;
  padding: 10px;
  border-radius: 14px;
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.06);
  display: none;
}

/* hover 시 메뉴 열림 + 화살표 회전 */
.side-dropdown:hover .side-dropdown-menu{ display: block; }
.side-dropdown:hover .dd-icon{ transform: rotate(180deg); }

.side-dropdown-menu li{ margin-bottom: 8px; }
.side-dropdown-menu li:last-child{ margin-bottom: 0; }

/* 드롭다운 내부 링크 */
.side-dropdown-menu a{
  display: flex;
  align-items: center;
  padding: 10px 12px;
  border-radius: 12px;
  color: rgba(255,255,255,0.82);
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.05);
  font-weight: 600;
  transition: 0.18s ease;
}
.side-dropdown-menu a:hover{
  background: rgba(255,255,255,0.06);
  border-color: rgba(255,255,255,0.10);
  transform: translateY(-1px);
}

/* =========================
   좌/우 레이아웃 카드
   ========================= */
.mypage-col-left{ padding-right: 28px !important; }
.mypage-col-right{ padding-left: 28px !important; }

/* 좌측 카드 위에 드롭다운이 자연스럽게 뜨도록 overflow visible */
.mypage-side-card{ position: relative; z-index: 2; overflow: visible; }

/* 우측 정보 카드 */
.mypage-right-card{
  position: relative;
  z-index: 1;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.06);
  box-shadow: 0 18px 60px rgba(0,0,0,.35);
}

/* 편집 모드일 때 우측 카드 강조 */
body.mypage-editing .mypage-right-card{
  border-color: rgba(229,54,55,.18);
  box-shadow: 0 18px 60px rgba(0,0,0,.45);
}

/* 수정/취소 버튼 묶음 */
.edit-actions{ margin-top: 20px; display: flex; gap: 12px; }
.edit-actions .mypage-btn{ width: 100%; }

/* 모바일/태블릿 대응 */
@media (max-width: 991.98px){
  .mypage-col-left{ padding-right: 0 !important; margin-bottom: 18px; }
  .mypage-col-right{ padding-left: 0 !important; }
  .split-row{ grid-template-columns: 1fr; }
  .nick-check-btn{ width: 100%; }
  .profile-img-wrap{ width: 100%; max-width: 256px; height: auto; aspect-ratio: 1/1; }
}

/* =========================
   ADMIN 무료 꾸미기 - 레인보우 스타일
   - 닉네임 글자 색상용(rainbow-text)
   - 카드/테두리용(rainbow-border)
   - 프로필 박스는 overflow 이슈 때문에 전용 처리
   ========================= */
:root{
  --rb1: #ff4d4d;
  --rb2: #ffa94d;
  --rb3: #ffd43b;
  --rb4: #51cf66;
  --rb5: #38d9a9;
  --rb6: #4dabf7;
  --rb7: #845ef7;
}

/* 닉네임 글자만 레인보우 (배경클립 텍스트 방식) */
.rainbow-text{
  background: linear-gradient(90deg,
    var(--rb1),var(--rb2),var(--rb3),var(--rb4),var(--rb5),var(--rb6),var(--rb7),var(--rb1));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent !important;

  /* 현재는 고정 레인보우(애니메이션 없음) */
  background-size: 100% 100%;
  background-position: 50% 50%;
}

/* 카드/필드용 레인보우 테두리 베이스 */
.rainbow-border{
  position: relative;
  border-radius: inherit;
  isolation: isolate;
}
.rainbow-border::before{
  content:"";
  position:absolute;
  inset:-3px;
  border-radius: inherit;
  background: conic-gradient(from 0deg,
    var(--rb1),var(--rb2),var(--rb3),var(--rb4),var(--rb5),var(--rb6),var(--rb7),var(--rb1));
  z-index: 0;

  /* 현재 회전/움직임 없는 고정 테두리 */
  transform: none;
  animation: none;
}

.rainbow-border > *{ position: relative; z-index: 2; }

/* 
  프로필 박스 전용 레인보우 처리.
  profileWrap은 기본적으로 overflow:hidden이라 바깥 테두리가 잘릴 수 있어서
  padding + 내부 레이어 방식으로 따로 처리한다.
*/
#profileWrap.rainbow-border{
  overflow: visible !important;   /* 바깥 테두리 보이게 */
  padding: 3px;                   /* 테두리 두께 */
  background: transparent !important;
}
#profileWrap.rainbow-border::before{
  inset: 0 !important;
  border-radius: 18px !important;
  z-index: 0;
}

/* 
  안쪽 어두운 배경 레이어.
  바깥 레인보우 테두리와 실제 이미지 사이를 분리해준다.
*/
#profileWrap.rainbow-border::after{
  inset: 3px !important;
  border-radius: 15px !important;
  background: rgba(11,12,42,.92);
  z-index: 1;
}

/* 이미지가 테두리를 덮어쓰지 않도록 이미지 레이어를 위로 올리고 라운드 재적용 */
#profileWrap.rainbow-border img{
  position: relative;
  z-index: 2;
  border-radius: 15px;
}

/* =========================
   꾸미기 토글 버튼
   ========================= */
.deco-btn{
  display:flex;
  align-items:center;
  justify-content:center;
  gap: 10px;
  width: 100%;
  padding: 12px 14px;
  border-radius: 14px;
  font-weight: 800;
  letter-spacing: .2px;
  color: rgba(255,255,255,0.92);
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(255,255,255,0.03);
  transition: .18s ease;
}
.deco-btn:hover{
  background: rgba(255,255,255,0.06);
  transform: translateY(-1px);
}
.deco-btn .badge-free{
  font-size: 11px;
  font-weight: 900;
  padding: 3px 8px;
  border-radius: 999px;
  background: rgba(255,255,255,0.08);
  border: 1px solid rgba(255,255,255,0.10);
}

/* 현재 켜진 상태 시각 표시 */
.deco-btn.is-on{
  background: rgba(255,255,255,0.05);
  border-color: rgba(255,255,255,0.18);
}

/* 
  닉네임 표시용 span.
  실제 서버 전송은 hidden-ish input(#nicknameInput)이 담당하고,
  사용자에게 보이는 텍스트는 이 span으로 관리한다.
*/
#nicknameText{
  display:inline-block;
  padding-left: 12px;
  font-size: 14.5px;
  font-weight: 620;
  color: rgba(255,255,255,0.90);
  line-height: 52px;
}

/* 
  닉네임 줄 박스 자체에는 레인보우 테두리를 막는다.
  이 페이지 정책은 '닉네임 글자만 레인보우'라서 pill 배경/테두리는 일반 상태 유지.
*/
#nicknamePill.rainbow-border,
#nicknamePill.rainbow-border::before,
#nicknamePill.rainbow-border::after{
  content: none !important;
  background: transparent !important;
  animation: none !important;
  filter: none !important;
}
</style>
</head>

<body>
  <%-- 
    header.jsp에서 사람(프로필) 아이콘 링크를 사용할 수 있게 값 주입.
    관리자 페이지에서는 일반 myPage 대신 관리자 대시보드로 보내는 정책.
  --%>
  <c:set var="profileHref" value="/admindashboard" />

  <%-- 공통 헤더 include --%>
  <%@ include file="/WEB-INF/common/header.jsp" %>

  <%-- 
    컨트롤러에서 내려준 안내 메시지(msg)가 있으면 상단 경고 박스로 표시.
    c:out으로 출력해서 메시지 출력 시 HTML 해석 방지.
  --%>
	<c:if test="${not empty msg}">
	  <div class="container" style="margin-top: 18px;">
	    <div class="alert alert-warning" style="border-radius: 14px;"><c:out value="${msg}" /></div>
	  </div>
	</c:if>

  <div class="container mypage-title">
    <h1 class="mypage-title__h1">관리자 페이지</h1>
  </div>

  <section class="spad mypage-spad">
    <div class="container">
      <div class="row">

        <%-- =========================
             LEFT 영역 (프로필/관리 메뉴)
             ========================= --%>
        <div class="col-12 col-lg-4 mypage-col-left">
          <div class="login-box-clean mypage-side-card text-center">

            <%-- 
              프로필 이미지 래퍼.
              초기에는 is-loading을 붙여두고, JS에서 실제 이미지 로드 완료 시 제거한다.
            --%>
            <div class="profile-img-wrap is-loading" id="profileWrap">
              <c:choose>
                <%-- 사용자가 프로필 이미지를 가지고 있는 경우 --%>
                <c:when test="${not empty memberData.memberProfileImage}">
				<img id="profilePreview" alt="프로필 이미지"
				     data-real-src="<c:out value='${ctx}${memberData.memberProfileImage}'/>"
				     data-initial-src="<c:out value='${ctx}${memberData.memberProfileImage}'/>"
				     data-default-src="<c:out value='${ctx}/img/profile-default.jpg'/>"
				     src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==">
                </c:when>

                <%-- 프로필 이미지가 없으면 기본 이미지 기준으로 시작 --%>
                <c:otherwise>
				<img id="profilePreview" alt="프로필 이미지"
				     data-initial-src="<c:out value='${ctx}/img/profile-default.jpg'/>"
				     data-default-src="<c:out value='${ctx}/img/profile-default.jpg'/>"
				     src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==">
                </c:otherwise>
              </c:choose>

              <%-- 로딩 오버레이 (이미지 로딩/재시도 중 표시) --%>
              <div class="profile-loader" role="status" aria-live="polite">
                <div class="loader-bar" aria-hidden="true"></div>
                <div class="loader-text">이미지 불러오는 중</div>
              </div>
            </div>

            <%-- 
              label을 버튼처럼 쓰고 내부에 hidden file input을 넣은 구조.
              라벨 클릭 = 파일 선택창 열림.
              기본 상태는 disabled-btn로 막아두고, 편집 모드 진입 시 JS가 활성화한다.
            --%>
            <label id="profileBtnLabel" class="mypage-btn profile-btn disabled-btn">
              <span class="btn-text">프로필 사진 변경</span>
              <input type="file" id="profileInput" accept="image/*" hidden>
            </label>
          </div>

          <div class="login-box-clean mypage-side-card" style="margin-top: 20px;">
            <ul class="side-menu">
              <li>
                <a class="menu-link" href="${urlNewsManage}">
                  <i class="fa fa-newspaper-o"></i><span>뉴스 관리</span>
                </a>
              </li>

              <%-- 
                게시글 관리 드롭다운.
                현재는 ANIME 카테고리만 노출.
                href="#" + onclick return false로 상위 항목은 토글 역할만 한다.
              --%>
              <li class="side-dropdown">
                <a class="menu-link" href="#" onclick="return false;">
                  <i class="fa fa-list-alt"></i><span>게시글 관리</span>
                  <i class="fa fa-angle-down dd-icon"></i>
                </a>
                <ul class="side-dropdown-menu">
                  <li>
                    <a href="${urlBoardManageAnime}">ANIME</a>
                  </li>
                </ul>
              </li>

              <li>
                <a class="menu-link" href="${urlAnimeListManage}">
                  <i class="fa fa-film"></i><span>애니리스트 관리</span>
                </a>
              </li>

              <li>
                <a class="menu-link" href="${urlMyPosts}">
                  <i class="fa fa-pencil"></i><span>내 글 보기</span>
                </a>
              </li>

              <li>
                <a class="menu-link" href="${urlChangePasswordPage}">
                  <i class="fa fa-lock"></i><span>비밀번호 변경</span>
                </a>
              </li>

              <%-- 
                관리자 무료 꾸미기 토글 버튼들.
                실제 서버 전송값은 오른쪽 form의 hidden input(adminNickDecoStyle/adminProfileDecoStyle)에 기록된다.
              --%>
              <li>
                <button type="button" class="deco-btn" id="btnNickDeco">
                  <i class="fa fa-magic"></i>
                  <span class="rainbow-text" style="font-weight: 900;">닉네임 꾸미기</span>
                  <span class="badge-free">무료</span>
                </button>
              </li>

              <li>
                <button type="button" class="deco-btn" id="btnProfileDeco">
                  <i class="fa fa-magic"></i>
                  <span class="rainbow-text" style="font-weight: 900;">프로필 꾸미기</span>
                  <span class="badge-free">무료</span>
                </button>
              </li>

              <%-- 
                로그아웃은 바로 submit되지 않게 type="button"으로 두고
                JS에서 SweetAlert2 확인 모달 후 form submit 처리한다.
              --%>
              <li>
                <form action="${ctx}/logout" method="get" style="margin: 0;" id="logoutForm">
                  <button type="button" class="menu-btn danger" id="logoutBtn">
                    <i class="fa fa-sign-out"></i><span>로그아웃</span>
                  </button>
                </form>
              </li>
            </ul>
          </div>
        </div>

        <%-- =========================
             RIGHT 영역 (내 정보 / 수정 폼)
             ========================= --%>
        <div class="col-12 col-lg-8 mypage-col-right">
          <div class="login-box-clean mypage-right-card">
            <h5 style="margin-bottom: 24px;">내 정보</h5>

            <%-- 
              관리자 정보 수정 폼.
              닉네임/프로필 임시 업로드 토큰/꾸미기 상태(hidden) 등을 함께 전송한다.
            --%>
            <form id="mypageForm" action="${ctx}/member/profile" method="post">
              <%-- 프로필 파일 임시 업로드 후 서버가 발급한 토큰(최종 저장 시 이 토큰 기준 반영) --%>
              <input type="hidden" id="temporaryProfileImageToken"
                     name="temporaryProfileImageToken" value="" />

              <%-- 
                꾸미기 상태 hidden input.
                localStorage 대신 DB 값을 화면 초기 소스로 쓰고, 저장 시 이 값을 서버로 보낸다.
                값은 NONE / RAINBOW 둘 중 하나로 관리.
              --%>
              <input type="hidden" id="adminNickDecoStyle" name="adminNickDecoStyle"
                     value="${memberData.memberNicknameColor eq 'RAINBOW' ? 'RAINBOW' : 'NONE'}" />
              <input type="hidden" id="adminProfileDecoStyle" name="adminProfileDecoStyle"
                     value="${memberData.memberProfileColor eq 'RAINBOW' ? 'RAINBOW' : 'NONE'}" />

              <%-- 아이디(읽기 전용) --%>
              <div class="split-pill">
                <div class="split-label">
                  <span class="split-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24"><path d="M20 21a8 8 0 0 0-16 0"></path><circle cx="12" cy="8" r="4"></circle></svg>
                  </span>
                  <span class="split-text">아이디</span>
                </div>
                <div class="split-value">
                  <input type="text" value="<c:out value='${memberData.memberName}'/>" readonly>
                </div>
              </div>

              <%-- 이메일(읽기 전용) --%>
              <div class="split-pill">
                <div class="split-label">
                  <span class="split-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24"><path d="M4 6h16v12H4z"></path><path d="m4 7 8 6 8-6"></path></svg>
                  </span>
                  <span class="split-text">이메일</span>
                </div>
                <div class="split-value">
                  <input type="email" value="<c:out value='${memberData.memberEmail}'/>" readonly>
                </div>
              </div>

              <%-- 권한(세션 기준 표시, 읽기 전용) --%>
              <div class="split-pill">
                <div class="split-label">
                  <span class="split-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24"><path d="M12 2 20 6v6c0 5-3.5 9.5-8 10-4.5-.5-8-5-8-10V6z"></path><path d="M9 12l2 2 4-4"></path></svg>
                  </span>
                  <span class="split-text">권한</span>
                </div>
                <div class="split-value">
                  <input type="text" value="${sessionScope.memberRole}" readonly>
                </div>
              </div>

              <%-- 
                닉네임 영역
                - 사용자에게 보이는 값: #nicknameText (span)
                - 실제 서버 전송값: #nicknameInput (input[name=memberNickname])
                이렇게 분리한 이유는 평소에는 보기 모드(span)로 두고,
                편집 모드에서만 input 값을 제어하면서 UI를 자연스럽게 유지하기 위해서다.
              --%>
              <div class="split-row">
                <div class="split-pill" id="nicknamePill">
                  <div class="split-label">
                    <span class="split-icon" aria-hidden="true">
                      <svg viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="14" rx="2"></rect><circle cx="8.5" cy="12" r="2"></circle><path d="M13 11h6"></path><path d="M13 14h6"></path></svg>
                    </span>
                    <span class="split-text">닉네임</span>
                  </div>

                  <div class="split-value" style="position:relative;">
                    <span id="nicknameText"><c:out value="${memberData.memberNickname}" /></span>

                    <%-- 
                      실제 전송용 input.
                      예전에 name 누락되면 서버에 값이 안 넘어가서 저장이 안 되는 문제가 있었음.
                      현재는 name="memberNickname" 필수로 유지.
                    --%>
                    <input type="text" id="nicknameInput" name="memberNickname"
                           value="<c:out value='${memberData.memberNickname}'/>" readonly
                           style="position:absolute; inset:0; opacity:0; pointer-events:none;">
                  </div>
                </div>

                <%-- 편집 모드에서만 활성화되는 닉네임 중복확인 버튼 --%>
                <button id="nickCheckBtn" class="nick-check-btn disabled-btn"
                        type="button">중복 확인</button>
              </div>

              <%-- 닉네임 검증/중복확인 메시지 출력 영역 --%>
              <div class="msg-area" id="nicknameMsg"></div>

              <%-- 보기 모드 버튼 영역 (기본 노출) --%>
              <div class="row" style="margin-top: 26px;" id="viewActions">
                <div class="col-md-12">
                  <button id="editBtn" type="button" class="mypage-btn">내 정보 수정</button>
                </div>
              </div>

              <%-- 편집 모드 버튼 영역 (기본 숨김) --%>
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
  <%@ include file="/WEB-INF/common/footer.jsp" %>

  <%-- 공통 JS 로드 --%>
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>

  <script>
  /* =========================
     프로필 이미지 초기 로딩/재시도 로직
     - 서버 저장 직후 캐시/반영 타이밍 때문에 이미지가 바로 안 보일 수 있어서
       일정 시간 동안 재시도 후, 끝까지 실패하면 fallback 이미지로 교체한다.
     ========================= */
  (function() {
    /* 
      캐시 무효화용 쿼리스트링 추가.
      같은 URL이어도 브라우저가 이전 캐시를 보여주는 걸 줄이기 위해 v=timestamp를 붙인다.
    */
    function addCacheBust(url) {
      const sep = url.includes("?") ? "&" : "?";
      return url + sep + "v=" + Date.now();
    }

    document.addEventListener("DOMContentLoaded", function() {
      const wrap = document.getElementById("profileWrap");
      const img = document.getElementById("profilePreview");
      if (!wrap || !img) return;

      /* data-* 속성에서 초기값/실제 이미지/fallback 추출 */
      const real = img.dataset.realSrc || "";
      const initial = img.dataset.initialSrc || img.dataset.defaultSrc || "";
      const fallback = img.dataset.defaultSrc || "";

      /* 로딩 시작 */
      wrap.classList.add("is-loading");

      /* 
        realSrc가 없는 경우(프로필 이미지 미보유)에는
        초기 이미지(대개 기본 이미지)만 넣고 즉시 로딩 종료.
      */
      if (!real) {
        img.src = addCacheBust(initial || fallback);
        wrap.classList.remove("is-loading");
        return;
      }

      /* 
        프로필 저장 직후 파일 반영 타이밍을 고려한 재시도 파라미터
        - START_DELAY_MS: 첫 시도 전 잠깐 대기
        - INTERVAL_MS: 실패 시 재시도 간격
        - MAX_WAIT_MS: 최대 대기 시간(넘으면 fallback)
      */
      const START_DELAY_MS = 1000;
      const INTERVAL_MS = 250;
      const MAX_WAIT_MS = 15000;
      const startAt = Date.now();

      function tryLoad() {
        const elapsed = Date.now() - startAt;

        /* 최대 대기시간 초과 시 fallback로 종료 */
        if (elapsed >= MAX_WAIT_MS) {
          img.src = addCacheBust(fallback || initial);
          wrap.classList.remove("is-loading");
          return;
        }

        /* 실제 이미지 URL에 캐시버스트 붙여 preloading 테스트 */
        const testSrc = addCacheBust(real);
        const pre = new Image();

        pre.onload = function() {
          /* preload 성공하면 실제 표시 이미지에 반영하고 로딩 종료 */
          img.src = testSrc;
          wrap.classList.remove("is-loading");
        };
        pre.onerror = function() {
          /* 아직 파일이 준비 안 됐거나 접근 불가면 잠시 후 재시도 */
          setTimeout(tryLoad, INTERVAL_MS);
        };

        pre.src = testSrc;
      }

      /* 첫 시도는 약간 기다렸다가 시작 */
      setTimeout(tryLoad, START_DELAY_MS);
    });
  })();
  </script>

  <script>
  $(function() {

    /* =========================
       페이지 내 API 엔드포인트 / 정규식 / 상태값
       ========================= */

    /* 프로필 임시 업로드 API (파일 업로드 후 토큰/임시 URL 반환) */
    const URL_PROFILE_UPLOAD = "${ctx}/member/profile/upload";

    /* 닉네임 중복 확인 API */
    const URL_NICK_CHECK = "${ctx}/member/nickname/check";

    /* 닉네임 규칙: 2~12자, 한글/영문/숫자만 허용 */
    const NICK_REGEX = /^[A-Za-z0-9가-힣]{2,12}$/;

    /* 
      편집 상태 플래그들
      - editMode: 현재 편집 모드 여부
      - nicknameChecked: 닉네임 중복확인 완료 여부(새 닉네임일 때 저장 가능 조건)
      - profileChanged: 프로필 이미지가 변경되었는지 여부
    */
    let editMode = false;
    let nicknameChecked = false;
    let profileChanged = false;

    /* 
      원본값 스냅샷
      - 취소 시 복원 기준
      - 변경 여부 판단 기준
    */
    const originalNickname = $("#nicknameInput").val().trim();
    const originalProfileSrc = $("#profilePreview").data("initialSrc");

    /* 캐시 무효화 유틸 (프로필 이미지 미리보기 갱신용) */
    function addCacheBust(url) {
      if (!url) return url;
      const sep = url.indexOf("?") >= 0 ? "&" : "?";
      return url + sep + "v=" + Date.now();
    }

    /* =========================
       저장 버튼 활성화 조건 계산
       =========================
       저장 가능 조건을 한 군데에서 관리해서
       닉네임/프로필/꾸미기 토글이 섞여도 판단 로직이 흩어지지 않게 한다.
    */
    function updateSaveButton() {
      const newNickname = $("#nicknameInput").val().trim();
      const token = $("#temporaryProfileImageToken").val().trim();

      /* 닉네임 변경 여부 */
      const nickChanged = editMode && (newNickname !== originalNickname);

      /* 프로필 업로드 완료 여부 (토큰이 있어야 실제 저장 가능) */
      const profileOk = editMode && profileChanged && token.length > 0;

      /* 꾸미기 토글 변경 여부 (내부 IIFE에서 window 함수로 제공) */
      const decoDirty = (typeof window.__adminDecoDirty === "function") ? window.__adminDecoDirty() : false;

      let canSave = true;

      /* 아무 것도 안 바뀌었으면 저장 불가 */
      if (!nickChanged && !profileOk && !decoDirty) canSave = false;

      /* 닉네임이 바뀐 경우는 규칙 + 중복확인 통과가 필수 */
      if (nickChanged) {
        if (!NICK_REGEX.test(newNickname)) canSave = false;
        if (!nicknameChecked) canSave = false;
      }

      /* 프로필 변경 플래그는 켰는데 토큰이 없으면 업로드 미완료 상태라 저장 불가 */
      if (editMode && profileChanged && token.length === 0) canSave = false;

      /* 버튼 클래스 토글 */
      if (editMode && canSave) $("#saveBtn").removeClass("disabled-btn");
      else $("#saveBtn").addClass("disabled-btn");
    }

    /* =========================
       편집 모드 진입
       ========================= */
    $("#editBtn").on("click", function() {
      editMode = true;
      $("body").addClass("mypage-editing");

      /* 보기 모드 버튼 숨기고 편집 버튼 묶음 노출 */
      $("#viewActions").hide();
      $("#editActions").show();

      /* 편집 가능한 요소 활성화 */
      $("#nicknameInput").prop("readonly", false);
      $("#nickCheckBtn").removeClass("disabled-btn");
      $("#profileBtnLabel").removeClass("disabled-btn");

      /* 새 편집 세션 시작 시 검증 상태 초기화 */
      nicknameChecked = false;
      profileChanged = false;
      $("#nicknameMsg").text("");

      /* 임시 업로드 관련 값 초기화 */
      $("#temporaryProfileImageToken").val("");
      $("#profileInput").val("");

      updateSaveButton();
    });

    /* 편집 취소 버튼 */
    $("#cancelBtn").on("click", function() {
      exitEditMode(true);
    });

    /* =========================
       편집 모드 종료 공통 함수
       resetValues=true면 원본값으로 복구
       ========================= */
    function exitEditMode(resetValues) {
      editMode = false;
      $("body").removeClass("mypage-editing");

      if (resetValues) {
        /* 닉네임 복구 (입력값 + 표시 span 둘 다) */
        $("#nicknameInput").val(originalNickname);
        $("#nicknameText").text(originalNickname);

        /* 프로필 이미지 복구 (쿼리 제거 후 캐시버스트 재부여) */
        const base = (originalProfileSrc || "").split("?")[0];
        $("#profileWrap").addClass("is-loading");
        $("#profilePreview").attr("src", addCacheBust(base));
        setTimeout(function() { $("#profileWrap").removeClass("is-loading"); }, 150);

        /* 임시 업로드 토큰/파일선택 초기화 */
        $("#temporaryProfileImageToken").val("");
        $("#profileInput").val("");

        /* 꾸미기 상태도 편집 시작 전 기준값으로 되돌림 */
        if (typeof window.__adminDecoResetToBase === "function") {
          window.__adminDecoResetToBase();
        }
      }

      /* 편집 UI 비활성화 */
      $("#nicknameInput").prop("readonly", true);
      $("#nickCheckBtn").addClass("disabled-btn").text("중복 확인");
      $("#profileBtnLabel").addClass("disabled-btn");

      /* 버튼 영역 전환 */
      $("#editActions").hide();
      $("#viewActions").show();

      /* 메시지/플래그 초기화 */
      $("#nicknameMsg").text("");

      nicknameChecked = false;
      profileChanged = false;

      updateSaveButton();
    }

    /* =========================
       닉네임 입력 실시간 검증
       ========================= */
    $("#nicknameInput").on("input", function() {
      if (!editMode) return;

      const val = $("#nicknameInput").val().trim();

      /* 화면에 보이는 닉네임 span 즉시 동기화 */
      $("#nicknameText").text(val);

      /* 형식 검증 메시지 */
      if (val.length > 0 && !NICK_REGEX.test(val)) {
        $("#nicknameMsg").removeClass("msg-ok").addClass("msg-error")
          .text("닉네임은 2~12자, 한글/영문/숫자만 사용할 수 있습니다.");
      } else {
        $("#nicknameMsg").text("");
      }

      /* 입력이 바뀌면 기존 중복확인 결과는 무효 */
      nicknameChecked = false;
      $("#nickCheckBtn").text("중복 확인");
      updateSaveButton();
    });

    /* =========================
       닉네임 중복 확인 버튼
       ========================= */
    $("#nickCheckBtn").on("click", function() {
      if (!editMode) return;

      const nickname = $("#nicknameInput").val().trim();

      /* 1) 형식 검증 먼저 */
      if (!NICK_REGEX.test(nickname)) {
        $("#nicknameMsg").removeClass("msg-ok").addClass("msg-error")
          .text("닉네임은 2~12자, 한글/영문/숫자만 사용할 수 있습니다.");
        nicknameChecked = false;
        updateSaveButton();
        return;
      }

      /* 2) 원래 닉네임과 같으면 중복확인 의미 없음 */
      if (nickname === originalNickname) {
        $("#nicknameMsg").removeClass("msg-ok").addClass("msg-error")
          .text("현재 닉네임과 동일합니다.");
        nicknameChecked = false;
        updateSaveButton();
        return;
      }

      /* 3) 서버 중복 확인 호출 */
      $.ajax({
        url: URL_NICK_CHECK,
        type: "GET",
        dataType: "json",
        data: { memberNickname: nickname },
        success: function(res) {
          /* 응답 형식 자체가 이상하거나 success=false면 실패 처리 */
          if (!res || res.success !== true) {
            $("#nicknameMsg").removeClass("msg-ok").addClass("msg-error")
              .text((res && res.message) ? res.message : "중복확인에 실패했습니다.");
            nicknameChecked = false;
            $("#nickCheckBtn").text("중복 확인");
            updateSaveButton();
            return;
          }

          /* 사용 가능 여부에 따라 상태/문구/버튼 텍스트 변경 */
          if (res.available === true) {
            $("#nicknameMsg").removeClass("msg-error").addClass("msg-ok")
              .text("사용 가능한 닉네임입니다.");
            nicknameChecked = true;
            $("#nickCheckBtn").text("확인 완료");
          } else {
            $("#nicknameMsg").removeClass("msg-ok").addClass("msg-error")
              .text("이미 사용 중인 닉네임입니다.");
            nicknameChecked = false;
            $("#nickCheckBtn").text("중복 확인");
          }
          updateSaveButton();
        },
        error: function() {
          /* 통신 실패 */
          $("#nicknameMsg").removeClass("msg-ok").addClass("msg-error")
            .text("중복확인 서버 호출에 실패했습니다.");
          nicknameChecked = false;
          $("#nickCheckBtn").text("중복 확인");
          updateSaveButton();
        }
      });
    });

    /* =========================
       프로필 이미지 업로드(임시 업로드)
       - 파일 선택 즉시 서버에 업로드
       - 성공하면 임시 URL 미리보기 + 임시 토큰 저장
       - 최종 저장 버튼에서 토큰과 함께 프로필 적용
       ========================= */
    $("#profileInput").on("change", function() {
      if (!editMode) return;

      const file = this.files[0];
      if (!file) return;

      /* 이미지 파일만 허용 */
      if (!file.type || !file.type.startsWith("image/")) {
        Swal.fire({ icon: "warning", title: "이미지 파일만 선택할 수 있습니다.", confirmButtonColor: "#e53637" });
        $(this).val("");
        return;
      }

      /* 로딩 오버레이 표시 */
      $("#profileWrap").addClass("is-loading");

      const formData = new FormData();
      formData.append("profileImageFile", file);

      $.ajax({
        url: URL_PROFILE_UPLOAD,
        type: "POST",
        data: formData,
        processData: false,
        contentType: false,
        dataType: "json",
        success: function(res) {
          /* 업로드 실패 응답 */
          if (!res || res.result !== "SUCCESS") {
            Swal.fire({ icon: "error", title: "업로드 실패", text: (res && res.errorMessage) ? res.errorMessage : "업로드에 실패했습니다.", confirmButtonColor: "#e53637" });
            $("#profileInput").val("");
            $("#profileWrap").removeClass("is-loading");
            return;
          }

          /* 
            임시 업로드 성공:
            - 미리보기 이미지 교체
            - 로딩 해제
            - 임시 토큰 hidden input 저장(최종 저장 시 서버가 참조)
          */
          $("#profilePreview").attr("src", addCacheBust(res.temporaryProfileImageUrl));
          $("#profileWrap").removeClass("is-loading");

          $("#temporaryProfileImageToken").val(res.temporaryProfileImageToken);

          profileChanged = true;
          updateSaveButton();
        },
        error: function(xhr) {
          Swal.fire({ icon: "error", title: "업로드 실패", text: "프로필 업로드 실패(" + xhr.status + "). 다시 시도해주세요.", confirmButtonColor: "#e53637" });
          $("#profileInput").val("");
          $("#profileWrap").removeClass("is-loading");
        }
      });
    });

    /* =========================
       ADMIN 무료 꾸미기(레인보우) 상태 관리
       - localStorage 대신 hidden input(DB값 기반)을 소스오브트루스로 사용
       - 닉네임/프로필 버튼 클릭 시 즉시 편집모드 진입 + 토글 반영
       - 저장 완료 후 기준값(baseNick/baseProf) 갱신
       ========================= */
    (function(){
      const $btnNick = $("#btnNickDeco");
      const $btnProf = $("#btnProfileDeco");

      const $nickText = $("#nicknameText");
      const $profile  = $("#profileWrap");

      /* 실제 서버 전송값을 들고 있는 hidden input */
      const $hNick = $("#adminNickDecoStyle");    // NONE|RAINBOW
      const $hProf = $("#adminProfileDecoStyle"); // NONE|RAINBOW

      /* 
        기준값(base) = 페이지 로드시 DB에서 내려온 값
        취소/dirty 판정/저장 후 commit 기준으로 사용한다.
      */
      let baseNick = $hNick.val() || "NONE";
      let baseProf = $hProf.val() || "NONE";

      /* 
        꾸미기 버튼을 먼저 눌러도 자연스럽게 편집 모드로 진입시키기 위한 헬퍼
        (닉네임/프로필 수정 흐름과 같은 편집 모드 UI를 재사용)
      */
      function enterEditModeIfNeeded(){
        if (editMode) return;

        editMode = true;
        $("body").addClass("mypage-editing");

        $("#viewActions").hide();
        $("#editActions").show();

        $("#nicknameInput").prop("readonly", false);
        $("#nickCheckBtn").removeClass("disabled-btn");
        $("#profileBtnLabel").removeClass("disabled-btn");

        /* 새 편집 세션이므로 닉네임 검증 상태/문구 초기화 */
        nicknameChecked = false;
        $("#nickCheckBtn").text("중복 확인");
        $("#nicknameMsg").text("");
      }

      /* 
        hidden input 값 상태를 기반으로 실제 화면 클래스 반영
        - 닉네임: rainbow-text
        - 프로필: rainbow-border
        - 버튼: is-on
      */
      function render(){
        const nickOn = ($hNick.val() === "RAINBOW");
        const profOn = ($hProf.val() === "RAINBOW");

        $nickText.toggleClass("rainbow-text", nickOn);
        $btnNick.toggleClass("is-on", nickOn);

        /* 프로필은 이미지 자체 색상 변경이 아니라 테두리만 레인보우 */
        $profile.toggleClass("rainbow-border", profOn);
        $btnProf.toggleClass("is-on", profOn);
      }

      /* 
        저장 버튼 활성화 로직에서 사용할 dirty 판정 함수(window에 노출)
        편집모드 중이고, 현재 값이 기준값(base)과 다르면 변경사항 있음으로 본다.
      */
      window.__adminDecoDirty = function(){
        return editMode && ($hNick.val() !== baseNick || $hProf.val() !== baseProf);
      };

      /* 취소 시 기준값(base)으로 hidden input 복구 + 화면 재렌더 */
      window.__adminDecoResetToBase = function(){
        $hNick.val(baseNick);
        $hProf.val(baseProf);
        render();
      };

      /* 페이지 로드 시 DB값 기준으로 첫 렌더링 */
      render();

      /* 닉네임 꾸미기 토글 버튼 */
      $btnNick.on("click", function(){
        enterEditModeIfNeeded();
        $hNick.val(($hNick.val() === "RAINBOW") ? "NONE" : "RAINBOW");
        render();
        updateSaveButton();
      });

      /* 프로필 꾸미기 토글 버튼 */
      $btnProf.on("click", function(){
        enterEditModeIfNeeded();
        $hProf.val(($hProf.val() === "RAINBOW") ? "NONE" : "RAINBOW");
        render();
        updateSaveButton();
      });

      /* 
        저장 직전 호출되는 commit 함수(window에 노출)
        현재 hidden input 값을 새로운 기준값(base)으로 확정한다.
        (localStorage를 안 쓰고도 저장 후 dirty 판단이 맞게 유지되게 하는 핵심)
      */
      window.__adminDecoCommit = function(){
        baseNick = $hNick.val() || "NONE";
        baseProf = $hProf.val() || "NONE";
      };
    })();

    /* =========================
       저장 버튼 클릭
       - 비활성 상태면 무시
       - SweetAlert2 확인 후 실제 submit
       - submit 직전에 꾸미기 기준값 commit 처리
       ========================= */
    $("#saveBtn").off("click").on("click", function() {
      if ($(this).hasClass("disabled-btn")) return;

      Swal.fire({
        title: "수정을 완료할까요?",
        icon: "question",
        showCancelButton: true,
        confirmButtonText: "확인",
        cancelButtonText: "취소",
        confirmButtonColor: "#e53637"
      }).then(function(result) {
        if (!result.isConfirmed) return;

        /* 저장 확정되면 현재 꾸미기 상태를 기준값으로 갱신 */
        if (typeof window.__adminDecoCommit === "function") {
          window.__adminDecoCommit();
        }

        /* 중복 제출 방지용으로 버튼 비활성화 후 submit */
        $("#saveBtn").addClass("disabled-btn");
        $("#mypageForm").submit();
      });
    });

    /* =========================
       로그아웃 버튼 클릭
       - SweetAlert2 확인 후 GET /logout form submit
       ========================= */
    $("#logoutBtn").on("click", function() {
      Swal.fire({
        title: "로그아웃 하시겠습니까?",
        icon: "question",
        showCancelButton: true,
        confirmButtonText: "확인",
        cancelButtonText: "취소",
        confirmButtonColor: "#e53637"
      }).then(function(result) {
        if (result.isConfirmed) {
          $("#logoutForm").submit();
        }
      });
    });

    /* 초기 진입 시 저장 버튼 상태 계산 */
    updateSaveButton();
  });
  </script>
</body>
</html>