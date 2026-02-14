package fourcheetah.animale.web.service.ai;

import java.util.ArrayDeque;
import java.util.Deque;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.exception.ApiException;
import jakarta.servlet.http.HttpSession;

@Service
public class RateLimitService {

    private static final String S_MINUTE_LOG = "ai.rate.minuteLog";
    private static final String S_SESSION_COUNT = "ai.rate.sessionCount";

    @Value("${ai.chat.rate.per-minute:5}")
    private int perMinute;

    @Value("${ai.chat.rate.per-session:10}")
    private int perSession;

    @SuppressWarnings("unchecked")
    public void checkAndConsume(HttpSession session) {
        long now = System.currentTimeMillis();

        // 1) per-minute
        Deque<Long> log = (Deque<Long>) session.getAttribute(S_MINUTE_LOG);
        if (log == null) {
            log = new ArrayDeque<>();
            session.setAttribute(S_MINUTE_LOG, log);
        }
        while (!log.isEmpty() && now - log.peekFirst() > 60_000) {
            log.pollFirst();
        }
        if (log.size() >= perMinute) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMIT_MINUTE",
                    "요청이 너무 많아요. 잠시 후 다시 시도해주세요.");
        }
        log.addLast(now);

        // 2) per-session
        Integer cnt = (Integer) session.getAttribute(S_SESSION_COUNT);
        if (cnt == null) cnt = 0;
        if (cnt >= perSession) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMIT_SESSION",
                    "세션 내 요청 한도를 초과했어요. 새 대화를 시작해 주세요.");
        }
        session.setAttribute(S_SESSION_COUNT, cnt + 1);
    }
}
