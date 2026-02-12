package fourcheetah.animale.web.exception;

import java.util.HashMap;
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
    public ResponseEntity<Map<String, Object>> handleApi(ApiException e) {
        Map<String, Object> body = new HashMap<>();
        body.put("code", e.getCode());
        body.put("message", e.getMessage());
        return ResponseEntity.status(e.getStatus()).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleAny(Exception e, HttpServletRequest req) {
    	
    	  // ✅ 이게 핵심: 어떤 URL에서 어떤 예외가 났는지 + 스택트레이스
        log.error("[AI-CHAT] Unhandled error: {} {}", req.getMethod(), req.getRequestURI(), e);
        Map<String, Object> body = new HashMap<>();
        body.put("code", "INTERNAL_ERROR");
        body.put("message", "서버 오류가 발생했습니다.");
        return ResponseEntity.status(500).body(body);
    }
}
