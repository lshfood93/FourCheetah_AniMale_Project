package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import jakarta.servlet.http.HttpSession;

@Controller
public class CashChargePageController {

    @GetMapping({"/cash/charge", "/cashcharge"})
    public String cashChargePage(HttpSession session) {
        if (session == null || session.getAttribute("memberId") == null) {
            return "redirect:/login";
        }
        return "cashcharge"; // /WEB-INF/views/cashcharge.jsp
    }
}
