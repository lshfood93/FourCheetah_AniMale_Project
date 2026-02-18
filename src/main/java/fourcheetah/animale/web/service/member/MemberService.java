package fourcheetah.animale.web.service.member;

import java.util.List;

import fourcheetah.animale.web.dto.member.MemberDTO;

public interface MemberService {
    List<MemberDTO> getMemberList(MemberDTO dto); // selectAll
    MemberDTO getMember(MemberDTO dto);           // selectOne
    boolean insertMember(MemberDTO dto);
    boolean updateMember(MemberDTO dto);
    boolean deleteMember(MemberDTO dto);
}
