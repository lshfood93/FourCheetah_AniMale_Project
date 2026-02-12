package fourcheetah.animale.web.repository.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import fourcheetah.animale.web.service.board.UserReportService;

/**
 * 사용자 신고 서비스 구현체
 */
@Service
public class UserReportServiceImpl implements UserReportService {

    @Autowired
    private BoardReportDAO boardReportDAO;

    /**
     * 게시글 신고
     * 
     * 처리 순서:
     * 1. 중복 신고 체크
     * 2. 신고 접수 (INSERT)
     * 3. 게시글 신고 횟수 증가
     */
    @Override
    @Transactional
    public boolean reportBoard(int boardId, int reporterMemberId, String reasonCode) {
        System.out.println("[Service] 게시글 신고 처리 시작");
        System.out.println("  - boardId: " + boardId);
        System.out.println("  - reporterMemberId: " + reporterMemberId);
        System.out.println("  - reasonCode: " + reasonCode);
        
        try {
            // 1. 중복 신고 체크
            System.out.println("[Service] 중복 신고 체크 시작");
            boolean isDuplicate = boardReportDAO.isDuplicateReport(boardId, reporterMemberId);
            
            if (isDuplicate) {
                System.out.println("[Service] 중복 신고 - 실패");
                return false;
            }
            
            System.out.println("[Service] 중복 신고 아님 - 계속 진행");
            
            // 2. 신고 접수 (INSERT)
            System.out.println("[Service] 신고 접수 시작");
            boolean insertSuccess = boardReportDAO.insertReport(boardId, reporterMemberId, reasonCode);
            
            if (!insertSuccess) {
                System.out.println("[Service] 신고 접수 실패");
                return false;
            }
            
            System.out.println("[Service] 신고 접수 성공");         
            System.out.println("[Service] 게시글 신고 처리 완료");
            
            return true;
            
        } catch (Exception e) {
            System.out.println("[Service 에러] " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("게시글 신고 처리 실패", e);
        }
    }
}
