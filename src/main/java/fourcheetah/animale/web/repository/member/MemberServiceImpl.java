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
<<<<<<< HEAD
    public List<MemberDTO> getMemberList(MemberDTO dto) {
=======
    public List<MemberDTO> selectAll(MemberDTO dto) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
        return memberDAO.selectAll(dto);
    }

    @Override
<<<<<<< HEAD
    public MemberDTO getMember(MemberDTO dto) {
=======
    public MemberDTO selectOne(MemberDTO dto) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
        return memberDAO.selectOne(dto);
    }

    @Override
<<<<<<< HEAD
    public boolean insertMember(MemberDTO dto) {
=======
    public boolean insert(MemberDTO dto) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
        return memberDAO.insert(dto);
    }

    @Override
<<<<<<< HEAD
    public boolean updateMember(MemberDTO dto) {
=======
    public boolean update(MemberDTO dto) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
        return memberDAO.update(dto);
    }

    @Override
<<<<<<< HEAD
    public boolean deleteMember(MemberDTO dto) {
        return memberDAO.delete(dto);
    }
=======
    public boolean delete(MemberDTO dto) {
        return memberDAO.delete(dto);
    }

	@Override
	public MemberDTO selectActiveWarning(int memberId) {
		// TODO Auto-generated method stub
		return null;
	}
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
}
