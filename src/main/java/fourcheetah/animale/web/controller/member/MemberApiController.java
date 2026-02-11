package fourcheetah.animale.web.controller.member;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.member.MemberDupCheckRepository;
import fourcheetah.animale.web.service.member.EmailService;
import fourcheetah.animale.web.service.member.MemberService;
import jakarta.servlet.http.HttpSession;

/**
 * 회원 API 컨트롤러 (비동기 AJAX 요청 처리)
 * 
 * 통합 이전:
 * - MemberDupCheckController
 * - MemberEmailCheckController
 * - EmailAuthController
 * - ConfirmEmailCodeController
 * - FindPasswordController
 * - FindPasswordMemberLookupController
 */
@RestController
public class MemberApiController {

    private final MemberService memberService;
    private final MemberDupCheckRepository dupCheckRepository;
    private final EmailService emailService;

    private static final String SESSION_JOIN_EMAIL = "joinEmail";
    private static final String SESSION_JOIN_EMAIL_VERIFIED = "joinEmailVerified";
    private static final String SESSION_JOIN_EMAIL_CODE = "joinEmailCode";
    private static final String SESSION_JOIN_EMAIL_EXPIRE_AT = "joinEmailExpireAt";

    private static final String SESSION_FINDPW_EMAIL = "findPasswordEmail";
    private static final String SESSION_FINDPW_CODE = "findPasswordCode";
    private static final String SESSION_FINDPW_EXPIRE_AT = "findPasswordExpireAt";
    private static final String SESSION_FINDPW_VERIFIED = "findPasswordVerified";
    private static final String SESSION_FINDPW_MEMBER_ID = "findPasswordMemberId";

    private static final long EXPIRE_MS = 3 * 60 * 1000L;

    public MemberApiController(
            MemberService memberService,
            MemberDupCheckRepository dupCheckRepository,
            EmailService emailService
    ) {
        this.memberService = memberService;
        this.dupCheckRepository = dupCheckRepository;
        this.emailService = emailService;
    }

    @PostMapping("/MemberNameCheck")
    public Map<String, Object> memberNameCheck(@RequestParam String memberName) {
        Map<String, Object> res = new HashMap<>();

        try {
            boolean exists = dupCheckRepository.existsByName(memberName.trim());
            res.put("success", true);
            res.put("available", !exists);
            res.put("message", exists ? "이미 사용 중인 아이디입니다." : "사용 가능한 아이디입니다.");
        } catch (Exception e) {
            res.put("success", false);
            res.put("available", false);
            res.put("message", "서버 오류");
        }

        return res;
    }

    @RequestMapping(value = "/MemberNickNameCheck", method = {RequestMethod.GET, RequestMethod.POST})
    public Map<String, Object> memberNicknameCheck(@RequestParam String memberNickname) {
        Map<String, Object> res = new HashMap<>();
        try {
            boolean exists = dupCheckRepository.existsByNickname(memberNickname.trim());
            res.put("success", true);
            res.put("available", !exists);
            res.put("message", exists ? "이미 사용 중인 닉네임입니다." : "사용 가능한 닉네임입니다.");
        } catch (Exception e) {
            res.put("success", false);
            res.put("available", false);
            res.put("message", "서버 오류");
        }
        return res;
    }

    @PostMapping("/MemberEmailCheck")
    public Map<String, Object> memberEmailCheck(@RequestParam String memberEmail) {
        Map<String, Object> res = new HashMap<>();

        try {
            boolean exists = dupCheckRepository.existsByEmail(memberEmail.trim());
            res.put("success", true);
            res.put("available", !exists);
            res.put("message", exists ? "이미 사용 중인 이메일입니다." : "사용 가능한 이메일입니다.");
        } catch (Exception e) {
            res.put("success", false);
            res.put("available", false);
            res.put("message", "서버 오류");
        }

        return res;
    }

    @PostMapping(value = "/FindPasswordMemberLookup", produces = "application/json; charset=UTF-8")
    public ResponseEntity<Map<String, Object>> findPasswordMemberLookup(MemberDTO dto) {

        Map<String, Object> result = new HashMap<>();

        String memberName = dto.getMemberName();
        if (memberName == null || memberName.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "아이디를 입력해주세요.");
            return ResponseEntity.badRequest().body(result);
        }

