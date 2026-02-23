package fourcheetah.animale.web.exception;

/**
 * 삭제된 게시글 예외
 * 삭제된 게시글에 접근하려고 할 때 발생
 */
public class BoardDeletedException extends RuntimeException {
    
    private static final long serialVersionUID = 1L;
    
    public BoardDeletedException() {
        super("삭제된 게시글입니다.");
    }
    
    public BoardDeletedException(String message) {
        super(message);
    }
    
    public BoardDeletedException(String message, Throwable cause) {
        super(message, cause);
    }
}