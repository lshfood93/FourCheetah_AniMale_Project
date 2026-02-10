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
    public List<MemberDTO> selectAll(MemberDTO dto) {
        return memberDAO.selectAll(dto);
    }

    @Override
    public MemberDTO selectOne(MemberDTO dto) {
        return memberDAO.selectOne(dto);
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
