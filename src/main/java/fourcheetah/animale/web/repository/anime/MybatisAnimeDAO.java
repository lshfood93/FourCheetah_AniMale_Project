package fourcheetah.animale.web.repository.anime;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.ibatis.session.SqlSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.anime.AnimeDTO;

@Repository
public class MybatisAnimeDAO {

    @Autowired
    private SqlSession sqlSession;

    private static final String NAMESPACE = "Anime.";

    public List<AnimeDTO> selectAll(AnimeDTO dto) {
        if (dto == null) return Collections.emptyList();

        String condition = dto.getCondition();

        try {
            if ("MAIN_ANIMELIST".equals(condition)) {
                return sqlSession.selectList(NAMESPACE + "mainAnimeList");
            }
            if ("ANIME_LIST_RECENT".equals(condition)) {
                return sqlSession.selectList(NAMESPACE + "animeListRecent");
            }
            if ("ANIME_LIST_TITLE".equals(condition)) {
                return sqlSession.selectList(NAMESPACE + "animeListTitle");
            }
            if ("ANIME_LIST_YEAR".equals(condition)) {
                return sqlSession.selectList(NAMESPACE + "animeListYear");
            }

            // 검색: mapper가 DTO를 받으므로 dto 통째로 넘김 (LIKE는 SQL에서 CONCAT 처리)
            if ("ANIME_SEARCH_TITLE".equals(condition)) {
                dto.setKeyword(safeKeyword(dto.getKeyword()));
                return sqlSession.selectList(NAMESPACE + "animeSearchTitle", dto);
            }
            if ("ANIME_SEARCH_STORY".equals(condition)) {
                dto.setKeyword(safeKeyword(dto.getKeyword()));
                return sqlSession.selectList(NAMESPACE + "animeSearchStory", dto);
            }

            int offset = calcOffset(dto);
            int rows   = calcRows(dto);
            if (rows <= 0) return Collections.emptyList();

            if ("ANIME_LIST_PAGE_RECENT".equals(condition)) {
                Map<String, Object> param = new HashMap<>();
                param.put("sort", dto.getSort());
                param.put("offset", offset);
                param.put("rows", rows);
                return sqlSession.selectList(NAMESPACE + "animeListPageBase", param);
            }

            // paging title: SQL에서 CONCAT 처리하므로 % 붙이지 않음
            if ("ANIME_LIST_PAGE_TITLE".equals(condition)) {
                Map<String, Object> param = new HashMap<>();
                param.put("sort", dto.getSort());
                param.put("keyword", safeKeyword(dto.getKeyword()));
                param.put("offset", offset);
                param.put("rows", rows);
                return sqlSession.selectList(NAMESPACE + "animeListPageTitle", param);
            }

            if ("ANIME_LIST_PAGE_STORY".equals(condition)) {
                Map<String, Object> param = new HashMap<>();
                param.put("sort", dto.getSort());
                param.put("keyword", safeKeyword(dto.getKeyword()));
                param.put("offset", offset);
                param.put("rows", rows);
                return sqlSession.selectList(NAMESPACE + "animeListPageStory", param);
            }

            return Collections.emptyList();
        } catch (Exception e) {
            e.printStackTrace();
            return Collections.emptyList();
        }
    }

    public AnimeDTO selectOne(AnimeDTO dto) {
        if (dto == null) return null;

        String condition = dto.getCondition();

        try {
            // 상세: mapper가 DTO를 받으므로 dto 통째로 넘김
            if ("ANIME_DETAIL".equals(condition)) {
                return sqlSession.selectOne(NAMESPACE + "animeDetail", dto);
            }

            if ("ANIME_COUNT_RECENT".equals(condition)) {
                Integer cnt = sqlSession.selectOne(NAMESPACE + "animeCountRecent");
                AnimeDTO data = new AnimeDTO();
                data.setAnimeCount(cnt == null ? 0 : cnt);
                return data;
            }

            // count title/story도 mapper가 DTO를 받음
            if ("ANIME_COUNT_TITLE".equals(condition)) {
                dto.setKeyword(safeKeyword(dto.getKeyword()));
                Integer cnt = sqlSession.selectOne(NAMESPACE + "animeCountTitle", dto);

                AnimeDTO data = new AnimeDTO();
                data.setAnimeCount(cnt == null ? 0 : cnt);
                return data;
            }

            if ("ANIME_COUNT_STORY".equals(condition)) {
                dto.setKeyword(safeKeyword(dto.getKeyword()));
                Integer cnt = sqlSession.selectOne(NAMESPACE + "animeCountStory", dto);

                AnimeDTO data = new AnimeDTO();
                data.setAnimeCount(cnt == null ? 0 : cnt);
                return data;
            }

            return null;

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public boolean insert(AnimeDTO dto) {
        if (dto == null) return false;
        if (!"ANIME_INSERT".equals(dto.getCondition())) return false;

        try {
            return sqlSession.insert(NAMESPACE + "insertAnime", dto) > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean update(AnimeDTO dto) {
        if (dto == null) return false;
        if (!"ANIME_UPDATE".equals(dto.getCondition())) return false;

        try {
            return sqlSession.update(NAMESPACE + "updateAnime", dto) > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean delete(AnimeDTO dto) {
        if (dto == null) return false;
        if (!"ANIME_DELETE".equals(dto.getCondition())) return false;

        try {
            // 삭제: mapper가 DTO를 받으므로 dto 통째로 넘김
            return sqlSession.delete(NAMESPACE + "deleteAnime", dto) > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private String safeKeyword(String keyword) {
        return keyword == null ? "" : keyword.trim();
    }

    private int calcOffset(AnimeDTO dto) {
        int startRow = dto.getStartRow();
        return Math.max(startRow - 1, 0);
    }

    private int calcRows(AnimeDTO dto) {
        int rows = dto.getEndRow() - dto.getStartRow() + 1;
        return Math.max(rows, 0);
    }
}
