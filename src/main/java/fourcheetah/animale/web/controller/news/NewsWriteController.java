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
 * 뉴스 작성 통합 컨트롤러
 * 
 * ✅ 페이지 이동: GET /newsWrite
 * ✅ 데이터 처리: POST /newsWrite
 */
@Controller
public class NewsWriteController {

    @Autowired
    private NewsService newsService;

    // GET /newsWrite - 작성 페이지 이동
    /**
     * 뉴스 작성 페이지 이동
     * 
     * GET /newsWrite
     * → 권한 체크 (관리자만)
     * → write.jsp 렌더링
     */
    @GetMapping("/newsWrite")
    public String newsWritePage(HttpSession session, Model model) {
        
        System.out.println("[뉴스 작성 페이지] GET /newsWrite 시작");

        // 1️⃣ 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        // 2️⃣ 관리자 권한 체크
        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 작성할 수 있습니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 3️⃣ JSP 렌더링
        model.addAttribute("type", "NEWS");
        System.out.println("[뉴스 작성 페이지] write.jsp 렌더링");
        return "write";
    }

    // POST /newsWrite - 작성 처리
    
    /**
     * 뉴스 작성 처리
     * 
     * POST /newsWrite
     * → 유효성 검증
     * → 파일 업로드
     * → DB INSERT
     * → /newsDetail로 리다이렉트 또는 에러 처리
     */
    @PostMapping("/newsWrite")
    public String newsWrite(
            NewsDTO dto,
            @RequestParam("thumbFile") MultipartFile thumbFile,
            HttpSession session,
            Model model,
            RedirectAttributes ra
    ) {
        System.out.println("[뉴스 작성] POST /newsWrite 시작");

        // 1️⃣ 권한 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 작성할 수 있습니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 2️⃣ 입력값 검증
        Integer animeId = dto.getAnimeId();
        String newsTitle = (dto.getNewsTitle() == null) ? "" : dto.getNewsTitle().trim();
        String newsContent = (dto.getNewsContent() == null) ? "" : dto.getNewsContent().trim();

        // 제목 검증
        if (newsTitle.isEmpty()) {
            model.addAttribute("msg", "제목은 필수입니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }
        if (newsTitle.length() > 255) {
            model.addAttribute("msg", "제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        // 내용 검증
        if (newsContent.isEmpty()) {
            model.addAttribute("msg", "내용은 필수입니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        // XSS 방지
        String lowerContent = newsContent.toLowerCase();
        if (lowerContent.contains("<script") || lowerContent.contains("javascript:")) {
            model.addAttribute("msg", "허용되지 않는 내용이 포함되어 있습니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        // 썸네일 파일 검증
        if (thumbFile == null || thumbFile.isEmpty()) {
            model.addAttribute("msg", "썸네일은 필수입니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        // 3️⃣ 파일 업로드 + DB 저장
        try {
            String thumbnailUrl = saveFile(thumbFile, "/upload/newsThumb/");
            String newsImageUrl = extractFirstImgSrc(newsContent);

            NewsDTO insertDTO = new NewsDTO();
            insertDTO.setAnimeId(animeId);
            insertDTO.setNewsTitle(newsTitle);
            insertDTO.setNewsContent(newsContent);
            insertDTO.setNewsThumbnailUrl(thumbnailUrl);
            insertDTO.setNewsImageUrl(newsImageUrl);
            insertDTO.setCondition("NEWS_INSERT");

            boolean result = newsService.insert(insertDTO);

            if (!result) {
                model.addAttribute("msg", "뉴스 작성에 실패했습니다.");
                model.addAttribute("location", "/newsWrite");
                return "message";
            }

            int newsId = insertDTO.getNewsId();
            if (newsId <= 0) {
                model.addAttribute("msg", "뉴스 ID 생성에 실패했습니다.");
                model.addAttribute("location", "/newsList");
                return "message";
            }

            System.out.println("[뉴스 작성] 완료 - newsId=" + newsId);
            ra.addFlashAttribute("msg", "뉴스 작성 완료!");
            return "redirect:/newsDetail?newsId=" + newsId;

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("msg", "파일 업로드 중 오류가 발생했습니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }
    }

   
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
