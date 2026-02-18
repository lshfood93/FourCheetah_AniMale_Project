package fourcheetah.animale.web.service.ai;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.ai.QuerySpec;

@Service
public class QuerySpecExtractor {

    // 프로젝트에서 쓰는 장르 목록으로 확장하면 됨
    private static final List<String> KNOWN_GENRES = Arrays.asList(
        "판타지","액션","로맨스","코미디","스릴러","공포","SF","일상","스포츠","음악","추리","모험"
    );

    public QuerySpec extract(String userMessage) {
        QuerySpec spec = new QuerySpec();
        spec.setRawUserMessage(userMessage);

        String msg = userMessage == null ? "" : userMessage.trim();

        // 장르 추출(단순 포함 기반)
        List<String> genres = new ArrayList<>();
        for (String g : KNOWN_GENRES) {
            if (msg.contains(g)) genres.add(g);
        }
        spec.setGenres(genres);

        // 키워드(아주 간단 버전)
        List<String> keywords = new ArrayList<>();
        for (String token : msg.split("\\s+")) {
            if (token.length() >= 2 && token.length() <= 10) {
                keywords.add(token);
            }
        }
        spec.setKeywords(keywords);

        return spec;
    }
}
