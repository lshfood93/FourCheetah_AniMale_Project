package fourcheetah.animale.web.repository.anime;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collections;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.anime.AnimeDTO;

@Repository
public class AnimeDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /* =========================
       SELECT_ALL (컨디션 분기)
       ========================= */

    // MAIN_ANIMELIST : 메인 최근 애니 12개
    private static final String SELECT_MAIN_ANIMELIST =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL " +
            "FROM ANIME " +
            "ORDER BY anime_id DESC " +
            "LIMIT 12";

    // ANIME_LIST_RECENT : 전체(최신등록순)
    private static final String SELECT_ANIME_LIST_RECENT =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL " +
            "FROM ANIME " +
            "ORDER BY anime_id DESC";

    // ANIME_LIST_TITLE : 전체(제목 가나다순)
    private static final String SELECT_ANIME_LIST_TITLE =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL " +
            "FROM ANIME " +
            "ORDER BY anime_title ASC, anime_id DESC";

    // ANIME_LIST_YEAR : 전체(방영년도별, NULL은 뒤로)  -> MySQL NULLS LAST 대응
    private static final String SELECT_ANIME_LIST_YEAR =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL " +
            "FROM ANIME " +
            "ORDER BY (anime_year IS NULL) ASC, anime_year DESC, anime_id DESC";

    // ANIME_SEARCH_TITLE : 제목 검색
    private static final String SELECT_ANIME_SEARCH_TITLE =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL " +
            "FROM ANIME " +
            "WHERE anime_title LIKE ? " +
            "ORDER BY anime_id DESC";

    // ANIME_SEARCH_STORY : 줄거리 검색 (Oracle DBMS_LOB.INSTR -> MySQL INSTR)
    private static final String SELECT_ANIME_SEARCH_STORY =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL " +
            "FROM ANIME " +
            "WHERE INSTR(anime_story, ?) > 0 " +
            "ORDER BY anime_id DESC";

    /* =========================
       PAGE 전용 (MySQL LIMIT)
       - offset = startRow - 1
       - rows   = endRow - startRow + 1
       ========================= */

    // PAGE 공통
    private static final String SELECT_ANIME_LIST_PAGE_BASE =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL " +
            "FROM ANIME %s " +
            "LIMIT ?, ?";

    // PAGE + 제목 검색
    private static final String SELECT_ANIME_LIST_PAGE_TITLE =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL " +
            "FROM ANIME " +
            "WHERE anime_title LIKE ? %s " +
            "LIMIT ?, ?";

    // PAGE + 줄거리 검색
    private static final String SELECT_ANIME_LIST_PAGE_STORY =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL " +
            "FROM ANIME " +
            "WHERE INSTR(anime_story, ?) > 0 %s " +
            "LIMIT ?, ?";

    /* =========================
       SELECT_ONE
       ========================= */

    // ANIME_DETAIL : 상세보기 (최프로 ERD 반영: genres/tags 포함)
    private static final String SELECT_ANIME_DETAIL =
            "SELECT " +
            "  anime_id            AS ANIME_ID, " +
            "  anime_title         AS ANIME_TITLE, " +
            "  original_title      AS ORIGINAL_TITLE, " +
            "  anime_year          AS ANIME_YEAR, " +
            "  anime_quarter       AS ANIME_QUARTER, " +
            "  anime_story         AS ANIME_STORY, " +
            "  anime_thumbnail_url AS ANIME_THUMBNAIL_URL, " +
            "  anime_genres        AS ANIME_GENRES, " +
            "  anime_tags          AS ANIME_TAGS " +
            "FROM ANIME " +
            "WHERE anime_id = ?";

    /* =========================
       INSERT / UPDATE / DELETE
       (MySQL: AUTO_INCREMENT라 anime_id/SEQ 없음)
       ========================= */

    // 애니 추가(관리자)
    private static final String INSERT_ANIME =
            "INSERT INTO ANIME (anime_title, original_title, anime_year, anime_quarter, anime_story, anime_thumbnail_url, anime_genres, anime_tags) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

    // 애니 수정(관리자)
    private static final String UPDATE_ANIME =
            "UPDATE ANIME " +
            "SET anime_title=?, original_title=?, anime_year=?, anime_quarter=?, anime_story=?, anime_thumbnail_url=?, anime_genres=?, anime_tags=? " +
            "WHERE anime_id=?";

    // 애니 삭제(관리자)
    private static final String DELETE_ANIME =
            "DELETE FROM ANIME WHERE anime_id=?";

    /* =========================
       COUNT
       ========================= */
    private static final String SELECT_ANIME_COUNT_RECENT = "SELECT COUNT(*) CNT FROM ANIME";
    private static final String SELECT_ANIME_COUNT_TITLE  = "SELECT COUNT(*) CNT FROM ANIME WHERE anime_title LIKE ?";
    private static final String SELECT_ANIME_COUNT_STORY  = "SELECT COUNT(*) CNT FROM ANIME WHERE INSTR(anime_story, ?) > 0";

    /* =========================
       SELECT_ALL (컨디션 분기 실행)
       ========================= */
    public List<AnimeDTO> selectAll(AnimeDTO dto) {
        if (dto == null) return Collections.emptyList();

        String condition = dto.getCondition();

        try {
            if ("MAIN_ANIMELIST".equals(condition)) {
                return jdbcTemplate.query(SELECT_MAIN_ANIMELIST, new AnimeListRowMapper());
            }
            if ("ANIME_LIST_RECENT".equals(condition)) {
                return jdbcTemplate.query(SELECT_ANIME_LIST_RECENT, new AnimeListRowMapper());
            }
            if ("ANIME_LIST_TITLE".equals(condition)) {
                return jdbcTemplate.query(SELECT_ANIME_LIST_TITLE, new AnimeListRowMapper());
            }
            if ("ANIME_LIST_YEAR".equals(condition)) {
                return jdbcTemplate.query(SELECT_ANIME_LIST_YEAR, new AnimeListRowMapper());
            }
            if ("ANIME_SEARCH_TITLE".equals(condition)) {
                String like = "%" + safeKeyword(dto.getKeyword()) + "%";
                return jdbcTemplate.query(SELECT_ANIME_SEARCH_TITLE, new AnimeListRowMapper(), like);
            }
            if ("ANIME_SEARCH_STORY".equals(condition)) {
                String keyword = safeKeyword(dto.getKeyword());
                return jdbcTemplate.query(SELECT_ANIME_SEARCH_STORY, new AnimeListRowMapper(), keyword);
            }

            // 페이징 3종
            int offset = calcOffset(dto);
            int rows   = calcRows(dto);
            if (rows <= 0) return Collections.emptyList();

            if ("ANIME_LIST_PAGE_RECENT".equals(condition)) {
                String sql = String.format(SELECT_ANIME_LIST_PAGE_BASE, getOrderBy(dto.getSort()));
                return jdbcTemplate.query(sql, new AnimeListRowMapper(), offset, rows);
            }
            if ("ANIME_LIST_PAGE_TITLE".equals(condition)) {
                String sql = String.format(SELECT_ANIME_LIST_PAGE_TITLE, getOrderBy(dto.getSort()));
                String like = "%" + safeKeyword(dto.getKeyword()) + "%";
                return jdbcTemplate.query(sql, new AnimeListRowMapper(), like, offset, rows);
            }
            if ("ANIME_LIST_PAGE_STORY".equals(condition)) {
                String sql = String.format(SELECT_ANIME_LIST_PAGE_STORY, getOrderBy(dto.getSort()));
                String keyword = safeKeyword(dto.getKeyword());
                return jdbcTemplate.query(sql, new AnimeListRowMapper(), keyword, offset, rows);
            }

            return Collections.emptyList();
        } catch (Exception e) {
            e.printStackTrace();
            return Collections.emptyList();
        }
    }

    /* =========================
       SELECT_ONE
       ========================= */
    public AnimeDTO selectOne(AnimeDTO dto) {
        if (dto == null) return null;

        String condition = dto.getCondition();

        try {
            if ("ANIME_DETAIL".equals(condition)) {
                return jdbcTemplate.queryForObject(
                        SELECT_ANIME_DETAIL,
                        new AnimeDetailRowMapper(),
                        dto.getAnimeId()
                );
            }

            // COUNT 3종: dto에 animeCount만 담아서 반환
            if ("ANIME_COUNT_RECENT".equals(condition)) {
                Integer cnt = jdbcTemplate.queryForObject(SELECT_ANIME_COUNT_RECENT, Integer.class);
                AnimeDTO data = new AnimeDTO();
                data.setAnimeCount(cnt == null ? 0 : cnt);
                return data;
            }
            if ("ANIME_COUNT_TITLE".equals(condition)) {
                String like = "%" + safeKeyword(dto.getKeyword()) + "%";
                Integer cnt = jdbcTemplate.queryForObject(SELECT_ANIME_COUNT_TITLE, Integer.class, like);
                AnimeDTO data = new AnimeDTO();
                data.setAnimeCount(cnt == null ? 0 : cnt);
                return data;
            }
            if ("ANIME_COUNT_STORY".equals(condition)) {
                String keyword = safeKeyword(dto.getKeyword());
                Integer cnt = jdbcTemplate.queryForObject(SELECT_ANIME_COUNT_STORY, Integer.class, keyword);
                AnimeDTO data = new AnimeDTO();
                data.setAnimeCount(cnt == null ? 0 : cnt);
                return data;
            }

            return null;

        } catch (EmptyResultDataAccessException e) {
            return null;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /* =========================
       INSERT / UPDATE / DELETE
       ========================= */

    public boolean insert(AnimeDTO dto) {
        if (dto == null) return false;
        if (!"ANIME_INSERT".equals(dto.getCondition())) return false;

        try {
            int result = jdbcTemplate.update(
                    INSERT_ANIME,
                    dto.getAnimeTitle(),
                    dto.getOriginalTitle(),
                    dto.getAnimeYear(),        // Integer null 가능
                    dto.getAnimeQuarter(),
                    dto.getAnimeStory(),
                    dto.getAnimeThumbnailUrl(),
                    dto.getAnimeGenres(),      // JSON 문자열 또는 null
                    dto.getAnimeTags()         // JSON 문자열 또는 null
            );
            return result > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean update(AnimeDTO dto) {
        if (dto == null) return false;
        if (!"ANIME_UPDATE".equals(dto.getCondition())) return false;

        try {
            int result = jdbcTemplate.update(
                    UPDATE_ANIME,
                    dto.getAnimeTitle(),
                    dto.getOriginalTitle(),
                    dto.getAnimeYear(),
                    dto.getAnimeQuarter(),
                    dto.getAnimeStory(),
                    dto.getAnimeThumbnailUrl(),
                    dto.getAnimeGenres(),
                    dto.getAnimeTags(),
                    dto.getAnimeId()
            );
            return result > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean delete(AnimeDTO dto) {
        if (dto == null) return false;
        if (!"ANIME_DELETE".equals(dto.getCondition())) return false;

        try {
            int result = jdbcTemplate.update(DELETE_ANIME, dto.getAnimeId());
            return result > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /* =========================
       공통 유틸
       ========================= */

    // 정렬 기준(페이징에서만 사용)
    private String getOrderBy(String sort) {
        if ("OLDEST".equals(sort)) {
            return "ORDER BY anime_id ASC";
        }
        if ("TITLE".equals(sort)) {
            return "ORDER BY anime_title ASC, anime_id DESC";
        }
        return "ORDER BY anime_id DESC";
    }

    private String safeKeyword(String keyword) {
        return keyword == null ? "" : keyword.trim();
    }

    // startRow/endRow -> MySQL LIMIT용 offset/rows
    private int calcOffset(AnimeDTO dto) {
        int startRow = dto.getStartRow();
        return Math.max(startRow - 1, 0);
    }

    private int calcRows(AnimeDTO dto) {
        int rows = dto.getEndRow() - dto.getStartRow() + 1;
        return Math.max(rows, 0);
    }
}

/* =========================
   RowMapper (파일 하단 분리)
   - PlusBoardDAO 스타일: 필요할 때마다 new 해서 사용
   ========================= */

// 리스트용 RowMapper
class AnimeListRowMapper implements RowMapper<AnimeDTO> {

    @Override
    public AnimeDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
        AnimeDTO data = new AnimeDTO();
        data.setAnimeId(rs.getInt("ANIME_ID"));
        data.setAnimeTitle(rs.getString("ANIME_TITLE"));
        data.setAnimeYear(getIntOrNull(rs, "ANIME_YEAR"));
        data.setAnimeQuarter(rs.getString("ANIME_QUARTER"));
        data.setAnimeThumbnailUrl(rs.getString("ANIME_THUMBNAIL_URL"));
        return data;
    }

    private Integer getIntOrNull(ResultSet rs, String colName) throws SQLException {
        Object obj = rs.getObject(colName);
        if (obj == null) return null;
        return ((Number) obj).intValue();
    }
}

// 상세용 RowMapper
class AnimeDetailRowMapper implements RowMapper<AnimeDTO> {

    @Override
    public AnimeDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
        AnimeDTO data = new AnimeDTO();
        data.setAnimeId(rs.getInt("ANIME_ID"));
        data.setAnimeTitle(rs.getString("ANIME_TITLE"));
        data.setOriginalTitle(rs.getString("ORIGINAL_TITLE"));
        data.setAnimeYear(getIntOrNull(rs, "ANIME_YEAR"));
        data.setAnimeQuarter(rs.getString("ANIME_QUARTER"));
        data.setAnimeStory(rs.getString("ANIME_STORY"));
        data.setAnimeThumbnailUrl(rs.getString("ANIME_THUMBNAIL_URL"));
        data.setAnimeGenres(rs.getString("ANIME_GENRES"));
        data.setAnimeTags(rs.getString("ANIME_TAGS"));
        return data;
    }

    private Integer getIntOrNull(ResultSet rs, String colName) throws SQLException {
        Object obj = rs.getObject(colName);
        if (obj == null) return null;
        return ((Number) obj).intValue();
    }
}
