package fourcheetah.animale.web.service.ai;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.ai.AiChatMessageResponse;
import fourcheetah.animale.web.dto.ai.AiChatOpenResponse;
import fourcheetah.animale.web.dto.ai.ChatMessage;
import fourcheetah.animale.web.dto.ai.QuerySpec;
import fourcheetah.animale.web.dto.ai.RecommendedAnimeDTO;
import fourcheetah.animale.web.exception.ApiException;
import jakarta.servlet.http.HttpSession;

@Service
public class AiChatService {

    private final AiChatSessionService sessionService;
    private final RateLimitService rateLimitService;
    private final QuerySpecExtractor extractor;
    private final CandidateService candidateService;
    private final RankerService rankerService;
    private static final Logger log = LoggerFactory.getLogger(AiChatService.class);

    @Value("${ai.chat.more.max:3}")
    private int moreMax;

    @Value("${ai.chat.history.maxTurns:8}")
    private int historyMaxTurns;

    public AiChatService(
            AiChatSessionService sessionService,
            RateLimitService rateLimitService,
            QuerySpecExtractor extractor,
            CandidateService candidateService,
            RankerService rankerService) {
        this.sessionService = sessionService;
        this.rateLimitService = rateLimitService;
        this.extractor = extractor;
        this.candidateService = candidateService;
        this.rankerService = rankerService;
    }

