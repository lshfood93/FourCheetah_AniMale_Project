package fourcheetah.animale.web.service.member;

import java.util.List;
import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.dto.member.MemberWarningDTO;  // 추가!

public interface MemberService {

    List<MemberDTO> selectAll(MemberDTO dto);
    
    MemberDTO selectOne(MemberDTO dto);
    
    MemberWarningDTO selectActiveWarning(int memberId);  // 추가!
    
    boolean insert(MemberDTO dto);
    
    boolean update(MemberDTO dto);
    
    boolean delete(MemberDTO dto);
}