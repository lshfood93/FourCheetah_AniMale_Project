package fourcheetah.animale.web.service.ai;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.ai.ChatMessage;
import fourcheetah.animale.web.dto.ai.QuerySpec;
import fourcheetah.animale.web.dto.ai.RecommendedAnimeDTO;
import jakarta.servlet.http.HttpSession;

@Service
public class AiChatSessionService {

    public static final String S_CHAT_HISTORY = "ai.chatHistory";
    public static final String S_EXCLUDE_IDS  = "ai.excludeAnimeIds";
    public static final String S_MORE_COUNT   = "ai.moreRecommendCount";
    public static final String S_LAST_SPEC    = "ai.lastQuerySpec";

    // ✅ 추가: 마지막 추천 리스트
    public static final String S_LAST_RECOMMENDS = "ai.lastRecommendedAnimes";

    /**
     * open/chat/more/change 진입 시 호출:
     * 세션 상태가 없으면 기본 상태만 생성 (이미 있으면 유지)
     */
    public void initIfAbsent(HttpSession session) {
        requireSession(session);

        if (!(session.getAttribute(S_CHAT_HISTORY) instanceof List)) {
            session.setAttribute(S_CHAT_HISTORY, new ArrayList<ChatMessage>());
        }
        if (!(session.getAttribute(S_EXCLUDE_IDS) instanceof Set)) {
            session.setAttribute(S_EXCLUDE_IDS, new HashSet<Integer>());
        }
        if (!(session.getAttribute(S_MORE_COUNT) instanceof Integer)) {
            session.setAttribute(S_MORE_COUNT, Integer.valueOf(0));
        }
        //  추가: 마지막 추천 리스트 초기화
        if (session.getAttribute(S_LAST_RECOMMENDS) == null) {
            session.setAttribute(S_LAST_RECOMMENDS, new ArrayList<RecommendedAnimeDTO>());
        }
        // S_LAST_SPEC는 null 허용 (아직 조건 입력 전)
    }

    @SuppressWarnings("unchecked")
    public List<ChatMessage> getChatHistory(HttpSession session) {
        requireSession(session);
        initIfAbsent(session);

        Object v = session.getAttribute(S_CHAT_HISTORY);
        if (v instanceof List<?>) {
            try {
                return (List<ChatMessage>) v;
            } catch (ClassCastException e) {
                List<ChatMessage> list = new ArrayList<>();
                session.setAttribute(S_CHAT_HISTORY, list);
                return list;
            }
        }

        List<ChatMessage> list = new ArrayList<>();
        session.setAttribute(S_CHAT_HISTORY, list);
        return list;
    }

    @SuppressWarnings("unchecked")
    public Set<Integer> getExcludeIds(HttpSession session) {
        requireSession(session);
        initIfAbsent(session);

        Object v = session.getAttribute(S_EXCLUDE_IDS);
        if (v instanceof Set<?>) {
            try {
                return (Set<Integer>) v;
            } catch (ClassCastException e) {
                Set<Integer> set = new HashSet<>();
                session.setAttribute(S_EXCLUDE_IDS, set);
                return set;
            }
        }

        Set<Integer> set = new HashSet<>();
        session.setAttribute(S_EXCLUDE_IDS, set);
        return set;
    }

    public int getMoreCount(HttpSession session) {
        requireSession(session);
        initIfAbsent(session);

        Object v = session.getAttribute(S_MORE_COUNT);
        if (v instanceof Integer) {
            return (Integer) v;
        }

        session.setAttribute(S_MORE_COUNT, Integer.valueOf(0));
        return 0;
    }

    public void setMoreCount(HttpSession session, int count) {
        requireSession(session);
        session.setAttribute(S_MORE_COUNT, Math.max(0, count));
    }

    public QuerySpec getLastSpec(HttpSession session) {
        requireSession(session);

        Object v = session.getAttribute(S_LAST_SPEC);
        return (v instanceof QuerySpec) ? (QuerySpec) v : null;
    }

    public void setLastSpec(HttpSession session, QuerySpec spec) {
        requireSession(session);

        if (spec == null) {
            session.removeAttribute(S_LAST_SPEC);
        } else {
            session.setAttribute(S_LAST_SPEC, spec);
        }
    }

    // ✅ 추가: 마지막 추천 리스트 조회
    @SuppressWarnings("unchecked")
    public List<RecommendedAnimeDTO> getLastRecommendedAnimes(HttpSession session) {
        Object v = session.getAttribute(S_LAST_RECOMMENDS);
        if (v == null) {
            List<RecommendedAnimeDTO> list = new ArrayList<>();
            session.setAttribute(S_LAST_RECOMMENDS, list);
            return list;
        }
        return (List<RecommendedAnimeDTO>) v;
    }

    // ✅ 추가: 마지막 추천 리스트 저장 (복사본 저장 권장)
    public void setLastRecommendedAnimes(HttpSession session, List<RecommendedAnimeDTO> list) {
        if (list == null) {
            session.setAttribute(S_LAST_RECOMMENDS, new ArrayList<RecommendedAnimeDTO>());
        } else {
            session.setAttribute(S_LAST_RECOMMENDS, new ArrayList<>(list));
        }
    }
    /**
     * reset()에서만 호출:
     * 대화/추천 관련 상태 전체 초기화
     */
    public void resetAll(HttpSession session) {
        requireSession(session);

        session.setAttribute(S_CHAT_HISTORY, new ArrayList<ChatMessage>());
        session.setAttribute(S_EXCLUDE_IDS, new HashSet<Integer>());
        session.setAttribute(S_MORE_COUNT, Integer.valueOf(0));
        session.removeAttribute(S_LAST_SPEC);
        //  추가: 마지막 추천 리스트도 초기화
        session.setAttribute(S_LAST_RECOMMENDS, new ArrayList<RecommendedAnimeDTO>());
    }

    private void requireSession(HttpSession session) {
        if (session == null) {
            throw new IllegalArgumentException("HttpSession must not be null");
        }
    }
}