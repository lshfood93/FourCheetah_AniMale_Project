package fourcheetah.animale.web.service.ai;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.genai.Client;
import com.google.genai.types.GenerateContentConfig;
import com.google.genai.types.GenerateContentResponse;
import com.google.genai.types.HttpOptions; // ✅ [ADDED] SDK timeout 설정
import com.google.genai.types.Schema;

import fourcheetah.animale.web.dto.ai.ChatMessage;
import fourcheetah.animale.web.dto.ai.RecommendedAnimeDTO;

@Service
public class RankerService {

    private static final Logger log = LoggerFactory.getLogger(RankerService.class);

    private final Client client;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // =========================================================
    // [ADDED] "과부하 방지"용: bounded thread pool + bulkhead (semaphore)
    // - bounded queue: 큐가 꽉 차면 즉시 reject → 즉시 fallback
    // - bulkhead: 동시에 LLM 호출 가능한 개수 제한 (헬스 보호)
    // =========================================================
    private ThreadPoolExecutor executor;          // [CHANGED] Executors.newFixedThreadPool → bounded executor
    private Semaphore inFlightLimiter;            // [ADDED] 동시 호출 제한

    @Value("${ai.chat.timeoutMs:5000}")
    private long timeoutMs;

    @Value("${ai.chat.recommend.size:3}")
    private int recommendSize;

    @Value("${ai.chat.model:gemini-3-flash-preview}")
    private String modelName;

    // [ADDED] 스레드풀 튜닝 파라미터 (기본값 포함)
    @Value("${ai.chat.ranker.poolSize:4}")
    private int poolSize;

    @Value("${ai.chat.ranker.queueCapacity:20}")
    private int queueCapacity;

    @Value("${ai.chat.ranker.maxInFlight:4}")
    private int maxInFlight;

    // [ADDED] future.get()의 대기 버퍼 (스케줄링/직렬화 오버헤드 약간 감안)
    @Value("${ai.chat.ranker.waitBufferMs:250}")
    private long waitBufferMs;

    public RankerService(Client client) {
        this.client = client;
        initExecutor(); // [ADDED] 생성 시 초기화 (스프링 주입 완료 전이어도 기본값으로 동작)
    }

    // [ADDED] executor/semaphore 초기화
    private void initExecutor() {
        // 스프링이 @Value를 주입하기 전에도 안전하도록 "최소" 기본값 가드
        int ps = (poolSize > 0) ? poolSize : 4;
        int qc = (queueCapacity > 0) ? queueCapacity : 20;
        int mi = (maxInFlight > 0) ? maxInFlight : ps;

        this.inFlightLimiter = new Semaphore(mi);

        BlockingQueue<Runnable> queue = new ArrayBlockingQueue<>(qc);

        ThreadFactory tf = new ThreadFactory() { // [ADDED] 쓰레드 이름 부여 (로그 추적 편함)
            private final AtomicInteger seq = new AtomicInteger(1);
            @Override public Thread newThread(Runnable r) {
                Thread t = new Thread(r);
                t.setName("ai-ranker-" + seq.getAndIncrement());
                t.setDaemon(true);
                return t;
            }
        };

        // [ADDED] AbortPolicy: 큐가 꽉 차면 RejectedExecutionException → 즉시 fallback
        this.executor = new ThreadPoolExecutor(
                ps, ps,
                30L, TimeUnit.SECONDS,
                queue,
                tf,
                new ThreadPoolExecutor.AbortPolicy()
        );
        this.executor.allowCoreThreadTimeOut(true); // [ADDED] 유휴 쓰레드 정리
    }

    // [ADDED] 종료 시 정리 (서버 종료/재시작 시 스레드 누수 방지)
    @jakarta.annotation.PreDestroy
    public void shutdown() {
        if (executor != null) executor.shutdownNow();
    }

