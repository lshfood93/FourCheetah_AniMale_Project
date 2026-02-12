package fourcheetah.animale.web.service.board;

/**
 * 사용자 신고 서비스 인터페이스
 */
public interface UserReportService {
    
    /**
     * 게시글 신고
     * 
     * @param boardId 게시글 ID
     * @param reporterMemberId 신고자 회원 ID
     * @param reasonCode 신고 사유 코드
     * @return 성공 여부
     */
    boolean reportBoard(int boardId, int reporterMemberId, String reasonCode);
}