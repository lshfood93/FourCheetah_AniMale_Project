package fourcheetah.animale.web.repository.ai;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import fourcheetah.animale.web.dto.ai.RecommendedAnimeDTO;

@Repository
public class AnimeRepository {

	@Autowired
    private JdbcTemplate jdbcTemplate;
	
    private final ObjectMapper objectMapper = new ObjectMapper();

   

    private final RowMapper<RecommendedAnimeDTO> mapper = (rs, rowNum) -> {
        RecommendedAnimeDTO dto = new RecommendedAnimeDTO();
        dto.setAnimeId(rs.getInt("anime_id"));
        dto.setTitle(rs.getString("anime_title"));
        dto.setThumbnailUrl(rs.getString("anime_thumbnail_url"));

        String genresJson = rs.getString("anime_genres"); // JSON or null
        if (genresJson != null && !genresJson.isBlank()) {
            try {
                dto.setGenres(objectMapper.readValue(genresJson, new TypeReference<List<String>>(){}));
            } catch (Exception e) {
                dto.setGenres(List.of());
            }
        } else {
            dto.setGenres(List.of());
        }
        return dto;
    };

    /**
     * specGenres가 있으면 JSON_OVERLAPS로 교집합 있는 것만 뽑음.
     * excludeIds는 NOT IN으로 제외.
     */
    public List<RecommendedAnimeDTO> findCandidates(List<String> specGenres, Set<Integer> excludeIds, int limit) {

        StringBuilder sql = new StringBuilder();
        List<Object> params = new ArrayList<>();

        sql.append("""
            SELECT anime_id, anime_title, anime_thumbnail_url, anime_genres
            FROM anime
            WHERE 1=1
        """);

        if (specGenres != null && !specGenres.isEmpty()) {
            // MySQL 8: JSON_OVERLAPS(anime_genres, CAST(? AS JSON))
            // param은 예: ["판타지","액션"]
            String jsonArray = toJsonArray(specGenres);
            sql.append(" AND anime_genres IS NOT NULL AND JSON_OVERLAPS(anime_genres, CAST(? AS JSON)) ");
            params.add(jsonArray);
        }

        if (excludeIds != null && !excludeIds.isEmpty()) {
            sql.append(" AND anime_id NOT IN (");
            int i = 0;
            for (Integer id : excludeIds) {
                if (i++ > 0) sql.append(",");
                sql.append("?");
                params.add(id);
            }
            sql.append(") ");
        }

        // 간단 버전: 랜덤 (데이터 커지면 개선 권장)
        sql.append(" ORDER BY RAND() LIMIT ? ");
        params.add(limit);

        return jdbcTemplate.query(sql.toString(), mapper, params.toArray());
    }

    private String toJsonArray(List<String> list) {
        try {
            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            return "[]";
        }
    }
}