    public List<RecommendedAnimeDTO> pickTopN(
            String userMessage,
            List<ChatMessage> recentHistory,
            List<RecommendedAnimeDTO> candidates) {

        if (candidates == null || candidates.isEmpty()) {
            return List.of();
        }

        // =========================================================
        // [ADDED] 0) "과부하 즉시 fallback"
        // - 동시 호출 제한(maxInFlight) 초과면 LLM 호출 자체를 안 하고 바로 fallback
        // =========================================================
        if (!inFlightLimiter.tryAcquire()) {
            log.warn("[AI-RANK] OVERLOAD: inFlight full (maxInFlight={}) -> immediate fallback", maxInFlight);
            return fallbackFromCandidates(candidates, "서버가 잠시 혼잡해서 후보 기반으로 빠르게 추천했어요.");
        }

        long queuedAtNs = System.nanoTime(); // [ADDED] queueWait 측정용

        try {
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

            // =========================================================
            // [ADDED] 2) SDK 레벨 timeout을 request config에 부여
            // - HttpOptions.timeout(ms)
            // - (가능하면 Client 레벨에도 설정 권장: 아래 2번 참고)
            // =========================================================
            GenerateContentConfig config = GenerateContentConfig.builder()
                    .responseMimeType("application/json")
                    .responseSchema(responseSchema)
                    .temperature((float) 0.3)
                    .maxOutputTokens(512)
                    .httpOptions(HttpOptions.builder()
                            .timeout((int) timeoutMs) // [ADDED] SDK timeout (ms)
                            .build())
                    .build();

            String prompt = buildPrompt(userMessage, recentHistory, candidates, recommendSize);

            // =========================================================
            // [ADDED] 3) bounded executor에 제출 + queueWait 로깅
            // - 큐가 꽉 차면 RejectedExecutionException -> 즉시 fallback
            // - semaphore release는 "작업이 실제 종료될 때" 수행 (헬스 보호)
            // =========================================================
            Future<GenerateContentResponse> future;
            try {
                future = executor.submit(() -> {
                    long startNs = System.nanoTime();
                    long queueWaitMs = TimeUnit.NANOSECONDS.toMillis(startNs - queuedAtNs);
                    log.info("[AI-RANK] queueWaitMs={} promptChars={} candidates={} history={}",
                            queueWaitMs,
                            (prompt != null ? prompt.length() : 0),
                            candidates.size(),
                            (recentHistory != null ? recentHistory.size() : 0)
                    );

                    try {
                        // [CHANGED] 실제 LLM 호출
                        return client.models.generateContent(modelName, prompt, config);
                    } finally {
                        // [ADDED] inFlightLimiter는 "LLM 호출이 끝난 시점"에 반환
                        inFlightLimiter.release();
                    }
                });
            } catch (RejectedExecutionException rex) {
                // [ADDED] 큐 포화 → 즉시 fallback (여기서는 아직 작업이 실행되지 않았으므로 permit 반환)
                inFlightLimiter.release();
                log.warn("[AI-RANK] OVERLOAD: executor queue full -> immediate fallback (pool={}, queueCap={})",
                        poolSize, queueCapacity);
                return fallbackFromCandidates(candidates, "요청이 많아서 후보 기반으로 빠르게 추천했어요.");
            }

            // =========================================================
            // [CHANGED] 4) hard timeout: timeoutMs + buffer
            // - timeout이면 cancel(true) 하고 "즉시 fallback" 반환
            // - (permit은 작업 finally에서 반환됨: SDK timeout으로 곧 종료되도록 유도)
            // =========================================================
            GenerateContentResponse resp;
            try {
                long waitMs = Math.max(1, timeoutMs + waitBufferMs);
                resp = future.get(waitMs, TimeUnit.MILLISECONDS);
            } catch (TimeoutException te) {
                future.cancel(true);
                log.warn("[AI-RANK] TIMEOUT -> immediate fallback timeoutMs={} waitBufferMs={}", timeoutMs, waitBufferMs);
                return fallbackFromCandidates(candidates, "AI 응답이 지연돼서 후보 기반으로 빠르게 추천했어요.");
            } catch (Exception e) {
                // [ADDED] 모든 예외는 사용자 UX 위해 fallback
                log.warn("[AI-RANK] ERROR -> fallback: {}", e.toString());
                return fallbackFromCandidates(candidates, "AI 오류로 후보 기반 추천을 제공해요.");
            }

            // 5) JSON 파싱
            String json = (resp != null) ? resp.text() : null;
            List<Map<String, Object>> picks = parseJsonArray(json);

            // 6) 후보 Map(id -> DTO)로 합치고 reason 주입
            Map<Integer, RecommendedAnimeDTO> byId = candidates.stream()
                    .collect(java.util.stream.Collectors.toMap(
                            RecommendedAnimeDTO::getAnimeId, x -> x, (a, b) -> a));

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

            // 7) 파싱 실패/누락 대비 fallback(기존 로직 유지)
            if (result.size() < recommendSize) {
                List<RecommendedAnimeDTO> padded = padWithCandidates(result, candidates,
                        "조건에 맞는 후보 중에서 추천합니다.");
                return padded;
            }

            return result;

        } finally {
            // [ADDED] inFlightLimiter.release()는 submit된 작업에서만 수행.
            // - 여기서 release하면 timeout 시 "실제로는 아직 LLM 호출 중"인데 permit이 풀려버려 과부하가 악화될 수 있음.
        }
    }

    // =========================================================
    // [ADDED] 즉시 fallback 생성기(항상 빠르게 끝남)
    // =========================================================
    private List<RecommendedAnimeDTO> fallbackFromCandidates(List<RecommendedAnimeDTO> candidates, String reason) {
        List<RecommendedAnimeDTO> result = new ArrayList<>();
        for (RecommendedAnimeDTO c : candidates) {
            RecommendedAnimeDTO out = new RecommendedAnimeDTO();
            out.setAnimeId(c.getAnimeId());
            out.setTitle(c.getTitle());
            out.setThumbnailUrl(c.getThumbnailUrl());
            out.setGenres(c.getGenres());
            out.setReason(reason);
            result.add(out);
            if (result.size() >= recommendSize) break;
        }
        return result;
    }

    // 기존: 부족하면 후보로 채우기
    private List<RecommendedAnimeDTO> padWithCandidates(List<RecommendedAnimeDTO> base,
                                                       List<RecommendedAnimeDTO> candidates,
                                                       String reason) {
        List<RecommendedAnimeDTO> result = new ArrayList<>(base);

        for (RecommendedAnimeDTO c : candidates) {
            boolean exists = result.stream().anyMatch(r -> r.getAnimeId() == c.getAnimeId());
            if (!exists) {
                RecommendedAnimeDTO out = new RecommendedAnimeDTO();
                out.setAnimeId(c.getAnimeId());
                out.setTitle(c.getTitle());
                out.setThumbnailUrl(c.getThumbnailUrl());
                out.setGenres(c.getGenres());
                out.setReason(reason);
                result.add(out);
            }
            if (result.size() >= recommendSize) break;
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
