package fourcheetah.animale.web.repository.member;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.dto.member.MemberWarningDTO;  // 추가!
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
     * 현재 활성화된 제재 정보 조회 (추가!)
     */
    @Override
    public MemberWarningDTO selectActiveWarning(int memberId) {
        System.out.println("[Service] 제재 정보 조회 - memberId: " + memberId);
        
        try {
            MemberWarningDTO result = memberDAO.selectActiveWarning(memberId);
            
            if (result != null) {
                System.out.println("[Service] 제재 발견: " + result.getWarningType());
            } else {
                System.out.println("[Service] 제재 없음 (정상 회원)");
            }
            
            return result;
        } catch (Exception e) {
            System.out.println("[Service 에러] 제재 정보 조회: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
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