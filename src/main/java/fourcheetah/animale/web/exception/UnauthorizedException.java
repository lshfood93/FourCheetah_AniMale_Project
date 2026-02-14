package fourcheetah.animale.web.exception;

/**
 * 인증 필요 예외
 * 로그인이 필요한 작업을 시도할 때 발생
 */
public class UnauthorizedException extends RuntimeException {
    
    private static final long serialVersionUID = 1L;
    
    public UnauthorizedException() {
        super("로그인이 필요합니다.");
    }
    
    public UnauthorizedException(String message) {
        super(message);
    }
    
    public UnauthorizedException(String message, Throwable cause) {
        super(message, cause);
    }
}