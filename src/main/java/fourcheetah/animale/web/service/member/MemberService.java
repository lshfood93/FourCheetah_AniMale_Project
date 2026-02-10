package fourcheetah.animale.web.service.member;

import java.util.List;
import fourcheetah.animale.web.dto.member.MemberDTO;

public interface MemberService {

    List<MemberDTO> selectAll(MemberDTO dto);
    MemberDTO selectOne(MemberDTO dto);
    
    boolean insert(MemberDTO dto);
    boolean update(MemberDTO dto);
    boolean delete(MemberDTO dto);
}
