package fourcheetah.animale.web.controller.member;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.dto.member.MemberWarningDTO;
import fourcheetah.animale.web.repository.member.WithdrawRepository;
import fourcheetah.animale.web.service.member.MemberService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * 회원 컨트롤러 (로그인/가입/프로필/비밀번호/탈퇴)
 *
 * 통합 이전:
 * - LoginController
 * - LogoutController
 * - JoinController
 * - ChangeProfileController
 * - PasswordController
 * - WithdrawController
 * - FindPasswordPageController
 */
@Controller
public class MemberController {

    private final MemberService memberService;
    private final WithdrawRepository withdrawRepository;

    @Value("${app.upload.profile-temp-dir}")
    private String profileTempDir;

    @Value("${app.upload.profile-dir}")
    private String profileDir;

    private static final String SESSION_JOIN_EMAIL = "joinEmail";
    private static final String SESSION_JOIN_EMAIL_VERIFIED = "joinEmailVerified";
    private static final String SESSION_JOIN_EMAIL_CODE = "joinEmailCode";
    private static final String SESSION_JOIN_EMAIL_EXPIRE_AT = "joinEmailExpireAt";

    private static final String PASSWORD_REGEX = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[!@#$%^&*()_+=-]).{8,16}$";

    // 제재 날짜 포맷터
    private static final DateTimeFormatter SANCTION_DATE_FORMATTER =
        DateTimeFormatter.ofPattern("yyyy년 MM월 dd일 HH시 mm분");

    public MemberController(
            MemberService memberService,
            WithdrawRepository withdrawRepository
    ) {
        this.memberService = memberService;
        this.withdrawRepository = withdrawRepository;
    }

    // ==================== 로그인 ====================

    @GetMapping("/login")
    public String loginPage() {
        return "login";
    }

    @PostMapping("/login")
    public String login(
            MemberDTO memberDTO,
            @RequestParam(value = "autoLogin", required = false) String autoLogin,
            HttpServletRequest request,
            HttpServletResponse response,
            Model model
    ) {
        HttpSession existingSession = request.getSession(false);
        if (existingSession != null && existingSession.getAttribute("memberId") != null) {
            String role = (String) existingSession.getAttribute("memberRole");
            String goPage = "ADMIN".equals(role) ? "/adminPage" : "/myPage";
            model.addAttribute("msg", "이미 로그인되어 있습니다.");
            model.addAttribute("location", goPage);
            return "message";
        }

        HttpSession session = request.getSession(true);

        memberDTO.setCondition("MEMBER_LOGIN");
        MemberDTO data = memberService.selectOne(memberDTO);

        if (data != null) {
            session.setAttribute("memberId", data.getMemberId());
            session.setAttribute("memberName", data.getMemberName());
            session.setAttribute("memberNickName", data.getMemberNickname());
            session.setAttribute("memberRole", data.getMemberRole());
            session.setAttribute("memberProfileImage", data.getMemberProfileImage());
            session.setAttribute("memberEmail", data.getMemberEmail());

            // 제재 정보 조회 (member_warning 테이블에서)
            MemberWarningDTO warningInfo = memberService.selectActiveWarning(data.getMemberId());

            if (warningInfo != null) {
                String warningType = warningInfo.getWarningType();

                System.out.println("[로그인] 제재 정보 발견: " + warningType);

                // BAN (영구정지) → 로그인 차단
                if ("BAN".equals(warningType)) {
                    session.invalidate();
                    model.addAttribute("msg", "영구 정지된 계정입니다. 관리자에게 문의하세요.");
                    model.addAttribute("location", "/login");
                    return "message";
                }

                // SUSPEND_7D / SUSPEND_30D (기간 정지 - 누적 3회: 7일, 5회: 30일)
                if ("SUSPEND_7D".equals(warningType) || "SUSPEND_30D".equals(warningType)) {
                    session.setAttribute("memberStatus", warningType);
                    session.setAttribute("showSanctionModal", true);
                    session.setAttribute("sanctionType", warningType);

                    // 날짜 포맷팅: ISO → 한국어 형식
                    String endAtStr = warningInfo.getEndAt() == null ?
                                     "미정" :
                                     warningInfo.getEndAt().format(SANCTION_DATE_FORMATTER);

                    session.setAttribute("sanctionEndAt", endAtStr);
                    session.setAttribute("sanctionReason", warningInfo.getReason());

                    System.out.println("[로그인] 정지 상태 - 제재 모달 표시");
                }

                // WARNING (경고 1, 2, 4회 - 기능 제한 없음, 안내만 표시)
                if ("WARNING".equals(warningType)) {
                    session.setAttribute("memberStatus", "WARNING");
                    session.setAttribute("showSanctionModal", true);
                    session.setAttribute("sanctionType", "WARNING");
                    session.setAttribute("sanctionEndAt", "해당 없음");
                    session.setAttribute("sanctionReason", warningInfo.getReason());

                    System.out.println("[로그인] 경고 상태 - 제재 모달 표시");
                }

            } else {
                // 제재 없음 = 정상
                session.setAttribute("memberStatus", "ACTIVE");
                System.out.println("[로그인] 정상 계정");
            }

            if ("Y".equals(autoLogin)) {
                Cookie cookie = new Cookie("autoLogin", data.getMemberName());
                cookie.setMaxAge(60 * 60 * 24 * 7);
                cookie.setPath("/");
                cookie.setHttpOnly(true);
                response.addCookie(cookie);
            }

            String location = "ADMIN".equals(data.getMemberRole()) ? "/admindashboard" : "/mainPage";

            model.addAttribute("msg", "로그인 성공!");
            model.addAttribute("location", location);
            return "message";

        } else {
            model.addAttribute("msg", "로그인 실패...");
            model.addAttribute("location", "/login");
            return "message";
        }
    }

    // ==================== 로그아웃 ====================

    @GetMapping("/logout")
    public String logout(HttpSession session, HttpServletResponse response, Model model) {

        Cookie killAuto = new Cookie("autoLogin", "");
        killAuto.setMaxAge(0);
        killAuto.setPath("/");
        killAuto.setHttpOnly(true);
        response.addCookie(killAuto);

        if (session != null) {
            session.invalidate();
        }

        model.addAttribute("msg", "로그아웃 성공!");
        model.addAttribute("location", "/mainPage");

        return "redirect:/mainPage";
    }

    /**
     * 제재 모달 닫기 (세션 플래그 제거)
     */
    @PostMapping("/member/clearSanctionModal")
    @ResponseBody
    public Map<String, Object> clearSanctionModal(HttpSession session) {
        System.out.println("[MemberController] 제재 모달 플래그 제거");

        if (session != null) {
            session.removeAttribute("showSanctionModal");
            session.removeAttribute("sanctionType");
        }

        Map<String, Object> response = new HashMap<>();
        response.put("result", "OK");

        return response;
    }

    // ==================== 회원가입 ====================

    @GetMapping("/joinPage")
    public String joinPage() {
        return "join";
    }

    @PostMapping("/join")
    public String join(MemberDTO memberDTO, HttpServletRequest request) {

        if (memberDTO == null
                || memberDTO.getMemberName() == null || memberDTO.getMemberName().trim().isEmpty()
                || memberDTO.getMemberNickname() == null || memberDTO.getMemberNickname().trim().isEmpty()
                || memberDTO.getMemberEmail() == null || memberDTO.getMemberEmail().trim().isEmpty()
                || memberDTO.getMemberPassword() == null || memberDTO.getMemberPassword().trim().isEmpty()) {

            return "redirect:/joinPage";
        }

        HttpSession session = request.getSession();
        boolean joinEmailVerified = Boolean.TRUE.equals(session.getAttribute(SESSION_JOIN_EMAIL_VERIFIED));
        String verifiedEmail = (String) session.getAttribute(SESSION_JOIN_EMAIL);

        String formEmail = memberDTO.getMemberEmail().trim();

        System.out.println("[JOIN] verified=" + joinEmailVerified
                + ", verifiedEmail=" + verifiedEmail
                + ", formEmail=" + formEmail);

        if (!joinEmailVerified) {
            session.setAttribute("joinError", "EMAIL_NOT_VERIFIED");
            return "redirect:/joinPage";
        }

        if (verifiedEmail == null || !formEmail.equals(verifiedEmail)) {
            session.setAttribute("joinError", "EMAIL_MISMATCH");
            return "redirect:/joinPage";
        }

        MemberDTO emailCheckDTO = new MemberDTO();
        emailCheckDTO.setCondition("MEMBER_EMAIL_CHECK");
        emailCheckDTO.setMemberEmail(formEmail);

        MemberDTO existEmail = memberService.selectOne(emailCheckDTO);
        if (existEmail != null) {
            session.setAttribute("joinError", "EMAIL_DUPLICATE");
            return "redirect:/joinPage";
        }

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

        } catch (DataAccessException e) {
            System.out.println("JOIN ERR: " + e.getMessage());
            session.setAttribute("joinError", "JOIN_FAIL");
            return "redirect:/joinPage";
        }
    }

