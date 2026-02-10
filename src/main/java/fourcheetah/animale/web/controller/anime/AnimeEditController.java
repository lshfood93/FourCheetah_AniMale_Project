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
public class AnimeEditController {

    @Autowired
    private AnimeService animeService;

    @Value("${app.upload.anime-dir:uploads/anime}")
    private String animeUploadDir;

    @Value("${app.upload.anime-url-prefix:/upload/anime}")
    private String animeUrlPrefix;
    
    @GetMapping("/animeEditPage")
    public String animeEditPage(
            AnimeDTO dto,          // 커맨드객체 바인딩 (animeId 자동 세팅)
            HttpSession session,
            Model model
    ) {

        // 1) 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            System.out.println("[애니 수정 이동 로그] 세션 없음 또는 memberId 유효하지 않음");
            model.addAttribute("msg", "잘못된 접근입니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 2) 관리자 권한 체크
        Object roleObj = session.getAttribute("memberRole");
        String memberRole = (roleObj == null) ? "" : roleObj.toString();
        System.out.println("[애니 수정 이동 로그] 로그인 유저 ROLE : memberRole [" + memberRole + "]");

        if (!"ADMIN".equalsIgnoreCase(memberRole)) {
            System.out.println("[애니 수정 이동 로그] 관리자 권한 없음 : [" + memberRole + "]");
            model.addAttribute("msg", "관리자만 접근할 수 있습니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 3) animeId 검증 (DTO에서 꺼내기)
        int animeId = dto.getAnimeId();
        System.out.println("[애니 수정 이동 로그] 애니 PK 검사 : animeId [" + animeId + "]");

        if (animeId <= 0) {
            model.addAttribute("msg", "잘못된 애니 접근입니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 4) 조회 (DTO 재활용)
        dto.setCondition("ANIME_DETAIL");
        AnimeDTO animeData = animeService.selectOne(dto);
        System.out.println("[애니 수정 이동 로그] 애니 조회 완료 : animeData = [" + animeData + "]");

        // 5) 존재여부 검사
        if (animeData == null) {
            model.addAttribute("msg", "존재하지 않는 애니입니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 6) 수정 페이지 forward
        model.addAttribute("animeData", animeData);
        return "animeedit";
    }

    // 커맨드객체(AnimeDTO)로 통일: /animeEdit?animeId=...
    @PostMapping("/animeEdit")
    public String editAnime(
            AnimeDTO dto,                 // 커맨드객체 바인딩
            BindingResult br,              // 타입 변환 오류 등 받기용(선택)
            HttpSession session,
            RedirectAttributes ra
    ) {
        // 0) 로그인 체크
        Object memberId = (session == null) ? null : session.getAttribute("memberId");
        if (memberId == null) {
            return "redirect:/loginPage";
        }

        int animeId = dto.getAnimeId();

        // 0-1) 관리자 체크
        Object roleObj = session.getAttribute("memberRole");
        String role = (roleObj == null) ? "" : roleObj.toString();
        if (!"ADMIN".equalsIgnoreCase(role)) {
            ra.addAttribute("animeId", animeId);
            ra.addFlashAttribute("msg", "권한이 없습니다.");
            return "redirect:/animeDetail";
        }

        // 0-2) 바인딩/타입변환 오류(예: animeYear에 문자가 들어온 경우)
        if (br.hasErrors()) {
            ra.addAttribute("animeId", animeId);
            ra.addFlashAttribute("msg", "입력값 형식이 올바르지 않습니다.");
            return "redirect:/animeEditPage";
        }

        // 1) PK 검증
        if (animeId <= 0) {
            ra.addFlashAttribute("msg", "잘못된 요청입니다.");
            return "redirect:/animeList";
        }

        // 2) 필수값 체크(최소)
        if (dto.getAnimeTitle() == null || dto.getAnimeTitle().trim().isEmpty()) {
            ra.addAttribute("animeId", animeId);
            ra.addFlashAttribute("msg", "제목은 필수입니다.");
            return "redirect:/animeEditPage";
        }

        // 3) 썸네일 기본은 기존값 유지 (hidden 값)
        // 폼에서 existingThumbUrl 이라는 name으로 넘어온다고 가정
        String thumbnailUrl = (dto.getExistingThumbUrl() == null) ? null : dto.getExistingThumbUrl().trim();

        // 4) 새 파일이 들어오면 저장하고 URL 갱신
        MultipartFile thumbFile = dto.getThumbFile();
        if (thumbFile != null && !thumbFile.isEmpty()) {
            try {
                String originalName = thumbFile.getOriginalFilename();
                String ext = extractExtLower(originalName);

                if (!(ext.equals(".jpg") || ext.equals(".jpeg") || ext.equals(".png") || ext.equals(".webp"))) {
                    ra.addAttribute("animeId", animeId);
                    ra.addFlashAttribute("msg", "이미지 파일(jpg, jpeg, png, webp)만 업로드 가능합니다.");
                    return "redirect:/animeEditPage";
                }

                String savedName = UUID.randomUUID().toString().replace("-", "") + ext;

                Path dir = Paths.get(animeUploadDir).toAbsolutePath().normalize();
                Files.createDirectories(dir);

                Path target = dir.resolve(savedName);
                thumbFile.transferTo(target.toFile());

                thumbnailUrl = animeUrlPrefix + "/" + savedName;

            } catch (Exception e) {
                e.printStackTrace();
                ra.addAttribute("animeId", animeId);
                ra.addFlashAttribute("msg", "썸네일 업로드 중 오류가 발생했습니다.");
                return "redirect:/animeEditPage";
            }
        }

        // 5) 업데이트 (컨디션은 서버에서 세팅)
        dto.setAnimeId(animeId);
        dto.setAnimeTitle(dto.getAnimeTitle().trim());
        dto.setAnimeThumbnailUrl(thumbnailUrl);
        dto.setCondition("ANIME_UPDATE");

        boolean ok = animeService.updateAnime(dto);

        ra.addAttribute("animeId", animeId);
        if (!ok) {
            ra.addFlashAttribute("msg", "수정에 실패했습니다. (대상 없음 또는 처리 실패)");
            return "redirect:/animeDetail";
        }

        return "redirect:/animeDetail";
    }

    private String extractExtLower(String filename) {
        if (filename == null) return "";
        int dot = filename.lastIndexOf('.');
        if (dot == -1) return "";
        return filename.substring(dot).toLowerCase();
    }
}
