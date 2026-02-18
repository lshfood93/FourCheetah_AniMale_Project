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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import fourcheetah.animale.web.dto.news.NewsDTO;
import fourcheetah.animale.web.service.news.NewsService;
import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("")
public class NewsEditController {

    @Autowired
    private NewsService newsService;

    @GetMapping("/newsEdit")
    public String execute(NewsDTO dto, HttpSession session, Model model) {
        
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

        int newsId = dto.getNewsId();

        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        NewsDTO newsDTO = new NewsDTO();
        newsDTO.setNewsId(newsId);
        newsDTO.setCondition("NEWS_DETAIL");

        NewsDTO newsData = newsService.selectOne(newsDTO);

        if (newsData == null) {
            model.addAttribute("msg", "존재하지 않는 뉴스입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        model.addAttribute("type", "NEWS");
        model.addAttribute("newsData", newsData);
        return "edit";
    }
    
    
    @PostMapping("/newsEdit")
    public String execute(
            NewsDTO dto,
            @RequestParam(required = false) String existingThumbUrl,
            @RequestParam(required = false) String existingImageUrl,
            @RequestParam(value = "thumbFile", required = false) MultipartFile thumbFile,
            @RequestParam(value = "newsImageFile", required = false) MultipartFile newsImageFile,
            HttpSession session,
            Model model
    ) {
        int newsId = dto.getNewsId();
        Integer animeId = dto.getAnimeId();
        String newsTitle = dto.getNewsTitle();
        String newsContent = dto.getNewsContent();

        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 수정할 수 있습니다.");
            model.addAttribute("location", "/newsDetail?newsId=" + newsId);
            return "message";
        }

        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        if (newsTitle == null || newsTitle.trim().isEmpty()) {
            model.addAttribute("msg", "제목은 필수입니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }
        newsTitle = newsTitle.trim();
        if (newsTitle.length() > 255) {
            model.addAttribute("msg", "제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }

        if (newsContent == null || newsContent.trim().isEmpty()) {
            model.addAttribute("msg", "내용은 필수입니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }
        newsContent = newsContent.trim();

        String lowerContent = newsContent.toLowerCase();
        if (lowerContent.contains("<script") || lowerContent.contains("javascript:")) {
            model.addAttribute("msg", "허용되지 않는 내용이 포함되어 있습니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }

        try {
            String thumbnailUrl = existingThumbUrl;
            if (thumbFile != null && !thumbFile.isEmpty()) {
                thumbnailUrl = saveFile(thumbFile, "/upload/newsThumb/");
            }

            String newsImageUrl = existingImageUrl;
            if (newsImageFile != null && !newsImageFile.isEmpty()) {
                newsImageUrl = saveFile(newsImageFile, "/upload/newsImage/");
            }

            if (newsImageUrl == null || newsImageUrl.isEmpty()) {
                newsImageUrl = extractFirstImgSrc(newsContent);
            }

            NewsDTO updateDTO = new NewsDTO();
            updateDTO.setNewsId(newsId);
            updateDTO.setAnimeId(animeId);
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

            return "redirect:/newsDetail?newsId=" + newsId;

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("msg", "파일 업로드 중 오류가 발생했습니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }
    }

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

    private String extractFirstImgSrc(String content) {
        Pattern pattern = Pattern.compile("<img[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"]", Pattern.CASE_INSENSITIVE);
        Matcher matcher = pattern.matcher(content);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }
}
