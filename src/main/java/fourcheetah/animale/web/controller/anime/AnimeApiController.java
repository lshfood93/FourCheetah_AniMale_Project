package fourcheetah.animale.web.controller.anime;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.service.anime.AnimeService;

@RestController
public class AnimeApiController {
	
	@Autowired
	private AnimeService animeService;

    @GetMapping(value = "/api/anime", produces = "application/json; charset=UTF-8")
    public Map<String, Object> execute(AnimeDTO dto) { // 커맨드객체 바인딩

        final int listSize = 16;

        // =========================================================
        // 1) 파라미터 수신 + 정리 (DTO에서 꺼냄)
        String page = dto.getPage();          // 신규 추가한 필드
        String condition = dto.getCondition();
        String keyword = dto.getKeyword();
        String sort = dto.getSort();

        // 1-1) page 보정
        int pageNum = 1;
        try {
            if (page != null && !page.trim().isEmpty()) {
                pageNum = Integer.parseInt(page.trim());
            }
        } catch (NumberFormatException e) {
            pageNum = 1;
        }
        if (pageNum < 1) pageNum = 1;

        System.out.println("[애니리스트 데이터 액션 로그] page : [" + pageNum + "]");
        System.out.println("[애니리스트 데이터 액션 로그] condition : [" + condition + "]");

        // 1-2) keyword 보정
        if (keyword != null) {
            keyword = keyword.trim();
            if (keyword.isEmpty()) keyword = null;
        }
        System.out.println("[애니리스트 데이터 액션 로그] keyword : [" + keyword + "]");

        // 1-3) sort 보정
        if (sort != null) sort = sort.trim();
        if (!"RECENT".equals(sort) && !"OLDEST".equals(sort) && !"TITLE".equals(sort)) {
            sort = "RECENT";
        }
        System.out.println("[애니리스트 데이터 액션 로그] sort 보정값 : [" + sort + "]");

        // =========================================================
        // 2) condition → DAO 컨디션 매핑(COUNT/LIST_PAGE)
        String countCondition;
        String listCondition;

        if ("ANIME_SEARCH_TITLE".equals(condition)) {
            countCondition = "ANIME_COUNT_TITLE";
            listCondition  = "ANIME_LIST_PAGE_TITLE";
        } else if ("ANIME_SEARCH_STORY".equals(condition)) {
            countCondition = "ANIME_COUNT_STORY";
            listCondition  = "ANIME_LIST_PAGE_STORY";
        } else {
            condition = "ANIME_LIST_RECENT";
            countCondition = "ANIME_COUNT_RECENT";
            listCondition  = "ANIME_LIST_PAGE_RECENT";
        }

        // =========================================================
        // 3) COUNT 조회
        AnimeDTO countDTO = new AnimeDTO();
        countDTO.setCondition(countCondition);
        countDTO.setKeyword(keyword);

        AnimeDTO countData = animeService.selectOne(countDTO);

        int animeCount = (countData != null) ? countData.getAnimeCount() : 0;
        System.out.println("[애니리스트 데이터 액션 로그] animeCount : [" + animeCount + "]");

        // =========================================================
        // 4) totalPage 계산 + page 상한 보정
        int totalPage = (int) Math.ceil((double) animeCount / listSize);
        if (totalPage < 1) totalPage = 1;
        if (pageNum > totalPage) pageNum = totalPage;

        // =========================================================
        // 5) startRow / endRow
        int startRow = (pageNum - 1) * listSize + 1;
        int endRow = pageNum * listSize;

        // =========================================================
        // 6) LIST_PAGE 조회
        AnimeDTO listDTO = new AnimeDTO();
        listDTO.setCondition(listCondition);
        listDTO.setStartRow(startRow);
        listDTO.setEndRow(endRow);
        listDTO.setKeyword(keyword);
        listDTO.setSort(sort);

        List<AnimeDTO> animeList = animeService.selectAll(listDTO);
        if (animeList == null) animeList = Collections.emptyList();

        // =========================================================
        // 7) 페이지 블록 계산
        int blockSize = 5;
        int startPage = ((pageNum - 1) / blockSize) * blockSize + 1;
        int endPage = Math.min(startPage + blockSize - 1, totalPage);

        boolean hasPrev = startPage > 1;
        boolean hasNext = endPage < totalPage;

        // =========================================================
        // 8) JSON 응답 구성
        Map<String, Object> paging = new HashMap<>();
        paging.put("page", pageNum);
        paging.put("listSize", listSize);
        paging.put("animeCount", animeCount);
        paging.put("totalPage", totalPage);
        paging.put("startPage", startPage);
        paging.put("endPage", endPage);
        paging.put("hasPrev", hasPrev);
        paging.put("hasNext", hasNext);

        paging.put("condition", condition);
        paging.put("keyword", keyword);
        paging.put("sort", sort);

        Map<String, Object> result = new HashMap<>();
        result.put("animeList", animeList);
        result.put("paging", paging);

        return result;
    }

}
