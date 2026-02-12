package fourcheetah.animale.web.service.ai;

import java.util.List;
import java.util.Set;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.ai.*;
import fourcheetah.animale.web.exception.ApiException;
import jakarta.servlet.http.HttpSession;

@Service
public class AiChatService {

    private final AiChatSessionService sessionService;
    private final RateLimitService rateLimitService;
    private final QuerySpecExtractor extractor;
    private final CandidateService candidateService;
    private final RankerService rankerService;

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

    public AiChatOpenResponse open(HttpSession session) {
        sessionService.resetAll(session);

        AiChatOpenResponse res = new AiChatOpenResponse();
        res.setWelcomeMessage("안녕! 취향 기반으로 애니 3개 추천해줄게~");
        res.setInitialPrompt("원하는 장르/분위기/키워드를 말해줘! 예: 판타지+성장+모험");
        return res;
    }

    public AiChatMessageResponse chat(HttpSession session, String userMessage) {
        validateUserMessage(userMessage);
        rateLimitService.checkAndConsume(session);

        List<ChatMessage> history = sessionService.getChatHistory(session);
        pushHistory(history, "user", userMessage);

        QuerySpec spec = extractor.extract(userMessage);
        sessionService.setLastSpec(session, spec);

        Set<Integer> excludeIds = sessionService.getExcludeIds(session);
        List<RecommendedAnimeDTO> candidates = candidateService.getCandidates(spec, excludeIds);

        List<RecommendedAnimeDTO> top = rankerService.pickTopN(userMessage, trim(history), candidates);

        // exclude 갱신 + moreCount 초기화
        for (RecommendedAnimeDTO a : top) excludeIds.add(a.getAnimeId());
        sessionService.setMoreCount(session, 0);

        // assistant 메시지로 “요약 응답”도 히스토리에 남기고 싶다면(선택)
        pushHistory(history, "assistant", "추천 결과 " + top.size() + "건 반환");

        AiChatMessageResponse res = new AiChatMessageResponse();
        res.setRecommendedAnimes(top);
        return res;
    }

    public AiChatMessageResponse more(HttpSession session) {
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

        for (RecommendedAnimeDTO a : top) excludeIds.add(a.getAnimeId());
        sessionService.setMoreCount(session, moreCount + 1);

        AiChatMessageResponse res = new AiChatMessageResponse();
        res.setRecommendedAnimes(top);
        return res;
    }

    public AiChatOpenResponse reset(HttpSession session) {
        return open(session);
    }

    public AiChatMessageResponse changeCondition(HttpSession session, String newUserMessage) {
        // exclude 초기화 권장 정책 반영
        sessionService.getExcludeIds(session).clear();
        sessionService.setMoreCount(session, 0);

        return chat(session, newUserMessage);
    }

    // -------------------------
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
        // 최근 N턴 유지(유저+assistant 합쳐서 maxTurns*2 정도로 관리하고 싶으면 여기서 조절)
        int max = Math.max(2, historyMaxTurns * 2);
        while (history.size() > max) history.remove(0);
    }

    private List<ChatMessage> trim(List<ChatMessage> history) {
        // ranker에는 최근 일부만 넘기기(이미 위에서 잘라놨지만 안전차원)
        int keep = Math.max(2, historyMaxTurns * 2);
        if (history.size() <= keep) return history;
        return history.subList(history.size() - keep, history.size());
    }
}
