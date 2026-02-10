package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.member.MemberDAO;
import jakarta.servlet.http.HttpSession;

@Controller
public class MyPageController {

    private final MemberDAO memberDAO;

    public MyPageController(MemberDAO memberDAO) {
        this.memberDAO = memberDAO;
    }

    // 대소문자/예전 주소까지 전부 커버
    @GetMapping({"/mypage", "/myPage", "/member/mypage"})
    public String myPage(HttpSession session, Model model) {

        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId == null) return "redirect:/login";

        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_MYPAGE");
        dto.setMemberId(memberId);

        MemberDTO member = memberDAO.selectOne(dto);

        // JSP가 쓰는 이름으로 넣어주기
        model.addAttribute("memberData", member);

        return "mypage";
    }

}
