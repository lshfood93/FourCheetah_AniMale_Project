package fourcheetah.animale.web.controller.member;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;

/**
 * 이메일 인증 코드 확인
 */
@RestController
@RequestMapping("/api")
public class ConfirmEmailCodeController {

    @PostMapping("/confirmEmailCode")
    public Map<String, Object> confirmCode(@RequestBody Map<String, String> data, HttpSession session) {

        Map<String, Object> result = new HashMap<>();
        String inputCode = data.get("code");

        if (inputCode == null || inputCode.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "인증번호를 입력해주세요.");
            return result;
        }
        inputCode = inputCode.trim();

        String savedCode = (String) session.getAttribute("pwResetCode");
        Long expireAt = (Long) session.getAttribute("pwResetExpireAt");

        if (savedCode == null || expireAt == null) {
            result.put("success", false);
            result.put("message", "인증번호 발급부터 다시 진행해주세요.");
            return result;
        }

        if (System.currentTimeMillis() > expireAt) {
            result.put("success", false);
            result.put("message", "인증번호가 만료되었습니다. 다시 발급받아주세요.");
            return result;
        }

        if (!savedCode.equals(inputCode)) {
            result.put("success", false);
            result.put("message", "인증번호가 일치하지 않습니다.");
            return result;
        }

        // 여기서 "검증 완료" 세션 세팅 (너 ChangePasswordAction이 쓰는 키랑 맞추면 됨)
        session.setAttribute("findPasswordVerified", true);

        result.put("success", true);
        result.put("message", "OK");
        return result;
    }
}
