package fourcheetah.animale.web.controller.member;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.service.member.MemberService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@Controller
public class JoinController {

    @Autowired
    private MemberService memberService;

    private static final String SESSION_JOIN_EMAIL = "joinEmail";
    private static final String SESSION_JOIN_EMAIL_VERIFIED = "joinEmailVerified";
    private static final String SESSION_JOIN_EMAIL_CODE = "joinEmailCode";
    private static final String SESSION_JOIN_EMAIL_EXPIRE_AT = "joinEmailExpireAt";


    @GetMapping("/joinPage")
    public String joinPage() {
        return "join"; // /WEB-INF/views/join.jsp
    }
    
    @PostMapping("/join")
    public String join(MemberDTO memberDTO, HttpServletRequest request) {

        // 1) 파라미터(필수) 검증
        if (memberDTO == null
                || memberDTO.getMemberName() == null || memberDTO.getMemberName().trim().isEmpty()
                || memberDTO.getMemberNickname() == null || memberDTO.getMemberNickname().trim().isEmpty()
                || memberDTO.getMemberEmail() == null || memberDTO.getMemberEmail().trim().isEmpty()
                || memberDTO.getMemberPassword() == null || memberDTO.getMemberPassword().trim().isEmpty()) {

            return "redirect:/joinPage";
        }

        HttpSession session = request.getSession(); // 없으면 생성
        boolean joinEmailVerified = Boolean.TRUE.equals(session.getAttribute(SESSION_JOIN_EMAIL_VERIFIED));
        String verifiedEmail = (String) session.getAttribute(SESSION_JOIN_EMAIL);

        String formEmail = memberDTO.getMemberEmail().trim();

        // ★ 디버깅용: 지금 이 로그가 찍히면 "가입 요청이 서버까지는 도착"한 겁니다.
        System.out.println("[JOIN] verified=" + joinEmailVerified
                + ", verifiedEmail=" + verifiedEmail
                + ", formEmail=" + formEmail);

        // 2) 이메일 인증 검증
        if (!joinEmailVerified) {
            session.setAttribute("joinError", "EMAIL_NOT_VERIFIED");
            return "redirect:/joinPage";
        }

        if (verifiedEmail == null || !formEmail.equals(verifiedEmail)) {
            session.setAttribute("joinError", "EMAIL_MISMATCH");
            return "redirect:/joinPage";
        }

        // 3) 이메일 중복 최종 검증(DB)
        MemberDTO emailCheckDTO = new MemberDTO();
        emailCheckDTO.setCondition("MEMBER_EMAIL_CHECK");
        emailCheckDTO.setMemberEmail(formEmail);

        MemberDTO existEmail = memberService.selectOne(emailCheckDTO);
        if (existEmail != null) {
            session.setAttribute("joinError", "EMAIL_DUPLICATE");
            return "redirect:/joinPage";
        }

        // 4) 가입 insert
        MemberDTO joinDTO = new MemberDTO();
        joinDTO.setCondition("MEMBER_JOIN");
        joinDTO.setMemberName(memberDTO.getMemberName().trim());
        joinDTO.setMemberNickname(memberDTO.getMemberNickname().trim());
        joinDTO.setMemberEmail(formEmail);
        joinDTO.setMemberPassword(memberDTO.getMemberPassword().trim());
        joinDTO.setMemberProfileImage(null);

        try {
            boolean result = memberService.insert(joinDTO);

            if (result) {
                session.removeAttribute(SESSION_JOIN_EMAIL_VERIFIED);
                session.removeAttribute(SESSION_JOIN_EMAIL);
                session.removeAttribute(SESSION_JOIN_EMAIL_CODE);
                session.removeAttribute(SESSION_JOIN_EMAIL_EXPIRE_AT);
                session.removeAttribute("joinError");
                return "redirect:/login?joinSuccess=true";
            }

            session.setAttribute("joinError", "JOIN_FAIL");
            return "redirect:/joinPage";

        } catch (DataAccessException dae) {
            // UNIQUE 위반(아이디/닉네임/이메일) 같은 DB 오류가 여기로 옵니다.
            dae.printStackTrace();
            session.setAttribute("joinError", "JOIN_DB_ERROR");
            return "redirect:/joinPage";
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("joinError", "JOIN_ERROR");
            return "redirect:/joinPage";
        }
    }
}
