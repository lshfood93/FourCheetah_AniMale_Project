<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!-- active 클래스 계산 (B 네이밍 유지) -->
<c:set var="homeCls" value="" />
<c:if test="${activeMenu eq 'HOME'}">
	<c:set var="homeCls" value="active" />
</c:if>

<c:set var="aniCls" value="" />
<c:if test="${activeMenu eq 'ANILIST'}">
	<c:set var="aniCls" value="active" />
</c:if>

<c:set var="comCls" value="" />
<c:if test="${activeMenu eq 'COMMUNITY'}">
	<c:set var="comCls" value="active" />
</c:if>

<c:set var="newsCls" value="" />
<c:if test="${activeMenu eq 'NEWS'}">
	<c:set var="newsCls" value="active" />
</c:if>
<style>
.header-profile-icon{
  font-size: 18px;
  color: #ffffff;
  vertical-align: middle;
}
</style>

<header class="header">
	<div class="container">
		<div class="row align-items-center">

			<%-- Logo --%>
			<div class="col-lg-2">
				<div class="header__logo">
					<a href="${ctx}/mainPage" class="logo-img"> <img
						src="${ctx}/img/animale-logo.png" alt="AniMale 로고" />
					</a>
				</div>
			</div>

			<%-- Menu --%>
			<div class="col-lg-8">
				<nav class="header__menu">
					<ul>
						<li class="${homeCls}"><a href="${ctx}/mainPage">HOME</a></li>

						<li class="${aniCls}"><a href="${ctx}/animeList">ANILIST</a></li>

						<li class="dropdown ${comCls}"><a href="javascript:void(0)">COMMUNITY</a>
							<ul class="dropdown-menu">
								<li><a href="${ctx}/boardList?boardCategory=ANIME">ANIME</a></li>
							</ul></li>
							<!-- 임시 네이버 스토어 >> 추후 오너먼트 페이지 사이트로 변경!! -->
						<li><a href="https://snxbest.naver.com/home" target="_blank" rel="noopener noreferrer">SHOP</a></li>
						

						<li class="${newsCls}"><a href="${ctx}/newsList">NEWS</a></li>
					</ul>
				</nav>
			</div>

			<%-- Right --%>
			<div class="col-lg-2">
				<div class="header__right">

					<%-- Profile Icon --%>
					<c:if test="${hideProfileIcon ne true}">
						<div class="header__right__icons">
							<c:choose>

								<c:when test="${not empty profileHref}">
									<a href="${ctx}${profileHref}" title="프로필"> <i
										class="fa fa-user header-profile-icon"></i>
									</a>
								</c:when>

								<c:when test="${empty sessionScope.memberId}">
									<a href="${ctx}/login" title="로그인"> <i
										class="fa fa-user header-profile-icon"></i>
									</a>
								</c:when>

								<c:when test="${sessionScope.memberRole eq 'ADMIN'}">
									<a href="${ctx}/adminPage" title="관리자 페이지"> <i
										class="fa fa-user header-profile-icon"></i>
									</a>
								</c:when>

								<c:otherwise>
									<a href="${ctx}/myPage" title="마이페이지"> <i
										class="fa fa-user header-profile-icon"></i>
									</a>
								</c:otherwise>

							</c:choose>
						</div>
					</c:if>


					<%-- 로그아웃 버튼 (로그인 상태에서만) --%>
					<c:if test="${not empty sessionScope.memberId}">
						<a href="${ctx}/logout" class="logout-link">로그아웃</a>
					</c:if>

				</div>
			</div>

		</div>
	</div>
</header>

<script src="${ctx}/js/header.js" defer></script>
