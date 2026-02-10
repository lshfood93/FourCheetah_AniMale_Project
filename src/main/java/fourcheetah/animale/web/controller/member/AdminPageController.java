package fourcheetah.animale.web.controller.member;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.service.member.MemberService;
import jakarta.servlet.http.HttpSession;

@Controller
public class AdminPageController {

    @Autowired
    private MemberService memberService;

    @GetMapping("/adminPage")
    public String adminPage(HttpSession session, Model model) {

        // 1) 세션 유무/로그인 체크
        Integer memberId = (Integer) session.getAttribute("memberId");
        String memberRole = (String) session.getAttribute("memberRole");

        if (memberId == null) {
            model.addAttribute("msg", "로그인 정보가 없습니다.");
            model.addAttribute("location", "/login");

            return "message";
        }

        // 2) 관리자 권한 체크
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "접근 권한이 없습니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 3) DB 조회
        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_ADMINPAGE");
        dto.setMemberId(memberId);

        MemberDTO memberData = memberService.selectOne(dto);

        if (memberData == null) {
            model.addAttribute("msg", "회원 정보를 불러올 수 없습니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 4) 화면 이동
        model.addAttribute("memberData", memberData);
        return "adminpage";
    }
}
