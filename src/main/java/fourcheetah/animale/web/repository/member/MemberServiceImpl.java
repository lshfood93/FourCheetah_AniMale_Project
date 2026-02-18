package fourcheetah.animale.web.repository.member;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.service.member.MemberService;

@Service
public class MemberServiceImpl implements MemberService {

    @Autowired
    private MemberDAO memberDAO;

    @Override
    public List<MemberDTO> getMemberList(MemberDTO dto) {
        return memberDAO.selectAll(dto);
    }

    @Override
    public MemberDTO getMember(MemberDTO dto) {
        return memberDAO.selectOne(dto);
    }

    @Override
    public boolean insertMember(MemberDTO dto) {
        return memberDAO.insert(dto);
    }

    @Override
    public boolean updateMember(MemberDTO dto) {
        return memberDAO.update(dto);
    }

    @Override
    public boolean deleteMember(MemberDTO dto) {
        return memberDAO.delete(dto);
    }
}
