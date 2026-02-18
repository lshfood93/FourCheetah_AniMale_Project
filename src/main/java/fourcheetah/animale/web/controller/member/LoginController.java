package fourcheetah.animale.web.controller.member;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.service.member.MemberService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@Controller
public class LoginController {

    @Autowired
    private MemberService memberService;

    // 겟요청 - 로그인 페이지 이동: /loginPage
    @GetMapping("/login")
    public String loginPage() {
        return "login"; // /WEB-INF/views/login.jsp
    }

    // 포스트요청 - 로그인 처리: /login
    @PostMapping("/login")
    public String login(
            MemberDTO memberDTO,
            @RequestParam(value = "autoLogin", required = false) String autoLogin,
            HttpServletRequest request,
            HttpServletResponse response,
            Model model
    ) {
        // 0) 이미 로그인 되어 있으면 세션 생성 X
        HttpSession existingSession = request.getSession(false);
        if (existingSession != null && existingSession.getAttribute("memberId") != null) {

            String role = (String) existingSession.getAttribute("memberRole");
            String goPage = "ADMIN".equals(role) ? "/adminPage" : "/myPage";

            model.addAttribute("msg", "이미 로그인되어 있습니다.");
            model.addAttribute("location", goPage);
            return "message"; // /WEB-INF/views/message.jsp
        }

        // 로그인 시도 → 세션 생성 OK
        HttpSession session = request.getSession(true);

        // 1) 로그인 조회
        memberDTO.setCondition("MEMBER_LOGIN");
        MemberDTO data = memberService.getMember(memberDTO);

        if (data != null) { // 성공
            // 2) 세션 저장
            session.setAttribute("memberId", data.getMemberId());
            session.setAttribute("memberName", data.getMemberName());
            session.setAttribute("memberNickName", data.getMemberNickname());
            session.setAttribute("memberRole", data.getMemberRole());
            session.setAttribute("memberProfileImage", data.getMemberProfileImage());
            session.setAttribute("memberEmail", data.getMemberEmail());

            // 3) 자동 로그인 쿠키
            if ("Y".equals(autoLogin)) {
                Cookie cookie = new Cookie("autoLogin", data.getMemberName());
                cookie.setMaxAge(60 * 60 * 24 * 7);
                cookie.setPath("/");
                cookie.setHttpOnly(true);
                // https면 권장
                // cookie.setSecure(true);
                response.addCookie(cookie);
            }

            // 4) 권한 분기
            String location = "ADMIN".equals(data.getMemberRole()) ? "/adminPage" : "/mainPage";

            model.addAttribute("msg", "로그인 성공!");
            model.addAttribute("location", location);
            return "message";

        } else { // 실패
            model.addAttribute("msg", "로그인 실패...");
            model.addAttribute("location", "/login");
            return "message";
        }
    }
}
