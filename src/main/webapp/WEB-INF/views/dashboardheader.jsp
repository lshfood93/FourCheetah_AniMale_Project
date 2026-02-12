<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<div class="admin-float-actions">
  <a class="admin-float-btn" href="${ctx}/logout" title="로그아웃">
    <img class="admin-logout-img" src="${ctx}/assets/images/icons/logout.png" alt="logout">
  </a>
  <a class="admin-float-btn" href="${ctx}/adminPage" title="관리자 마이페이지">
    <img class="admin-profile-img" src="${ctx}/assets/images/profile/user-1.jpg" alt="admin">
  </a>
</div>
