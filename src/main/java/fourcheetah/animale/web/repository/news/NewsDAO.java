package fourcheetah.animale.web.repository.news;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collections;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.news.NewsDTO;

/**
 * 뉴스 DAO (Spring Boot + JdbcTemplate + MySQL 버전)
 * 
 * 개선사항:
 * - RowMapper를 파일 하단 독립 클래스로 분리
 * - 재사용성 및 가독성 향상
 * - 각 RowMapper가 독립적으로 존재
 */
@Repository
public class NewsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /* SELECT 쿼리 상수 (SQL 모음) */

    // 메인 배너용: 최근 뉴스 3개
    private static final String SELECT_MAIN_BANNER_NEWSLIST =
        "SELECT NEWS_ID, NEWS_TITLE, NEWS_THUMBNAIL_URL " +
        "FROM NEWS " +
        "ORDER BY NEWS_ID DESC " +
        "LIMIT 3";

    // 뉴스 전체 목록 (정렬순)
    private static final String SELECT_NEWS_LIST =
        "SELECT NEWS_ID, NEWS_TITLE, NEWS_THUMBNAIL_URL " +
        "FROM NEWS " +
        "ORDER BY NEWS_ID DESC";

    // 제목 검색
    private static final String SELECT_NEWS_SEARCH_TITLE =
        "SELECT NEWS_ID, NEWS_TITLE, NEWS_THUMBNAIL_URL " +
        "FROM NEWS " +
        "WHERE NEWS_TITLE LIKE ? " +
        "ORDER BY NEWS_ID DESC";

    // 내용 검색 (LONGTEXT도 LIKE 사용)
    private static final String SELECT_NEWS_SEARCH_CONTENT =
        "SELECT NEWS_ID, NEWS_TITLE, NEWS_THUMBNAIL_URL " +
        "FROM NEWS " +
        "WHERE NEWS_CONTENT LIKE ? " +
        "ORDER BY NEWS_ID DESC";

    // 페이징 (정렬순)
    private static final String SELECT_NEWS_LIST_PAGE =
        "SELECT NEWS_ID, NEWS_TITLE, NEWS_THUMBNAIL_URL " +
        "FROM NEWS " +
        "ORDER BY NEWS_ID DESC " +
        "LIMIT ? OFFSET ?";

    // 페이징 + 제목 검색
    private static final String SELECT_NEWS_LIST_PAGE_TITLE =
        "SELECT NEWS_ID, NEWS_TITLE, NEWS_THUMBNAIL_URL " +
        "FROM NEWS " +
        "WHERE NEWS_TITLE LIKE ? " +
        "ORDER BY NEWS_ID DESC " +
        "LIMIT ? OFFSET ?";

    // 페이징 + 내용 검색
    private static final String SELECT_NEWS_LIST_PAGE_CONTENT =
        "SELECT NEWS_ID, NEWS_TITLE, NEWS_THUMBNAIL_URL " +
        "FROM NEWS " +
        "WHERE NEWS_CONTENT LIKE ? " +
        "ORDER BY NEWS_ID DESC " +
        "LIMIT ? OFFSET ?";

    // 뉴스 상세 (애니 JOIN)
    private static final String SELECT_NEWS_DETAIL =
        "SELECT " +
        "    N.NEWS_ID, " +
        "    N.ANIME_ID, " +
        "    N.NEWS_TITLE, " +
        "    N.NEWS_CONTENT, " +
        "    N.NEWS_IMAGE_URL, " +
        "    N.NEWS_THUMBNAIL_URL, " +
        "    A.ANIME_TITLE, " +
        "    A.ANIME_YEAR, " +
        "    A.ANIME_QUARTER, " +
        "    A.ANIME_THUMBNAIL_URL AS ANIME_THUMBNAIL_URL " +
        "FROM NEWS N " +
        "LEFT JOIN ANIME A ON A.ANIME_ID = N.ANIME_ID " +
        "WHERE N.NEWS_ID = ?";

    // 뉴스 개수 (전체)
    private static final String SELECT_NEWS_COUNT =
        "SELECT COUNT(*) FROM NEWS";

    // 뉴스 개수 (제목 검색)
    private static final String SELECT_NEWS_COUNT_TITLE =
        "SELECT COUNT(*) FROM NEWS WHERE NEWS_TITLE LIKE ?";

    // 뉴스 개수 (내용 검색)
    private static final String SELECT_NEWS_COUNT_CONTENT =
        "SELECT COUNT(*) FROM NEWS WHERE NEWS_CONTENT LIKE ?";

    // INSERT (AUTO_INCREMENT 사용)
    private static final String INSERT_NEWS =
        "INSERT INTO NEWS (ANIME_ID, NEWS_TITLE, NEWS_CONTENT, NEWS_IMAGE_URL, NEWS_THUMBNAIL_URL) " +
        "VALUES (?, ?, ?, ?, ?)";

    // UPDATE
    private static final String UPDATE_NEWS =
        "UPDATE NEWS " +
        "SET ANIME_ID = ?, NEWS_TITLE = ?, NEWS_CONTENT = ?, NEWS_IMAGE_URL = ?, NEWS_THUMBNAIL_URL = ? " +
        "WHERE NEWS_ID = ?";

    // DELETE
    private static final String DELETE_NEWS =
        "DELETE FROM NEWS WHERE NEWS_ID = ?";

    /* SELECT_ALL (리스트 조회) */

    public List<NewsDTO> selectAll(NewsDTO dto) {
        if (dto == null) return Collections.emptyList();

        String condition = dto.getCondition();

        try {
            // 메인 배너: 최근 3개
            if ("MAIN_BANNER_NEWSLIST".equals(condition)) {
                return jdbcTemplate.query(SELECT_MAIN_BANNER_NEWSLIST, new NewsListRowMapper());
            }

            // 전체 목록
            if ("NEWS_LIST".equals(condition)) {
                return jdbcTemplate.query(SELECT_NEWS_LIST, new NewsListRowMapper());
            }

            // 제목 검색 (페이징 없음)
            if ("NEWS_SEARCH_TITLE".equals(condition)) {
                String keyword = "%" + safeKeyword(dto.getKeyword()) + "%";
                return jdbcTemplate.query(SELECT_NEWS_SEARCH_TITLE, new NewsListRowMapper(), keyword);
            }

            // 내용 검색 (페이징 없음)
            if ("NEWS_SEARCH_CONTENT".equals(condition)) {
                String keyword = "%" + safeKeyword(dto.getKeyword()) + "%";
                return jdbcTemplate.query(SELECT_NEWS_SEARCH_CONTENT, new NewsListRowMapper(), keyword);
            }

            // 페이징 (정렬순)
            if ("NEWS_LIST_PAGE".equals(condition)) {
                int listSize = dto.getListSize();
                int startNum = dto.getStartNum();
                
                // 음수 방지
                if (startNum < 0) startNum = 0;
                if (listSize <= 0) listSize = 12;
                
                return jdbcTemplate.query(SELECT_NEWS_LIST_PAGE, new NewsListRowMapper(), listSize, startNum);
            }

            // 페이징 + 제목 검색
            if ("NEWS_LIST_PAGE_TITLE".equals(condition)) {
                String keyword = "%" + safeKeyword(dto.getKeyword()) + "%";
                int limit = dto.getEndRow() - dto.getStartRow() + 1;
                int offset = dto.getStartRow() - 1;
                return jdbcTemplate.query(SELECT_NEWS_LIST_PAGE_TITLE, new NewsListRowMapper(), keyword, limit, offset);
            }

            // 페이징 + 내용 검색
            if ("NEWS_LIST_PAGE_CONTENT".equals(condition)) {
                String keyword = "%" + safeKeyword(dto.getKeyword()) + "%";
                int limit = dto.getEndRow() - dto.getStartRow() + 1;
                int offset = dto.getStartRow() - 1;
                return jdbcTemplate.query(SELECT_NEWS_LIST_PAGE_CONTENT, new NewsListRowMapper(), keyword, limit, offset);
            }

            return Collections.emptyList();

        } catch (Exception e) {
            e.printStackTrace();
            return Collections.emptyList();
        }
    }

    /* SELECT_ONE (단건 조회) */

    public NewsDTO selectOne(NewsDTO dto) {
        if (dto == null) return null;

        String condition = dto.getCondition();

        try {
            // 상세보기 (NEWS_DETAIL)
            if ("NEWS_DETAIL".equals(condition)) {
                return jdbcTemplate.queryForObject(
                    SELECT_NEWS_DETAIL,
                    new NewsDetailRowMapper(),
                    dto.getNewsId()
                );
            }

            // COUNT 전체
            if ("NEWS_COUNT".equals(condition)) {
                Integer count = jdbcTemplate.queryForObject(SELECT_NEWS_COUNT, Integer.class);
                NewsDTO data = new NewsDTO();
                data.setNewsCount(count != null ? count : 0);
                return data;
            }

            // COUNT 제목 검색
            if ("NEWS_COUNT_TITLE".equals(condition)) {
                String keyword = "%" + safeKeyword(dto.getKeyword()) + "%";
                Integer count = jdbcTemplate.queryForObject(SELECT_NEWS_COUNT_TITLE, Integer.class, keyword);
                NewsDTO data = new NewsDTO();
                data.setNewsCount(count != null ? count : 0);
                return data;
            }

            // COUNT 내용 검색
            if ("NEWS_COUNT_CONTENT".equals(condition)) {
                String keyword = "%" + safeKeyword(dto.getKeyword()) + "%";
                Integer count = jdbcTemplate.queryForObject(SELECT_NEWS_COUNT_CONTENT, Integer.class, keyword);
                NewsDTO data = new NewsDTO();
                data.setNewsCount(count != null ? count : 0);
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

    /* INSERT */

    public boolean insert(NewsDTO dto) {
        if (dto == null) return false;
        if (!"NEWS_INSERT".equals(dto.getCondition())) return false;

        try {
            int result = jdbcTemplate.update(
                INSERT_NEWS,
                dto.getAnimeId(),
                dto.getNewsTitle(),
                dto.getNewsContent(),
                dto.getNewsImageUrl(),
                dto.getNewsThumbnailUrl()
            );

            if (result > 0) {
                // INSERT 후 방금 추가된 뉴스의 ID를 재조회
                String selectSql = "SELECT NEWS_ID FROM NEWS WHERE NEWS_TITLE = ? ORDER BY NEWS_ID DESC LIMIT 1";
                Integer newsId = jdbcTemplate.queryForObject(selectSql, Integer.class, dto.getNewsTitle());
                
                if (newsId != null) {
                    dto.setNewsId(newsId);
                    System.out.println("[로그] NewsDAO insert: newsId = " + dto.getNewsId());
                    return true;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    /* UPDATE */

    public boolean update(NewsDTO dto) {
        if (dto == null) return false;
        if (!"NEWS_UPDATE".equals(dto.getCondition())) return false;

        try {
            int result = jdbcTemplate.update(
                UPDATE_NEWS,
                dto.getAnimeId(),
                dto.getNewsTitle(),
                dto.getNewsContent(),
                dto.getNewsImageUrl(),
                dto.getNewsThumbnailUrl(),
                dto.getNewsId()
            );
            return result > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /* DELETE */

    public boolean delete(NewsDTO dto) {
        if (dto == null) return false;
        if (!"NEWS_DELETE".equals(dto.getCondition())) return false;

        try {
            int result = jdbcTemplate.update(DELETE_NEWS, dto.getNewsId());
            return result > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /* 유틸리티 메서드 */

    private String safeKeyword(String keyword) {
        return (keyword == null) ? "" : keyword.trim();
    }
}

/* RowMapper 클래스 (파일 하단 분리)
   - AnimeDAO 스타일: 파일 밖에 독립적으로 정의
   - 재사용성 높음 */

/**
 * 뉴스 목록용 RowMapper
 * 
 * 역할: DB의 ResultSet을 NewsDTO로 변환
 * 필드: NEWS_ID, NEWS_TITLE, NEWS_THUMBNAIL_URL만 필요
 * 
 * 예시:
 * SELECT NEWS_ID, NEWS_TITLE, NEWS_THUMBNAIL_URL FROM NEWS...
 *         ↓
 *   NewsListRowMapper 변환
 *         ↓
 *   NewsDTO (newsId, newsTitle, newsThumbnailUrl)
 */
class NewsListRowMapper implements RowMapper<NewsDTO> {

    @Override
    public NewsDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
        NewsDTO data = new NewsDTO();
        data.setNewsId(rs.getInt("NEWS_ID"));
        data.setNewsTitle(rs.getString("NEWS_TITLE"));
        data.setNewsThumbnailUrl(rs.getString("NEWS_THUMBNAIL_URL"));
        return data;
    }
}

/**
 * 뉴스 상세용 RowMapper (ANIME JOIN)
 * 
 * 역할: DB의 ResultSet을 NewsDTO로 변환 (상세 정보 + 애니 정보 포함)
 * 필드: 뉴스 전체 + ANIME 정보
 * 
 * 예시:
 * SELECT N.NEWS_ID, N.NEWS_TITLE, N.NEWS_CONTENT, A.ANIME_TITLE... FROM NEWS N LEFT JOIN ANIME A...
 *         ↓
 *   NewsDetailRowMapper 변환
 *         ↓
 *   NewsDTO (뉴스 정보 + 애니 정보)
 */
class NewsDetailRowMapper implements RowMapper<NewsDTO> {

    @Override
    public NewsDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
        NewsDTO data = new NewsDTO();
        
        // ===== NEWS 테이블 기본 정보 =====
        data.setNewsId(rs.getInt("NEWS_ID"));
        data.setNewsTitle(rs.getString("NEWS_TITLE"));
        data.setNewsContent(rs.getString("NEWS_CONTENT"));           // LONGTEXT → String 자동 변환
        data.setNewsImageUrl(rs.getString("NEWS_IMAGE_URL"));
        data.setNewsThumbnailUrl(rs.getString("NEWS_THUMBNAIL_URL"));
        
        // ===== FK (NULL 가능) =====
        data.setAnimeId(getIntOrNull(rs, "ANIME_ID"));
        
        // ===== JOIN 결과 (ANIME 테이블 정보) =====
        data.setAnimeTitle(rs.getString("ANIME_TITLE"));
        data.setAnimeYear(getIntOrNull(rs, "ANIME_YEAR"));
        data.setAnimeQuarter(rs.getString("ANIME_QUARTER"));
        data.setAnimeThumbnailUrl(rs.getString("ANIME_THUMBNAIL_URL"));
        
        return data;
    }

    // NULL 값 안전하게 처리하는 유틸 메서드
    private Integer getIntOrNull(ResultSet rs, String colName) throws SQLException {
        Object obj = rs.getObject(colName);
        if (obj == null) return null;
        return ((Number) obj).intValue();
    }
}
