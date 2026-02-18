<!-- =========================================================
  AniMale Anime List (비동기 + 필터 + 검색 + 정렬 + 페이징)
  - JSP 안에 JS(inline script) 포함 버전 (통합본)
  - ✅ 이번 요청: 기능 변경 없이 '주석만' 상세하게 보강
========================================================= -->

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 애니리스트</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<!-- ✅ 파비콘: 컨텍스트 경로 기준 -->
<link rel="icon" type="image/png"
  href="<%=request.getContextPath()%>/favicon.png">
<link rel="stylesheet"
  href="${pageContext.request.contextPath}/css/elegant-icons.css">

<!-- Google Font -->
<link
  href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&display=swap"
  rel="stylesheet">
<link
  href="https://fonts.googleapis.com/css2?family=Mulish:wght@300;400;500;600;700;800;900&display=swap"
  rel="stylesheet">

<!-- CSS -->
<link rel="stylesheet"
  href="<%=request.getContextPath()%>/css/bootstrap.min.css">
<link rel="stylesheet"
  href="<%=request.getContextPath()%>/css/font-awesome.min.css">
<link rel="stylesheet"
  href="<%=request.getContextPath()%>/css/style.css">
<link rel="stylesheet"
  href="${pageContext.request.contextPath}/css/anime-list.css">
</head>

