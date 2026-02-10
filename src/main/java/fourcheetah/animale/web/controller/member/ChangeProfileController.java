package fourcheetah.animale.web.controller.member;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.member.MemberDAO;
import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/member")
public class ChangeProfileController {

    private final MemberDAO memberDAO;

    // 업로드 경로 (application.properties에서 지정 권장)
    @Value("${app.upload.profile-temp-dir}")
    private String profileTempDir;

    @Value("${app.upload.profile-dir}")
    private String profileDir;

    public ChangeProfileController(MemberDAO memberDAO) {
        this.memberDAO = memberDAO;
    }

    @PostMapping("/profile")
    public String updateProfile(
            @RequestParam(required=false) String memberNickname,
            @RequestParam(required=false) String temporaryProfileImageToken,
            HttpSession session,
            Model model
    ) {

        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId == null) return "redirect:/login";

        // 관리자 여부
        String role = (String) session.getAttribute("memberRole");
        boolean isAdmin = role != null && role.toUpperCase().contains("ADMIN");

        // 1) 현재 내 정보 조회(기준값)
        MemberDTO curQ = new MemberDTO();
        curQ.setCondition("MEMBER_MYPAGE");
        curQ.setMemberId(memberId);
        MemberDTO cur = memberDAO.selectOne(curQ);
        if (cur == null) {
            session.setAttribute("msg", "회원 정보를 불러오지 못했습니다.");
            return "redirect:/member/mypage";
        }

        String newNick = (memberNickname == null) ? "" : memberNickname.trim();
        boolean nickChanged = !newNick.isEmpty() && !newNick.equals(cur.getMemberNickname());

        boolean profileChanged = (temporaryProfileImageToken != null && !temporaryProfileImageToken.trim().isEmpty());
        String token = profileChanged ? temporaryProfileImageToken.trim() : null;

        // 바뀐 게 없으면 종료
        if (!nickChanged && !profileChanged) {
            session.setAttribute("msg", "변경된 내용이 없습니다.");
            return "redirect:/member/mypage";
        }

        // 2) 닉네임 중복 서버 재검증(프론트 우회 방지)
        if (nickChanged) {
            MemberDTO dup = new MemberDTO();
            dup.setCondition("JOIN_NICKNAME");
            dup.setMemberNickname(newNick);

            MemberDTO found = memberDAO.selectOne(dup);
            if (found != null && found.getMemberId() != memberId) {
                session.setAttribute("msg", "이미 사용 중인 닉네임입니다.");
                return "redirect:/member/mypage";
            }
        }

        // 3) 프로필 토큰이 있으면 temp → final 이동 후 DB에 저장할 경로 만들기
        String finalProfilePathForDb = null; // 예: "/uploads/profile/xxxx.jpg"
        if (profileChanged) {
            try {
                Files.createDirectories(Paths.get(profileDir));

                Path tempFile = Paths.get(profileTempDir, token);
                if (!Files.exists(tempFile)) {
                    session.setAttribute("msg", "프로필 임시 파일이 없습니다. 다시 업로드해주세요.");
                    return "redirect:/member/mypage";
                }

                String finalName = token; // token 그대로 이동
                Path finalFile = Paths.get(profileDir, finalName);

                Files.move(tempFile, finalFile, StandardCopyOption.REPLACE_EXISTING);

                // 정적 매핑 URL
                finalProfilePathForDb = "/uploads/profile/" + finalName;

            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("msg", "프로필 파일 처리 중 오류가 발생했습니다.");
                return "redirect:/member/mypage";
            }
        }

        // 4) 비용 계산(관리자는 무료)
        int cost = 0;
        if (!isAdmin) {
            if (nickChanged) cost += 300;
            if (profileChanged) cost += 500;
        }

        // 5) DAO 업데이트 호출(조건 분기)
        MemberDTO upd = new MemberDTO();
        upd.setMemberId(memberId);
        upd.setMemberPayCash(cost);

        // 관리자면 캐시 조건 없는 전용 컨디션으로 태움
        if (isAdmin) {
            if (nickChanged && profileChanged) {
                upd.setCondition("ADMIN_MEMBER_INFORM_UPDATE");
                upd.setMemberNickname(newNick);
                upd.setMemberProfileImage(finalProfilePathForDb);
            } else if (nickChanged) {
                upd.setCondition("ADMIN_MEMBER_NICKNAME_UPDATE");
                upd.setMemberNickname(newNick);
            } else {
                upd.setCondition("ADMIN_MEMBER_PROFILE_UPDATE");
                upd.setMemberProfileImage(finalProfilePathForDb);
            }
        } else {
            if (nickChanged && profileChanged) {
                upd.setCondition("MEMBER_INFORM_UPDATE");
                upd.setMemberNickname(newNick);
                upd.setMemberProfileImage(finalProfilePathForDb);
            } else if (nickChanged) {
                upd.setCondition("MEMBER_NICKNAME_UPDATE");
                upd.setMemberNickname(newNick);
            } else {
                upd.setCondition("MEMBER_PROFILE_UPDATE");
                upd.setMemberProfileImage(finalProfilePathForDb);
            }
        }

        boolean ok = memberDAO.update(upd);
        if (!ok) {
            session.setAttribute("msg", isAdmin
                    ? "수정 실패(DB 반영 실패)."
                    : "수정 실패(캐시 부족 또는 DB 반영 실패).");
            return "redirect:/member/mypage";
        }

        // 6) 갱신값 재조회해서 세션 + 화면값 최신화
        MemberDTO after = memberDAO.selectOne(curQ);
        if (after != null) {
            session.setAttribute("memberNickName", after.getMemberNickname());
            session.setAttribute("memberProfileImage", after.getMemberProfileImage());
            session.setAttribute("memberCash", after.getMemberCash());
            if (after.getMemberRole() != null) session.setAttribute("memberRole", after.getMemberRole());
        }

        session.setAttribute("msg", "내 정보가 수정되었습니다.");
        return "redirect:/member/mypage";
    }
}
