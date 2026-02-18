package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class ChangePasswordPageController {

    @GetMapping("/changePasswordPage")
    public String changePasswordPage() {
        return "changepassword"; // /WEB-INF/views/changepassword.jsp
    }
}
