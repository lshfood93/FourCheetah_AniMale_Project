package fourcheetah.animale.web.controller.news;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.service.anime.AnimeService;

/**
 * 뉴스 API 컨트롤러
 * 
 * 기능:
 * - 애니 검색: GET /newsAnimeSearch
 * 
 * 통합 이전:
 * - NewsAnimeSearchController
 */
@RestController
public class NewsApiController {

    @Autowired
    private AnimeService animeService;

    /**
     * 뉴스 작성/수정 시 애니메이션 검색 API
     * 
     * GET /newsAnimeSearch?keyword=xxx
     * 
     * @param dto 검색 조건 (keyword)
     * @return 애니메이션 목록 (제목 매칭)
     */
    @GetMapping("/newsAnimeSearch")
    public List<AnimeDTO> searchAnime(AnimeDTO dto) {

        System.out.println("[뉴스 연관애니 검색] GET 요청");

        String keyword = (dto == null) ? null : dto.getKeyword();
        if (keyword == null || keyword.trim().isEmpty()) {
            System.out.println("[뉴스 연관애니 검색] 검색어 없음");
            return List.of();
        }

        // 컨디션/정규화는 컨트롤러가 아닌 서비스로 보내는 게 더 깔끔하지만,
        // 일단은 기존 구조 유지하면서 서비스 호출로만 변경
        dto.setCondition("ANIME_SEARCH_TITLE");
        dto.setKeyword(keyword.trim());

        List<AnimeDTO> animeList = animeService.selectAll(dto);

        System.out.println("[뉴스 연관애니 검색] 조회완료 - keyword=[" + dto.getKeyword()
                + "], count=[" + animeList.size() + "]");

        return animeList;
    }
}