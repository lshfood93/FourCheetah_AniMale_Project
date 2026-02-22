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
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<style>
.header-profile-icon{
  font-size: 18px;
  color: #ffffff;
  line-height: 1;
  display: inline-block;
  transform: translateY(-1px);
  /* 더 올리고 싶으면 -2px, -3px로 */
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
                     
                     <li class="${newsCls}"><a href="${ctx}/newsList">NEWS</a></li>
                     <!-- 임시 네이버 스토어 >> 추후 오너먼트 페이지 사이트로 변경!! -->
                  <li><a href="${ctx}/ornably">SHOP</a></li>
                  
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
                           <a href="${ctx}/admindashboard" title="관리자 대시보드"> <i
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

<!-- 제재 안내 모달 -->
<c:if test="${not empty sessionScope.showSanctionModal}">
<div class="modal" id="sanctionModal" style="display: flex !important; 
     position: fixed; top: 0; left: 0; width: 100%; height: 100%; 
     background: rgba(0,0,0,0.7); z-index: 9999; align-items: center; justify-content: center;">
    <div class="modal-dialog" style="max-width: 500px; margin: 0;">
        <div class="modal-content" style="background: rgba(30, 30, 40, 0.98); color: #fff; border: 1px solid rgba(255,255,255,0.2); border-radius: 12px;">
            <div class="modal-header" style="border-bottom: 1px solid rgba(255,255,255,0.1);">
                <h5 class="modal-title" style="color: #ff6b6b;">⚠️ 계정 이용 제한 안내</h5>
            </div>
            <div class="modal-body" style="padding: 20px;">
                <p style="margin-bottom: 10px;"><strong>사유:</strong> ${sessionScope.sanctionReason}</p>
                <p style="margin-bottom: 20px;"><strong>제한 해제일:</strong> ${sessionScope.sanctionEndAt}</p>
                <hr style="border-color: rgba(255,255,255,0.1); margin: 20px 0;">
                <p style="margin-bottom: 10px;"><strong>🚫 제한 내용:</strong></p>
                <ul style="margin-bottom: 20px; padding-left: 20px;">
                    <li>게시글 작성/수정/삭제 불가</li>
                    <li>댓글 작성/수정/삭제 불가</li>
                    <li>신고 기능 불가</li>
                </ul>
                <p style="margin-bottom: 0;"><strong>✅ 이용 가능:</strong> 조회, 좋아요, 캐시 충전/사용</p>
            </div>
            <div class="modal-footer" style="border-top: 1px solid rgba(255,255,255,0.1);">
                <button type="button" class="btn-sm2 btn-primary2" onclick="closeSanctionModal()">확인</button>
            </div>
        </div>
    </div>
</div>
</c:if>

<%-- ChatAI 위젯 (전 페이지 공통) --%>
<jsp:include page='/WEB-INF/common/chatai.jsp' />

<%-- ChatAI 전용 CSS/JS (전 페이지 공통 1회 로드) --%>
<link rel='stylesheet' href='${ctx}/css/chatai.css' />
<script src='${ctx}/js/chatai.js' defer></script>

<script src="${ctx}/js/header.js" defer></script>
