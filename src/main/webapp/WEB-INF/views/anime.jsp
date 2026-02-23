<%-- =========================================================
  AniMale Anime List (비동기 + 필터 + 검색 + 정렬 + 페이징)
  ---------------------------------------------------------
  이 페이지는 '처음 JSP 렌더 1번 + 이후 데이터는 JS(fetch)로 교체' 구조다.
  즉, 화면 골격은 JSP가 만들고 카드 목록/페이징은 API 응답으로 다시 그린다.

  내가 나중에 다시 볼 때 핵심 흐름
  1) 상단 컨트롤에서 상태값(검색/필터/정렬) 변경
  2) loadAnimeList(page)에서 /api/anime 호출
  3) renderAnimeList / renderPaging로 DOM 갱신
  4) 서버 paging 값으로 필터 UI(syncFilterUI) 재동기화

  참고:
  - 경로는 ctx(contextPath) 기준으로 통일
  - 카드 렌더링 시 escapeHtml로 텍스트 출력 XSS 방어
========================================================= --%>

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%-- 이 페이지에서 정적 리소스 / 링크 / API 경로 만들 때 계속 쓰므로 ctx로 한번 빼둠 --%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 애니</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<!-- 파비콘: 컨텍스트 경로 기준 -->
<link rel="icon" type="image/png" href="${ctx}/favicon.png">
<link rel="stylesheet" href="${ctx}/css/elegant-icons.css">

<!-- Google Font -->
<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

<!-- CSS -->
<link rel="stylesheet" href="${ctx}/css/bootstrap.min.css">
<link rel="stylesheet" href="${ctx}/css/font-awesome.min.css">
<link rel="stylesheet" href="${ctx}/css/style.css">
<link rel="stylesheet" href="${ctx}/css/anime-list.css">
</head>

