package fourcheetah.animale.web.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 제재 상태 체크 Interceptor
 * SUSPEND 상태일 때 특정 기능 차단
 */
@Component
public class SanctionCheckInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) 
            throws Exception {
        
        HttpSession session = request.getSession(false);
        
        if (session == null) {
            // 로그인 안 됨 → 통과 (다른 인터셉터에서 처리)
            return true;
        }
        
        String memberStatus = (String) session.getAttribute("memberStatus");
        
        // SUSPEND 상태 체크
        if ("SUSPEND_7D".equals(memberStatus) || "SUSPEND_30D".equals(memberStatus)) {
            
            System.out.println("[제재 체크] 정지된 사용자의 요청 차단: " + request.getRequestURI());
            
            // AJAX 요청인지 확인
            String ajaxHeader = request.getHeader("X-Requested-With");
            boolean isAjax = "XMLHttpRequest".equals(ajaxHeader);
            
            if (isAjax) {
                // AJAX → JSON 응답
                response.setContentType("application/json; charset=UTF-8");
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().write("{\"fail\":\"정지 상태에서는 이용할 수 없는 기능입니다.\"}");
            } else {
                // 일반 요청 → 에러 페이지 또는 리다이렉트
                response.sendRedirect(request.getContextPath() + "/boardList?error=suspended");
            }
            
            return false; // 요청 차단
        }
        
        // BANNED는 로그인 단계에서 차단되므로 여기선 체크 불필요
        
        return true; // 요청 통과
    }
}