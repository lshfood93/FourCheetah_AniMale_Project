package fourcheetah.animale.web.controller.anime;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.service.anime.AnimeService;
import jakarta.servlet.http.HttpSession;

@Controller
public class AnimeWriteController {

    @Autowired
    private AnimeService animeService;

    @Value("${app.upload.anime-dir:uploads/anime}")
    private String animeUploadDir;

    @Value("${app.upload.anime-url-prefix:/upload/anime}")
    private String animeUrlPrefix;

    /*
     * [역할]
     * 1) 로그인 체크
     * 2) 관리자 권한 체크
     * 3) 통과하면 animewrite.jsp(뷰)로 이동
     * 4) 실패하면 message.jsp(alert + location.href)로 이동
     *
     * ※ 부트에서는 "뷰 이름 리턴" = forward(포워드)와 동일한 효과
     *    - return "animewrite";  => /WEB-INF/views/animewrite.jsp 렌더링
     *    - return "redirect:/..."; => 리다이렉트
     */
    @GetMapping("/animeWritePage")
    public String animeWritePage(HttpSession session, Model model) {

        // 1) 로그인 체크
        Object memberId = (session == null) ? null : session.getAttribute("memberId");
        // (혹시 로그인 컨트롤러에서 userId로 넣는 경우도 있어서 안전빵)
        if (memberId == null && session != null) {
            memberId = session.getAttribute("userId");
        }

        if (memberId == null) {
            System.out.println("[애니 추가 이동 로그] 세션 없음 : 로그인 필요");
            model.addAttribute("msg", "로그인 정보가 없습니다.");
            model.addAttribute("location", "/loginPage");
            return "message";
        }

        // 2) 관리자 권한 체크
        Object roleObj = session.getAttribute("memberRole");
        if (roleObj == null) roleObj = session.getAttribute("userRole"); // 안전빵

        String memberRole = (roleObj == null) ? "" : roleObj.toString();
        System.out.println("[애니 추가 이동 로그] 세션 : memberId=[" + memberId + "]");
        System.out.println("[애니 추가 이동 로그] 세션 : memberRole=[" + memberRole + "]");

        if (!"ADMIN".equalsIgnoreCase(memberRole)) {
            model.addAttribute("msg", "관리자만 접근할 수 있습니다.");
            model.addAttribute("location", "/main");   // 너희 메인 매핑에 맞게 바꿔도 됨 (/main, /index 등)
            return "message";
        }

        // 3) 통과 → 작성 페이지로 forward
        return "animewrite"; // /WEB-INF/views/animewrite.jsp
    }
    
    
    @PostMapping("/animeWrite")
    public String writeAnime(
            AnimeDTO dto,                 // 커맨드객체 바인딩
            BindingResult br,             // 타입 변환 실패(예: year) 감지용
            HttpSession session,
            Model model,
            RedirectAttributes ra
    ) {
        System.out.println("[애니 추가 액션] start");

        // 0) 로그인/관리자 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인 정보가 없습니다.");
            model.addAttribute("location", "/loginPage");
            return "message";
        }

        Object roleObj = session.getAttribute("memberRole");
        String role = (roleObj == null) ? "" : roleObj.toString();
        if (!"ADMIN".equalsIgnoreCase(role)) {
            model.addAttribute("msg", "관리자만 접근할 수 있습니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 1) 바인딩 타입 오류(예: animeYear에 문자가 들어온 경우)
        if (br != null && br.hasErrors()) {
            model.addAttribute("errorMsg", "입력 값 형식이 올바르지 않습니다.");
            return "animewrite";
        }

        // 2) 필수값 검증
        String animeTitle = (dto.getAnimeTitle() == null) ? "" : dto.getAnimeTitle().trim();
        if (animeTitle.isEmpty()) {
            model.addAttribute("errorMsg", "애니 제목은 필수입니다.");
            return "animewrite";
        }

        Integer animeYear = dto.getAnimeYear();
        if (animeYear == null) {
            model.addAttribute("errorMsg", "연도 값이 올바르지 않습니다.");
            return "animewrite";
        }

        String animeQuarter = (dto.getAnimeQuarter() == null) ? "" : dto.getAnimeQuarter().trim();
        if (animeQuarter.isEmpty()) {
            model.addAttribute("errorMsg", "분기 값이 올바르지 않습니다.");
            return "animewrite";
        }

        // 3) 파일 필수 + 확장자 검증
        MultipartFile thumbFile = dto.getThumbFile();
        if (thumbFile == null || thumbFile.isEmpty()) {
            model.addAttribute("errorMsg", "썸네일 이미지를 선택해주세요.");
            return "animewrite";
        }

        String originalName = thumbFile.getOriginalFilename();
        String ext = extractExtLower(originalName);
        if (!(ext.equals(".jpg") || ext.equals(".jpeg") || ext.equals(".png") || ext.equals(".webp"))) {
            model.addAttribute("errorMsg", "이미지 파일(jpg, jpeg, png, webp)만 업로드 가능합니다.");
            return "animewrite";
        }

        // 4) 저장 + DB URL 세팅
        try {
            String savedName = UUID.randomUUID().toString().replace("-", "") + ext;

            Path dir = Paths.get(animeUploadDir).toAbsolutePath().normalize();
            Files.createDirectories(dir);

            Path target = dir.resolve(savedName);
            thumbFile.transferTo(target.toFile());

            String thumbnailUrl = animeUrlPrefix + "/" + savedName;

            // 5) 서버에서 값 정리/세팅 (클라 입력값 그대로 신뢰 X)
            dto.setAnimeTitle(animeTitle);
            if (dto.getOriginalTitle() != null) dto.setOriginalTitle(dto.getOriginalTitle().trim());
            if (dto.getAnimeStory() != null) dto.setAnimeStory(dto.getAnimeStory().trim());

            dto.setAnimeThumbnailUrl(thumbnailUrl);
            dto.setCondition("ANIME_INSERT");

            // 6) INSERT
            boolean ok = animeService.insertAnime(dto);
            if (!ok) {
                model.addAttribute("errorMsg", "애니 등록에 실패했습니다.");
                return "animewrite";
            }

            ra.addFlashAttribute("msg", "애니 등록 완료!");
            return "redirect:/animeList";

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("errorMsg", "처리 중 오류가 발생했습니다: " + e.getMessage());
            return "animewrite";
        }
    }

    private String extractExtLower(String filename) {
        if (filename == null) return "";
        int dot = filename.lastIndexOf('.');
        if (dot == -1) return "";
        return filename.substring(dot).toLowerCase();
    }
}
