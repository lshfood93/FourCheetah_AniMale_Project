package fourcheetah.animale.web.controller.admin;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import fourcheetah.animale.web.service.admin.AdminDashboardService;
import jakarta.servlet.http.HttpSession;

import java.util.*;
import java.time.LocalDate;

@Controller
@RequestMapping("/admin")
public class AdminDashboardController {

    @Autowired
    private AdminDashboardService adminDashboardService;

    // =========================================================
    // 메인 대시보드 페이지 (JSP 반환)
    // URL: /admin/dashboard
    // JSP: adminDashboardMain.jsp
    // =========================================================
    
    @GetMapping("/dashboard")
    public String dashboard(
            @RequestParam(required = false) Integer year,
            HttpSession session,
            Model model
    ) {
        System.out.println("========================================");
        System.out.println("[캐시 대시보드] 페이지 진입");
        System.out.println("[파라미터] year=" + year);
        
        // =========================================================
        // STEP 1: 권한 체크
        // =========================================================
        
        Integer memberId = (Integer) session.getAttribute("memberId");
        String memberRole = (String) session.getAttribute("memberRole");
        
        System.out.println("[세션] memberId=" + memberId + ", role=" + memberRole);
        
        if (memberId == null) {
            System.out.println("[권한 체크] 로그인 필요");
            return message(model, "로그인이 필요합니다.", "/login");
        }
        
        if (!"ADMIN".equals(memberRole)) {
            System.out.println("[권한 체크] 권한 없음");
            return message(model, "관리자 권한이 필요합니다.", "/mainPage");
        }
        
        System.out.println("[권한 체크] 통과");
        
        // =========================================================
        // STEP 2: 기본값 설정
        // =========================================================
        
        if (year == null || year < 2020 || year > 2030) {
            year = LocalDate.now().getYear();
        }
        
        int currentMonth = LocalDate.now().getMonthValue();
        
        // =========================================================
        // STEP 3: Service에서 데이터 조회
        // =========================================================
        
        Map<String, Object> dashboardData = adminDashboardService.getDashboardData(year);
        
        // =========================================================
        // STEP 4: Model에 데이터 담기
        // =========================================================
        
        model.addAttribute("year", year);
        model.addAttribute("currentMonth", currentMonth);
        model.addAttribute("yearlyTotalAmount", dashboardData.get("yearlyTotalAmount"));
        model.addAttribute("monthlyData", dashboardData.get("monthlyData"));
        model.addAttribute("lastYearAmount", dashboardData.get("lastYearAmount"));
        model.addAttribute("yearGrowthRate", dashboardData.get("yearGrowthRate"));
        model.addAttribute("paymentStats", dashboardData.get("paymentStats"));
        
        System.out.println("[Controller] Model 설정 완료");
        System.out.println("========================================");
        
        return "adminDashboardMain";
    }
    
    // =========================================================
    // 백엔드 테스트용 AJAX API (JSON 반환)
    // URL: /admin/dashboard/data
    // =========================================================
    
    @GetMapping("/dashboard/data")
    @ResponseBody
    public Map<String, Object> dashboardData(
            @RequestParam(required = false) Integer year,
            HttpSession session
    ) {
        System.out.println("========================================");
        System.out.println("[캐시 대시보드 AJAX] 데이터 조회");
        
        // 권한 체크
        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            return fail("권한이 없습니다.");
        }
        
        // 기본값
        if (year == null) {
            year = LocalDate.now().getYear();
        }
        
        // Service에서 조회
        Map<String, Object> dashboardData = adminDashboardService.getDashboardData(year);
        
        // 응답 구성
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("year", year);
        response.putAll(dashboardData);
        
        System.out.println("========================================");
        
        return response;
    }
    
    // =========================================================
    // 공통 유틸
    // =========================================================
    
    private String message(Model model, String msg, String location) {
        model.addAttribute("msg", msg);
        model.addAttribute("location", location);
        return "message";
    }
    
    private Map<String, Object> fail(String msg) {
        Map<String, Object> res = new HashMap<>();
        res.put("success", false);
        res.put("message", msg);
        return res;
    }
}