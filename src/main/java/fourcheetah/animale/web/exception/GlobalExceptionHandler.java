// GlobalExceptionHandler.java
package fourcheetah.animale.web.exception;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;
import jakarta.servlet.http.HttpServletRequest;

@ControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // =========================================================
    // 1) 삭제된 게시글 접근
    // - REST 요청(toggleLike, reportBoard, replyWrite): JSON 응답
    // - 페이지 요청(boardEditPage): 게시글 상세 페이지로 이동
    // =========================================================
    @ExceptionHandler(BoardDeletedException.class)
    public Object handleBoardDeleted(BoardDeletedException e, HttpServletRequest request, Model model) {
        String uri = request.getRequestURI();

        // REST 요청 판별 (AJAX/API 경로)
        boolean isRestRequest = isRestRequest(request, uri);

        if (isRestRequest) {
            // JSON 응답
            Map<String, Object> body = new HashMap<>();
            body.put("fail", e.getMessage());
            return ResponseEntity.status(403).body(body);
        }

        // 페이지 요청 - boardId 추출해서 상세 페이지로 이동
        String boardIdParam = request.getParameter("boardId");
        String location = "/mainPage";
        if (boardIdParam != null && !boardIdParam.isEmpty()) {
            location = "/boardDetail?boardId=" + boardIdParam;
        }

        model.addAttribute("msg", e.getMessage());
        model.addAttribute("location", location);
        return "message";
    }

    // =========================================================
    // 2) API 예외 -> JSON 응답
    // =========================================================
    @ResponseBody
    @ExceptionHandler(ApiException.class)
    public ResponseEntity<Map<String, Object>> handleApi(ApiException e, HttpServletRequest req) {
        String uri = req.getRequestURI();
        Map<String, Object> body = new HashMap<>();
        body.put("code", e.getCode());
        body.put("message", e.getMessage());
        body.put("errorMessage", e.getMessage());

        if (uri != null && uri.contains("/api/ai-chat") && "AI_TIMEOUT".equals(e.getCode())) {
            body.put("recommendedAnimes", List.of());
            body.put("fallback", true);
            log.warn("[AI-CHAT] timeout -> 200 OK: {} {} code={}", req.getMethod(), uri, e.getCode());
            return ResponseEntity.ok(body);
        }
        return ResponseEntity.status(e.getStatus()).body(body);
    }

    // =========================================================
    // 3) 나머지 예외 -> JSON 응답
    // =========================================================
    @ResponseBody
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleAny(Exception e, HttpServletRequest req) {
        log.error("Unhandled error: {} {}", req.getMethod(), req.getRequestURI(), e);
        Map<String, Object> body = new HashMap<>();
        body.put("code", "INTERNAL_ERROR");
        body.put("message", "서버 오류가 발생했습니다.");
        return ResponseEntity.status(500).body(body);
    }

    /**
     * REST 요청 판별
     * - URI에 API 경로 포함
     * - Accept 헤더가 application/json
     * - X-Requested-With: XMLHttpRequest
     */
    private boolean isRestRequest(HttpServletRequest request, String uri) {
        if (uri != null && (
            uri.contains("/BoardLikeToggle") ||
            uri.contains("/report/board") ||
            uri.contains("/reply/write") ||
            uri.contains("/reply/") ||
            uri.contains("/api/")
        )) {
            return true;
        }
        String accept = request.getHeader("Accept");
        if (accept != null && accept.contains("application/json")) {
            return true;
        }
        String xRequestedWith = request.getHeader("X-Requested-With");
        if ("XMLHttpRequest".equals(xRequestedWith)) {
            return true;
        }
        return false;
    }
}