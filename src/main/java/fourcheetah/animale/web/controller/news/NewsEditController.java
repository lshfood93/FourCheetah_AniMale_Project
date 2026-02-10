package fourcheetah.animale.web.controller.news;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import fourcheetah.animale.web.dto.news.NewsDTO;
import fourcheetah.animale.web.service.news.NewsService;
import jakarta.servlet.http.HttpSession;

/**
 * 뉴스 수정 통합 컨트롤러
 * 
 * ✅ 페이지 이동: GET /newsEdit?newsId=X
 * ✅ 데이터 처리: POST /newsEdit
 */
@Controller
public class NewsEditController {

    @Autowired
    private NewsService newsService;


    // GET /newsEdit - 수정 페이지 이동
 
    /**
     * 뉴스 수정 페이지 이동
     * 
     * GET /newsEdit?newsId=X
     * → 권한 체크 (관리자만)
     * → 뉴스 데이터 조회
     * → edit.jsp 렌더링
     */
    @GetMapping("/newsEdit")
    public String newsEditPage(
            NewsDTO dto,
            HttpSession session,
            Model model
    ) {
        System.out.println("[뉴스 수정 페이지] GET /newsEdit?newsId=" + dto.getNewsId());

        // 1️⃣ 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        // 2️⃣ 관리자 권한 체크
        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 수정할 수 있습니다.");
            model.addAttribute("location", "/newsDetail?newsId=" + dto.getNewsId());
            return "message";
        }

        // 3️⃣ newsId 유효성 체크
        int newsId = dto.getNewsId();
        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 4️⃣ 뉴스 데이터 조회
        NewsDTO searchDTO = new NewsDTO();
        searchDTO.setNewsId(newsId);
        searchDTO.setCondition("NEWS_DETAIL");

        NewsDTO newsData = newsService.selectOne(searchDTO);

        if (newsData == null) {
            model.addAttribute("msg", "존재하지 않는 뉴스입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 5️⃣ JSP 렌더링
        model.addAttribute("type", "NEWS");
        model.addAttribute("newsData", newsData);
        System.out.println("[뉴스 수정 페이지] edit.jsp 렌더링 - newsId=" + newsId);
        return "edit";
    }

    // POST /newsEdit - 수정 처리
    
    /**
     * 뉴스 수정 처리
     * 
     * POST /newsEdit
     * → 권한 체크
     * → 유효성 검증
     * → 파일 업로드 (선택사항)
     * → DB UPDATE
     * → /newsDetail로 리다이렉트 또는 에러 처리
     */
    @PostMapping("/newsEdit")
    public String newsEdit(
            NewsDTO dto,
            @RequestParam(required = false) String existingThumbUrl,
            @RequestParam(required = false) String existingImageUrl,
            @RequestParam(value = "thumbFile", required = false) MultipartFile thumbFile,
            @RequestParam(value = "newsImageFile", required = false) MultipartFile newsImageFile,
            HttpSession session,
            Model model,
            RedirectAttributes ra
    ) {
        System.out.println("[뉴스 수정] POST /newsEdit 시작 - newsId=" + dto.getNewsId());

        // 1️⃣ 권한 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 수정할 수 있습니다.");
            model.addAttribute("location", "/newsDetail?newsId=" + dto.getNewsId());
            return "message";
        }

        // 2️⃣ newsId 유효성 체크
        int newsId = dto.getNewsId();
        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 3️⃣ 입력값 검증
        String newsTitle = (dto.getNewsTitle() == null) ? "" : dto.getNewsTitle().trim();
        String newsContent = (dto.getNewsContent() == null) ? "" : dto.getNewsContent().trim();

        // 제목 검증
        if (newsTitle.isEmpty()) {
            model.addAttribute("msg", "제목은 필수입니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }
        if (newsTitle.length() > 255) {
            model.addAttribute("msg", "제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }

        // 내용 검증
        if (newsContent.isEmpty()) {
            model.addAttribute("msg", "내용은 필수입니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }

        // XSS 방지
        String lowerContent = newsContent.toLowerCase();
        if (lowerContent.contains("<script") || lowerContent.contains("javascript:")) {
            model.addAttribute("msg", "허용되지 않는 내용이 포함되어 있습니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }

        // 4️⃣ 파일 업로드 처리 (선택사항)
        try {
            String thumbnailUrl = existingThumbUrl;
            if (thumbFile != null && !thumbFile.isEmpty()) {
                thumbnailUrl = saveFile(thumbFile, "/upload/newsThumb/");
            }

            String newsImageUrl = existingImageUrl;
            if (newsImageFile != null && !newsImageFile.isEmpty()) {
                newsImageUrl = saveFile(newsImageFile, "/upload/newsImage/");
            }

            // 이미지 URL이 없으면 content에서 추출
            if (newsImageUrl == null || newsImageUrl.isEmpty()) {
                newsImageUrl = extractFirstImgSrc(newsContent);
            }

            // 5️⃣ DB UPDATE
            NewsDTO updateDTO = new NewsDTO();
            updateDTO.setNewsId(newsId);
            updateDTO.setAnimeId(dto.getAnimeId());
            updateDTO.setNewsTitle(newsTitle);
            updateDTO.setNewsContent(newsContent);
            updateDTO.setNewsThumbnailUrl(thumbnailUrl);
            updateDTO.setNewsImageUrl(newsImageUrl);
            updateDTO.setCondition("NEWS_UPDATE");

            boolean result = newsService.update(updateDTO);

            if (!result) {
                model.addAttribute("msg", "뉴스 수정에 실패했습니다.");
                model.addAttribute("location", "/newsDetail?newsId=" + newsId);
                return "message";
            }

            System.out.println("[뉴스 수정] 완료 - newsId=" + newsId);
            ra.addFlashAttribute("msg", "뉴스 수정 완료!");
            return "redirect:/newsDetail?newsId=" + newsId;

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("msg", "파일 업로드 중 오류가 발생했습니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }
    }

   
    // 유틸 메서드

    /**
     * 파일 저장 유틸
     */
    private String saveFile(MultipartFile file, String webDir) throws Exception {
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }

        String savedName = UUID.randomUUID().toString() + extension;
        String uploadPath = System.getProperty("user.dir") + "/src/main/webapp" + webDir;
        Path dirPath = Paths.get(uploadPath);

        if (!Files.exists(dirPath)) {
            Files.createDirectories(dirPath);
        }

        Path savedPath = dirPath.resolve(savedName);
        try (InputStream inputStream = file.getInputStream()) {
            Files.copy(inputStream, savedPath, StandardCopyOption.REPLACE_EXISTING);
        }

        return webDir + savedName;
    }

    /**
     * HTML 내용에서 첫 번째 이미지 src 추출
     */
    private String extractFirstImgSrc(String content) {
        Pattern pattern = Pattern.compile("<img[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"]", Pattern.CASE_INSENSITIVE);
        Matcher matcher = pattern.matcher(content);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }
}
