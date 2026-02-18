package fourcheetah.animale.web.controller.member;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.member.MemberDAO;

/**
 * 회원 이메일 중복 확인
 * Servlet -> RestController 변환
 */
@RestController
@RequestMapping("/api")
public class MemberEmailCheckController {
    
    /**
     * POST /api/memberEmailCheck
     * 
     * 요청:
     * {
     *   "memberEmail": "email@gmail.com"
     * }
     * 
     * 응답:
     * {
     *   "success": true,
     *   "available": true/false,
     *   "message": "..."
     * }
     */
    @PostMapping("/memberEmailCheck")
    public Map<String, Object> checkEmail(@RequestBody Map<String, String> data) {
        
        Map<String, Object> result = new HashMap<>();
        
        String memberEmail = data.get("memberEmail");
        
        // 입력값 검증
        if (memberEmail == null || memberEmail.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "이메일을 입력해주세요.");
            return result;
        }
        
        memberEmail = memberEmail.trim();
        
        // DB에서 이메일 조회
        MemberDAO dao = new MemberDAO();
        MemberDTO dto = new MemberDTO();
        dto.setMemberEmail(memberEmail);
        dto.setCondition("MEMBER_EMAIL_CHECK");
        
        MemberDTO exist = dao.selectOne(dto);
        
        result.put("success", true);
        
        if (exist != null) {
            // 이미 존재
            result.put("available", false);
            result.put("message", "이미 사용 중인 이메일입니다.");
        } else {
            // 사용 가능
            result.put("available", true);
            result.put("message", "사용 가능한 이메일입니다.");
        }
        
        return result;
    }
}
