<!-- =========================================================
  AniMale Anime List (비동기 + 필터 + 검색 + 정렬 + 페이징)
  - JSP 안에 JS(inline script) 포함 버전 (통합본)

  ✅ 이번 반영(기능은 동일, 안정성/호환성 보강)
  1) ✅ ctx 경로 통일: <%=request.getContextPath()%> 혼용 제거
  2) ✅ ES5 호환 문법으로 정리(const/let/arrow/startsWith 제거)
  3) ✅ 서버 paging.year / paging.quarter 값이 '2024년' / '1분기'처럼 내려와도 정상 동기화
  4) ✅ 썸네일 없는 데이터로 인해 카드가 0개가 되는 케이스도 Empty UI 처리
  5) ✅ 카드 렌더 시 escapeHtml 적용(XSS 방어)
========================================================= -->

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AniMale | 애니리스트</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<!-- ✅ 변경: 파비콘 경로 ctx로 통일 -->
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
                 ========================================================= -->
              <div class="anime-search-wrapper">
                <div class="anime-search-box">
                  <select id="animeSearchType">
                    <option value="ANIME_SEARCH_TITLE">제목</option>
                    <option value="ANIME_SEARCH_STORY">줄거리</option>
                  </select>

                  <input type="text" id="animeSearchInput" placeholder="검색어를 입력하세요">

                  <button type="button" id="animeSearchBtn">
                    <i class="fa fa-search"></i>
                  </button>
                </div>

                <button type="button" id="animeResetBtn" class="anime-reset-btn">전체보기</button>

                <c:if test="${fn:toUpperCase(sessionScope.memberRole) eq 'ADMIN'}">
                  <a class="anime-admin-btn" href="${ctx}/animeWritePage">애니 추가</a>
                </c:if>
              </div>

              <!-- =========================================================
                   2줄: 연도/분기 + 정렬
                 ========================================================= -->
              <div class="anime-sub-controls">

                <div class="product__page__filter filter-box">
                  <p>연도/분기</p>

                  <!-- Year -->
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

                  <!-- Quarter -->
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

                  <button type="button" id="filterApplyBtn" class="anime-filter-apply">필터 적용</button>
                  <span id="filterStatus" class="filter-status"></span>
                </div>

                <div class="product__page__filter sort-box">
                  <p>정렬</p>

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

      <div class="row" id="animeContainer"></div>

      <div class="search-result-wrapper" id="searchEmpty" style="display:none;">
        <div class="search-empty">검색 결과가 없습니다.</div>
      </div>

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

  <!-- ✅ 변경: js 경로 ctx로 통일 -->
  <script src="${ctx}/js/jquery-3.3.1.min.js"></script>
  <script src="${ctx}/js/bootstrap.min.js"></script>
  <script src="${ctx}/js/main.js"></script>

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
  // ✅ 변경: ctx를 그대로 JS에 주입(스크립틀릿 제거)
  var contextPath = '${ctx}';

  // =========================================================
  // 1) 전역 상태 변수(페이지 전체에서 유지되는 상태)
  // =========================================================
  var currentSort = 'RECENT';

  var uiYear = 'ALL';
  var uiQuarter = 'ALL';

  var filterYear = null;
  var filterQuarter = null;

  var condition = 'ANIME_LIST_RECENT';
  var keyword = null;

  // =========================================================
  // 공통 유틸(ES5)
  // =========================================================

  // ✅ 변경: XSS 방어(서버에서 escape를 해도, 프론트에서도 한 번 더 안전장치)
  function escapeHtml(v){
    var s = (v === null || v === undefined) ? '' : String(v);
    return s
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  // ✅ 변경: 서버가 '2024년', '1분기'처럼 내려줘도 숫자만 뽑아서 통일
  function extractNumber(v){
    if(v === null || v === undefined) return null;
    var s = String(v);
    var only = s.replace(/[^0-9]/g, '');
    if(!only) return null;
    return parseInt(only, 10);
  }

  // ✅ 변경: querystring 생성(URLSearchParams 미사용)
  function buildQuery(obj){
    var parts = [];
    for(var k in obj){
      if(!obj.hasOwnProperty(k)) continue;
      if(obj[k] === null || obj[k] === undefined) continue;
      parts.push(encodeURIComponent(k) + '=' + encodeURIComponent(String(obj[k])));
    }
    return parts.join('&');
  }

  // =========================================================
  // 2) DOM Ready: 이벤트 바인딩 + 최초 로딩
  // =========================================================
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

      var $dd = $(this).closest('.am-dd');
      if ($dd.hasClass('is-open')) closeAllDropdowns();
      else openDropdown($dd);
    });

    $('.am-dd').on('click', '.am-dd__list li', function (e) {
      e.preventDefault();
      e.stopPropagation();

      var $li = $(this);
      var $dd = $li.closest('.am-dd');
      var value = String($li.data('value'));
      var label = $li.text();

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
    // (B) 필터 적용 버튼(연도/분기)
    // =========================================================
    $('#filterApplyBtn').on('click', function () {
      filterYear = (uiYear !== 'ALL') ? parseInt(uiYear, 10) : null;
      filterQuarter = (uiQuarter !== 'ALL') ? parseInt(uiQuarter, 10) : null;
      loadAnimeList(1);
    });

    // =========================================================
    // (C) 검색 버튼 / 엔터 처리
    // =========================================================
    $('#animeSearchBtn').on('click', function () {
      var value = $.trim($('#animeSearchInput').val());
      var searchType = $('#animeSearchType').val();

      if (value === '') {
        keyword = null;
        condition = 'ANIME_LIST_RECENT';
      } else {
        keyword = value;
        condition = searchType;
      }
      loadAnimeList(1);
    });

    // ✅ 변경: e.key 대신 keyCode(ES5/호환)
    $('#animeSearchInput').on('keydown', function (e) {
      if (e.keyCode === 13) {
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
    // (E) 페이지네이션 이벤트 위임
    // =========================================================
    $('#pagingArea').on('click', 'a.page-link', function (e) {
      e.preventDefault();

      var page = parseInt($(this).data('page'), 10);
      if (!page || page < 1) return;

      loadAnimeList(page);
    });

    // =========================================================
    // (F) 최초 로딩
    // =========================================================
    loadAnimeList(1);

    // =========================================================
    // (G) API 호출 함수
    // =========================================================
    function loadAnimeList(page) {
      var queryObj = {
        page: page,
        condition: condition,
        sort: currentSort
      };

      if (keyword != null && keyword !== '') queryObj.keyword = keyword;
      if (filterYear != null) queryObj.year = filterYear;
      if (filterQuarter != null) queryObj.quarter = filterQuarter;

      var url = contextPath + '/api/anime?' + buildQuery(queryObj);

      fetch(url, { method: 'GET', headers: { 'Accept': 'application/json' } })
        .then(function (res) {
          if (!res.ok) throw new Error('HTTP ' + res.status);
          return res.json();
        })
        .then(function (data) {
          renderAnimeList(data ? data.animeList : null);
          renderPaging(data ? data.paging : null);

          // ✅ 서버 상태 기준으로 드롭다운/상태 텍스트 동기화
          syncFilterUI(data ? data.paging : null);
        })
        .catch(function (err) {
          console.log('[에러] AnimeListData:', err);
        });
    }

    // =========================================================
    // (H) 서버가 내려준 필터 상태로 UI 동기화
    // =========================================================
    function syncFilterUI(paging) {
      if (!paging) return;

      // ✅ 변경: '2024년' 같이 내려와도 숫자만 추출해서 동기화
      var y = extractNumber(paging.year);
      var q = extractNumber(paging.quarter);

      // year
      if (y != null) {
        uiYear = String(y);
        filterYear = y;
        setDropdown($('#ddYear'), uiYear, y + '년');
      } else {
        uiYear = 'ALL';
        filterYear = null;
        setDropdown($('#ddYear'), 'ALL', '전체 연도');
      }

      // quarter
      if (q != null) {
        uiQuarter = String(q);
        filterQuarter = q;
        setDropdown($('#ddQuarter'), uiQuarter, q + '분기');
      } else {
        uiQuarter = 'ALL';
        filterQuarter = null;
        setDropdown($('#ddQuarter'), 'ALL', '전체 분기');
      }

      // 상태 텍스트(예: '2024년 · 2분기 적용중')
      var $status = $('#filterStatus');
      if ($status.length === 0) return;

      $status.text('');

      if (filterYear == null && filterQuarter == null) return;

      var parts = [];
      if (filterYear != null) parts.push(filterYear + '년');
      if (filterQuarter != null) parts.push(filterQuarter + '분기');
      $status.text(parts.join(' · ') + ' 적용중');
    }
  });

  // =========================================================
  // 3) 렌더 함수(전역)
  // =========================================================
  function renderAnimeList(list) {
    var $container = $('#animeContainer');
    $container.empty();

    // ✅ 리스트 자체가 비었으면 Empty
    if (!list || list.length === 0) {
      $('#searchEmpty').show();
      return;
    }

    $('#searchEmpty').hide();

    var appended = 0; // ✅ 변경: 썸네일 없는 항목 skip 때문에 '카드 0개' 상황 감지용

    for (var idx = 0; idx < list.length; idx++) {
      var item = list[idx];
      if (!item) continue;

      // ✅ 썸네일이 없으면 카드 생성 스킵
      if (!item.animeThumbnailUrl) continue;

      var raw = String(item.animeThumbnailUrl);

      // ✅ 변경: startsWith 제거(ES5)
      var thumbUrl;
      if (/^https?:\/\//i.test(raw)) thumbUrl = raw;
      else if (raw.charAt(0) === '/') thumbUrl = contextPath + raw;
      else thumbUrl = contextPath + '/' + raw;

      var yearText = item.animeYear ? (String(item.animeYear) + '년') : '연도 미정';
      var quarterText = item.animeQuarter ? String(item.animeQuarter) : '분기 미정';

      var delay = Math.min(idx * 35, 350);

      // ✅ 변경: 출력값 escape 처리(보안/깨짐 방지)
      var titleSafe = escapeHtml(item.animeTitle);
      var yearSafe = escapeHtml(yearText);
      var quarterSafe = escapeHtml(quarterText);

      var html =
        '<div class="col-lg-3 col-md-4 col-sm-6 anime-card" style="animation-delay:' + delay + 'ms">' +
          '<a href="' + contextPath + '/animeDetail?animeId=' + encodeURIComponent(item.animeId) + '" class="anime-link">' +
            '<div class="product__item">' +
              '<div class="product__item__pic set-bg" data-setbg="' + escapeHtml(thumbUrl) + '"></div>' +
              '<div class="product__item__text">' +
                '<ul class="anime-meta">' +
                  '<li>' + yearSafe + '</li>' +
                  '<li class="badge-q">' + quarterSafe + '</li>' +
                '</ul>' +
                '<h5 class="anime-title">' + titleSafe + '</h5>' +
              '</div>' +
            '</div>' +
          '</a>' +
        '</div>';

      $container.append(html);
      appended++;
    }

    // ✅ 변경: list는 있는데(서버 응답) 썸네일 없는 데이터만 있어서 카드가 0개인 경우
    if (appended === 0) {
      $('#searchEmpty').show();
      return;
    }

    // ✅ 변경: 전체 .set-bg 말고, 이번에 그린 카드 내부만 처리(불필요한 사이드이펙트 줄임)
    $container.find('.set-bg').each(function () {
      var bg = $(this).data('setbg');
      if (bg) $(this).css('background-image', "url('" + bg + "')");
    });
  }

  function renderPaging(p) {
    var $paging = $('#pagingArea');
    $paging.empty();

    if (!p) return;
    if (p.totalPage <= 1) return;

    // 이전 블록
    if (p.hasPrev) {
      $paging.append(
        '<li class="arrow">' +
          '<a href="#" class="page-link" data-page="' + (p.startPage - 1) + '">&lt;</a>' +
        '</li>'
      );
    }

    // 페이지 번호
    for (var i = p.startPage; i <= p.endPage; i++) {
      var active = (i === p.page) ? 'active' : '';
      $paging.append(
        '<li class="' + active + '">' +
          '<a href="#" class="page-link" data-page="' + i + '">' + i + '</a>' +
        '</li>'
      );
    }

    // 다음 블록
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