    /**
     * open = 없으면 초기화, 있으면 유지
     * + 마지막 추천 리스트 복원용 데이터 포함
     */
    public AiChatOpenResponse open(HttpSession session) {
        if (session == null) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "NO_SESSION", "세션이 없습니다.");
        }

        sessionService.initIfAbsent(session);

        List<ChatMessage> history = sessionService.getChatHistory(session);
        Set<Integer> excludeIds = sessionService.getExcludeIds(session);
        int moreCount = sessionService.getMoreCount(session);
        boolean hasLastSpec = sessionService.getLastSpec(session) != null;
        List<RecommendedAnimeDTO> lastRecs = sessionService.getLastRecommendedAnimes(session);

        log.info("[AI-OPEN] sessionId={}, isNew={}, historySize={}, excludeSize={}, moreCount={}, lastSpec={}, lastRecSize={}",
                session.getId(),
                session.isNew(),
                history.size(),
                excludeIds.size(),
                moreCount,
                hasLastSpec,
                lastRecs == null ? 0 : lastRecs.size());

        return buildOpenResponse(history, moreCount, lastRecs);
    }

    public AiChatMessageResponse chat(HttpSession session, String userMessage) {
        if (session == null) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "NO_SESSION", "세션이 없습니다.");
        }

        sessionService.initIfAbsent(session);

        String rid = UUID.randomUUID().toString().substring(0, 8);
        long t0 = System.currentTimeMillis();

        log.info("[AI:{}] chat start msgLen={}", rid, userMessage == null ? 0 : userMessage.length());

        validateUserMessage(userMessage);

        long t1 = System.currentTimeMillis();
        rateLimitService.checkAndConsume(session);
        log.info("[AI:{}] rateLimit ms={}", rid, System.currentTimeMillis() - t1);

        List<ChatMessage> history = sessionService.getChatHistory(session);
        pushHistory(history, "user", userMessage);

        long t2 = System.currentTimeMillis();
        QuerySpec spec = extractor.extract(userMessage);
        log.info("[AI:{}] extract ms={}", rid, System.currentTimeMillis() - t2);

        sessionService.setLastSpec(session, spec);

        long t3 = System.currentTimeMillis();
        Set<Integer> excludeIds = sessionService.getExcludeIds(session);
        List<RecommendedAnimeDTO> candidates = candidateService.getCandidates(spec, excludeIds);
        log.info("[AI:{}] candidates size={} ms={}", rid,
                candidates == null ? 0 : candidates.size(),
                System.currentTimeMillis() - t3);

        long t4 = System.currentTimeMillis();
        List<RecommendedAnimeDTO> top = rankerService.pickTopN(userMessage, trim(history), candidates);
        log.info("[AI:{}] ranker ms={} topSize={}", rid,
                System.currentTimeMillis() - t4,
                top == null ? 0 : top.size());

        if (top != null) {
            for (RecommendedAnimeDTO a : top) {
                excludeIds.add(a.getAnimeId());
            }
        }

        // 새로운 조건 추천 -> 더보기 카운트 리셋
        sessionService.setMoreCount(session, 0);

        // ✅ 최소 복원 핵심: 마지막 추천 리스트 저장
        sessionService.setLastRecommendedAnimes(session, top);
        
        log.info("[AI-CHAT-SAVE] sessionId={}, topSize={}, savedLastRecSize={}",
                session.getId(),
                top == null ? 0 : top.size(),
                sessionService.getLastRecommendedAnimes(session).size());

        pushHistory(history, "assistant", "추천 결과 " + (top == null ? 0 : top.size()) + "건 반환");

        AiChatMessageResponse res = new AiChatMessageResponse();
        res.setRecommendedAnimes(top);

        log.info("[AI:{}] chat end totalMs={}", rid, System.currentTimeMillis() - t0);
        return res;
    }

    public AiChatMessageResponse more(HttpSession session) {
        if (session == null) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "NO_SESSION", "세션이 없습니다.");
        }

        sessionService.initIfAbsent(session);

        rateLimitService.checkAndConsume(session);

        int moreCount = sessionService.getMoreCount(session);
        if (moreCount >= moreMax) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "MORE_LIMIT",
                    "추가 추천은 최대 " + moreMax + "번까지 가능해요. 새 대화를 시작해볼까?");
        }

        QuerySpec spec = sessionService.getLastSpec(session);
        if (spec == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "NO_CONTEXT",
                    "이전 조건이 없어요. 먼저 조건을 입력해줘!");
        }

        List<ChatMessage> history = sessionService.getChatHistory(session);
        Set<Integer> excludeIds = sessionService.getExcludeIds(session);

        List<RecommendedAnimeDTO> candidates = candidateService.getCandidates(spec, excludeIds);
        List<RecommendedAnimeDTO> top = rankerService.pickTopN(spec.getRawUserMessage(), trim(history), candidates);

        if (top != null) {
            for (RecommendedAnimeDTO a : top) {
                excludeIds.add(a.getAnimeId());
            }
        }

        sessionService.setMoreCount(session, moreCount + 1);

        // ✅ 최소 복원 핵심: 마지막 추천 리스트 갱신
        sessionService.setLastRecommendedAnimes(session, top);
        
        log.info("[AI-MORE-SAVE] sessionId={}, topSize={}, savedLastRecSize={}",
                session.getId(),
                top == null ? 0 : top.size(),
                sessionService.getLastRecommendedAnimes(session).size());

        pushHistory(history, "assistant", "추가 추천 결과 " + (top == null ? 0 : top.size()) + "건 반환");

        AiChatMessageResponse res = new AiChatMessageResponse();
        res.setRecommendedAnimes(top);
        return res;
    }

    /**
     * reset = 진짜 초기화 담당
     */
    public AiChatOpenResponse reset(HttpSession session) {
        if (session == null) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "NO_SESSION", "세션이 없습니다.");
        }

        // ✅ 반드시 초기화 수행
        sessionService.resetAll(session);
        sessionService.initIfAbsent(session);

        return buildOpenResponse(
                sessionService.getChatHistory(session),
                sessionService.getMoreCount(session),
                sessionService.getLastRecommendedAnimes(session)
        );
    }

    public AiChatMessageResponse changeCondition(HttpSession session, String newUserMessage) {
        if (session == null) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "NO_SESSION", "세션이 없습니다.");
        }

        sessionService.initIfAbsent(session);

        // 정책상 exclude만 초기화 (기존 대화 맥락 유지)
        sessionService.getExcludeIds(session).clear();
        sessionService.setMoreCount(session, 0);

        return chat(session, newUserMessage);
    }

    // -------------------------
    /**
     * open/reset 응답 생성 (최소 복원: lastRecommendedAnimes 포함)
     */
    private AiChatOpenResponse buildOpenResponse(
            List<ChatMessage> history,
            int moreCount,
            List<RecommendedAnimeDTO> lastRecommendedAnimes) {

        AiChatOpenResponse res = new AiChatOpenResponse();
        res.setWelcomeMessage("안녕! 취향 기반으로 애니 3개 추천해줄게~");
        res.setInitialPrompt("원하는 장르/분위기/키워드를 말해줘! 예: 판타지+성장+모험");

        boolean resumed = history != null && !history.isEmpty();
        res.setResumed(resumed);
        res.setChatHistory(history == null ? new ArrayList<>() : new ArrayList<>(history));
        res.setMoreCount(moreCount);

        // ✅ 최소 복원용
        res.setLastRecommendedAnimes(
                lastRecommendedAnimes == null ? new ArrayList<>() : new ArrayList<>(lastRecommendedAnimes)
        );

        return res;
    }

    private void validateUserMessage(String msg) {
        if (msg == null || msg.trim().isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "EMPTY_INPUT", "메시지를 입력해줘!");
        }
        if (msg.length() > 500) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "TOO_LONG", "메시지는 500자 이내로 입력해줘!");
        }
    }

    private void pushHistory(List<ChatMessage> history, String role, String content) {
        history.add(new ChatMessage(role, content));
        int max = Math.max(2, historyMaxTurns * 2);
        while (history.size() > max) {
            history.remove(0);
        }
    }

    private List<ChatMessage> trim(List<ChatMessage> history) {
        int keep = Math.max(2, historyMaxTurns * 2);
        if (history.size() <= keep) return history;
        return history.subList(history.size() - keep, history.size());
    }
}