package fourcheetah.animale.web.service.member;

import java.util.List;
<<<<<<< HEAD

import fourcheetah.animale.web.dto.member.MemberDTO;

public interface MemberService {
    List<MemberDTO> getMemberList(MemberDTO dto); // selectAll
    MemberDTO getMember(MemberDTO dto);           // selectOne
    boolean insertMember(MemberDTO dto);
    boolean updateMember(MemberDTO dto);
    boolean deleteMember(MemberDTO dto);
=======
import fourcheetah.animale.web.dto.member.MemberDTO;

public interface MemberService {

    List<MemberDTO> selectAll(MemberDTO dto);
    MemberDTO selectOne(MemberDTO dto);
    
    boolean insert(MemberDTO dto);
    boolean update(MemberDTO dto);
    boolean delete(MemberDTO dto);
	MemberDTO selectActiveWarning(int memberId);
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
}