<body>
  <!-- ✅ 공용 헤더 포함 -->
  <jsp:include page="/WEB-INF/common/header.jsp" />

  <section class="product-page spad anime-list-page">
    <div class="container">

      <!-- =========================================================
           상단 타이틀 영역
           - 좌측: 페이지 타이틀(애니)
           - 우측: 검색/전체보기/관리자 버튼 + 필터/정렬 컨트롤
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
                   1줄: 검색 + 전체보기 (+ 관리자)
                   - 검색어 없으면: 기본 리스트(최근 리스트)
                   - 검색어 있으면: 제목/줄거리 조건으로 서버 조회
                   - 전체보기: 검색/정렬/필터 모두 초기화하여 기본 리스트로 복귀
                 ========================================================= -->
              <div class="anime-search-wrapper">
                <div class="anime-search-box">
                  <!-- ✅ 검색 조건 선택 (서버에 condition으로 전달) -->
                  <select id="animeSearchType">
                    <option value="ANIME_SEARCH_TITLE">제목</option>
                    <option value="ANIME_SEARCH_STORY">줄거리</option>
                  </select>

                  <!-- ✅ 키워드 입력 -->
                  <input type="text" id="animeSearchInput" placeholder="검색어를 입력하세요">

                  <!-- ✅ 검색 실행 버튼 -->
                  <button type="button" id="animeSearchBtn">
                    <i class="fa fa-search"></i>
                  </button>
                </div>

                <!-- ✅ 전체보기: 상태 초기화 + 1페이지 재조회 -->
                <button type="button" id="animeResetBtn" class="anime-reset-btn">전체보기</button>

                <!-- ✅ 관리자일 때만 '애니 추가' 노출 -->
                <c:if test="${fn:toUpperCase(sessionScope.memberRole) eq 'ADMIN'}">
                  <a class="anime-admin-btn" href="${pageContext.request.contextPath}/animeWritePage">애니 추가</a>
                </c:if>
              </div>

              <!-- =========================================================
                   2줄: 연도/분기 + 정렬 (같은 라인)
                   - 연도/분기:
                     1) 드롭다운 선택은 UI에만 반영(uiYear/uiQuarter)
                     2) '필터 적용' 버튼을 눌러야 서버 적용 값(filterYear/filterQuarter) 확정
                   - 정렬:
                     1) 드롭다운 선택 즉시 서버 재조회(loadAnimeList(1))
                 ========================================================= -->
              <div class="anime-sub-controls">

                <div class="product__page__filter filter-box">
                  <p>연도/분기</p>

                  <!-- =========================================================
                       커스텀 드롭다운: Year
                       - data-value에 선택 값을 저장
                       - li.active로 현재 선택 상태 표현
                     ========================================================= -->
                  <div class="am-dd am-dd--year" id="ddYear" data-value="ALL">
                    <button type="button" class="am-dd__btn" aria-expanded="false">
                      <span class="am-dd__text" id="yearText">전체 연도</span>
                      <i class="fa fa-angle-down am-dd__chev"></i>
                    </button>
                    <ul class="am-dd__list" role="listbox">
                      <li class="active" data-value="ALL">전체 연도</li>
                      <c:forEach var="y" begin="1980" end="2026">
                        <li data-value="${y}">${y}년</li>
                      </c:forEach>
                    </ul>
                  </div>

                  <!-- =========================================================
                       커스텀 드롭다운: Quarter
                       - data-value에 선택 값을 저장
                       - li.active로 현재 선택 상태 표현
                     ========================================================= -->
                  <div class="am-dd am-dd--quarter" id="ddQuarter" data-value="ALL">
                    <button type="button" class="am-dd__btn" aria-expanded="false">
                      <span class="am-dd__text" id="quarterText">전체 분기</span>
                      <i class="fa fa-angle-down am-dd__chev"></i>
                    </button>
                    <ul class="am-dd__list" role="listbox">
                      <li class="active" data-value="ALL">전체 분기</li>
                      <c:forEach var="q" begin="1" end="4">
                        <li data-value="${q}">${q}분기</li>
                      </c:forEach>
                    </ul>
                  </div>

                  <!-- ✅ Apply 버튼: uiYear/uiQuarter → filterYear/filterQuarter로 확정 -->
                  <button type="button" id="filterApplyBtn" class="anime-filter-apply">필터 적용</button>

                  <!-- ✅ 현재 적용 중인 필터 상태 표시(예: 2024년 · 2분기 적용중) -->
                  <span id="filterStatus" class="filter-status"></span>
                </div>

                <div class="product__page__filter sort-box">
                  <p>정렬</p>

                  <!-- =========================================================
                       커스텀 드롭다운: Sort
                       - 정렬은 선택 즉시 currentSort를 바꾸고 1페이지부터 재조회
                     ========================================================= -->
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

      <!-- =========================================================
           카드 리스트 렌더 영역
           - JS에서 #animeContainer에 카드 HTML을 append
         ========================================================= -->
      <div class="row" id="animeContainer"></div>

      <!-- =========================================================
           검색 결과 없음 UI
           - 리스트가 비면 show, 리스트가 있으면 hide
         ========================================================= -->
      <div class="search-result-wrapper" id="searchEmpty" style="display:none;">
        <div class="search-empty">검색 결과가 없습니다.</div>
      </div>

      <!-- =========================================================
           페이지네이션 영역
           - JS에서 #pagingArea에 페이지 번호를 동적으로 생성
         ========================================================= -->
      <div class="row">
        <div class="col-lg-12">
          <div class="pagination-wrapper">
            <ul class="anime-pagination" id="pagingArea"></ul>
          </div>
        </div>
      </div>

    </div><!-- /.container -->
  </section>

  <%@ include file="/WEB-INF/common/footer.jsp"%>

  <!-- ✅ 라이브러리 로드(순서 중요: jquery → bootstrap → main) -->
  <script src="<%=request.getContextPath()%>/js/jquery-3.3.1.min.js"></script>
  <script src="<%=request.getContextPath()%>/js/bootstrap.min.js"></script>
  <script src="<%=request.getContextPath()%>/js/main.js"></script>

  <!-- =========================================================
       Anime List Inline JS (통합)
       - 상태 변수:
         1) currentSort                 : 정렬(선택 즉시 반영)
         2) uiYear/uiQuarter             : 드롭다운에서 선택한 'UI 값'(Apply 전)
         3) filterYear/filterQuarter     : 서버로 보내는 '확정 값'(Apply 후)
         4) condition/keyword            : 검색 조건/키워드
       - 메인 흐름:
         loadAnimeList(page) → fetch → renderAnimeList + renderPaging + syncFilterUI
  ========================================================= -->
  <script>
  // ✅ JSP 컨텍스트 경로를 JS에서 사용하기 위한 상수
  const contextPath = '<%=request.getContextPath()%>';

  // =========================================================
  // 1) 전역 상태 변수(페이지 전체에서 유지되는 상태)
  // =========================================================

  // ✅ 정렬: 드롭다운 선택 즉시 서버 반영
  let currentSort = 'RECENT';

  // ✅ UI에서 선택한 값(Apply 전까지는 서버로 보내지 않음)
  let uiYear = 'ALL';
  let uiQuarter = 'ALL';

  // ✅ 서버로 실제 전달되는 필터(Apply 버튼으로 확정)
  // - null이면 '필터 미적용' 의미
  let filterYear = null;
  let filterQuarter = null;

  // ✅ 검색 조건(기본은 최근 리스트)
  // - condition: 'ANIME_LIST_RECENT' 또는 'ANIME_SEARCH_TITLE'/'ANIME_SEARCH_STORY'
  // - keyword: 검색어(없으면 null)
  let condition = 'ANIME_LIST_RECENT';
  let keyword = null;

  // =========================================================
  // 2) DOM Ready: 이벤트 바인딩 + 최초 로딩
  // =========================================================
  $(function () {

    // =========================================================
    // (A) 커스텀 드롭다운 공통 로직
    // - 열고/닫기, 선택 반영, 바깥 클릭 닫기
    // =========================================================

    // ✅ 모든 드롭다운 닫기(열림 상태 해제 + aria 업데이트)
    function closeAllDropdowns() {
      $('.am-dd')
        .removeClass('is-open')
        .find('.am-dd__btn')
        .attr('aria-expanded', 'false');
    }

    // ✅ 특정 드롭다운만 열기(나머지는 닫고 해당만 open)
    function openDropdown($dd) {
      closeAllDropdowns();
      $dd.addClass('is-open').find('.am-dd__btn').attr('aria-expanded', 'true');
    }

    // ✅ 드롭다운 UI 상태를 강제로 세팅
    // - data-value 갱신
    // - 표시 텍스트 갱신
    // - li.active 갱신(현재 선택 표시)
    function setDropdown($dd, value, label) {
      $dd.attr('data-value', value);
      $dd.find('.am-dd__text').text(label);

      $dd.find('.am-dd__list li').removeClass('active');
      $dd.find('.am-dd__list li[data-value="' + value + '"]').addClass('active');
    }

    // ✅ 드롭다운 버튼 클릭: 열기/닫기 토글
    // - stopPropagation: document click 닫기 이벤트에 즉시 닫히는 것을 방지
    $('.am-dd').on('click', '.am-dd__btn', function (e) {
      e.preventDefault();
      e.stopPropagation();

      const $dd = $(this).closest('.am-dd');
      if ($dd.hasClass('is-open')) closeAllDropdowns();
      else openDropdown($dd);
    });

    // ✅ 드롭다운 항목 클릭: 선택 확정(단, 연도/분기는 UI만 변경)
    $('.am-dd').on('click', '.am-dd__list li', function (e) {
      e.preventDefault();
      e.stopPropagation();

      const $li = $(this);
      const $dd = $li.closest('.am-dd');
      const value = String($li.data('value')); // ✅ data-value는 숫자여도 문자열로 통일
      const label = $li.text();

      // ✅ UI에 보이는 값/active 표시를 먼저 업데이트
      setDropdown($dd, value, label);
      closeAllDropdowns();

      // ✅ 어떤 드롭다운인지 id로 구분
      if ($dd.attr('id') === 'ddYear') {
        // ✅ 연도는 Apply 전까지는 서버에 보내지 않음(UI 선택만 유지)
        uiYear = value;
      } else if ($dd.attr('id') === 'ddQuarter') {
        // ✅ 분기 역시 Apply 전까지는 서버에 보내지 않음(UI 선택만 유지)
        uiQuarter = value;
      } else if ($dd.attr('id') === 'ddSort') {
        // ✅ 정렬은 즉시 반영 → 1페이지부터 재조회
        currentSort = value;
        loadAnimeList(1);
      }
    });

    // ✅ 문서 바깥 클릭 시 드롭다운 닫기
    $(document).on('click', function () {
      closeAllDropdowns();
    });

    // =========================================================
    // (B) 필터 적용 버튼(연도/분기)
    // - uiYear/uiQuarter → filterYear/filterQuarter로 확정
    // - null이면 서버에 파라미터를 보내지 않아 '필터 해제' 의미가 됨
    // =========================================================
    $('#filterApplyBtn').on('click', function () {
      // ✅ 'ALL'이면 null(미적용), 숫자면 int로 변환하여 전달
      filterYear = (uiYear !== 'ALL') ? parseInt(uiYear, 10) : null;
      filterQuarter = (uiQuarter !== 'ALL') ? parseInt(uiQuarter, 10) : null;

      // ✅ 필터가 바뀌면 1페이지부터 다시 조회
      loadAnimeList(1);
    });

    // =========================================================
    // (C) 검색 버튼 / 엔터 처리
    // - 검색어가 비면 기본 리스트로 복귀
    // - 검색어가 있으면 condition을 선택된 검색타입으로 설정
    // =========================================================
    $('#animeSearchBtn').on('click', function () {
      const value = $('#animeSearchInput').val().trim();
      const searchType = $('#animeSearchType').val(); // 'ANIME_SEARCH_TITLE' or 'ANIME_SEARCH_STORY'

      if (value === '') {
        // ✅ 검색어 없음 → 최근 리스트로 전환
        keyword = null;
        condition = 'ANIME_LIST_RECENT';
      } else {
        // ✅ 검색어 있음 → condition + keyword 설정
        keyword = value;
        condition = searchType;
      }

      // ✅ 검색 조건 변경 시 1페이지부터 조회
      loadAnimeList(1);
    });

    // ✅ 검색 입력창에서 Enter 누르면 검색 버튼 클릭과 동일하게 동작
    $('#animeSearchInput').on('keydown', function (e) {
      if (e.key === 'Enter') $('#animeSearchBtn').click();
    });

    // =========================================================
    // (D) 전체보기(검색/정렬/필터 초기화)
    // - 화면(UI) + 전역 상태 변수 모두 초기화
    // =========================================================
    $('#animeResetBtn').on('click', function () {
      // ✅ 검색 UI 초기화
      $('#animeSearchInput').val('');
      $('#animeSearchType').val('ANIME_SEARCH_TITLE');

      // ✅ 검색 상태 초기화
      keyword = null;
      condition = 'ANIME_LIST_RECENT';

      // ✅ 정렬 상태 초기화
      currentSort = 'RECENT';
      setDropdown($('#ddSort'), 'RECENT', '최신 등록순');

      // ✅ 필터 상태 초기화(UI 선택/서버 확정 모두 초기화)
      uiYear = 'ALL';
      uiQuarter = 'ALL';
      filterYear = null;
      filterQuarter = null;

      setDropdown($('#ddYear'), 'ALL', '전체 연도');
      setDropdown($('#ddQuarter'), 'ALL', '전체 분기');

      // ✅ 필터 상태 텍스트 제거
      $('#filterStatus').text('');

      // ✅ 기본 상태로 1페이지부터 재조회
      loadAnimeList(1);
    });

    // =========================================================
    // (E) 페이지네이션 이벤트 위임
    // - pagingArea 내부 a.page-link는 JS로 동적 생성되므로 위임 방식 필요
    // =========================================================
    $('#pagingArea').on('click', 'a.page-link', function (e) {
      e.preventDefault();

      // ✅ data-page에서 이동할 페이지 숫자를 읽어옴
      const page = parseInt($(this).data('page'), 10);

      // ✅ 방어 로직: 유효하지 않으면 무시
      if (!page || page < 1) return;

      // ✅ 해당 페이지로 조회
      loadAnimeList(page);
    });

    // =========================================================
    // (F) 최초 로딩: 기본 상태(최근/정렬RECENT/필터없음/검색없음)로 1페이지 조회
    // =========================================================
    loadAnimeList(1);

    // =========================================================
    // (G) API 호출 함수: 서버에서 목록 + 페이징 정보 받아서 렌더링
    // =========================================================
    function loadAnimeList(page) {
      // ✅ URLSearchParams로 쿼리스트링 안전하게 생성
      const params = new URLSearchParams();

      // ✅ 공통 파라미터
      params.set('page', String(page));
      params.set('condition', condition);
      params.set('sort', currentSort);

      // ✅ 선택 파라미터(값이 있을 때만 추가)
      // - keyword: 검색어
      // - year/quarter: Apply로 확정된 값만 전달
      if (keyword != null && keyword !== '') params.set('keyword', keyword);
      if (filterYear != null) params.set('year', String(filterYear));
      if (filterQuarter != null) params.set('quarter', String(filterQuarter));

      // ✅ 최종 호출 URL
      const url = contextPath + '/api/anime?' + params.toString();

      // ✅ fetch로 GET 요청 (JSON 응답 기대)
      fetch(url, { method: 'GET', headers: { 'Accept': 'application/json' } })
        .then((res) => {
          // ✅ HTTP 에러를 catch로 넘기기 위한 처리
          if (!res.ok) throw new Error('HTTP ' + res.status);
          return res.json();
        })
        .then((data) => {
          // ✅ 서버 응답 구조를 가정:
          // data.animeList : 카드 목록 배열
          // data.paging    : 페이지 정보 + 현재 적용된 필터 상태(year/quarter 포함)
          renderAnimeList(data.animeList);
          renderPaging(data.paging);

          // ✅ 서버가 인정한(실제 적용된) 필터값을 기준으로 UI를 동기화
          // - 사용자가 Apply를 누른 값이 서버에서 그대로 반영되었는지, 혹은 null 처리되었는지
          syncFilterUI(data.paging);
        })
        .catch((err) => console.log('[에러] AnimeListData:', err));
    }

    // =========================================================
    // (H) 서버가 내려준 필터 상태로 UI 동기화(커스텀 드롭다운)
    // - 핵심 목적:
    //   1) 새로고침/페이지 이동 후에도 드롭다운 표시가 서버 상태와 동일하게 유지
    //   2) 서버가 year/quarter를 null로 내려주면 '전체'로 되돌림
    // =========================================================
    function syncFilterUI(paging) {
      if (!paging) return;

      // -------------------------
      // year 동기화
      // -------------------------
      if (paging.year != null) {
        // ✅ 서버 적용값이 존재 → UI 값 + 확정값 둘 다 갱신
        uiYear = String(paging.year);
        filterYear = parseInt(paging.year, 10);
        setDropdown($('#ddYear'), uiYear, paging.year + '년');
      } else {
        // ✅ 서버 적용값 없음 → 전체 연도로 초기화
        uiYear = 'ALL';
        filterYear = null;
        setDropdown($('#ddYear'), 'ALL', '전체 연도');
      }

      // -------------------------
      // quarter 동기화
      // -------------------------
      if (paging.quarter != null) {
        uiQuarter = String(paging.quarter);
        filterQuarter = parseInt(paging.quarter, 10);
        setDropdown($('#ddQuarter'), uiQuarter, paging.quarter + '분기');
      } else {
        uiQuarter = 'ALL';
        filterQuarter = null;
        setDropdown($('#ddQuarter'), 'ALL', '전체 분기');
      }

      // -------------------------
      // 상태 텍스트 표시(예: '2024년 · 2분기 적용중')
      // -------------------------
      const $status = $('#filterStatus');
      if ($status.length === 0) return;

      // ✅ 기본적으로 텍스트를 지운 뒤, 적용값이 있을 때만 세팅
      $status.text('');

      // ✅ 둘 다 null이면 '필터 미적용' 상태이므로 표시하지 않음
      if (filterYear == null && filterQuarter == null) return;

      // ✅ 적용된 항목만 조합해서 표시
      const parts = [];
      if (filterYear != null) parts.push(filterYear + '년');
      if (filterQuarter != null) parts.push(filterQuarter + '분기');
      $status.text(parts.join(' · ') + ' 적용중');
    }
  });

  // =========================================================
  // 3) 렌더 함수(전역)
  // - ✅ 이유: loadAnimeList 내부가 아니라 전역에 두면
  //   1) 다른 스크립트에서 재사용 가능
  //   2) 함수 선언부가 한 번만 로드됨(중복 선언 방지)
  // =========================================================

  function renderAnimeList(list) {
    const $container = $('#animeContainer');
    $container.empty(); // ✅ 기존 카드 제거 후 새로 렌더링

    // ✅ 리스트가 비어있으면 '검색 결과 없음' 표시 후 종료
    if (!list || list.length === 0) {
      $('#searchEmpty').show();
      return;
    }
    $('#searchEmpty').hide();

    // ✅ 카드 생성
    list.forEach((item, idx) => {
      // ✅ 썸네일이 없으면 카드 생성하지 않음
      // - 참고: 이 경우 'list.length는 있는데 카드가 0개'가 될 수도 있음(데이터 정책에 따라)
      if (!item.animeThumbnailUrl) return;

      // =========================================================
      // 썸네일 URL 정규화
      // - 서버가 주는 값이
      //   1) http로 시작하면 절대 URL
      //   2) /로 시작하면 contextPath + raw
      //   3) 그 외 상대경로면 contextPath + '/' + raw
      // =========================================================
      const raw = item.animeThumbnailUrl;
      const thumbUrl = raw.startsWith('http')
        ? raw
        : (raw.startsWith('/') ? (contextPath + raw) : (contextPath + '/' + raw));

      // ✅ 표기 텍스트(값 없을 때 대체 문구)
      const yearText = item.animeYear ? (item.animeYear + '년') : '연도 미정';
      const quarterText = item.animeQuarter ? item.animeQuarter : '분기 미정';

      // ✅ 카드 애니메이션 딜레이(너무 커지지 않게 상한 350ms)
      const delay = Math.min(idx * 35, 350);

      // =========================================================
      // 카드 HTML 생성
      // - animeDetail로 이동 링크 포함
      // - set-bg는 아래에서 background-image로 변환
      // - ⚠️ item.animeTitle 등을 그대로 innerHTML로 넣기 때문에
      //   서버에서 XSS 방지(escape) 처리된 값이라는 전제가 필요함
      // =========================================================
      const html =
        '<div class="col-lg-3 col-md-4 col-sm-6 anime-card" style="animation-delay:' + delay + 'ms">' +
          '<a href="' + contextPath + '/animeDetail?animeId=' + item.animeId + '" class="anime-link">' +
            '<div class="product__item">' +
              '<div class="product__item__pic set-bg" data-setbg="' + thumbUrl + '"></div>' +
              '<div class="product__item__text">' +
                '<ul class="anime-meta">' +
                  '<li>' + yearText + '</li>' +
                  '<li class="badge-q">' + quarterText + '</li>' +
                '</ul>' +
                '<h5 class="anime-title">' + item.animeTitle + '</h5>' +
              '</div>' +
            '</div>' +
          '</a>' +
        '</div>';

      $container.append(html);
    });

    // ✅ set-bg 처리: data-setbg 값을 background-image로 적용
    // - 기존 템플릿(main.js) 방식과 동일한 패턴 유지
    $('.set-bg').each(function () {
      const bg = $(this).data('setbg');
      if (bg) $(this).css('background-image', "url('" + bg + "')");
    });
  }

  function renderPaging(p) {
    const $paging = $('#pagingArea');
    $paging.empty(); // ✅ 기존 페이지 버튼 제거 후 새로 렌더링

    // ✅ 페이징 정보가 없거나, 페이지가 1개면 표시할 필요 없음
    if (!p) return;
    if (p.totalPage <= 1) return;

    // =========================================================
    // 이전 블록 이동(예: 1~10에서 이전 누르면 0으로 가면 안 되므로
    // 서버가 hasPrev/startPage를 적절히 내려준다는 전제)
    // =========================================================
    if (p.hasPrev) {
      $paging.append(
        '<li class="arrow">' +
          '<a href="#" class="page-link" data-page="' + (p.startPage - 1) + '">&lt;</a>' +
        '</li>'
      );
    }

    // =========================================================
    // 현재 블록 페이지 번호 렌더링
    // - active 클래스: 현재 페이지 강조
    // =========================================================
    for (let i = p.startPage; i <= p.endPage; i++) {
      const active = (i === p.page) ? 'active' : '';
      $paging.append(
        '<li class="' + active + '">' +
          '<a href="#" class="page-link" data-page="' + i + '">' + i + '</a>' +
        '</li>'
      );
    }

    // =========================================================
    // 다음 블록 이동(예: 1~10에서 다음 누르면 11로 이동)
    // =========================================================
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
