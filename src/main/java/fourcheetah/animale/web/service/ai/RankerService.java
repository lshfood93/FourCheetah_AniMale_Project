package fourcheetah.animale.web.service.ai;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.genai.Client;
import com.google.genai.types.GenerateContentConfig;
import com.google.genai.types.GenerateContentResponse;
import com.google.genai.types.Schema;

import fourcheetah.animale.web.dto.ai.ChatMessage;
import fourcheetah.animale.web.dto.ai.RecommendedAnimeDTO;
import fourcheetah.animale.web.exception.ApiException;

@Service
public class RankerService {

    private final Client client;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private final ExecutorService executor = Executors.newFixedThreadPool(4);

    @Value("${ai.chat.timeoutMs:5000}")
    private long timeoutMs;

    @Value("${ai.chat.recommend.size:3}")
    private int recommendSize;

    // 모델명은 프로젝트 상황에 맞춰 변경
    @Value("${ai.chat.model:gemini-3-flash-preview}")
    private String modelName;

    public RankerService(Client client) {
        this.client = client;
    }

    public List<RecommendedAnimeDTO> pickTopN(
            String userMessage,
            List<ChatMessage> recentHistory,
            List<RecommendedAnimeDTO> candidates) {

        if (candidates == null || candidates.isEmpty()) {
            return List.of();
        }

        // 1) JSON 스키마: [{ animeId: number, reason: string }]
        Schema item = Schema.builder()
                .type(Object.class.getSimpleName())
                .properties(Map.of(
                        "animeId", Schema.builder().type(Number.class.getSimpleName()).build(),
                        "reason", Schema.builder().type(String.class.getSimpleName()).build()
                ))
                .required(List.of("animeId", "reason"))
                .build();

        Schema responseSchema = Schema.builder()
                .type(Array.class.getSimpleName())
                .items(item)
                .build();

        GenerateContentConfig config = GenerateContentConfig.builder()
                .responseMimeType("application/json")
                .responseSchema(responseSchema)
                .temperature((float) 0.3)         // 흔들림 줄이기
                .maxOutputTokens(512)
                .build();

        // 2) 프롬프트: “SQL 생성 금지 / 후보 목록 밖 선택 금지 / JSON만”
        String prompt = buildPrompt(userMessage, recentHistory, candidates, recommendSize);

        // 3) 5초 타임아웃 실행
        CompletableFuture<GenerateContentResponse> future =
                CompletableFuture.supplyAsync(() -> client.models.generateContent(modelName, prompt, config), executor);

        GenerateContentResponse resp;
        try {
            resp = future.get(timeoutMs, TimeUnit.MILLISECONDS);
        } catch (TimeoutException e) {
            future.cancel(true);
            throw new ApiException(HttpStatus.REQUEST_TIMEOUT, "AI_TIMEOUT", "AI 응답이 지연되고 있어요. 잠시 후 다시 시도해주세요.");
        } catch (Exception e) {
            throw new ApiException(HttpStatus.BAD_GATEWAY, "AI_ERROR", "AI 추천 처리 중 오류가 발생했어요.");
        }

        // 4) JSON 파싱
        String json = resp.text(); // JSON 모드면 여기에 JSON 텍스트가 옴
        List<Map<String, Object>> picks = parseJsonArray(json);

        // 5) 후보 Map( id -> DTO )로 합치고 reason 주입
        Map<Integer, RecommendedAnimeDTO> byId = candidates.stream()
                .collect(java.util.stream.Collectors.toMap(RecommendedAnimeDTO::getAnimeId, x -> x, (a,b)->a));

        List<RecommendedAnimeDTO> result = new ArrayList<>();
        for (Map<String, Object> p : picks) {
            Integer id = toInt(p.get("animeId"));
            String reason = (p.get("reason") != null) ? String.valueOf(p.get("reason")) : "";
            if (id != null && byId.containsKey(id)) {
                RecommendedAnimeDTO dto = byId.get(id);
                RecommendedAnimeDTO out = new RecommendedAnimeDTO();
                out.setAnimeId(dto.getAnimeId());
                out.setTitle(dto.getTitle());
                out.setThumbnailUrl(dto.getThumbnailUrl());
                out.setGenres(dto.getGenres());
                out.setReason(reason);
                result.add(out);
            }
            if (result.size() >= recommendSize) break;
        }

        // 6) 파싱 실패/누락 대비 fallback
        if (result.size() < recommendSize) {
            for (RecommendedAnimeDTO c : candidates) {
                boolean exists = result.stream().anyMatch(r -> r.getAnimeId() == c.getAnimeId());
                if (!exists) {
                    RecommendedAnimeDTO out = new RecommendedAnimeDTO();
                    out.setAnimeId(c.getAnimeId());
                    out.setTitle(c.getTitle());
                    out.setThumbnailUrl(c.getThumbnailUrl());
                    out.setGenres(c.getGenres());
                    out.setReason("조건에 맞는 후보 중에서 추천합니다.");
                    result.add(out);
                }
                if (result.size() >= recommendSize) break;
            }
        }

        return result;
    }

    private List<Map<String, Object>> parseJsonArray(String json) {
        try {
            if (json == null) return List.of();
            return objectMapper.readValue(json, new TypeReference<List<Map<String, Object>>>() {});
        } catch (Exception e) {
            return List.of();
        }
    }

    private Integer toInt(Object v) {
        if (v == null) return null;
        if (v instanceof Number) return ((Number) v).intValue();
        try { return Integer.parseInt(String.valueOf(v)); } catch (Exception e) { return null; }
    }

    private String buildPrompt(String userMessage, List<ChatMessage> history,
                               List<RecommendedAnimeDTO> candidates, int topN) {

        StringBuilder sb = new StringBuilder();
        sb.append("""
        너는 애니 추천 엔진이다.
        절대 SQL을 만들거나 DB/웹 검색을 하지 마라.
        반드시 아래 후보 목록(candidates) 안에서만 고른다.
        출력은 반드시 JSON 배열만. 다른 텍스트 금지.
        각 원소는 { "animeId": number, "reason": string } 형식.
        reason은 1~2문장, 사용자 조건과 연결해 설명.
        """);

        sb.append("\n[사용자 입력]\n").append(userMessage).append("\n");

        if (history != null && !history.isEmpty()) {
            sb.append("\n[최근 대화]\n");
            for (ChatMessage m : history) {
                sb.append("- ").append(m.getRole()).append(": ").append(m.getContent()).append("\n");
            }
        }

        sb.append("\n[candidates]\n");
        for (RecommendedAnimeDTO c : candidates) {
            sb.append("{")
              .append("\"animeId\":").append(c.getAnimeId()).append(",")
              .append("\"title\":\"").append(escape(c.getTitle())).append("\",")
              .append("\"genres\":").append(c.getGenres() == null ? "[]" : c.getGenres().toString())
              .append("}\n");
        }

        sb.append("\n위 candidates에서 상위 ").append(topN).append("개를 골라 JSON 배열로만 출력해.\n");
        return sb.toString();
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("\"", "\\\"");
    }
}
