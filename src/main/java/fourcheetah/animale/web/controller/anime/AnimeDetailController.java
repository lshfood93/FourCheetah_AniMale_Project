package fourcheetah.animale.web.controller.anime;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.service.anime.AnimeService;

@Controller
public class AnimeDetailController {

    private final AnimeService animeService;

    public AnimeDetailController(AnimeService animeService) {
        this.animeService = animeService;
    }

    /*
     * 변경 포인트
     * - 요청: /animeDetail?animeId=1
     * - 수신: 커맨드객체(AnimeDTO) 바인딩으로 animeId 자동 세팅
     */
    @GetMapping("/animeDetail")
    public String execute(AnimeDTO dto, Model model) {

        model.addAttribute("activeMenu", "ANILIST");

        // 1) animeId 검증 (커맨드객체로 받은 값)
        int animeId = dto.getAnimeId();

        if (animeId <= 0) {
            System.out.println("[애니 상세보기 로그] 조회 실패 : animeId 유효하지 않음");
            model.addAttribute("msg", "잘못된 애니 선택입니다...");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 2) selectOne
        dto.setCondition("ANIME_DETAIL");
        System.out.println("[애니 상세 로그] param animeId = [" + animeId + "]");

        AnimeDTO animeData = animeService.getAnime(dto);

        System.out.println("[애니 상세 로그] selectOne result = " + animeData);

        // 3) 존재여부 검사
        if (animeData == null) {
            System.out.println("[애니 상세보기 로그] 조회 실패 : 해당 애니는 없는 애니");
            model.addAttribute("msg", "잘못된 애니 선택입니다...");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 4) 썸네일 경로 보정
        String thumb = animeData.getAnimeThumbnailUrl();
        if (thumb != null && !thumb.startsWith("/")) {
            animeData.setAnimeThumbnailUrl("/" + thumb);
        }

        System.out.println("[애니 상세보기 로그] 조회 완료 : animeData = [" + animeData + "]");

        // 5) 결과 담아서 페이지 전달
        model.addAttribute("animeData", animeData);
        return "animedetail";
    }
}