        memberName = memberName.trim();
        dto.setMemberName(memberName);
        dto.setCondition("MEMBER_ID_EMAIL");

        MemberDTO memberData = memberService.selectOne(dto);

        result.put("success", true);

        if (memberData == null) {
            result.put("exists", false);
            result.put("message", "존재하지 않는 아이디입니다.");
        } else {
            result.put("exists", true);
            result.put("memberId", memberData.getMemberId());
            result.put("memberEmail", memberData.getMemberEmail());
        }

        return ResponseEntity.ok(result);
    }

    @PostMapping("/FindPasswordSendCode")
    public Map<String, Object> sendCode(
            @RequestParam(value = "purpose", required = false) String purpose,
            @RequestParam(value = "memberEmail", required = false) String memberEmail,
            @RequestParam(value = "memberName", required = false) String memberName,
            HttpSession session
    ) {
        Map<String, Object> res = new HashMap<>();

        String flow = (purpose == null || purpose.trim().isEmpty())
                ? "FINDPW"
                : purpose.trim().toUpperCase();

        String email;

        if ("JOIN".equals(flow)) {

            String mail = (memberEmail == null) ? "" : memberEmail.trim();
            if (mail.isEmpty()) {
                res.put("success", false);
                res.put("message", "이메일을 입력해주세요.");
                return res;
            }
            email = mail;

            MemberDTO check = new MemberDTO();
            check.setCondition("MEMBER_EMAIL_CHECK");
            check.setMemberEmail(email);

            MemberDTO exist = memberService.selectOne(check);
            if (exist != null) {
                res.put("success", false);
                res.put("message", "이미 사용 중인 이메일입니다.");
                return res;
            }

            String code = String.format("%06d", new Random().nextInt(1_000_000));
            long expireAt = System.currentTimeMillis() + EXPIRE_MS;

            session.setAttribute(SESSION_JOIN_EMAIL, email);
            session.setAttribute(SESSION_JOIN_EMAIL_CODE, code);
            session.setAttribute(SESSION_JOIN_EMAIL_EXPIRE_AT, expireAt);
            session.setAttribute(SESSION_JOIN_EMAIL_VERIFIED, false);

            try {
                emailService.sendPasswordResetCode(email, code);

                res.put("success", true);
                res.put("message", "인증번호가 발송되었습니다.");
                res.put("expireSeconds", 180);
                return res;

            } catch (Exception e) {
                e.printStackTrace();
                res.put("success", false);
                res.put("message", "메일 발송에 실패했습니다.");
                return res;
            }
        }

        String name = (memberName == null) ? "" : memberName.trim();
        if (name.isEmpty()) {
            res.put("success", false);
            res.put("message", "아이디를 입력해주세요.");
            return res;
        }

        MemberDTO find = new MemberDTO();
        find.setCondition("MEMBER_ID_EMAIL");
        find.setMemberName(name);

        MemberDTO found = memberService.selectOne(find);
        if (found == null || found.getMemberEmail() == null) {
            res.put("success", false);
            res.put("message", "가입된 아이디가 아닙니다.");
            return res;
        }

        email = found.getMemberEmail();
        Integer memberId = found.getMemberId();

        String code = String.format("%06d", new Random().nextInt(1_000_000));
        long expireAt = System.currentTimeMillis() + EXPIRE_MS;

        session.setAttribute(SESSION_FINDPW_EMAIL, email);
        session.setAttribute(SESSION_FINDPW_CODE, code);
        session.setAttribute(SESSION_FINDPW_EXPIRE_AT, expireAt);
        session.setAttribute(SESSION_FINDPW_VERIFIED, false);
        session.setAttribute(SESSION_FINDPW_MEMBER_ID, memberId);

        try {
            emailService.sendPasswordResetCode(email, code);

            res.put("success", true);
            res.put("message", "인증번호가 발송되었습니다.");
            res.put("expireSeconds", 180);
            return res;

        } catch (Exception e) {
            e.printStackTrace();
            res.put("success", false);
            res.put("message", "메일 발송에 실패했습니다.");
            return res;
        }
    }

    @PostMapping("/FindPasswordVerifyCode")
    public Map<String, Object> verifyCode(
            @RequestParam(value = "purpose", required = false) String purpose,
            @RequestParam("code") String code,
            HttpSession session
    ) {
        Map<String, Object> res = new HashMap<>();

        String flow = (purpose == null || purpose.trim().isEmpty())
                ? "FINDPW"
                : purpose.trim().toUpperCase();

        String input = (code == null) ? "" : code.trim();
        if (input.isEmpty()) {
            res.put("success", false);
            res.put("message", "인증번호를 입력해주세요.");
            return res;
        }

        String savedCode;
        Long expireAt;

        if ("JOIN".equals(flow)) {
            savedCode = (String) session.getAttribute(SESSION_JOIN_EMAIL_CODE);
            expireAt = (Long) session.getAttribute(SESSION_JOIN_EMAIL_EXPIRE_AT);
        } else {
            savedCode = (String) session.getAttribute(SESSION_FINDPW_CODE);
            expireAt = (Long) session.getAttribute(SESSION_FINDPW_EXPIRE_AT);
        }

        if (savedCode == null || expireAt == null) {
            res.put("success", false);
            res.put("message", "인증번호 발급부터 다시 진행해주세요.");
            return res;
        }

        if (System.currentTimeMillis() > expireAt) {
            if ("JOIN".equals(flow)) {
                session.setAttribute(SESSION_JOIN_EMAIL_VERIFIED, false);
            } else {
                session.setAttribute(SESSION_FINDPW_VERIFIED, false);
            }
            res.put("success", false);
            res.put("message", "인증번호가 만료되었습니다. 다시 발급받아주세요.");
            return res;
        }

        if (!savedCode.equals(input)) {
            res.put("success", false);
            res.put("message", "인증번호가 일치하지 않습니다.");
            return res;
        }

        if ("JOIN".equals(flow)) {
            session.setAttribute(SESSION_JOIN_EMAIL_VERIFIED, true);
        } else {
            session.setAttribute(SESSION_FINDPW_VERIFIED, true);
        }

        res.put("success", true);
        res.put("message", "OK");
        return res;
    }

    @PostMapping("/api/memberEmailCheck")
    public Map<String, Object> apiMemberEmailCheck(@RequestBody Map<String, String> data) {

        Map<String, Object> result = new HashMap<>();

        String memberEmail = data.get("memberEmail");

        if (memberEmail == null || memberEmail.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "이메일을 입력해주세요.");
            return result;
        }

        memberEmail = memberEmail.trim();

        MemberDTO dto = new MemberDTO();
        dto.setMemberEmail(memberEmail);
        dto.setCondition("MEMBER_EMAIL_CHECK");

        MemberDTO exist = memberService.selectOne(dto);

        result.put("success", true);

        if (exist != null) {
            result.put("available", false);
            result.put("message", "이미 사용 중인 이메일입니다.");
        } else {
            result.put("available", true);
            result.put("message", "사용 가능한 이메일입니다.");
        }

        return result;
    }

    @PostMapping("/api/confirmEmailCode")
    public Map<String, Object> apiConfirmEmailCode(@RequestBody Map<String, String> data, HttpSession session) {

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

        session.setAttribute("findPasswordVerified", true);

        result.put("success", true);
        result.put("message", "OK");
        return result;
    }

    @PostMapping("/api/findPasswordSendCode")
    public Map<String, Object> apiFindPasswordSendCode(@RequestBody Map<String, String> data, HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        String email = data.get("email");

        if (email == null || email.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "이메일을 입력해주세요.");
            return result;
        }
        email = email.trim();

        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_EMAIL_CHECK");
        dto.setMemberEmail(email);

        MemberDTO exist = memberService.selectOne(dto);
        if (exist == null) {
            result.put("success", false);
            result.put("message", "가입된 이메일이 아닙니다.");
            return result;
        }

        String code = String.format("%06d", new Random().nextInt(1_000_000));

        session.setAttribute("findPasswordEmail", email);
        session.setAttribute("findPasswordCode", code);
        session.setAttribute("findPasswordExpireAt", System.currentTimeMillis() + 5 * 60 * 1000);
        session.setAttribute("findPasswordVerified", false);
        session.setAttribute("findPasswordMemberId", exist.getMemberId());

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

    @PostMapping("/api/findPasswordVerifyCode")
    public Map<String, Object> apiFindPasswordVerifyCode(@RequestBody Map<String, String> data, HttpSession session) {
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