    // ==================== 마이페이지 ====================

    @GetMapping("/myPage")
    public String myPage(HttpSession session, Model model) {
        if (session == null || session.getAttribute("memberId") == null) {
            return "redirect:/login";
        }

        Integer memberId = (Integer) session.getAttribute("memberId");

        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_MYPAGE");
        dto.setMemberId(memberId);

        MemberDTO member = memberService.selectOne(dto);

        model.addAttribute("memberData", member);

        return "mypage";
    }

    // ==================== 프로필 변경 ====================

    @GetMapping("/changeProfilePage")
    public String changeProfilePage(HttpSession session) {
        if (session == null || session.getAttribute("memberId") == null) {
            return "redirect:/login";
        }
        return "changeprofile";
    }

    @GetMapping("/member/change-profile-page")
    public String legacyChangeProfile() {
        return "redirect:/changeprofile";
    }

    @PostMapping("/member/profile")
    public String changeProfile(
            @RequestParam(value = "memberNickname", required = false) String memberNickname,
            @RequestParam(value = "memberProfileImage", required = false) String newProfileImage,
            @RequestParam(value = "temporaryProfileImageToken", required = false) String temporaryProfileImageToken,
            @RequestParam(value = "memberProfileColor", required = false) String memberProfileColor,
            @RequestParam(value = "memberNicknameColor", required = false) String memberNicknameColor,
            HttpSession session
    ) {
        if (session == null || session.getAttribute("memberId") == null) {
            return "redirect:/login";
        }

        Integer memberId = (Integer) session.getAttribute("memberId");

        String role = (String) session.getAttribute("memberRole");
        boolean isAdmin = "ADMIN".equals(role);

        String backPage = isAdmin ? "redirect:/adminPage" : "redirect:/mypage";

        String newNick = trimToNull(memberNickname);
        String reqProfileColor = trimToNull(memberProfileColor);
        String reqNicknameColor = trimToNull(memberNicknameColor);
        String token = trimToNull(temporaryProfileImageToken);

        if (reqProfileColor != null && !isValidHexColor(reqProfileColor)) {
            session.setAttribute("msg", "프로필 테두리 색상 값이 올바르지 않습니다. (#RRGGBB)");
            return backPage;
        }
        if (reqNicknameColor != null && !isValidHexColor(reqNicknameColor)) {
            session.setAttribute("msg", "닉네임 색상 값이 올바르지 않습니다. (#RRGGBB)");
            return backPage;
        }

        MemberDTO curQ = new MemberDTO();
        curQ.setCondition("MEMBER_MYPAGE");
        curQ.setMemberId(memberId);

        MemberDTO cur = memberService.selectOne(curQ);
        if (cur == null) {
            session.setAttribute("msg", "회원 정보를 불러오지 못했습니다.");
            return backPage;
        }

        boolean nickChanged = (newNick != null && !newNick.equals(cur.getMemberNickname()));
        boolean imgChanged = (token != null && !token.equals(cur.getMemberProfileImage()));
        boolean profileColorChanged = (reqProfileColor != null &&
                (cur.getMemberProfileColor() == null || !reqProfileColor.equals(cur.getMemberProfileColor())));
        boolean nicknameColorChanged = (reqNicknameColor != null &&
                (cur.getMemberNicknameColor() == null || !reqNicknameColor.equals(cur.getMemberNicknameColor())));

        if (!nickChanged && !imgChanged && !profileColorChanged && !nicknameColorChanged) {
            session.setAttribute("msg", "변경된 내용이 없습니다.");
            return backPage;
        }

        final int NICK_COST = 300;
        final int IMG_COST = 500;
        final int BORDER_COLOR_COST = 200;
        final int NICK_COLOR_COST = 200;

        int needCash = 0;
        if (!isAdmin) {
            needCash += (nickChanged ? NICK_COST : 0);
            needCash += (imgChanged ? IMG_COST : 0);
            needCash += (profileColorChanged ? BORDER_COLOR_COST : 0);
            needCash += (nicknameColorChanged ? NICK_COLOR_COST : 0);

            if (cur.getMemberCash() < needCash) {
                session.setAttribute("msg", "캐시가 부족합니다. (필요: " + needCash + ")");
                return backPage;
            }
        }

        if (nickChanged) {
            MemberDTO dup = new MemberDTO();
            dup.setCondition("JOIN_NICKNAME");
            dup.setMemberNickname(newNick);

            MemberDTO found = memberService.selectOne(dup);

            if (found != null && found.getMemberId() != memberId.intValue()) {
                session.setAttribute("msg", "이미 사용 중인 닉네임입니다.");
                return backPage;
            }
        }

        if (imgChanged) {
            try {
                Path tempFile = Paths.get(profileTempDir, token);
                if (!Files.exists(tempFile)) {
                    session.setAttribute("msg", "프로필 임시 파일이 없습니다. 다시 업로드해주세요.");
                    return backPage;
                }

                Path targetFile = Paths.get(profileDir, token);
                Files.createDirectories(targetFile.getParent());
                Files.move(tempFile, targetFile, StandardCopyOption.REPLACE_EXISTING);

            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("msg", "프로필 파일 처리 중 오류가 발생했습니다.");
                return backPage;
            }
        }

        MemberDTO up = new MemberDTO();
        up.setMemberId(memberId);
        up.setCondition(isAdmin ? "ADMIN_MEMBER_INFORM_UPDATE" : "MEMBER_INFORM_UPDATE");

        up.setMemberNickname(nickChanged ? newNick : null);
        up.setMemberProfileImage(imgChanged ? "/uploads/profile/" + token : null);
        up.setMemberProfileColor(profileColorChanged ? reqProfileColor : null);
        up.setMemberNicknameColor(nicknameColorChanged ? reqNicknameColor : null);

        if (!isAdmin) {
            up.setMemberPayCash(needCash);
        }

        boolean ok = memberService.update(up);
        if (!ok) {
            session.setAttribute("msg", isAdmin
                    ? "수정 실패(DB 반영 실패)."
                    : "수정 실패(캐시 부족 또는 DB 반영 실패).");
            return backPage;
        }

        MemberDTO after = memberService.selectOne(curQ);
        if (after != null) {
            session.setAttribute("memberNickName", after.getMemberNickname());
            session.setAttribute("memberProfileImage", after.getMemberProfileImage());
            session.setAttribute("memberCash", after.getMemberCash());
            session.setAttribute("memberProfileColor", after.getMemberProfileColor());
            session.setAttribute("memberNicknameColor", after.getMemberNicknameColor());
            if (after.getMemberRole() != null) {
                session.setAttribute("memberRole", after.getMemberRole());
            }
        }

        session.setAttribute("msg", "내 정보가 수정되었습니다.");
        return backPage;
    }

