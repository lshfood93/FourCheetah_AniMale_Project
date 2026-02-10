package fourcheetah.animale.web.controller.board;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import jakarta.servlet.ServletContext;
import jakarta.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

@RestController
public class ContentImageUploadController {

    @Autowired
    private ServletContext servletContext;

    private static final Set<String> ALLOWED_TYPES =
            Collections.unmodifiableSet(new HashSet<>(Arrays.asList("board", "news")));

    private static final Set<String> ALLOWED_EXTENSION =
            Collections.unmodifiableSet(new HashSet<>(Arrays.asList("jpg", "jpeg", "png")));

    private static final long MAX_BYTES = 5L * 1024 * 1024; // 5MB
    private static final int MAX_DIMENSION = 1920;
    private static final long MAX_PIXELS = 10_000_000L; // 1천만 픽셀
    private static final float JPEG_QUALITY = 0.85f;

    // CKEditor(SimpleUploadAdapter) 요청:
    // POST /ContentImageUpload?type=board
    // multipart/form-data, file field name = upload
    @PostMapping(value = "/ContentImageUpload", produces = "application/json; charset=UTF-8")
    public ResponseEntity<String> upload(
            @RequestParam(value = "type", required = false) String type,
            @RequestParam(value = "upload", required = false) MultipartFile upload,
            HttpServletRequest request
    ) {

        try {
            // 0) type 파라미터 검증
            if (type == null || !ALLOWED_TYPES.contains(type)) {
                return ckError("type 파라미터가 올바르지 않습니다. (board/news만 허용)");
            }

            // 1) 파일 파트 수신 + null/empty 체크
            if (upload == null || upload.isEmpty() || upload.getSize() == 0) {
                return ckError("업로드된 파일이 없습니다.");
            }

            // 2) 업로드 용량 제한(로직 2차 체크)
            if (upload.getSize() > MAX_BYTES) {
                int maxMB = (int) (MAX_BYTES / (1024 * 1024));
                return ckError("이미지 용량은 최대 " + maxMB + "MB 까지만 업로드할 수 있습니다.");
            }

            // 3) Content-Type 1차 체크
            String contentType = upload.getContentType();
            if (contentType == null || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
                return ckError("이미지 파일만 업로드할 수 있습니다.");
            }

            // 4) 원본 파일명/확장자 체크
            String fileName = upload.getOriginalFilename();
            if (fileName == null || fileName.trim().isEmpty()) {
                return ckError("파일명이 올바르지 않습니다.");
            }

            String originalName = Paths.get(fileName).getFileName().toString();
            String extension = getExt(originalName);

            if (extension.isEmpty() || !ALLOWED_EXTENSION.contains(extension)) {
                return ckError("허용되지 않은 확장자입니다. (jpg, jpeg, png만 지원)");
            }

            // 5) 이미지 디코딩(진짜 이미지인지 검증)
            BufferedImage image = ImageIO.read(upload.getInputStream());
            if (image == null) {
                return ckError("올바른 이미지 파일이 아닙니다.");
            }

            int width = image.getWidth();
            int height = image.getHeight();

            // 6) 픽셀 총량 제한(폭탄 방지)
            long pixels = (long) width * (long) height;
            if (pixels > MAX_PIXELS) {
                return ckError("이미지가 너무 큽니다. (픽셀 수 제한 초과: " + width + "x" + height + ")");
            }

            // 7) 자동 리사이즈
            int maxSide = Math.max(width, height);
            if (maxSide > MAX_DIMENSION) {
                double scale = (double) MAX_DIMENSION / (double) maxSide;
                int resizeWidth = Math.max(1, (int) Math.round(width * scale));
                int resizeHeight = Math.max(1, (int) Math.round(height * scale));

                boolean keepAlpha = extension.equals("png");
                image = resize(image, resizeWidth, resizeHeight, keepAlpha);
            }

            // 8) 저장 폴더 결정: /upload/{type}
            String relDir = "/upload/" + type;
            String realDir = servletContext.getRealPath(relDir);

            if (realDir == null) {
                // jar 실행 환경에서는 getRealPath가 null일 수 있음
                return ckError("서버 저장 경로를 찾을 수 없습니다. (getRealPath가 null)");
            }

            Path saveDir = Paths.get(realDir);
            Files.createDirectories(saveDir);

            // 9) 저장 파일명 생성
            String savedName = UUID.randomUUID().toString().replace("-", "") + "." + extension;
            File savedFile = saveDir.resolve(savedName).toFile();

            // 10) 파일 저장
            if (extension.equals("jpg") || extension.equals("jpeg")) {
                BufferedImage rgb = toRgb(image);
                writeJpeg(rgb, savedFile, JPEG_QUALITY);
            } else {
                ImageIO.write(image, extension, savedFile);
            }

            // 11) 브라우저 접근 URL 생성
            String fileUrl = request.getContextPath() + relDir + "/" + savedName;

            // 12) CKEditor 성공 응답 규격: {"url":"..."}
            return ResponseEntity.ok("{\"url\":\"" + escapeJson(fileUrl) + "\"}");

        } catch (MaxUploadSizeExceededException e) {
            return ckError("파일이 너무 큽니다. (업로드 용량 제한 초과)");
        } catch (IllegalStateException e) {
            // 멀티파트 처리 중 제한 초과 등
            return ckError("파일이 너무 큽니다. (업로드 용량 제한 초과)");
        } catch (Exception e) {
            e.printStackTrace();
            return ckError("업로드 중 오류가 발생했습니다.");
        }
    }

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

    // CKEditor 실패 응답 규격: {"error":{"message":"..."}}
    private ResponseEntity<String> ckError(String message) {
        String body = "{\"error\":{\"message\":\"" + escapeJson(message) + "\"}}";
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    private String escapeJson(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
