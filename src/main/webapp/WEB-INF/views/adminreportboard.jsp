<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!-- =========================================================
  Admin Guard
  - ADMIN 이외 접근은 메인으로 리다이렉트
  - (주의) redirect는 response commit 전에 실행되어야 하므로 최상단 배치 유지
========================================================= -->
<c:if test="${empty sessionScope.memberRole or sessionScope.memberRole ne 'ADMIN'}">
  <c:redirect url="${ctx}/mainPage" />
</c:if>

<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AniMale Admin | 신고 게시글 관리</title>

  <!-- ✅ 파비콘/스타일 경로는 ctx 기준으로 통일 -->
  <link rel="icon" type="image/png" href="${ctx}/favicon.png" />
  <link rel="stylesheet" href="${ctx}/assets/css/styles.min.css" />
  <link rel="stylesheet" href="${ctx}/assets/css/admincustom.css" />

  <style>
    /* =========================================================
      Admin Report Board (UI only)
      - 서버 연동 전 UI 가독성/클릭 영역/줄바꿈 정도만 최소 보강
      - 템플릿 톤 유지(색/폰트/레이아웃은 최대한 그대로)
    ========================================================= */

    /* 테이블에서 제목/내용 링크 클릭 영역을 넓히고 hover를 자연스럽게 */
    .report-link{
      display:inline-block;
      max-width: 100%;
      color: inherit;
      text-decoration: none;
    }
    .report-link:hover{
      text-decoration: underline;
    }

    /* 긴 내용이 한 줄로 너무 길어지지 않게 줄임표 처리(원하면 줄바꿈으로 바꿔도 됨) */
    .td-ellipsis{
      max-width: 520px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    /* 신고횟수 badge 정렬 보정(가독성) */
    .badge-count{
      min-width: 44px;
      display: inline-flex;
      justify-content: center;
      align-items: center;
    }

    /* Action 버튼 간격/아이콘 정렬 */
    .action-btns .btn{
      display:inline-flex;
      align-items:center;
      justify-content:center;
    }
  </style>
</head>

<body class="admin-dashboard">

  <div class="page-wrapper"
       id="main-wrapper"
       data-layout="vertical"
       data-navbarbg="skin6"
       data-sidebartype="full"
       data-sidebar-position="fixed"
       data-header-position="fixed">

    <!-- =========================================================
      Sidebar
      - 대시보드 페이지와 동일한 구조 유지
    ========================================================= -->
    <aside class="left-sidebar">
      <div>
        <div class="brand-logo d-flex align-items-center justify-content-center">
          <a href="${ctx}/admindashboard" class="text-nowrap logo-img">
            <img src="${ctx}/assets/images/logos/animale-logo.svg" width="150" alt="AniMale Logo">
          </a>
        </div>

        <nav class="sidebar-nav scroll-sidebar" data-simplebar="">
          <ul id="sidebarnav">
            <li class="sidebar-item">
              <a class="sidebar-link" href="${ctx}/admindashboard">
                <span class="hide-menu">관리자 대시보드</span>
              </a>
            </li>

            <!-- ✅ 현재 페이지 active 표시(UX) -->
            <li class="sidebar-item">
              <a class="sidebar-link active" href="${ctx}/adminreportboard">
                <span class="hide-menu">신고 게시글 관리</span>
              </a>
            </li>
          </ul>
        </nav>
      </div>
    </aside>

    <!-- =========================================================
      Body
    ========================================================= -->
    <div class="body-wrapper">

      <!-- ✅ 우상단 영역(공통 include) -->
      <jsp:include page="dashboardheader.jsp" />

      <div class="container-fluid">

        <!-- =========================================================
          Report Board Manager (UI)
          - 지금은 더미 데이터
          - 추후 연동 시:
            1) 제목/내용 링크 -> 게시글 상세로 이동
            2) 정렬 select -> condition 파라미터로 재조회
            3) 반려/처리 버튼 -> 처리 API 호출
        ========================================================= -->
        <div class="card w-100">
          <div class="card-body">

            <div class="d-flex align-items-center justify-content-between mb-3">
              <h5 class="card-title mb-0">신고 게시글 관리</h5>

              <!-- ✅ (UI) 정렬 선택: 추후 서버 연동 시 name/id 부여 추천 -->
              <select class="form-select" style="max-width: 180px;" aria-label="정렬 선택">
                <option value="RECENT" selected>최신순</option>
                <option value="OLDEST">오래된순</option>
              </select>
            </div>

            <p class="text-muted mb-3">제목 / 내용 클릭 시 게시글 이동</p>

            <div class="table-responsive">
              <table class="table align-middle">
                <thead>
                  <tr>
                    <th style="width:140px;">작성자ID</th>
                    <th style="width:220px;">제목</th>
                    <th style="width:120px;" class="text-center">신고횟수</th>
                    <th>내용</th>
                    <th style="width:140px;" class="text-center">Action</th>
                  </tr>
                </thead>

                <tbody>
                  <!-- =========================================================
                    더미 행(샘플)
                    - 추후 c:forEach로 서버 데이터 바인딩 예정
                    - 링크 href는 지금은 javascript:void(0)
                  ========================================================= -->
                  <tr>
                    <td>이현빈</td>
                    <td>
                      <a href="javascript:void(0);" class="fw-semibold report-link" title="게시글로 이동">
                        마린조아
                      </a>
                    </td>
                    <td class="text-center">
                      <span class="badge rounded-pill text-bg-light badge-count">36</span>
                    </td>
                    <td class="td-ellipsis">
                      <a href="javascript:void(0);" class="text-muted report-link" title="게시글로 이동">
                        마린우히히
                      </a>
                    </td>
                    <td class="text-center">
                      <div class="d-inline-flex gap-2 action-btns">
                        <button class="btn btn-sm btn-outline-primary" type="button" title="반려(패스)">
                          <i class="ti ti-x" aria-hidden="true"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-dark" type="button" title="신고 처리">
                          <i class="ti ti-check" aria-hidden="true"></i>
                        </button>
                      </div>
                    </td>
                  </tr>

                  <tr>
                    <td>최준혁</td>
                    <td>
                      <a href="javascript:void(0);" class="fw-semibold report-link" title="게시글로 이동">
                        술줘
                      </a>
                    </td>
                    <td class="text-center">
                      <span class="badge rounded-pill text-bg-light badge-count">5</span>
                    </td>
                    <td class="td-ellipsis">
                      <a href="javascript:void(0);" class="text-muted report-link" title="게시글로 이동">
                        부어라마셔라
                      </a>
                    </td>
                    <td class="text-center">
                      <div class="d-inline-flex gap-2 action-btns">
                        <button class="btn btn-sm btn-outline-primary" type="button" title="반려(패스)">
                          <i class="ti ti-x" aria-hidden="true"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-dark" type="button" title="신고 처리">
                          <i class="ti ti-check" aria-hidden="true"></i>
                        </button>
                      </div>
                    </td>
                  </tr>

                  <tr>
                    <td>김영인</td>
                    <td>
                      <a href="javascript:void(0);" class="fw-semibold report-link" title="게시글로 이동">
                        치킨공주
                      </a>
                    </td>
                    <td class="text-center">
                      <span class="badge rounded-pill text-bg-light badge-count">99</span>
                    </td>
                    <td class="td-ellipsis">
                      <a href="javascript:void(0);" class="text-muted report-link" title="게시글로 이동">
                        난피자보다치킨이좋아
                      </a>
                    </td>
                    <td class="text-center">
                      <div class="d-inline-flex gap-2 action-btns">
                        <button class="btn btn-sm btn-outline-primary" type="button" title="반려(패스)">
                          <i class="ti ti-x" aria-hidden="true"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-dark" type="button" title="신고 처리">
                          <i class="ti ti-check" aria-hidden="true"></i>
                        </button>
                      </div>
                    </td>
                  </tr>

                  <tr>
                    <td>이승환</td>
                    <td>
                      <a href="javascript:void(0);" class="fw-semibold report-link" title="게시글로 이동">
                        닭목살킬러
                      </a>
                    </td>
                    <td class="text-center">
                      <span class="badge rounded-pill text-bg-light badge-count">999</span>
                    </td>
                    <td class="td-ellipsis">
                      <a href="javascript:void(0);" class="text-muted report-link" title="게시글로 이동">
                        에다가 오이라면까지
                      </a>
                    </td>
                    <td class="text-center">
                      <div class="d-inline-flex gap-2 action-btns">
                        <button class="btn btn-sm btn-outline-primary" type="button" title="반려(패스)">
                          <i class="ti ti-x" aria-hidden="true"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-dark" type="button" title="신고 처리">
                          <i class="ti ti-check" aria-hidden="true"></i>
                        </button>
                      </div>
                    </td>
                  </tr>

                </tbody>
              </table>
            </div>

            <!-- =========================================================
              Pagination (UI)
              - 추후 서버 연동 시: start/end/hasPrev/hasNext 기반으로 생성
            ========================================================= -->
            <nav class="d-flex justify-content-center mt-4" aria-label="페이지네이션">
              <ul class="pagination mb-0">
                <li class="page-item"><a class="page-link" href="javascript:void(0);">이전</a></li>
                <li class="page-item active"><a class="page-link" href="javascript:void(0);">1</a></li>
                <li class="page-item"><a class="page-link" href="javascript:void(0);">2</a></li>
                <li class="page-item"><a class="page-link" href="javascript:void(0);">3</a></li>
                <li class="page-item"><a class="page-link" href="javascript:void(0);">다음</a></li>
              </ul>
            </nav>

          </div>
        </div>

      </div>
    </div>
  </div>

  <!-- ✅ 템플릿 JS -->
  <script src="${ctx}/assets/libs/jquery/dist/jquery.min.js"></script>
  <script src="${ctx}/assets/libs/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
  <script src="${ctx}/assets/js/sidebarmenu.js"></script>
  <script src="${ctx}/assets/js/app.min.js"></script>
  <script src="${ctx}/assets/libs/simplebar/dist/simplebar.js"></script>
</body>
</html>
