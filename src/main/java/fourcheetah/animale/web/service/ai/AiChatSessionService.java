package fourcheetah.animale.web.service.ai;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.ai.ChatMessage;
import fourcheetah.animale.web.dto.ai.QuerySpec;
import jakarta.servlet.http.HttpSession;

@Service
public class AiChatSessionService {

    public static final String S_CHAT_HISTORY = "ai.chatHistory";
    public static final String S_EXCLUDE_IDS  = "ai.excludeAnimeIds";
    public static final String S_MORE_COUNT   = "ai.moreRecommendCount";
    public static final String S_LAST_SPEC    = "ai.lastQuerySpec";

    @SuppressWarnings("unchecked")
    public List<ChatMessage> getChatHistory(HttpSession session) {
        Object v = session.getAttribute(S_CHAT_HISTORY);
        if (v == null) {
            List<ChatMessage> list = new ArrayList<>();
            session.setAttribute(S_CHAT_HISTORY, list);
            return list;
        }
        return (List<ChatMessage>) v;
    }

    @SuppressWarnings("unchecked")
    public Set<Integer> getExcludeIds(HttpSession session) {
        Object v = session.getAttribute(S_EXCLUDE_IDS);
        if (v == null) {
            Set<Integer> set = new HashSet<>();
            session.setAttribute(S_EXCLUDE_IDS, set);
            return set;
        }
        return (Set<Integer>) v;
    }

    public int getMoreCount(HttpSession session) {
        Object v = session.getAttribute(S_MORE_COUNT);
        if (v == null) {
            session.setAttribute(S_MORE_COUNT, 0);
            return 0;
        }
        return (Integer) v;
    }

    public void setMoreCount(HttpSession session, int count) {
        session.setAttribute(S_MORE_COUNT, count);
    }

    public QuerySpec getLastSpec(HttpSession session) {
        Object v = session.getAttribute(S_LAST_SPEC);
        return (v instanceof QuerySpec) ? (QuerySpec) v : null;
    }

    public void setLastSpec(HttpSession session, QuerySpec spec) {
        session.setAttribute(S_LAST_SPEC, spec);
    }

    public void resetAll(HttpSession session) {
        session.setAttribute(S_CHAT_HISTORY, new ArrayList<ChatMessage>());
        session.setAttribute(S_EXCLUDE_IDS, new HashSet<Integer>());
        session.setAttribute(S_MORE_COUNT, 0);
        session.removeAttribute(S_LAST_SPEC);
    }
}