    private String trimToNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    private boolean isValidHexColor(String color) {
        return color != null && color.matches("^#([0-9a-fA-F]{6})$");
    }

    // ==================== 비밀번호 변경 ====================

    @GetMapping("/changePasswordPage")
    public String changePasswordPage() {
        return "changepassword";
    }

    @GetMapping("/member/change-password-page")
    public String legacyPasswordPage() {
        return "redirect:/changepassword";
    }

    @PostMapping("/member/change-password")
    public String changePassword(
            @RequestParam(value = "currentPassword", required = false) String currentPassword,
            @RequestParam("newPassword") String newPassword,
            HttpSession session,
            HttpServletResponse response,
            RedirectAttributes ra
    ) {
        if (session == null) {
            ra.addFlashAttribute("msg", "로그인이 필요합니다.");
            return "redirect:/login";
        }

        String cur = (currentPassword == null) ? "" : currentPassword.trim();
        String nw = (newPassword == null) ? "" : newPassword.trim();

        if (nw.isEmpty()) {
            ra.addFlashAttribute("msg", "새 비밀번호를 입력해주세요.");
            return "redirect:/changepassword";
        }

        if (!nw.matches(PASSWORD_REGEX)) {
            ra.addFlashAttribute("msg", "비밀번호 형식이 올바르지 않습니다. (8~16자, 영문/숫자/특수문자 포함)");
            return "redirect:/changepassword";
        }

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

            MemberDTO check = new MemberDTO();
            check.setCondition("MEMBER_PASSWORD_CHECK");
            check.setMemberId(memberId);
            check.setMemberPassword(cur);

            MemberDTO okUser = memberService.selectOne(check);
            if (okUser == null) {
                ra.addFlashAttribute("msg", "현재 비밀번호가 올바르지 않습니다.");
                return "redirect:/changepassword";
            }

            MemberDTO dto = new MemberDTO();
            dto.setCondition("MEMBER_PASSWORD_UPDATE");
            dto.setMemberId(memberId);
            dto.setMemberPassword(nw);

            boolean ok = memberService.update(dto);
            if (!ok) {
                ra.addFlashAttribute("msg", "비밀번호 변경에 실패했습니다.");
                return "redirect:/changepassword";
            }

            Cookie killAuto = new Cookie("autoLogin", "");
            killAuto.setMaxAge(0);
            killAuto.setPath("/");
            killAuto.setHttpOnly(true);
            response.addCookie(killAuto);

            session.invalidate();

            ra.addAttribute("pwChanged", "true");
            return "redirect:/login";
        }

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

