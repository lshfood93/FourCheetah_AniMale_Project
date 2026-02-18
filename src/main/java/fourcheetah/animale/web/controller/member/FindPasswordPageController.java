package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.member.MemberDAO;
import jakarta.servlet.http.HttpSession;

@Controller
public class FindPasswordPageController {

    private final MemberDAO memberDAO;

    // 프론트 정규식과 동일
    private static final String PASSWORD_REGEX =
            "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[!@#$%^&*()_+=-]).{8,16}$";

    public FindPasswordPageController(MemberDAO memberDAO) {
        this.memberDAO = memberDAO;
    }

    // (1) 비밀번호 찾기/재설정 페이지 진입 (404 해결)
    // 주소창: http://localhost:8088/findPasswordPage
    @GetMapping("/findPasswordPage")
    public String findPasswordPage() {
        // /WEB-INF/views/findpassword.jsp
        return "findpassword";
    }

    // (2) 비밀번호 재설정 처리 (findpassword.jsp 폼 action)
    @PostMapping("/member/password/find")
    public String resetPassword(
            @RequestParam("memberPassword") String memberPassword,
            HttpSession session,
            RedirectAttributes ra
    ) {
        Boolean verified = (Boolean) session.getAttribute("findPasswordVerified");
        Integer memberId = (Integer) session.getAttribute("findPasswordMemberId");
        Long expireAt = (Long) session.getAttribute("findPasswordExpireAt");

        if (!Boolean.TRUE.equals(verified) || memberId == null) {
            ra.addFlashAttribute("msg", "이메일 인증이 필요합니다.");
            return "redirect:/login";
        }
        if (expireAt == null || System.currentTimeMillis() > expireAt) {
            session.setAttribute("findPasswordVerified", false);
            ra.addFlashAttribute("msg", "인증 시간이 만료되었습니다. 다시 진행해주세요.");
            return "redirect:/findPasswordPage";
        }

        String pw = (memberPassword == null) ? "" : memberPassword.trim();
        if (!pw.matches(PASSWORD_REGEX)) {
            ra.addFlashAttribute("msg", "비밀번호 형식이 올바르지 않습니다. (8~16자, 영문/숫자/특수문자 포함)");
            return "redirect:/findPasswordPage";
        }

        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_PASSWORD_UPDATE");
        dto.setMemberId(memberId);
        dto.setMemberPassword(pw);

        boolean ok = memberDAO.update(dto);
        if (!ok) {
            ra.addFlashAttribute("msg", "비밀번호 변경에 실패했습니다.");
            return "redirect:/findPasswordPage";
        }

        // 성공 시 세션 정리
        session.removeAttribute("findPasswordVerified");
        session.removeAttribute("findPasswordMemberId");
        session.removeAttribute("findPasswordExpireAt");
        session.removeAttribute("findPasswordEmail");
        session.removeAttribute("findPasswordCode");
        // (EmailAuthController에서 pwResetCode/pwResetExpireAt 쓰면 그것도 지워주세요)
        session.removeAttribute("pwResetCode");
        session.removeAttribute("pwResetExpireAt");

        ra.addFlashAttribute("msg", "비밀번호가 변경되었습니다. 로그인 해주세요.");
        return "redirect:/login";
    }
}
