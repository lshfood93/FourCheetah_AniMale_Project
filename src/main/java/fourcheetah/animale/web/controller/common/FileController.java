package fourcheetah.animale.web.controller.common;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.ServletContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

/**
 * 파일 업로드 컨트롤러 (Common)
 * 
 * 통합 이전:
 * - ProfileImageUploadController (프로필 이미지 임시 업로드)
 * - ContentImageUploadController (CKEditor 콘텐츠 이미지 업로드)
 */
@RestController
public class FileController {

    @Autowired
    private ServletContext servletContext;

    @Value("${app.upload.profile-temp-dir}")
    private String profileTempDir;

    private static final Set<String> ALLOWED_TYPES =
            Collections.unmodifiableSet(new HashSet<>(Arrays.asList("board", "news")));

    private static final Set<String> ALLOWED_EXTENSION =
            Collections.unmodifiableSet(new HashSet<>(Arrays.asList("jpg", "jpeg", "png")));

    private static final long MAX_BYTES = 5L * 1024 * 1024;
    private static final int MAX_DIMENSION = 1920;
    private static final long MAX_PIXELS = 10_000_000L;
    private static final float JPEG_QUALITY = 0.85f;

    // ==================== 프로필 이미지 업로드 ====================

    @PostMapping(value = "/member/profile/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> uploadProfile(@RequestParam("profileImageFile") MultipartFile file,
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
            
            if (file.getSize() <= 0 || file.getSize() > MAX_BYTES) {
                res.put("result", "FAIL");
                res.put("errorMessage", "프로필 이미지는 최대 3MB까지 업로드 가능합니다.");
                return res;
            }

            String ct = file.getContentType();
            if (ct == null || !ct.toLowerCase(Locale.ROOT).startsWith("image/")) {
                res.put("result", "FAIL");
                res.put("errorMessage", "이미지 파일만 업로드 가능합니다.");
                return res;
            }

            Path dir = Paths.get(profileTempDir).toAbsolutePath().normalize();
            Files.createDirectories(dir);

            String original = StringUtils.hasText(file.getOriginalFilename()) ? file.getOriginalFilename() : "";
            String safeOriginal = Paths.get(original).getFileName().toString();
            String ext = getExt(safeOriginal); // 기존 헬퍼 재사용 (jpg / png 형태)
            

            if (ext.isEmpty() || !ALLOWED_EXTENSION.contains(ext)) {
                res.put("result", "FAIL");
                res.put("errorMessage", "지원하지 않는 이미지 형식입니다. (jpg/jpeg/png)");
                return res;
            }
            
            
            
            
            String token = "m" + memberId + "_" + UUID.randomUUID().toString().replace("-", "") + "." + ext;

            Path savePath = dir.resolve(token).normalize();
            if (!savePath.startsWith(dir)) {
                res.put("result", "FAIL");
                res.put("errorMessage", "잘못된 저장 경로입니다.");
                return res;
            }
            
            file.transferTo(savePath.toFile());

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

    // ==================== 콘텐츠 이미지 업로드 (CKEditor) ====================

    @PostMapping(value = "/ContentImageUpload", produces = "application/json; charset=UTF-8")
    public ResponseEntity<String> uploadContent(
            @RequestParam(value = "type", required = false) String type,
            @RequestParam(value = "upload", required = false) MultipartFile upload,
            HttpServletRequest request
    ) {

        try {
            if (type == null || !ALLOWED_TYPES.contains(type)) {
                return ckError("type 파라미터가 올바르지 않습니다. (board/news만 허용)");
            }

            if (upload == null || upload.isEmpty() || upload.getSize() == 0) {
                return ckError("업로드된 파일이 없습니다.");
            }

            if (upload.getSize() > MAX_BYTES) {
                int maxMB = (int) (MAX_BYTES / (1024 * 1024));
                return ckError("이미지 용량은 최대 " + maxMB + "MB 까지만 업로드할 수 있습니다.");
            }

            String contentType = upload.getContentType();
            if (contentType == null || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
                return ckError("이미지 파일만 업로드할 수 있습니다.");
            }

            String fileName = upload.getOriginalFilename();
            if (fileName == null || fileName.trim().isEmpty()) {
                return ckError("파일명이 올바르지 않습니다.");
            }

            String originalName = Paths.get(fileName).getFileName().toString();
            String extension = getExt(originalName);

            if (extension.isEmpty() || !ALLOWED_EXTENSION.contains(extension)) {
                return ckError("허용되지 않은 확장자입니다. (jpg, jpeg, png만 지원)");
            }

            BufferedImage image = ImageIO.read(upload.getInputStream());
            if (image == null) {
                return ckError("올바른 이미지 파일이 아닙니다.");
            }

            int width = image.getWidth();
            int height = image.getHeight();

            long pixels = (long) width * (long) height;
            if (pixels > MAX_PIXELS) {
                return ckError("이미지가 너무 큽니다. (픽셀 수 제한 초과: " + width + "x" + height + ")");
            }

            int maxSide = Math.max(width, height);
            if (maxSide > MAX_DIMENSION) {
                double scale = (double) MAX_DIMENSION / (double) maxSide;
                int resizeWidth = Math.max(1, (int) Math.round(width * scale));
                int resizeHeight = Math.max(1, (int) Math.round(height * scale));

                boolean keepAlpha = extension.equals("png");
                image = resize(image, resizeWidth, resizeHeight, keepAlpha);
            }

            String relDir = "/upload/" + type;
            String realDir = servletContext.getRealPath(relDir);

            if (realDir == null) {
                return ckError("서버 저장 경로를 찾을 수 없습니다. (getRealPath가 null)");
            }

            Path saveDir = Paths.get(realDir);
            Files.createDirectories(saveDir);

            String savedName = UUID.randomUUID().toString().replace("-", "") + "." + extension;
            File savedFile = saveDir.resolve(savedName).toFile();

            if (extension.equals("jpg") || extension.equals("jpeg")) {
                BufferedImage rgb = toRgb(image);
                writeJpeg(rgb, savedFile, JPEG_QUALITY);
            } else {
                ImageIO.write(image, extension, savedFile);
            }

            String fileUrl = request.getContextPath() + relDir + "/" + savedName;

            return ResponseEntity.ok("{\"url\":\"" + escapeJson(fileUrl) + "\"}");

        } catch (MaxUploadSizeExceededException e) {
            return ckError("파일이 너무 큽니다. (업로드 용량 제한 초과)");
        } catch (IllegalStateException e) {
            return ckError("파일이 너무 큽니다. (업로드 용량 제한 초과)");
        } catch (Exception e) {
            e.printStackTrace();
            return ckError("업로드 중 오류가 발생했습니다.");
        }
    }

    // ==================== 헬퍼 메서드 ====================

    private String getExt(String filename) {
        int dot = filename.lastIndexOf('.');
        if (dot < 0 || dot == filename.length() - 1) return "";
        return filename.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    private BufferedImage resize(BufferedImage src, int resizeWidth, int resizeHeight, boolean keepAlpha) {
        int type = keepAlpha ? BufferedImage.TYPE_INT_ARGB : BufferedImage.TYPE_INT_RGB;

        BufferedImage dst = new BufferedImage(resizeWidth, resizeHeight, type);
        Graphics2D g = dst.createGraphics();

        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

        if (!keepAlpha) {
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, resizeWidth, resizeHeight);
        }

        g.drawImage(src, 0, 0, resizeWidth, resizeHeight, null);
        g.dispose();
        return dst;
    }

    private BufferedImage toRgb(BufferedImage src) {
        if (src.getType() == BufferedImage.TYPE_INT_RGB) return src;

        BufferedImage rgb = new BufferedImage(src.getWidth(), src.getHeight(), BufferedImage.TYPE_INT_RGB);
        Graphics2D g = rgb.createGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, rgb.getWidth(), rgb.getHeight());
        g.drawImage(src, 0, 0, null);
        g.dispose();
        return rgb;
    }

    private void writeJpeg(BufferedImage img, File outFile, float quality) throws IOException {
        ImageWriter writer = null;
        ImageOutputStream ios = null;

        try {
            writer = ImageIO.getImageWritersByFormatName("jpeg").next();
            ImageWriteParam param = writer.getDefaultWriteParam();

            if (param.canWriteCompressed()) {
                param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
                param.setCompressionQuality(quality);
            }

            ios = ImageIO.createImageOutputStream(outFile);
            writer.setOutput(ios);
            writer.write(null, new IIOImage(img, null, null), param);

        } finally {
            if (ios != null) ios.close();
            if (writer != null) writer.dispose();
        }
    }

    private ResponseEntity<String> ckError(String message) {
        String body = "{\"error\":{\"message\":\"" + escapeJson(message) + "\"}}";
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}