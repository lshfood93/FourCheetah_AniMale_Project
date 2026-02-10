package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class KakaoPayFailController {

    @GetMapping("/KakaoPayFail")
    public String kakaoPayFail(Model model) {

        System.out.println("[카카오페이 FAIL 로그] 결제 실패 : 완료페이지 이동");

        // cashresult.jsp에서 성공/실패 판별용
        model.addAttribute("payResult", "FAIL");

        return "cashresult"; // /WEB-INF/views/cashresult.jsp (forward)
    }
}
