package fourcheetah.animale.web.controller.member;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@RestController
public class ProfileImageUploadController {

	@Value("${app.upload.profile-temp-dir}")
	private String profileTempDir;

    @PostMapping(value = "/member/profile/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> upload(@RequestParam("profileImageFile") MultipartFile file,
                                      HttpSession session,
                                      HttpServletRequest request) {

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

            // 1) temp dir 생성(없으면 생성)
            Path dir = Paths.get(profileTempDir);
            Files.createDirectories(dir);

            // 2) 확장자 유지(권장)
            String original = StringUtils.hasText(file.getOriginalFilename()) ? file.getOriginalFilename() : "";
            String ext = "";
            int dot = original.lastIndexOf('.');
            if (dot >= 0) {
                ext = original.substring(dot).toLowerCase(); // .jpg
            }

            // 허용 확장자 최소 필터(선택)
            if (!(ext.equals(".jpg") || ext.equals(".jpeg") || ext.equals(".png") || ext.equals(".webp") || ext.isEmpty())) {
                res.put("result", "FAIL");
                res.put("errorMessage", "지원하지 않는 이미지 형식입니다.(jpg/jpeg/png/webp)");
                return res;
            }

            // 3) 파일명(token) 생성
            String token = "m" + memberId + "_" + UUID.randomUUID().toString().replace("-", "") + ext;

            // 4) 저장 (transferTo 대신 copy로 더 안정적으로)
            Path savePath = dir.resolve(token);
            Files.copy(file.getInputStream(), savePath, StandardCopyOption.REPLACE_EXISTING);

            // 5) 접근 URL 반환 (ResourceHandler에서 /uploads/profile_temp/** 매핑 필요)
            String ctx = request.getContextPath();
            String url = ctx + "/uploads/profile_temp/" + token;

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