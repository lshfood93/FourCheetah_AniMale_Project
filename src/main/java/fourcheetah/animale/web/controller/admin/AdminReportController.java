package fourcheetah.animale.web.controller.admin;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import fourcheetah.animale.web.service.board.AdminReportService;

import jakarta.servlet.http.HttpSession;
import java.util.*;

@Controller
@RequestMapping("/admin/reports")
public class AdminReportController {

    @Autowired
    private AdminReportService adminReportService;

    /**
     * 신고 목록 페이지 (STEP 3: 실제 데이터 표시)
     */
    @GetMapping("/admin/reports")
    public String reportList(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "desc") String sortOrder,
            HttpSession session,
            Model model) {
        
        System.out.println("========================================");
        System.out.println("[신고 관리] 페이지 진입");
        System.out.println("[파라미터] page=" + page + ", sortOrder=" + sortOrder);
        
        // 세션 체크
        Integer memberId = (Integer) session.getAttribute("memberId");
        String memberRole = (String) session.getAttribute("memberRole");
        
        System.out.println("[세션] memberId=" + memberId + ", role=" + memberRole);
        
        // 권한 체크
        if (memberId == null || !"ADMIN".equals(memberRole)) {
            System.out.println("[권한 체크] 실패 - 관리자 아님");
            model.addAttribute("msg", "관리자만 접근 가능합니다.");
            model.addAttribute("location", "/");
            return "message";
        }
        
        System.out.println("[권한 체크] 통과");
        
        // Service 호출 (실제 DB 조회)
        System.out.println("[Controller] Service.selectReportList() 호출");
        
        int pageSize = 10; // 페이지당 10개
        Map<String, Object> result = adminReportService.selectReportList(page, pageSize, sortOrder);
        
        System.out.println("[Controller] Service 호출 완료");
        System.out.println("  - 조회 결과: " + result.get("reports"));
        System.out.println("  - 전체 건수: " + result.get("totalCount"));
        
        // Model에 데이터 담기
        model.addAttribute("reports", result.get("reports"));
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", result.get("totalPages"));
        model.addAttribute("totalCount", result.get("totalCount"));
        model.addAttribute("startPage", result.get("startPage"));
        model.addAttribute("endPage", result.get("endPage"));
        model.addAttribute("sortOrder", sortOrder);
        
        System.out.println("[Controller] JSP로 이동: admindashboardreport.jsp");
        System.out.println("========================================");
        
        return "adminreportboard";
    }
    
    /**
     * 신고 반려 (AJAX)
     */
    @PostMapping("/reject")
    @ResponseBody
    public Map<String, Object> rejectReport(
            @RequestParam int boardId,
            HttpSession session) {
        
        System.out.println("========================================");
        System.out.println("[신고 반려] 요청");
        System.out.println("[파라미터] boardId=" + boardId);
        
        Map<String, Object> response = new HashMap<>();
        
        try {
            Integer memberId = (Integer) session.getAttribute("memberId");
            
            if (memberId == null) {
                System.out.println("[신고 반려] 로그인 필요");
                response.put("fail", "로그인이 필요합니다.");
                return response;
            }
            
            System.out.println("[신고 반려] 처리자 ID=" + memberId);
            System.out.println("[신고 반려] Service.updateReportReject() 호출");
            
            // Service 호출
            boolean result = adminReportService.updateReportReject(boardId, memberId);
            
            if (result) {
                response.put("ok", "신고를 반려했습니다.");
                System.out.println("[신고 반려] 성공");
            } else {
                response.put("fail", "신고 반려 처리에 실패했습니다.");
                System.out.println("[신고 반려] 실패");
            }
            
        } catch (Exception e) {
            System.out.println("[신고 반려 에러] " + e.getMessage());
            e.printStackTrace();
            response.put("fail", "신고 반려 처리 중 오류가 발생했습니다.");
        }
        
        System.out.println("========================================");
        
        return response;
    }
    
    /**
     * 신고 승인 (AJAX)
     */
    @PostMapping("/approve")
    @ResponseBody
    public Map<String, Object> approveReport(
            @RequestParam int boardId,
            HttpSession session) {
        
        System.out.println("========================================");
        System.out.println("[신고 승인] 요청");
        System.out.println("[파라미터] boardId=" + boardId);
        
        Map<String, Object> response = new HashMap<>();
        
        try {
            Integer memberId = (Integer) session.getAttribute("memberId");
            
            if (memberId == null) {
                System.out.println("[신고 승인] 로그인 필요");
                response.put("fail", "로그인이 필요합니다.");
                return response;
            }
            
            System.out.println("[신고 승인] 처리자 ID=" + memberId);
            System.out.println("[신고 승인] Service.updateReportApprove() 호출");
            
            // Service 호출
            boolean result = adminReportService.updateReportApprove(boardId, memberId);
            
            if (result) {
                response.put("ok", "신고를 승인했습니다. 게시글이 삭제되고 작성자에게 경고가 부과되었습니다.");
                System.out.println("[신고 승인] 성공");
            } else {
                response.put("fail", "신고 승인 처리에 실패했습니다.");
                System.out.println("[신고 승인] 실패");
            }
            
        } catch (Exception e) {
            System.out.println("[신고 승인 에러] " + e.getMessage());
            e.printStackTrace();
            response.put("fail", "신고 승인 처리 중 오류가 발생했습니다.");
        }
        
        System.out.println("========================================");
        
        return response;
    }
}