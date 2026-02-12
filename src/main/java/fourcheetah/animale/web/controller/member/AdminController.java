package fourcheetah.animale.web.controller.member;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.service.member.MemberService;
import jakarta.servlet.http.HttpSession;

@Controller
public class AdminController {

    @Autowired
    private MemberService memberService;

    // 관리자 공통 체크
    private boolean checkAdmin(HttpSession session, Model model) {
        Integer memberId = (Integer) session.getAttribute("memberId");
        String memberRole = (String) session.getAttribute("memberRole");

        if (memberId == null) {
            model.addAttribute("msg", "로그인 정보가 없습니다.");
            model.addAttribute("location", "/login");
            return false;
        }

        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "접근 권한이 없습니다.");
            model.addAttribute("location", "/mainPage");
            return false;
        }

        return true;
    }

    @GetMapping("/adminPage")
    public String adminPage(HttpSession session, Model model) {

        // 1) 관리자 권한 체크
        if (!checkAdmin(session, model)) return "message";

        Integer memberId = (Integer) session.getAttribute("memberId");

        // 2) DB 조회
        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_ADMINPAGE");
        dto.setMemberId(memberId);

        MemberDTO memberData = memberService.selectOne(dto);

        if (memberData == null) {
            model.addAttribute("msg", "회원 정보를 불러올 수 없습니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 3) 화면 이동
        model.addAttribute("memberData", memberData);
        return "adminpage";
    }

    // 관리자 대시보드 페이지 이동
    @GetMapping("/admindashboard")
    public String admindashboard(HttpSession session, Model model) {
        if (!checkAdmin(session, model)) return "message";
        return "admindashboard";
    }

    // 신고 게시글 관리 페이지 이동
    @GetMapping("/adminreportboard")
    public String adminReportBoard(HttpSession session, Model model) {
        if (!checkAdmin(session, model)) return "message";
        return "adminreportboard";
    }
}
