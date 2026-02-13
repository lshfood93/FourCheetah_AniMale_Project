package fourcheetah.animale.web.repository.member;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.dto.member.MemberWarningDTO;
import fourcheetah.animale.web.service.member.MemberService;

@Service
public class MemberServiceImpl implements MemberService {

    @Autowired
    private MemberDAO memberDAO;

    @Override
    public List<MemberDTO> selectAll(MemberDTO dto) {
        return memberDAO.selectAll(dto);
    }

    @Override
    public MemberDTO selectOne(MemberDTO dto) {
        return memberDAO.selectOne(dto);
    }

    /**
     * ⭐ 활성 제재 조회 (로그인 시 사용)
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
        return memberDAO.insert(dto);
    }

    @Override
    public boolean update(MemberDTO dto) {
        return memberDAO.update(dto);
    }

    @Override
    public boolean delete(MemberDTO dto) {
        return memberDAO.delete(dto);
    }
}