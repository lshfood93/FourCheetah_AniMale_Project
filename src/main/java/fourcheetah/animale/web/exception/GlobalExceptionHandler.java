package fourcheetah.animale.web.exception;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import jakarta.servlet.http.HttpServletRequest;

@RestControllerAdvice
public class GlobalExceptionHandler {
	
	 private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

	   @ExceptionHandler(ApiException.class)
	    public ResponseEntity<Map<String, Object>> handleApi(ApiException e, HttpServletRequest req) {
	        String uri = req.getRequestURI(); // 예: /animale/api/ai-chat/message

	        Map<String, Object> body = new HashMap<>();
	        body.put("code", e.getCode());
	        body.put("message", e.getMessage());

	        // ✅ 프론트가 우선으로 보는 키
	        body.put("errorMessage", e.getMessage());

	        // ✅ AI 챗봇 타임아웃은 200으로 내려서 res.ok를 true로 만들기
	        if (uri != null && uri.contains("/api/ai-chat") && "AI_TIMEOUT".equals(e.getCode())) {
	            body.put("recommendedAnimes", List.of()); // 프론트가 배열로 안전 처리
	            body.put("fallback", true);

	            log.warn("[AI-CHAT] timeout -> 200 OK: {} {} code={}", req.getMethod(), uri, e.getCode());
	            return ResponseEntity.ok(body);
	        }

	        return ResponseEntity.status(e.getStatus()).body(body);
	    }


    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleAny(Exception e, HttpServletRequest req) {
    	
    	  // 핵심: 어떤 URL에서 어떤 예외가 났는지 + 스택트레이스
    	log.error("[UNHANDLED] {} {}", req.getMethod(), req.getRequestURI(), e);
        Map<String, Object> body = new HashMap<>();
        body.put("code", "INTERNAL_ERROR");
        body.put("message", "서버 오류가 발생했습니다.");
        return ResponseEntity.status(500).body(body);
    }
}
