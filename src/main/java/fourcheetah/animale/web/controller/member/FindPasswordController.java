package fourcheetah.animale.web.controller.member;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.member.MemberDAO;
import jakarta.servlet.http.HttpSession;


@RequestMapping("/api")
public class FindPasswordController {

    private final EmailServiceController emailService;
    private final MemberDAO memberDAO;

    public FindPasswordController(EmailServiceController emailService, MemberDAO memberDAO) {
        this.emailService = emailService;
        this.memberDAO = memberDAO;
    }

    // 1) 인증번호 발송
    @PostMapping("/findPasswordSendCode")
    public Map<String, Object> sendCode(@RequestBody Map<String, String> data, HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        String email = data.get("email");

        if (email == null || email.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "이메일을 입력해주세요.");
            return result;
        }
        email = email.trim();

        // 이메일 존재 확인 + memberId 확보
        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_EMAIL_CHECK");
        dto.setMemberEmail(email);

        MemberDTO exist = memberDAO.selectOne(dto);
        if (exist == null) {
            result.put("success", false);
            result.put("message", "가입된 이메일이 아닙니다.");
            return result;
        }

        // 6자리 코드
        String code = String.format("%06d", new Random().nextInt(1_000_000));

        // JSP가 보는 키로 통일
        session.setAttribute("findPasswordEmail", email);
        session.setAttribute("findPasswordCode", code);
        session.setAttribute("findPasswordExpireAt", System.currentTimeMillis() + 5 * 60 * 1000);
        session.setAttribute("findPasswordVerified", false);
        session.setAttribute("findPasswordMemberId", exist.getMemberId()); // 매우 중요

        try {
            emailService.sendPasswordResetCode(email, code);
            result.put("success", true);
            result.put("message", "인증번호가 발송되었습니다.");
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "메일 발송에 실패했습니다.");
        }
        return result;
    }

    // 2) 인증번호 검증
    @PostMapping("/findPasswordVerifyCode")
    public Map<String, Object> verifyCode(@RequestBody Map<String, String> data, HttpSession session) {
        Map<String, Object> res = new HashMap<>();
        String inputCode = data.get("code");

        String savedCode = (String) session.getAttribute("findPasswordCode");
        Long expireAt = (Long) session.getAttribute("findPasswordExpireAt");

        if (savedCode == null || expireAt == null) {
            res.put("success", false);
            res.put("message", "인증 요청부터 다시 진행해주세요.");
            return res;
        }
        if (System.currentTimeMillis() > expireAt) {
            session.setAttribute("findPasswordVerified", false);
            res.put("success", false);
            res.put("message", "인증 시간이 만료되었습니다. 다시 요청해주세요.");
            return res;
        }
        if (inputCode == null || !savedCode.equals(inputCode.trim())) {
            res.put("success", false);
            res.put("message", "인증번호가 올바르지 않습니다.");
            return res;
        }

        session.setAttribute("findPasswordVerified", true);
        res.put("success", true);
        res.put("message", "인증이 완료되었습니다.");
        return res;
    }
}
