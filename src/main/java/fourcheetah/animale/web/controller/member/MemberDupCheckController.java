package fourcheetah.animale.web.controller.member;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.repository.member.MemberDupCheckRepository;

@RestController
public class MemberDupCheckController {

    private final MemberDupCheckRepository repo;

    public MemberDupCheckController(MemberDupCheckRepository repo) {
        this.repo = repo;
    }

    @PostMapping("/MemberNameCheck")
    public Map<String, Object> memberNameCheck(@RequestParam String memberName) {
        Map<String, Object> res = new HashMap<>();

        try {
            boolean exists = repo.existsByName(memberName.trim());
            res.put("success", true);
            res.put("available", !exists);
            res.put("message", exists ? "이미 사용 중인 아이디입니다." : "사용 가능한 아이디입니다.");
        } catch (Exception e) {
            res.put("success", false);
            res.put("available", false);
            res.put("message", "서버 오류");
        }

        return res;
    }
   
    @RequestMapping(value="/MemberNickNameCheck", method={RequestMethod.GET, RequestMethod.POST})
    public Map<String, Object> memberNicknameCheck(@RequestParam String memberNickname) {
        Map<String, Object> res = new HashMap<>();
        try {
            boolean exists = repo.existsByNickname(memberNickname.trim());
            res.put("success", true);
            res.put("available", !exists);
            res.put("message", exists ? "이미 사용 중인 닉네임입니다." : "사용 가능한 닉네임입니다.");
        } catch (Exception e) {
            res.put("success", false);
            res.put("available", false);
            res.put("message", "서버 오류");
        }
        return res;
    }

    @PostMapping("/MemberEmailCheck")
    public Map<String, Object> memberEmailCheck(@RequestParam String memberEmail) {
        Map<String, Object> res = new HashMap<>();

        try {
            boolean exists = repo.existsByEmail(memberEmail.trim());
            res.put("success", true);
            res.put("available", !exists);
            res.put("message", exists ? "이미 사용 중인 이메일입니다." : "사용 가능한 이메일입니다.");
        } catch (Exception e) {
            res.put("success", false);
            res.put("available", false);
            res.put("message", "서버 오류");
        }

        return res;
    }
}
