package fourcheetah.animale.web.controller.member;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.member.MemberDAO;
import jakarta.servlet.http.HttpSession;

@RestController
public class EmailAuthController {

    private final MemberDAO memberDAO;
    private final EmailServiceController emailService;

    public EmailAuthController(MemberDAO memberDAO, EmailServiceController emailService) {
        this.memberDAO = memberDAO;
        this.emailService = emailService;
    }

    // ===== JoinAction이 기대하는 세션 키 =====
    private static final String SESSION_JOIN_EMAIL            = "joinEmail";
    private static final String SESSION_JOIN_EMAIL_VERIFIED   = "joinEmailVerified";
    private static final String SESSION_JOIN_EMAIL_CODE       = "joinEmailCode";
    private static final String SESSION_JOIN_EMAIL_EXPIRE_AT  = "joinEmailExpireAt";

    // ===== 비번찾기(findpassword.jsp / change-password.jsp)가 쓰는 세션 키 =====
    private static final String SESSION_FINDPW_EMAIL          = "findPasswordEmail";
    private static final String SESSION_FINDPW_CODE           = "findPasswordCode";
    private static final String SESSION_FINDPW_EXPIRE_AT      = "findPasswordExpireAt";
    private static final String SESSION_FINDPW_VERIFIED       = "findPasswordVerified";
    private static final String SESSION_FINDPW_MEMBER_ID      = "findPasswordMemberId";

    private static final long EXPIRE_MS = 3 * 60 * 1000L; // 3분

    /**
     * findpassword.jsp: 아이디 확인 -> 이메일 자동 채우기용
     * POST /FindPasswordMemberLookup  (form-data)
     */
    @PostMapping("/FindPasswordMemberLookup")
    public Map<String, Object> findPwMemberLookup(
            @RequestParam("memberName") String memberName,
            HttpSession session
    ) {
        Map<String, Object> res = new HashMap<>();

        String name = (memberName == null) ? "" : memberName.trim();
        if (name.isEmpty()) {
            res.put("success", false);
            res.put("exists", false);
            res.put("message", "아이디를 입력해주세요.");
            return res;
        }

        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_ID_EMAIL");
        dto.setMemberName(name);

        MemberDTO found = memberDAO.selectOne(dto);

        if (found == null || found.getMemberEmail() == null) {
            res.put("success", true);
            res.put("exists", false);
            res.put("message", "존재하지 않는 아이디입니다.");
            return res;
        }

        // 비밀번호 재설정 플로우에서 필요
        session.setAttribute(SESSION_FINDPW_MEMBER_ID, found.getMemberId());
        session.setAttribute(SESSION_FINDPW_EMAIL, found.getMemberEmail());

        res.put("success", true);
        res.put("exists", true);
        res.put("memberEmail", found.getMemberEmail());
        res.put("message", "아이디가 확인되었습니다.");
        return res;
    }

    /**
     * join.jsp / findpassword.jsp 공용: 인증번호 발송
     *
     * join.jsp:      purpose=JOIN,  memberEmail=...
     * findpassword.jsp: purpose 없음, memberName=...
     *
     * POST /FindPasswordSendCode  (form-data)
     */
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
        Integer memberId = null;

        // ===== JOIN 플로우 =====
        if ("JOIN".equals(flow)) {

            String mail = (memberEmail == null) ? "" : memberEmail.trim();
            if (mail.isEmpty()) {
                res.put("success", false);
                res.put("message", "이메일을 입력해주세요.");
                return res;
            }
            email = mail;

            // JOIN은 이메일이 DB에 없어야 함
            MemberDTO check = new MemberDTO();
            check.setCondition("MEMBER_EMAIL_CHECK");
            check.setMemberEmail(email);

            MemberDTO exist = memberDAO.selectOne(check);
            if (exist != null) {
                res.put("success", false);
                res.put("message", "이미 사용 중인 이메일입니다.");
                return res;
            }

            // 세션 세팅
            String code = String.format("%06d", new Random().nextInt(1_000_000));
            long expireAt = System.currentTimeMillis() + EXPIRE_MS;

            session.setAttribute(SESSION_JOIN_EMAIL, email);
            session.setAttribute(SESSION_JOIN_EMAIL_CODE, code);
            session.setAttribute(SESSION_JOIN_EMAIL_EXPIRE_AT, expireAt);
            session.setAttribute(SESSION_JOIN_EMAIL_VERIFIED, false);

            try {
                // JOIN 전용 메서드가 있으면 그걸로 교체 권장
                // emailService.sendJoinEmailCode(email, code);
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

        // ===== FINDPW 플로우 =====
        String name = (memberName == null) ? "" : memberName.trim();
        if (name.isEmpty()) {
            res.put("success", false);
            res.put("message", "아이디를 입력해주세요.");
            return res;
        }

        MemberDTO find = new MemberDTO();
        find.setCondition("MEMBER_ID_EMAIL");
        find.setMemberName(name);

        MemberDTO found = memberDAO.selectOne(find);
        if (found == null || found.getMemberEmail() == null) {
            res.put("success", false);
            res.put("message", "가입된 아이디가 아닙니다.");
            return res;
        }

        email = found.getMemberEmail();
        memberId = found.getMemberId();

        String code = String.format("%06d", new Random().nextInt(1_000_000));
        long expireAt = System.currentTimeMillis() + EXPIRE_MS;

        // findpassword.jsp / change-password.jsp가 쓰는 키로 통일
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

    /**
     * join.jsp / findpassword.jsp 공용: 인증번호 확인
     *
     * join.jsp: purpose=JOIN, code=...
     * findpassword.jsp: purpose 없음, code=...
     *
     * POST /FindPasswordVerifyCode  (form-data)
     */
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
            expireAt  = (Long) session.getAttribute(SESSION_JOIN_EMAIL_EXPIRE_AT);
        } else {
            savedCode = (String) session.getAttribute(SESSION_FINDPW_CODE);
            expireAt  = (Long) session.getAttribute(SESSION_FINDPW_EXPIRE_AT);
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
}
