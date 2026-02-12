package fourcheetah.animale.web.exception;

import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

/**
 * 전역 예외 처리 핸들러
 * AOP에서 던진 예외를 받아서 일관된 형식의 응답 반환
 */
@ControllerAdvice
public class GlobalExceptionHandler {
    
    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);
    
    /**
     * 회원 제재 예외 처리
     * 제재 중인 회원이 제한된 활동 시도 시 호출
     */
    @ExceptionHandler(MemberSanctionedException.class)
    public ResponseEntity<Map<String, Object>> handleMemberSanctionedException(MemberSanctionedException ex) {
        logger.warn("[예외처리] 회원 제재 - {}", ex.getMessage());
        
        Map<String, Object> response = new HashMap<>();
        response.put("result", "FAIL");
        response.put("code", "MEMBER_SANCTIONED");
        response.put("msg", ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
    }
    
    /**
     * 삭제된 게시글 예외 처리
     * 삭제된 게시글 접근 시도 시 호출
     */
    @ExceptionHandler(BoardDeletedException.class)
    public ResponseEntity<Map<String, Object>> handleBoardDeletedException(BoardDeletedException ex) {
        logger.warn("[예외처리] 삭제된 게시글 - {}", ex.getMessage());
        
        Map<String, Object> response = new HashMap<>();
        response.put("result", "FAIL");
        response.put("code", "BOARD_DELETED");
        response.put("msg", ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
    }
    
    /**
     * 로그인 필요 예외 처리
     * 로그인하지 않은 사용자의 요청 시 호출
     */
    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, Object>> handleUnauthorizedException(UnauthorizedException ex) {
        logger.warn("[예외처리] 로그인 필요 - {}", ex.getMessage());
        
        Map<String, Object> response = new HashMap<>();
        response.put("result", "FAIL");
        response.put("code", "LOGIN_REQUIRED");
        response.put("msg", ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
    }
    
    /**
     * 기타 런타임 예외 처리
     * 예상치 못한 예외 발생 시 호출
     */
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, Object>> handleRuntimeException(RuntimeException ex) {
        logger.error("[예외처리] 런타임 에러 - {}", ex.getMessage(), ex);
        
        Map<String, Object> response = new HashMap<>();
        response.put("result", "FAIL");
        response.put("code", "SERVER_ERROR");
        response.put("msg", "서버 오류가 발생했습니다.");
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}