        boolean ok = memberService.update(dto);
        if (!ok) {
            ra.addFlashAttribute("msg", "비밀번호 재설정에 실패했습니다.");
            return "redirect:/login";
        }

        session.removeAttribute("findPasswordVerified");
        session.removeAttribute("findPasswordMemberId");
        session.removeAttribute("findPasswordExpireAt");
        session.removeAttribute("findPasswordEmail");
        session.removeAttribute("findPasswordCode");
        session.removeAttribute("pwResetCode");
        session.removeAttribute("pwResetExpireAt");

        ra.addAttribute("pwChanged", "true");
        return "redirect:/login";
    }

    // ==================== 비밀번호 찾기 ====================

    @GetMapping("/findPasswordPage")
    public String findPasswordPage() {
        return "findpassword";
    }

    @PostMapping("/member/password/find")
    public String resetPassword(
            @RequestParam("memberPassword") String memberPassword,
            HttpSession session,
            RedirectAttributes ra
    ) {
        Boolean verified = (Boolean) session.getAttribute("findPasswordVerified");
        Integer memberId = (Integer) session.getAttribute("findPasswordMemberId");
        Long expireAt = (Long) session.getAttribute("findPasswordExpireAt");

        if (!Boolean.TRUE.equals(verified) || memberId == null) {
            ra.addFlashAttribute("msg", "이메일 인증이 필요합니다.");
            return "redirect:/login";
        }
        if (expireAt == null || System.currentTimeMillis() > expireAt) {
            session.setAttribute("findPasswordVerified", false);
            ra.addFlashAttribute("msg", "인증 시간이 만료되었습니다. 다시 진행해주세요.");
            return "redirect:/findPasswordPage";
        }

        String pw = (memberPassword == null) ? "" : memberPassword.trim();
        if (!pw.matches(PASSWORD_REGEX)) {
            ra.addFlashAttribute("msg", "비밀번호 형식이 올바르지 않습니다. (8~16자, 영문/숫자/특수문자 포함)");
            return "redirect:/findPasswordPage";
        }

        MemberDTO dto = new MemberDTO();
        dto.setCondition("MEMBER_PASSWORD_UPDATE");
        dto.setMemberId(memberId);
        dto.setMemberPassword(pw);

        boolean ok = memberService.update(dto);
        if (!ok) {
            ra.addFlashAttribute("msg", "비밀번호 변경에 실패했습니다.");
            return "redirect:/findPasswordPage";
        }

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

    // ==================== 회원 탈퇴 ====================

    @PostMapping("/member/withdraw")
    public String withdraw(HttpServletRequest request, HttpSession session) {

        if (session == null || session.getAttribute("memberId") == null) {
            request.setAttribute("msg", "로그인 정보가 없습니다.");
            request.setAttribute("location", "/login");
            return "message";
        }

        int memberId = (Integer) session.getAttribute("memberId");

        boolean ok = withdrawRepository.withdraw(memberId);

        if (ok) {
            session.invalidate();
            request.setAttribute("msg", "회원 탈퇴가 완료되었습니다. 이용해주셔서 감사합니다.");
            request.setAttribute("location", "/");
        } else {
            request.setAttribute("msg", "회원 탈퇴에 실패했습니다. 잠시 후 다시 시도해주세요.");
            request.setAttribute("location", "/mypage");
        }

        return "message";
    }
}