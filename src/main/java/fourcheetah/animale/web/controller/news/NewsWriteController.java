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
public class NewsWriteController {

    @Autowired
    private NewsService newsService;

    
    @GetMapping("/newsWrite")
    public String execute(HttpSession session, Model model) {
        
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

        model.addAttribute("type", "NEWS");
        return "write";
    }
    
    
    
    @PostMapping("/newsWrite")
    public String execute(
            NewsDTO dto,
            @RequestParam("thumbFile") MultipartFile thumbFile,
            HttpSession session,
            Model model
    ) {
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
            model.addAttribute("msg", "관리자만 작성할 수 있습니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        if (newsTitle == null || newsTitle.trim().isEmpty()) {
            model.addAttribute("msg", "제목은 필수입니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }
        newsTitle = newsTitle.trim();
        if (newsTitle.length() > 255) {
            model.addAttribute("msg", "제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        if (newsContent == null || newsContent.trim().isEmpty()) {
            model.addAttribute("msg", "내용은 필수입니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }
        newsContent = newsContent.trim();

        String lowerContent = newsContent.toLowerCase();
        if (lowerContent.contains("<script") || lowerContent.contains("javascript:")) {
            model.addAttribute("msg", "허용되지 않는 내용이 포함되어 있습니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        if (thumbFile == null || thumbFile.isEmpty()) {
            model.addAttribute("msg", "인네일은 필수입니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

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

            return "redirect:/newsDetail?newsId=" + newsId;

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("msg", "파일 업로드 중 오류가 발생했습니다.");
            model.addAttribute("location", "/newsWrite");
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
