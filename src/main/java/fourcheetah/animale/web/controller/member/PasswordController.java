package fourcheetah.animale.web.controller.member;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.member.MemberDAO;
import jakarta.servlet.http.HttpSession;

@Controller
public class PasswordController {

    private final MemberDAO memberDAO;

    // 프론트 정규식과 동일
    private static final String PASSWORD_REGEX =
            "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[!@#$%^&*()_+=-]).{8,16}$";

    public PasswordController(MemberDAO memberDAO) {
        this.memberDAO = memberDAO;
    }

    // 비밀번호 변경 페이지 진입 (404 해결)
    @GetMapping("/changepassword")
    public String changePasswordPage() {
        // JSP 파일명에 맞춰 수정하세요.
        return "changepassword";
    }

    // 기존 코드에서 쓰던 경로 호환 (redirect:/member/change-password-page)
    @GetMapping("/member/change-password-page")
    public String legacyPage() {
        return "redirect:/changepassword";
    }

    /**
     * POST /member/change-password 는 "여기 1개만" 남기세요.
     * - 로그인 상태면: 현재 비밀번호 검증 후 변경
     * - (선택) 비번찾기/재설정 흐름까지 여기서 처리하려면 아래 resetFlow 분기 사용
     */
    @PostMapping("/member/change-password")
    public String changePassword(
            @RequestParam(value = "currentPassword", required = false) String currentPassword,
            @RequestParam("newPassword") String newPassword,
            HttpSession session,
            RedirectAttributes ra
    ) {
        if (session == null) {
            ra.addFlashAttribute("msg", "로그인이 필요합니다.");
            return "redirect:/login";
        }

        String cur = (currentPassword == null) ? "" : currentPassword.trim();
        String nw  = (newPassword == null) ? "" : newPassword.trim();

        if (nw.isEmpty()) {
            ra.addFlashAttribute("msg", "새 비밀번호를 입력해주세요.");
            return "redirect:/changepassword";
        }

        if (!nw.matches(PASSWORD_REGEX)) {
            ra.addFlashAttribute("msg", "비밀번호 형식이 올바르지 않습니다. (8~16자, 영문/숫자/특수문자 포함)");
            return "redirect:/changepassword";
        }

        // ========== A) 로그인 상태 변경 ==========
        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId != null) {

            if (cur.isEmpty()) {
                ra.addFlashAttribute("msg", "현재 비밀번호를 입력해주세요.");
                return "redirect:/changepassword";
            }

            if (cur.equals(nw)) {
                ra.addFlashAttribute("msg", "현재 비밀번호와 다른 비밀번호를 입력해주세요.");
                return "redirect:/changepassword";
            }

            // 현재 비밀번호 DB 확인
            MemberDTO check = new MemberDTO();
            check.setCondition("MEMBER_PASSWORD_CHECK");
            check.setMemberId(memberId);
            check.setMemberPassword(cur);

            MemberDTO okUser = memberDAO.selectOne(check);
            if (okUser == null) {
                ra.addFlashAttribute("msg", "현재 비밀번호가 올바르지 않습니다.");
                return "redirect:/changepassword";
            }

            // 비밀번호 업데이트
            MemberDTO dto = new MemberDTO();
            dto.setCondition("MEMBER_PASSWORD_UPDATE");
            dto.setMemberId(memberId);
            dto.setMemberPassword(nw);

            boolean ok = memberDAO.update(dto);
            if (!ok) {
                ra.addFlashAttribute("msg", "비밀번호 변경에 실패했습니다.");
                return "redirect:/changepassword";
            }

            ra.addFlashAttribute("msg", "비밀번호가 변경되었습니다.");

            // 변경 후 이동(관리자/유저)
            String role = (String) session.getAttribute("memberRole");
            boolean isAdmin = role != null && role.toUpperCase().contains("ADMIN");
            return isAdmin ? "redirect:/admin" : "redirect:/member/mypage";
        }

        // ========== B) (선택) 비번찾기/재설정 흐름 ==========
        // change-password.jsp를 재설정 화면으로도 쓰는 경우만 필요합니다.
        Boolean verified = (Boolean) session.getAttribute("findPasswordVerified");
        Integer fpMemberId = (Integer) session.getAttribute("findPasswordMemberId");

        if (!Boolean.TRUE.equals(verified) || fpMemberId == null) {
            ra.addFlashAttribute("msg", "접근 권한이 없습니다. 다시 진행해주세요.");
            return "redirect:/login";
        }

        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_PASSWORD_UPDATE");
        dto.setMemberId(fpMemberId);
        dto.setMemberPassword(nw);

        boolean ok = memberDAO.update(dto);
        if (!ok) {
            ra.addFlashAttribute("msg", "비밀번호 재설정에 실패했습니다.");
            return "redirect:/login";
        }

        // 재설정 성공 시 세션 정리
        session.removeAttribute("findPasswordVerified");
        session.removeAttribute("findPasswordMemberId");
        session.removeAttribute("findPasswordExpireAt");
        session.removeAttribute("findPasswordEmail");
        session.removeAttribute("findPasswordCode");
        session.removeAttribute("pwResetCode");
        session.removeAttribute("pwResetExpireAt");

        ra.addFlashAttribute("msg", "비밀번호가 변경되었습니다. 로그인 해주세요.");
        return "redirect:/login";
    }
}
