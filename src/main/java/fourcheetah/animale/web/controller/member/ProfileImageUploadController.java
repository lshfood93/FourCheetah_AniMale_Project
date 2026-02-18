package fourcheetah.animale.web.controller.member;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpSession;

@RestController
public class ProfileImageUploadController {

    @Value("${app.upload.profile-temp-dir:D:/DoNotUse2/animaletest/uploads/profile_temp}")
    private String profileTempDir;

    @PostMapping(value="/member/profile/upload", consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> upload(@RequestParam("profileImageFile") MultipartFile file,
                                      HttpSession session) {

        Map<String, Object> res = new HashMap<>();

        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId == null) {
            res.put("result", "FAIL");
            res.put("errorMessage", "로그인이 필요합니다.");
            return res;
        }

        try {
            if (file == null || file.isEmpty()) {
                res.put("result", "FAIL");
                res.put("errorMessage", "파일이 없습니다.");
                return res;
            }

            String ct = file.getContentType();
            if (ct == null || !ct.startsWith("image/")) {
                res.put("result", "FAIL");
                res.put("errorMessage", "이미지 파일만 업로드 가능합니다.");
                return res;
            }

            Files.createDirectories(Paths.get(profileTempDir));

            // token을 파일명으로 사용(단순/안전)
            String token = UUID.randomUUID().toString().replace("-", "");
            Path savePath = Paths.get(profileTempDir, token);
            file.transferTo(savePath.toFile());

            // 정적 리소스로 접근할 URL (ResourceHandler에서 /uploads/profile_temp/** 매핑 필요)
            String url = "/uploads/profile_temp/" + token;

            res.put("result", "SUCCESS");
            res.put("temporaryProfileImageToken", token);
            res.put("temporaryProfileImageUrl", url);
            return res;

        } catch (Exception e) {
            e.printStackTrace();
            res.put("result", "FAIL");
            res.put("errorMessage", "업로드 중 오류가 발생했습니다.");
            return res;
        }
    }
}
