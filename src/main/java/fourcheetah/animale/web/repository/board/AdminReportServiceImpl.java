package fourcheetah.animale.web.repository.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.service.board.AdminReportService;
import fourcheetah.animale.web.dto.board.BoardReportDTO;
import fourcheetah.animale.web.repository.board.BoardReportDAO;

import java.util.*;



@Service
public class AdminReportServiceImpl implements AdminReportService {


    @Autowired
    private BoardReportDAO boardReportDAO;

    /**
     * 신고 목록 조회 (STEP 3: 실제 DB 조회)
     
    @Override
    public Map<String, Object> selectReportList(int page, int pageSize, String sortOrder) {
        System.out.println("[Service] selectReportList 호출됨");
        System.out.println("  - page: " + page);
        System.out.println("  - pageSize: " + pageSize);
        System.out.println("  - sortOrder: " + sortOrder);
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            // DTO 생성
            BoardReportDTO dto = new BoardReportDTO();
            dto.setCondition("report_list");
            dto.setPage(page);
            dto.setPageSize(pageSize);
            dto.setSortOrder(sortOrder);
            
            System.out.println("[Service] DAO 호출 시작");
            
            // DAO 호출 - 신고 목록 조회
            List<BoardReportDTO> reports = boardReportDAO.selectAll(dto);
            
            // DAO 호출 - 전체 건수 조회
            int totalCount = boardReportDAO.getTotalCount();
            
            System.out.println("[Service] DAO 호출 완료");
            System.out.println("  - 조회된 신고: " + reports.size() + "건");
            System.out.println("  - 전체 신고: " + totalCount + "건");
            
            // 페이징 계산
            int totalPages = (int) Math.ceil((double) totalCount / pageSize);
            
            // 페이지 그룹 계산 (1~10, 11~20 식으로)
            int pageGroupSize = 10;
            int currentGroup = (page - 1) / pageGroupSize;
            int startPage = currentGroup * pageGroupSize + 1;
            int endPage = Math.min(startPage + pageGroupSize - 1, totalPages);
            
            System.out.println("[Service] 페이징 계산 완료");
            System.out.println("  - 전체 페이지: " + totalPages);
            System.out.println("  - 페이지 그룹: " + startPage + " ~ " + endPage);
            
            // 결과 담기
            result.put("reports", reports);
            result.put("totalCount", totalCount);
            result.put("totalPages", totalPages);
            result.put("startPage", startPage);
            result.put("endPage", endPage);
            
            System.out.println("[Service] 결과 반환");
            
        } catch (Exception e) {
            System.out.println("[Service 에러] " + e.getMessage());
            e.printStackTrace();
            
            // 에러 발생 시 빈 데이터
            result.put("reports", new ArrayList<>());
            result.put("totalCount", 0);
            result.put("totalPages", 0);
            result.put("startPage", 1);
            result.put("endPage", 1);
        }
        
        return result;
    }

    /**
     * 신고 상세 조회
     */

    /*
    @Override
    public BoardReportDTO selectReportDetail(int boardId) {
        System.out.println("[Service] selectReportDetail 호출됨");
        System.out.println("  - boardId: " + boardId);
        
        try {
            BoardReportDTO dto = new BoardReportDTO();
            dto.setBoardId(boardId);
            
            BoardReportDTO result = boardReportDAO.selectOne(dto);
            
            if (result == null) {
                System.out.println("[Service] 신고 데이터 없음");
            } else {
                System.out.println("[Service] 신고 상세 조회 완료");
            }
            
            return result;
            
        } catch (Exception e) {
            System.out.println("[Service 에러] " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }
*/

    /**
     * 신고 반려 (CRUD 통일)
     */
    
    /*
    @Override
    public boolean updateReportReject(int boardId, int handledBy) {
        System.out.println("[Service] updateReportReject 호출됨");
        System.out.println("  - boardId: " + boardId);
        System.out.println("  - handledBy: " + handledBy);
        
        try {
            BoardReportDTO dto = new BoardReportDTO();
            dto.setBoardId(boardId);
            dto.setHandledBy(handledBy);
            
            boolean result = boardReportDAO.update(dto);
            
            if (result) {
                System.out.println("[Service] 신고 반려 처리 완료");
            } else {
                System.out.println("[Service] 신고 반려 처리 실패 (PENDING 상태 신고 없음)");
            }
            
            return result;
            
        } catch (Exception e) {
            System.out.println("[Service 에러] " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
*/

    /**
     * 신고 승인 (CRUD 통일)
     * 
     * 주의: boardWriterId를 따로 조회해야 함!
     */


    @Override
    public boolean updateReportApprove(int boardId, int handledBy) {
        System.out.println("[Service] updateReportApprove 호출됨");
        System.out.println("  - boardId: " + boardId);
        System.out.println("  - handledBy: " + handledBy);
       
        try {
            // 1. 먼저 게시글 작성자 ID 조회
            BoardReportDTO reportDetail = selectReportDetail(boardId);
            
            if (reportDetail == null) {
                System.out.println("[Service] 신고 데이터를 찾을 수 없음");
                return false;
            }
            
            int boardWriterId = reportDetail.getBoardWriterId();
            System.out.println("[Service] 게시글 작성자 ID: " + boardWriterId);
            
            // 2. DAO의 트랜잭션 메서드 호출
            boolean result = boardReportDAO.approveReport(boardId, boardWriterId, handledBy);
            
            if (result) {
                System.out.println("[Service] 신고 승인 처리 완료");
                System.out.println("  - 게시글 삭제됨");
                System.out.println("  - 작성자 경고 +1");
                System.out.println("  - 경고 기록 생성");
            }
            
            return result;
            
        } catch (Exception e) {
            System.out.println("[Service 에러] " + e.getMessage());
            e.printStackTrace();
            return false;
        }
        
    }

	@Override
	public Map<String, Object> selectReportList(int page, int pageSize, String sortOrder) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public BoardReportDTO selectReportDetail(int boardId) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public boolean updateReportReject(int boardId, int handledBy) {
		// TODO Auto-generated method stub
		return false;
	}
}

