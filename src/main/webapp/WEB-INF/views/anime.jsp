<!-- =========================================================
  AniMale Anime List (비동기 + 필터 + 검색 + 정렬 + 페이징)
  - JSP 안에 JS(inline script) 포함 버전 (통합본)
  - ✅ 이번 최종본: 경로/정적리소스 관점 안정화 + (XSS 방어용) escapeHtml 추가
========================================================= -->

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

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
  <!-- 공용 헤더 포함 -->
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

                <!-- 관리자일 때만 '애니 추가' 노출 -->
                <c:if test="${fn:toUpperCase(sessionScope.memberRole) eq 'ADMIN'}">
                  <a class="anime-admin-btn" href="${ctx}/animeWrite">애니 추가</a>
                </c:if>
              </div>

              <!-- =========================================================
                   2줄: 연도/분기 + 정렬 (같은 라인)
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
                      <c:forEach var="q" begin="1" end="4">
                        <li data-value="${q}">${q}분기</li>
                      </c:forEach>
                    </ul>
                  </div>

                  <!-- Apply 버튼: uiYear/uiQuarter → filterYear/filterQuarter로 확정 -->
                  <button type="button" id="filterApplyBtn" class="anime-filter-apply">필터 적용</button>

                  <!-- 현재 적용 중인 필터 상태 표시 -->
                  <span id="filterStatus" class="filter-status"></span>
                </div>

                <div class="product__page__filter sort-box">
                  <p>정렬</p>

                  <!-- 커스텀 드롭다운: Sort -->
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

      <!-- 카드 리스트 렌더 영역 -->
      <div class="row" id="animeContainer"></div>

      <!-- 검색 결과 없음 UI -->
      <div class="search-result-wrapper" id="searchEmpty" style="display:none;">
        <div class="search-empty">검색 결과가 없습니다.</div>
      </div>

      <!-- 페이지네이션 영역 -->
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

  <!-- 라이브러리 로드(순서 중요: jquery → bootstrap → main) -->
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

  <script>
  // JSP 컨텍스트 경로(JS에서 공통으로 사용)
  const contextPath = '${ctx}';

  // =========================================================
  // 1) 전역 상태 변수
  // =========================================================
  let currentSort = 'RECENT';      // 정렬(선택 즉시 반영)
  let uiYear = 'ALL';              // UI 선택값(Apply 전)
  let uiQuarter = 'ALL';           // UI 선택값(Apply 전)
  let filterYear = null;           // 서버 전달 필터(Apply 후 확정)
  let filterQuarter = null;        // 서버 전달 필터(Apply 후 확정)
  let condition = 'ANIME_LIST_RECENT'; // 검색 조건
  let keyword = null;              // 검색어(없으면 null)

  $(function () {

    // =========================================================
    // (A) 커스텀 드롭다운 공통 로직
    // =========================================================
    function closeAllDropdowns() {
      $('.am-dd')
        .removeClass('is-open')
        .find('.am-dd__btn')
        .attr('aria-expanded', 'false');
    }

    function openDropdown($dd) {
      closeAllDropdowns();
      $dd.addClass('is-open').find('.am-dd__btn').attr('aria-expanded', 'true');
    }

    function setDropdown($dd, value, label) {
      $dd.attr('data-value', value);
      $dd.find('.am-dd__text').text(label);

      $dd.find('.am-dd__list li').removeClass('active');
      $dd.find('.am-dd__list li[data-value="' + value + '"]').addClass('active');
    }

    $('.am-dd').on('click', '.am-dd__btn', function (e) {
      e.preventDefault();
      e.stopPropagation();

      const $dd = $(this).closest('.am-dd');
      if ($dd.hasClass('is-open')) closeAllDropdowns();
      else openDropdown($dd);
    });

    $('.am-dd').on('click', '.am-dd__list li', function (e) {
      e.preventDefault();
      e.stopPropagation();

      const $li = $(this);
      const $dd = $li.closest('.am-dd');
      const value = String($li.data('value'));
      const label = $li.text();

      setDropdown($dd, value, label);
      closeAllDropdowns();

      if ($dd.attr('id') === 'ddYear') {
        uiYear = value;
      } else if ($dd.attr('id') === 'ddQuarter') {
        uiQuarter = value;
      } else if ($dd.attr('id') === 'ddSort') {
        currentSort = value;
        loadAnimeList(1);
      }
    });

    $(document).on('click', function () {
      closeAllDropdowns();
    });

    // =========================================================
    // (B) 필터 적용(연도/분기)
    // =========================================================
    $('#filterApplyBtn').on('click', function () {
      filterYear = (uiYear !== 'ALL') ? parseInt(uiYear, 10) : null;
      filterQuarter = (uiQuarter !== 'ALL') ? parseInt(uiQuarter, 10) : null;
      loadAnimeList(1);
    });

    // =========================================================
    // (C) 검색(버튼/엔터)
    // =========================================================
    $('#animeSearchBtn').on('click', function () {
      const value = $('#animeSearchInput').val().trim();
      const searchType = $('#animeSearchType').val();

      if (value === '') {
        keyword = null;
        condition = 'ANIME_LIST_RECENT';
      } else {
        keyword = value;
        condition = searchType;
      }
      loadAnimeList(1);
    });

    $('#animeSearchInput').on('keydown', function (e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        $('#animeSearchBtn').click();
      }
    });

    // =========================================================
    // (D) 전체보기(검색/정렬/필터 초기화)
    // =========================================================
    $('#animeResetBtn').on('click', function () {
      $('#animeSearchInput').val('');
      $('#animeSearchType').val('ANIME_SEARCH_TITLE');

      keyword = null;
      condition = 'ANIME_LIST_RECENT';

      currentSort = 'RECENT';
      setDropdown($('#ddSort'), 'RECENT', '최신 등록순');

      uiYear = 'ALL';
      uiQuarter = 'ALL';
      filterYear = null;
      filterQuarter = null;

      setDropdown($('#ddYear'), 'ALL', '전체 연도');
      setDropdown($('#ddQuarter'), 'ALL', '전체 분기');

      $('#filterStatus').text('');
      loadAnimeList(1);
    });

    // =========================================================
    // (E) 페이지네이션(위임)
    // =========================================================
    $('#pagingArea').on('click', 'a.page-link', function (e) {
      e.preventDefault();
      const page = parseInt($(this).data('page'), 10);
      if (!page || page < 1) return;
      loadAnimeList(page);
    });

    // 최초 로딩
    loadAnimeList(1);

    // =========================================================
    // (F) 서버 호출
    // =========================================================
    function loadAnimeList(page) {
      const params = new URLSearchParams();

      params.set('page', String(page));
      params.set('condition', condition);
      params.set('sort', currentSort);

      if (keyword != null && keyword !== '') params.set('keyword', keyword);
      if (filterYear != null) params.set('year', String(filterYear));
      if (filterQuarter != null) params.set('quarter', String(filterQuarter));

      const url = contextPath + '/api/anime?' + params.toString();

      fetch(url, { method: 'GET', headers: { 'Accept': 'application/json' } })
        .then((res) => {
          if (!res.ok) throw new Error('HTTP ' + res.status);
          return res.json();
        })
        .then((data) => {
          renderAnimeList(data.animeList);
          renderPaging(data.paging);
          syncFilterUI(data.paging);
        })
        .catch((err) => console.log('[에러] AnimeListData:', err));
    }

    // =========================================================
    // (G) 서버 필터 상태 → UI 동기화
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
  // =========================================================
  function escapeHtml(str){
    if(str == null) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function normalizeUrl(raw){
    if(!raw) return '';
    raw = String(raw).trim();
    if(!raw) return '';
    if(raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    // DB가 ctx 포함(/animale/...)이면 그대로 사용
    if(contextPath && raw.startsWith(contextPath + '/')) return raw;

    if(raw.startsWith('/')) return contextPath + raw;
    return contextPath + '/' + raw;
  }

  function renderAnimeList(list) {
    const $container = $('#animeContainer');
    $container.empty();

    if (!list || list.length === 0) {
      $('#searchEmpty').show();
      return;
    }
    $('#searchEmpty').hide();

    list.forEach((item, idx) => {
      if (!item.animeThumbnailUrl) return;

      const thumbUrl = normalizeUrl(item.animeThumbnailUrl);

      const yearText = item.animeYear ? (escapeHtml(item.animeYear) + '년') : '연도 미정';
      const quarterText = item.animeQuarter ? escapeHtml(item.animeQuarter) : '분기 미정';
      const titleText = escapeHtml(item.animeTitle);

      const delay = Math.min(idx * 35, 350);

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

    $('.set-bg').each(function () {
      const bg = $(this).data('setbg');
      if (bg) $(this).css('background-image', "url('" + bg + "')");
    });
  }

  function renderPaging(p) {
    const $paging = $('#pagingArea');
    $paging.empty();

    if (!p) return;
    if (p.totalPage <= 1) return;

    if (p.hasPrev) {
      $paging.append(
        '<li class="arrow">' +
          '<a href="#" class="page-link" data-page="' + (p.startPage - 1) + '">&lt;</a>' +
        '</li>'
      );
    }

    for (let i = p.startPage; i <= p.endPage; i++) {
      const active = (i === p.page) ? 'active' : '';
      $paging.append(
        '<li class="' + active + '">' +
          '<a href="#" class="page-link" data-page="' + i + '">' + i + '</a>' +
        '</li>'
      );
    }

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
