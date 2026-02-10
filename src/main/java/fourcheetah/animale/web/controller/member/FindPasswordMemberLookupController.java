package fourcheetah.animale.web.controller.member;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.service.member.MemberService;

@RestController
public class FindPasswordMemberLookupController {

    @Autowired
    private MemberService memberService;

    @PostMapping(
        value = "/FindPasswordMemberLookup",
        produces = "application/json; charset=UTF-8"
    )
    public ResponseEntity<Map<String, Object>> lookup(MemberDTO dto) {

        Map<String, Object> result = new HashMap<>();

        String memberName = dto.getMemberName();
        if (memberName == null || memberName.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "아이디를 입력해주세요.");
            return ResponseEntity.badRequest().body(result);
        }

        memberName = memberName.trim();
        dto.setMemberName(memberName);
        dto.setCondition("MEMBER_ID_EMAIL");

        MemberDTO memberData = memberService.selectOne(dto);

        result.put("success", true);

        if (memberData == null) {
            result.put("exists", false);
            result.put("message", "존재하지 않는 아이디입니다.");
        } else {
            result.put("exists", true);
            result.put("memberId", memberData.getMemberId());
            result.put("memberEmail", memberData.getMemberEmail());
        }

        return ResponseEntity.ok(result);
    }
}
