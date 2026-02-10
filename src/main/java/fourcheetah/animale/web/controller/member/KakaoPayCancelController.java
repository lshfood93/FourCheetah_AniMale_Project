package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class KakaoPayCancelController {

    @GetMapping("/KakaoPayCancel")
    public String kakaoPayCancel(Model model) {

        System.out.println("[카카오페이 CANCEL 로그] 결제 취소 : 마이페이지 이동");

        // message.jsp 재활용: 메시지 + 이동 URL 전달
        model.addAttribute("msg", "결제가 취소되었습니다.");
        model.addAttribute("location", "/myPage"); // 기존 myPage.do -> 부트에선 /myPage 추천

        return "message"; // /WEB-INF/views/message.jsp
    }
}
