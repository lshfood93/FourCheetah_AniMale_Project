package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.repository.member.WithdrawRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@Controller
public class WithdrawController {

    private final WithdrawRepository repo;

    public WithdrawController(WithdrawRepository repo) {
        this.repo = repo;
    }

    @PostMapping("/member/withdraw")
    public String withdraw(HttpServletRequest request, HttpSession session) {

        if (session == null || session.getAttribute("memberId") == null) {
            request.setAttribute("msg", "로그인 정보가 없습니다.");
            request.setAttribute("location", "/login");
            return "message";
        }

        int memberId = (Integer) session.getAttribute("memberId");

        boolean ok = repo.withdraw(memberId);

        if (ok) {
            session.invalidate();
            request.setAttribute("msg", "회원 탈퇴가 완료되었습니다. 이용해주셔서 감사합니다.");
            request.setAttribute("location", "/");
        } else {
            request.setAttribute("msg", "회원 탈퇴에 실패했습니다. 잠시 후 다시 시도해주세요.");
            request.setAttribute("location", "/mypage");
        }

        return "message";
    }
}
