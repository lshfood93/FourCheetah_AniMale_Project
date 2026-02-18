package fourcheetah.animale.web.controller.news;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.repository.anime.AnimeDAO;

@RestController
public class NewsAnimeSearchController {

    @Autowired
    private AnimeDAO animeDAO;

    @GetMapping("/newsAnimeSearch")
    public List<AnimeDTO> searchAnime(AnimeDTO dto) {

        System.out.println("[뉴스 연관애니 검색] GET 요청");

        String keyword = dto.getKeyword();
        if (keyword == null || keyword.trim().isEmpty()) {
            System.out.println("[뉴스 연관애니 검색] 검색어 없음");
            return List.of();
        }

        dto.setCondition("ANIME_SEARCH_TITLE");
        dto.setKeyword(keyword.trim());

        List<AnimeDTO> animeList = animeDAO.selectAll(dto);
        System.out.println("[뉴스 연관애니 검색] 조회완료 - keyword=[" + dto.getKeyword() + "], count=[" + animeList.size() + "]");

        return animeList;
    }
}
