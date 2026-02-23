package fourcheetah.animale.web.repository.member;

import java.util.List;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.dto.member.MemberWarningDTO;
import fourcheetah.animale.web.service.member.MemberService;

@Service
public class MemberServiceImpl implements MemberService {

    // 생성자 주입 + PasswordEncoder 주입
    private final MemberDAO memberDAO;
    private final PasswordEncoder passwordEncoder;

    public MemberServiceImpl(MemberDAO memberDAO, PasswordEncoder passwordEncoder) {
        this.memberDAO = memberDAO;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public List<MemberDTO> selectAll(MemberDTO dto) {
        return memberDAO.selectAll(dto);
    }

    @Override
    public MemberDTO selectOne(MemberDTO dto) {
        if (dto == null) {
            return null;
        }

        String condition = dto.getCondition();

        // 로그인 / 현재비밀번호확인만 서비스에서 비밀번호 검증 처리
        if ("MEMBER_LOGIN".equals(condition) || "MEMBER_PASSWORD_CHECK".equals(condition)) {
            String rawPassword = dto.getMemberPassword();

            // null/공백 방어
            if (rawPassword == null || rawPassword.trim().isEmpty()) {
                return null;
            }

            // DAO는 이제 사용자 조회만 수행 (비밀번호 비교 안 함)
            MemberDTO target = memberDAO.selectOne(dto);
            if (target == null) {
                return null;
            }

            // 저장된 비밀번호(해시 또는 기존 평문)
            String savedPassword = target.getMemberPassword();

            // 해시 비교(matches) + 임시 평문 fallback
            boolean matched = isPasswordMatched(rawPassword, savedPassword);
            if (!matched) {
                return null;
            }

            return target;
        }

        // 그 외 조건은 기존처럼 DAO 위임
        return memberDAO.selectOne(dto);
    }

    /**
     * 활성 제재 조회 (로그인 시 사용)
     */
    @Override
    public MemberWarningDTO selectActiveWarning(int memberId) {
        System.out.println("[MemberService] selectActiveWarning 호출 - memberId=" + memberId);

        MemberWarningDTO warning = memberDAO.selectActiveWarning(memberId);

        if (warning != null) {
            System.out.println("[MemberService] 제재 정보 발견 - warningType=" + warning.getWarningType());
        } else {
            System.out.println("[MemberService] 제재 없음 (정상 회원)");
        }

        return warning;
    }

    @Override
    public boolean insert(MemberDTO dto) {
        // 회원가입(MEMBER_JOIN)일 때만 비밀번호 해시 처리
        if (dto != null && "MEMBER_JOIN".equals(dto.getCondition())) {
            String rawPassword = dto.getMemberPassword();

            if (rawPassword != null && !rawPassword.trim().isEmpty()) {
                // 이중 해시 방지
                if (!isBcryptHash(rawPassword)) {
                    dto.setMemberPassword(passwordEncoder.encode(rawPassword));
                }
            }
        }

        return memberDAO.insert(dto);
    }

    @Override
    public boolean update(MemberDTO dto) {
        // 비밀번호 변경/재설정(MEMBER_PASSWORD_UPDATE)일 때만 해시 처리
        if (dto != null && "MEMBER_PASSWORD_UPDATE".equals(dto.getCondition())) {
            String rawPassword = dto.getMemberPassword();

            if (rawPassword != null && !rawPassword.trim().isEmpty()) {
                // 이중 해시 방지
                if (!isBcryptHash(rawPassword)) {
                    dto.setMemberPassword(passwordEncoder.encode(rawPassword));
                }
            }
        }

        return memberDAO.update(dto);
    }

    @Override
    public boolean delete(MemberDTO dto) {
        return memberDAO.delete(dto);
    }

    /**
     * CHANGED: 비밀번호 일치 여부 판단
     *
     * 정책:
     * 1) 저장값이 bcrypt 해시면 matches(raw, encoded)
     * 2) 저장값이 구 평문이면 raw.equals(saved) (임시 호환)
     *
     * ※ 나중에 전체 회원 비밀번호를 해시로 전환 완료하면
     *    평문 fallback(raw.equals(saved))는 제거 권장
     */
    private boolean isPasswordMatched(String rawPassword, String savedPassword) {
        if (rawPassword == null || savedPassword == null) {
            return false;
        }

        // bcrypt 해시면 정식 비교
        if (isBcryptHash(savedPassword)) {
            try {
                return passwordEncoder.matches(rawPassword, savedPassword);
            } catch (Exception e) {
                // 저장값 형식 이상 등 예외 방어
                System.out.println("[MemberService] password matches() error: " + e.getMessage());
                return false;
            }
        }

        // 임시 호환: 기존 평문 계정
        return rawPassword.equals(savedPassword);
    }

    /**
     * CHANGED: bcrypt 해시 문자열 여부 간단 체크
     */
    private boolean isBcryptHash(String value) {
        if (value == null) {
            return false;
        }
        return value.startsWith("$2a$")
            || value.startsWith("$2b$")
            || value.startsWith("$2y$");
    }
}