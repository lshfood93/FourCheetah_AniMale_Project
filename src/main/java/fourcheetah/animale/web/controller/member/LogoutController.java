package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@Controller
public class LogoutController {

	@GetMapping("/logout")
    public String logout(HttpSession session, HttpServletResponse response, Model model) {

        // 1) 자동로그인 쿠키 삭제
        Cookie killAuto = new Cookie("autoLogin", "");
        killAuto.setMaxAge(0);
        killAuto.setPath("/");
        killAuto.setHttpOnly(true);
        response.addCookie(killAuto);

        // 2) 세션 종료
        if (session != null) {
            session.invalidate();
        }

        // 3) 메시지 페이지로 보낼 값
        model.addAttribute("msg", "로그아웃 성공!");
        model.addAttribute("location", "/mainPage"); // ctx는 jsp에서 붙일 것

        // 4) message.jsp로 이동
        return "redirect:/mainPage";
    }
}