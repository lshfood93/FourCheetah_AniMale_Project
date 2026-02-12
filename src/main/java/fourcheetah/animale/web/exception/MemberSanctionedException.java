package fourcheetah.animale.web.exception;

/**
 * 회원 제재 예외
 * 제재 중인 회원이 제한된 활동을 시도할 때 발생
 */
public class MemberSanctionedException extends RuntimeException {
    
    private static final long serialVersionUID = 1L;
    
    public MemberSanctionedException() {
        super("제재 중인 회원입니다.");
    }
    
    public MemberSanctionedException(String message) {
        super(message);
    }
    
    public MemberSanctionedException(String message, Throwable cause) {
        super(message, cause);
    }
}