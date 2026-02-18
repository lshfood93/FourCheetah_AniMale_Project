package fourcheetah.animale.web.controller.anime;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.anime.AnimeDTO;

@Controller
public class AnimeListController {

    @GetMapping("/animeList")
    public String execute(AnimeDTO dto, Model model) {

        model.addAttribute("activeMenu", "ANILIST");

        String condition = dto.getCondition();
        String keyword = dto.getKeyword();

        // 1) 검색 분기값
        System.out.println("[애니리스트 이동 로그] condition : [" + condition + "]");
        System.out.println("[애니리스트 이동 로그] keyword : [" + keyword + "]");

        // 보정: 검색 조건 외 값은 기본 목록
        if (!"ANIME_SEARCH_TITLE".equals(condition) && !"ANIME_SEARCH_STORY".equals(condition)) {
            condition = "ANIME_LIST_RECENT";
        }

        // 2) 검색 여부
        boolean isSearch = "ANIME_SEARCH_TITLE".equals(condition) || "ANIME_SEARCH_STORY".equals(condition);
        System.out.println("[애니리스트 이동 로그] isSearch : [" + isSearch + "]");

        // 3) keyword 정리
        if (keyword != null) {
            keyword = keyword.trim();
        }

        // 4) 검색인데 keyword가 없으면 차단
        if (isSearch && (keyword == null || keyword.isEmpty())) {
            model.addAttribute("msg", "검색어가 없습니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 5) 검색 아닌 경우 빈 문자열이면 null로 정리
        if (!isSearch && keyword != null && keyword.isEmpty()) {
            keyword = null;
        }

        // 6) JSP에 전달 (폼 상태 유지 + JS 비동기 호출 파라미터로 재사용)
        System.out.println("[애니리스트 이동 로그] 최종 condition : [" + condition + "]");
        System.out.println("[애니리스트 이동 로그] 최종 keyword : [" + keyword + "]");

        model.addAttribute("condition", condition);
        model.addAttribute("keyword", keyword);

        return "anime";
    }
}
