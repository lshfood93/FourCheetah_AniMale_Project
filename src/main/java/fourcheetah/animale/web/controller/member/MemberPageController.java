package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.service.member.MemberService;
import jakarta.servlet.http.HttpSession;

/**
 * 회원 페이지 컨트롤러
 * 
 * 통합 이전:
 * - MyPageController
 * - CashChargePageController
 */
@Controller
public class MemberPageController {

    private final MemberService memberService;

    public MemberPageController(MemberService memberService) {
        this.memberService = memberService;
    }

    @GetMapping({"/mypage", "/member/mypage"})
    public String myPage(HttpSession session, Model model) {

        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId == null) return "redirect:/login";

        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_MYPAGE");
        dto.setMemberId(memberId);

        MemberDTO member = memberService.selectOne(dto);

        model.addAttribute("memberData", member);

        return "mypage";
    }

    @GetMapping({"/cash/charge", "/cashcharge"})
    public String cashChargePage(HttpSession session) {
        if (session == null || session.getAttribute("memberId") == null) {
            return "redirect:/login";
        }
        return "cashcharge";
    }
}