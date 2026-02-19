<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!-- =========================================================
  dashboardheader.jsp
  - 관리자 템플릿 페이지에서 공통으로 include 하는 우상단 플로팅 액션
  - admincustom.css에 이미 스타일이 있으면 그대로 타고,
    없을 때도 최소한으로 보이도록 fallback 스타일을 포함
========================================================= -->

<style>
/* fallback: admincustom.css가 아직 없거나, 클래스명이 다를 때도 최소 표시 */
.admin-dashboard .admin-float-actions{
  position: fixed;
  top: 16px;
  right: 16px;
  z-index: 9999;
  display: flex;
  gap: 10px;
}
.admin-dashboard .admin-float-actions .afa-btn{
  width: 44px;
  height: 44px;
  border-radius: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid rgba(255,255,255,0.14);
  background: rgba(11,12,42,0.55);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  color: #fff;
  text-decoration: none;
  box-shadow: 0 10px 24px rgba(0,0,0,0.25);
}
.admin-dashboard .admin-float-actions .afa-btn:hover{
  background: rgba(11,12,42,0.72);
}
.admin-dashboard .admin-float-actions form{ margin:0; }
.admin-dashboard .admin-float-actions button.afa-btn{
  cursor: pointer;
}
</style>

<div class="admin-float-actions">
  <!-- 관리자 마이페이지 -->
  <a class="afa-btn" href="${ctx}/adminPage" title="관리자 페이지">
    <i class="ti ti-user"></i>
  </a>

  <!-- 메인 -->
  <a class="afa-btn" href="${ctx}/mainPage" title="메인">
    <i class="ti ti-home"></i>
  </a>

  <!-- 로그아웃 -->
  <form action="${ctx}/logout" method="get">
    <button type="submit" class="afa-btn" title="로그아웃"
            onclick="return confirm('로그아웃 하시겠습니까?');">
      <i class="ti ti-logout"></i>
    </button>
  </form>
</div>