<body>
  <%-- 공용 헤더 포함 (상단 네비/로그인 상태 등 공통 UI) --%>
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <section class="product-page spad anime-list-page">
    <div class="container">

      <!-- =========================================================
           상단 타이틀 + 컨트롤 영역
           ---------------------------------------------------------
           좌측: 페이지 제목
           우측: 검색 / 전체보기 / 관리자 버튼 / 필터 / 정렬
           실제 목록 데이터는 아래 animeContainer에 비동기로 렌더됨
         ========================================================= -->
      <div class="product__page__title">
        <div class="row align-items-center">
          <div class="col-lg-8">
            <div class="section-title">
              <h4>애니</h4>
            </div>
          </div>

          <div class="col-lg-4">
            <div class="anime-controls">

              <!-- =========================================================
                   1줄: 검색 + 전체보기 + (관리자 전용) 애니 추가
                   ---------------------------------------------------------
                   검색은 즉시 서버 호출하지 않고 버튼/엔터로 실행
                   전체보기는 검색/필터/정렬 상태를 초기값으로 되돌림
                 ========================================================= -->
              <div class="anime-search-wrapper">
                <div class="anime-search-box">
                  <!-- 검색 조건(서버로 condition 전달) -->
                  <select id="animeSearchType">
                    <option value="ANIME_SEARCH_TITLE">제목</option>
                    <option value="ANIME_SEARCH_STORY">줄거리</option>
                  </select>

                  <!-- 키워드 입력 -->
                  <input type="text" id="animeSearchInput" placeholder="검색어를 입력하세요">

                  <!-- 검색 실행 버튼 -->
                  <button type="button" id="animeSearchBtn"><i class="fa fa-search"></i></button>
                </div>

                <!-- 전체보기: 상태 초기화 + 1페이지 재조회 -->
                <button type="button" id="animeResetBtn" class="anime-reset-btn">전체보기</button>

                <%-- 관리자일 때만 애니 등록 버튼 노출
                     sessionScope.memberRole를 대문자로 맞춰 비교해서 대소문자 흔들림 방지 --%>
                <c:if test="${fn:toUpperCase(sessionScope.memberRole) eq 'ADMIN'}">
                  <a class="anime-admin-btn" href="${ctx}/animeWrite">애니 추가</a>
                </c:if>
              </div>

              <!-- =========================================================
                   2줄: 연도/분기 필터 + 정렬
                   ---------------------------------------------------------
                   연도/분기는 선택값(uiYear/uiQuarter)과 실제 적용값(filterYear/filterQuarter)을 분리함.
                   즉, 드롭다운에서 고른 뒤 '필터 적용' 눌러야 서버 반영.
                   정렬은 선택 즉시 반영(loadAnimeList 호출).
                 ========================================================= -->
              <div class="anime-sub-controls">

                <div class="product__page__filter filter-box">
                  <p>연도/분기</p>

                  <!-- 커스텀 드롭다운: Year -->
                  <div class="am-dd am-dd--year" id="ddYear" data-value="ALL">
                    <button type="button" class="am-dd__btn" aria-expanded="false">
                      <span class="am-dd__text" id="yearText">전체 연도</span>
                      <i class="fa fa-angle-down am-dd__chev"></i>
                    </button>
                    <ul class="am-dd__list" role="listbox">
                      <li class="active" data-value="ALL">전체 연도</li>
                      <%-- 연도 목록은 화면에서 바로 바꿔보기 쉽도록 JSTL 반복으로 생성 --%>
                      <c:forEach var="y" begin="1980" end="2026">
                        <li data-value="${y}">${y}년</li>
                      </c:forEach>
                    </ul>
                  </div>

                  <!-- 커스텀 드롭다운: Quarter -->
                  <div class="am-dd am-dd--quarter" id="ddQuarter" data-value="ALL">
                    <button type="button" class="am-dd__btn" aria-expanded="false">
                      <span class="am-dd__text" id="quarterText">전체 분기</span>
                      <i class="fa fa-angle-down am-dd__chev"></i>
                    </button>
                    <ul class="am-dd__list" role="listbox">
                      <li class="active" data-value="ALL">전체 분기</li>
                      <%-- 분기 값은 서버 전달 시 숫자(1~4)로 쓰기 쉽게 data-value를 숫자로 유지 --%>
                      <c:forEach var="q" begin="1" end="4">
                        <li data-value="${q}">${q}분기</li>
                      </c:forEach>
                    </ul>
                  </div>

                  <!-- Apply 버튼: uiYear/uiQuarter → filterYear/filterQuarter로 확정 -->
                  <button type="button" id="filterApplyBtn" class="anime-filter-apply">필터 적용</button>

                  <!-- 현재 적용 중인 필터 상태 표시 (예: 2025년 · 1분기 적용중) -->
                  <span id="filterStatus" class="filter-status"></span>
                </div>

                <div class="product__page__filter sort-box">
                  <p>정렬</p>

                  <!-- 커스텀 드롭다운: Sort
                       정렬은 별도 Apply 없이 선택 즉시 서버 재조회 -->
                  <div class="am-dd am-dd--sort" id="ddSort" data-value="RECENT">
                    <button type="button" class="am-dd__btn" aria-expanded="false">
                      <span class="am-dd__text">최신 등록순</span>
                      <i class="fa fa-angle-down am-dd__chev"></i>
                    </button>
                    <ul class="am-dd__list" role="listbox">
                      <li class="active" data-value="RECENT">최신 등록순</li>
                      <li data-value="OLDEST">오래된 순</li>
                      <li data-value="TITLE">제목 가나다순</li>
                    </ul>
                  </div>
                </div>

              </div><!-- /.anime-sub-controls -->

            </div><!-- /.anime-controls -->
          </div>
        </div><!-- /.row -->
      </div><!-- /.product__page__title -->

      <!-- 카드 리스트 렌더 영역
           fetch 응답 받은 animeList를 JS에서 여기 안에 통째로 다시 그림 -->
      <div class="row" id="animeContainer"></div>

      <!-- 검색 결과 없음 UI
           목록이 비어 있을 때만 JS에서 show() -->
      <div class="search-result-wrapper" id="searchEmpty" style="display:none;">
        <div class="search-empty">검색 결과가 없습니다.</div>
      </div>

      <!-- 페이지네이션 영역
           paging 데이터 기준으로 JS가 li/a를 동적으로 생성 -->
      <div class="row">
        <div class="col-lg-12">
          <div class="pagination-wrapper">
            <ul class="anime-pagination" id="pagingArea"></ul>
          </div>
        </div>
      </div>

    </div><!-- /.container -->
  </section>

  <%-- 공용 푸터 포함 --%>
  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <!-- 라이브러리 로드 순서 중요
       jquery 먼저, 그 다음 bootstrap, 마지막 main.js -->
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <script>
  // JSP의 ctx를 JS에서도 공통 사용하기 위해 상수로 보관
  // (API 호출 경로 / 상세페이지 링크 / 썸네일 경로 보정에 모두 사용)
  const contextPath = '${ctx}';

  // =========================================================
  // 1) 전역 상태 변수
  // ---------------------------------------------------------
  // 이 페이지는 '현재 화면 상태'를 JS 변수로 들고 있다가
  // 서버 호출 시 params로 조합하는 방식이다.
  //
  // 상태를 나눠둔 이유:
  // - uiYear/uiQuarter: 드롭다운에서 고른 값 (아직 적용 안 됨)
  // - filterYear/filterQuarter: 실제 서버에 반영된 값
  // =========================================================
  let currentSort = 'RECENT';      // 정렬 상태 (정렬 드롭다운 선택 즉시 반영)
  let uiYear = 'ALL';              // 연도 드롭다운에서 현재 선택된 값 (Apply 전)
  let uiQuarter = 'ALL';           // 분기 드롭다운에서 현재 선택된 값 (Apply 전)
  let filterYear = null;           // 서버 전달용 연도 필터 (Apply 후 확정)
  let filterQuarter = null;        // 서버 전달용 분기 필터 (Apply 후 확정)
  let condition = 'ANIME_LIST_RECENT'; // 서버 조회 조건(검색 안 하면 기본 목록 조건)
  let keyword = null;              // 검색어 (없으면 null로 보내서 파라미터 생략)

  $(function () {

    // =========================================================
    // (A) 커스텀 드롭다운 공통 로직
    // ---------------------------------------------------------
    // am-dd 클래스(연도/분기/정렬) 모두 같은 패턴이라 공통 함수로 처리
    // =========================================================
    function closeAllDropdowns() {
      // 열려있는 드롭다운 전부 닫고 aria-expanded도 false로 맞춤
      $('.am-dd')
        .removeClass('is-open')
        .find('.am-dd__btn')
        .attr('aria-expanded', 'false');
    }

    function openDropdown($dd) {
      // 한 번에 하나만 열리게: 먼저 전체 닫고 대상만 열기
      closeAllDropdowns();
      $dd.addClass('is-open').find('.am-dd__btn').attr('aria-expanded', 'true');
    }

    function setDropdown($dd, value, label) {
      // 드롭다운 표시값/선택 상태(active) 동기화용 공통 함수
      // 여기 하나로 UI 텍스트 + data-value + active 클래스까지 맞춘다.
      $dd.attr('data-value', value);
      $dd.find('.am-dd__text').text(label);

      $dd.find('.am-dd__list li').removeClass('active');
      $dd.find('.am-dd__list li[data-value="' + value + '"]').addClass('active');
    }

    $('.am-dd').on('click', '.am-dd__btn', function (e) {
      // 버튼 클릭 시 드롭다운 토글
      // stopPropagation 안 하면 document 클릭 핸들러가 바로 닫아버릴 수 있음
      e.preventDefault();
      e.stopPropagation();

      const $dd = $(this).closest('.am-dd');
      if ($dd.hasClass('is-open')) closeAllDropdowns();
      else openDropdown($dd);
    });

    $('.am-dd').on('click', '.am-dd__list li', function (e) {
      // 항목 선택 시:
      // 1) UI 갱신
      // 2) 상태 변수 반영
      // 3) 정렬이면 즉시 조회 / 필터면 Apply 전까지 대기
      e.preventDefault();
      e.stopPropagation();

      const $li = $(this);
      const $dd = $li.closest('.am-dd');
      const value = String($li.data('value'));
      const label = $li.text();

      setDropdown($dd, value, label);
      closeAllDropdowns();

      if ($dd.attr('id') === 'ddYear') {
        // 연도는 일단 UI 선택값만 바꿈 (Apply 버튼 누를 때 확정)
        uiYear = value;
      } else if ($dd.attr('id') === 'ddQuarter') {
        // 분기도 동일하게 UI 선택값만 변경
        uiQuarter = value;
      } else if ($dd.attr('id') === 'ddSort') {
        // 정렬은 선택 즉시 서버 재조회
        currentSort = value;
        loadAnimeList(1);
      }
    });

    $(document).on('click', function () {
      // 드롭다운 바깥 클릭하면 전부 닫기
      closeAllDropdowns();
    });

    // =========================================================
    // (B) 필터 적용(연도/분기)
    // ---------------------------------------------------------
    // uiYear/uiQuarter(화면 선택값)를 서버 전달용 filterYear/filterQuarter로 변환
    // ALL이면 null로 보내서 서버에서 필터 미적용 처리
    // =========================================================
    $('#filterApplyBtn').on('click', function () {
      filterYear = (uiYear !== 'ALL') ? parseInt(uiYear, 10) : null;
      filterQuarter = (uiQuarter !== 'ALL') ? parseInt(uiQuarter, 10) : null;
      loadAnimeList(1);
    });

    // =========================================================
    // (C) 검색(버튼/엔터)
    // ---------------------------------------------------------
    // 검색어가 비어있으면 일반 목록 모드로 복귀
    // 검색어가 있으면 condition을 검색 타입(제목/줄거리)으로 변경
    // =========================================================
    $('#animeSearchBtn').on('click', function () {
      const value = $('#animeSearchInput').val().trim();
      const searchType = $('#animeSearchType').val();

      if (value === '') {
        // 빈 검색은 검색 해제와 동일하게 처리
        keyword = null;
        condition = 'ANIME_LIST_RECENT';
      } else {
        keyword = value;
        condition = searchType;
      }
      loadAnimeList(1);
    });

    $('#animeSearchInput').on('keydown', function (e) {
      // 입력창에서 Enter 누르면 버튼 클릭과 동일하게 처리
      if (e.key === 'Enter') {
        e.preventDefault();
        $('#animeSearchBtn').click();
      }
    });

    // =========================================================
    // (D) 전체보기(검색/정렬/필터 초기화)
    // ---------------------------------------------------------
    // 페이지 새로고침 없이 현재 화면 상태만 초기값으로 돌리고 다시 조회
    // =========================================================
    $('#animeResetBtn').on('click', function () {
      // 검색 UI/상태 초기화
      $('#animeSearchInput').val('');
      $('#animeSearchType').val('ANIME_SEARCH_TITLE');

      keyword = null;
      condition = 'ANIME_LIST_RECENT';

      // 정렬 초기화 + 드롭다운 UI 동기화
      currentSort = 'RECENT';
      setDropdown($('#ddSort'), 'RECENT', '최신 등록순');

      // 필터 상태 초기화 (UI 선택값 + 실제 적용값 둘 다)
      uiYear = 'ALL';
      uiQuarter = 'ALL';
      filterYear = null;
      filterQuarter = null;

      setDropdown($('#ddYear'), 'ALL', '전체 연도');
      setDropdown($('#ddQuarter'), 'ALL', '전체 분기');

      // 적용중 텍스트 제거
      $('#filterStatus').text('');

      // 초기 상태로 1페이지 조회
      loadAnimeList(1);
    });

    // =========================================================
    // (E) 페이지네이션 클릭(이벤트 위임)
    // ---------------------------------------------------------
    // pagingArea 내부 li/a는 JS가 동적으로 다시 만들기 때문에
    // 직접 바인딩이 아니라 부모에 위임으로 처리
    // =========================================================
    $('#pagingArea').on('click', 'a.page-link', function (e) {
      e.preventDefault();
      const page = parseInt($(this).data('page'), 10);
      if (!page || page < 1) return;
      loadAnimeList(page);
    });

    // 최초 로딩: 페이지 진입 시 1페이지 조회
    loadAnimeList(1);

    // =========================================================
    // (F) 서버 호출
    // ---------------------------------------------------------
    // 현재 상태 변수들을 querystring으로 조합해서 /api/anime 호출
    // 응답 형식 가정:
    // {
    //   animeList: [...],
    //   paging: {...}
    // }
    // =========================================================
    function loadAnimeList(page) {
      const params = new URLSearchParams();

      // 기본 파라미터는 항상 전달
      params.set('page', String(page));
      params.set('condition', condition);
      params.set('sort', currentSort);

      // 선택값이 있을 때만 전달 (서버에서 null/미전달을 '전체'로 처리)
      if (keyword != null && keyword !== '') params.set('keyword', keyword);
      if (filterYear != null) params.set('year', String(filterYear));
      if (filterQuarter != null) params.set('quarter', String(filterQuarter));

      const url = contextPath + '/api/anime?' + params.toString();

      fetch(url, { method: 'GET', headers: { 'Accept': 'application/json' } })
        .then((res) => {
          // HTTP 오류코드면 catch로 보내기 위해 직접 throw
          if (!res.ok) throw new Error('HTTP ' + res.status);
          return res.json();
        })
        .then((data) => {
          // 카드 목록 / 페이지네이션 / 필터 UI 상태를 한 번에 갱신
          renderAnimeList(data.animeList);
          renderPaging(data.paging);
          syncFilterUI(data.paging);
        })
        .catch((err) => console.log('[에러] AnimeListData:', err));
    }

    // =========================================================
    // (G) 서버 필터 상태 → UI 동기화
    // ---------------------------------------------------------
    // 서버가 실제 적용한 paging.year / paging.quarter 기준으로
    // 드롭다운 표시와 내부 상태(ui/filter)를 다시 맞춘다.
    //
    // 이유:
    // - 서버 기본값 처리 결과를 화면에 정확히 반영하려고
    // - 잘못된 파라미터가 들어가도 최종 상태를 서버 기준으로 맞추려고
    // =========================================================
    function syncFilterUI(paging) {
      if (!paging) return;

      if (paging.year != null) {
        uiYear = String(paging.year);
        filterYear = parseInt(paging.year, 10);
        setDropdown($('#ddYear'), uiYear, paging.year + '년');
      } else {
        uiYear = 'ALL';
        filterYear = null;
        setDropdown($('#ddYear'), 'ALL', '전체 연도');
      }

      if (paging.quarter != null) {
        uiQuarter = String(paging.quarter);
        filterQuarter = parseInt(paging.quarter, 10);
        setDropdown($('#ddQuarter'), uiQuarter, paging.quarter + '분기');
      } else {
        uiQuarter = 'ALL';
        filterQuarter = null;
        setDropdown($('#ddQuarter'), 'ALL', '전체 분기');
      }

      const $status = $('#filterStatus');
      if ($status.length === 0) return;

      // 상태 문구 초기화 후, 실제 적용값이 있으면 "적용중" 텍스트 표시
      $status.text('');
      if (filterYear == null && filterQuarter == null) return;

      const parts = [];
      if (filterYear != null) parts.push(filterYear + '년');
      if (filterQuarter != null) parts.push(filterQuarter + '분기');
      $status.text(parts.join(' · ') + ' 적용중');
    }
  });

  // =========================================================
  // 2) 렌더 함수(전역)
  // ---------------------------------------------------------
  // loadAnimeList 내부에서 호출하는 UI 렌더링 함수들.
  // 전역으로 둔 이유는 구조를 단순하게 유지하려는 의도(현재 버전 기준).
  // =========================================================

  function escapeHtml(str){
    // 카드 제목/메타 텍스트를 innerHTML 문자열로 붙이고 있어서
    // 서버/DB 값에 특수문자가 들어와도 태그로 해석되지 않게 이스케이프 처리
    // (XSS 방어용 기본 유틸)
    if(str == null) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function normalizeUrl(raw){
    // 썸네일 URL이 절대경로/상대경로/ctx포함경로로 섞여 들어와도
    // 브라우저에서 실제로 열 수 있는 형태로 보정하는 함수
    if(!raw) return '';
    raw = String(raw).trim();
    if(!raw) return '';

    // 외부 URL이면 그대로 사용
    if(raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    // DB가 이미 ctx 포함(/animale/...) 경로로 저장한 경우 중복으로 ctx 붙이지 않음
    if(contextPath && raw.startsWith(contextPath + '/')) return raw;

    // 루트경로(/uploads/...)면 ctx를 앞에 붙여서 프로젝트 기준으로 맞춤
    if(raw.startsWith('/')) return contextPath + raw;

    // 상대경로면 ctx/상대경로 형태로 보정
    return contextPath + '/' + raw;
  }

  function renderAnimeList(list) {
    // 목록 영역 초기화 후, 서버 응답으로 다시 채우는 방식
    const $container = $('#animeContainer');
    $container.empty();

    // 목록이 비어 있으면 카드 대신 '검색 결과 없음' UI 표시
    if (!list || list.length === 0) {
      $('#searchEmpty').show();
      return;
    }
    $('#searchEmpty').hide();

    list.forEach((item, idx) => {
      // 썸네일 없는 데이터는 현재 카드 레이아웃 특성상 스킵
      // (빈 카드/레이아웃 깨짐 방지)
      if (!item.animeThumbnailUrl) return;

      const thumbUrl = normalizeUrl(item.animeThumbnailUrl);

      // 카드에 들어갈 텍스트는 모두 escapeHtml 처리 후 사용
      const yearText = item.animeYear ? (escapeHtml(item.animeYear) + '년') : '연도 미정';
      const quarterText = item.animeQuarter ? escapeHtml(item.animeQuarter) : '분기 미정';
      const titleText = escapeHtml(item.animeTitle);

      // 카드 등장 애니메이션 딜레이(앞 카드부터 순차 등장)
      // 너무 길어지지 않도록 최대 350ms로 제한
      const delay = Math.min(idx * 35, 350);

      // 카드 HTML 문자열 조립
      // 주의:
      // - 상세 링크 animeId는 encodeURIComponent로 안전하게 처리
      // - set-bg 클래스는 아래에서 background-image 일괄 적용
      const html =
        '<div class="col-lg-3 col-md-4 col-sm-6 anime-card" style="animation-delay:' + delay + 'ms">' +
          '<a href="' + contextPath + '/animeDetail?animeId=' + encodeURIComponent(item.animeId) + '" class="anime-link">' +
            '<div class="product__item">' +
              '<div class="product__item__pic set-bg" data-setbg="' + thumbUrl + '"></div>' +
              '<div class="product__item__text">' +
                '<ul class="anime-meta">' +
                  '<li>' + yearText + '</li>' +
                  '<li class="badge-q">' + quarterText + '</li>' +
                '</ul>' +
                '<h5 class="anime-title">' + titleText + '</h5>' +
              '</div>' +
            '</div>' +
          '</a>' +
        '</div>';

      $container.append(html);
    });

    // 템플릿(set-bg) 패턴 유지:
    // data-setbg 값을 실제 background-image로 변환
    $('.set-bg').each(function () {
      const bg = $(this).data('setbg');
      if (bg) $(this).css('background-image', "url('" + bg + "')");
    });
  }

  function renderPaging(p) {
    // 페이지네이션 영역도 매번 다시 그림
    const $paging = $('#pagingArea');
    $paging.empty();

    if (!p) return;
    if (p.totalPage <= 1) return; // 페이지가 1개면 페이징 표시 불필요

    // 이전 블록 이동(<)
    if (p.hasPrev) {
      $paging.append(
        '<li class="arrow">' +
          '<a href="#" class="page-link" data-page="' + (p.startPage - 1) + '">&lt;</a>' +
        '</li>'
      );
    }

    // 현재 페이지 블록 번호들
    for (let i = p.startPage; i <= p.endPage; i++) {
      const active = (i === p.page) ? 'active' : '';
      $paging.append(
        '<li class="' + active + '">' +
          '<a href="#" class="page-link" data-page="' + i + '">' + i + '</a>' +
        '</li>'
      );
    }

    // 다음 블록 이동(>)
    if (p.hasNext) {
      $paging.append(
        '<li class="arrow">' +
          '<a href="#" class="page-link" data-page="' + (p.endPage + 1) + '">&gt;</a>' +
        '</li>'
      );
    }
  }
  </script>

</body>
</html>