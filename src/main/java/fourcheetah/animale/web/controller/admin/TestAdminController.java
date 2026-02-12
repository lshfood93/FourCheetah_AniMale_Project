package fourcheetah.animale.web.controller.admin;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/test")
public class TestAdminController {

    @GetMapping("/admin-login")
    public String adminLogin(HttpSession session) {
        session.setAttribute("memberId", 1);
        session.setAttribute("memberRole", "ADMIN");
        session.setAttribute("memberName", "관리자");
        session.setAttribute("memberNickname", "관리자");
        
        System.out.println("========================================");
        System.out.println("[테스트] 관리자 로그인 완료");
        System.out.println("  - memberId: 1");
        System.out.println("  - memberRole: ADMIN");
        System.out.println("========================================");
        
        return "redirect:/admin/reports";
    }
    
    @GetMapping("/logout")
    public String logout(HttpSession session) {
        session.invalidate();
        System.out.println("[테스트] 로그아웃 완료");
        return "redirect:/";
    }
}