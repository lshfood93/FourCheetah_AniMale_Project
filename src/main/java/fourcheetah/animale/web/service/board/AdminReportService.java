package fourcheetah.animale.web.service.board;

import fourcheetah.animale.web.dto.board.BoardReportDTO;
import java.util.List;
import java.util.Map;

public interface AdminReportService {
    
    /**
     * 신고 목록 조회
     */
    Map<String, Object> selectReportList(int page, int pageSize, String sortOrder);
    
    /**
     * 신고 상세 조회
     */
    BoardReportDTO selectReportDetail(int boardId);
    
    /**
     * 신고 반려 (CRUD 통일 - update)
     */
    boolean updateReportReject(int boardId, int handledBy);
    
    /**
     * 신고 승인 (CRUD 통일 - update)
     */
    boolean updateReportApprove(int boardId, int handledBy);
}