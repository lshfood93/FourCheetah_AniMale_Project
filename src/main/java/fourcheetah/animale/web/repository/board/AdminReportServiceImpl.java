package fourcheetah.animale.web.repository.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import fourcheetah.animale.web.service.board.AdminReportService;
import fourcheetah.animale.web.service.member.EmailService;
import fourcheetah.animale.web.dto.board.BoardReportDTO;
import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.dto.member.MemberWarningDTO;
import fourcheetah.animale.web.repository.board.BoardReportDAO;
import fourcheetah.animale.web.repository.board.BoardDAO;
import fourcheetah.animale.web.repository.member.MemberDAO;
import fourcheetah.animale.web.repository.member.MemberWarningDAO;

import java.time.LocalDateTime;
import java.util.*;

@Service
public class AdminReportServiceImpl implements AdminReportService {

    @Autowired
    private BoardReportDAO boardReportDAO;
    
    @Autowired
    private BoardDAO boardDAO;
    
    @Autowired
    private MemberDAO memberDAO;
    
    @Autowired
    private MemberWarningDAO memberWarningDAO;
    
    @Autowired
    private EmailService emailService;

    /**
     * 신고 목록 조회 (STEP 3: 실제 DB 조회)
     */
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
    @Override
    public BoardReportDTO selectReportDetail(int boardId) {
        System.out.println("[Service] selectReportDetail 호출됨");
        System.out.println("  - boardId: " + boardId);
        
        try {
            BoardReportDTO dto = new BoardReportDTO();
            dto.setBoardId(boardId);
            
            dto.setCondition("REPORT_DETAIL");
            BoardReportDTO result = boardReportDAO.selectAll(dto).stream()
                .findFirst()
                .orElse(null);
            
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

    /**
     * 신고 반려
     */
    @Override
    public boolean updateReportReject(int boardId, int handledBy) {
        System.out.println("[Service] updateReportReject 호출됨");
        System.out.println("  - boardId: " + boardId);
        System.out.println("  - handledBy: " + handledBy);
        
        try {
            boolean result = boardReportDAO.rejectReport(boardId, handledBy);
            
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

    /**
     * ⭐ 신고 승인 (5단계 트랜잭션 + 제재 판정 + 이메일 발송)
     */
    @Override
    @Transactional
    public boolean updateReportApprove(int boardId, int handledBy) {
        System.out.println("========================================");
        System.out.println("[Service] updateReportApprove 호출됨");
        System.out.println("  - boardId: " + boardId);
        System.out.println("  - handledBy: " + handledBy);
        
        try {
            // ========================================
            // 【1단계】 게시글 작성자 조회
            // ========================================
            BoardReportDTO reportDetail = selectReportDetail(boardId);
            
            if (reportDetail == null) {
                System.out.println("[Service] 신고 데이터를 찾을 수 없음");
                return false;
            }
            
            int boardWriterId = reportDetail.getBoardWriterId();
            System.out.println("[1단계] 게시글 작성자 ID: " + boardWriterId);
            
            // ========================================
            // 【2단계】 게시글 삭제 + 신고 승인
            // ========================================
            System.out.println("[2단계] BoardReportDAO.approveReport() 호출");
            boolean daoResult = boardReportDAO.approveReport(boardId, boardWriterId, handledBy);
            
            if (!daoResult) {
                System.out.println("[2단계] DAO 처리 실패");
                return false;
            }
            
            System.out.println("[2단계] DAO 처리 완료 (게시글 삭제 + 신고 승인 + 작성자 누적 +1)");
            
            // ========================================
            // 【3단계】 작성자 정보 재조회 (누적 횟수 확인)
            // ========================================
            MemberDTO memberDTO = new MemberDTO();
            memberDTO.setMemberId(boardWriterId);
            memberDTO.setCondition("MEMBER_MYPAGE");
            
            MemberDTO member = memberDAO.selectOne(memberDTO);
            
            if (member == null) {
                System.out.println("[3단계] 회원 정보 조회 실패");
                return false;
            }
            
            int newCount = member.getValidReportCount();
            String memberEmail = member.getMemberEmail();
            
            System.out.println("[3단계] 작성자 누적 신고 횟수: " + newCount + "회");
            System.out.println("[3단계] 작성자 이메일: " + memberEmail);
            
            // ========================================
            // 【4단계】 제재 판정 (3회/5회/6회)
            // ========================================
            String warningType = null;
            LocalDateTime endAt = null;
            String reason = null;
            
            if (newCount == 3) {
                warningType = "SUSPEND_7D";
                endAt = LocalDateTime.now().plusDays(7);
                reason = "유효 신고 누적 3회 - 7일 정지";
                System.out.println("[4단계] 제재 판정: 7일 정지");
                
            } else if (newCount == 5) {
                warningType = "SUSPEND_30D";
                endAt = LocalDateTime.now().plusDays(30);
                reason = "유효 신고 누적 5회 - 30일 정지";
                System.out.println("[4단계] 제재 판정: 30일 정지");
                
            } else if (newCount >= 6) {
                warningType = "BAN";
                endAt = null;
                reason = "유효 신고 누적 6회 이상 - 영구 정지";
                System.out.println("[4단계] 제재 판정: 영구 정지");
                
            } else {
                System.out.println("[4단계] 제재 없음 (누적 " + newCount + "회)");
            }
            
         // ========================================
         // 【5단계】 이메일 발송
         // ========================================
         if (warningType != null) {
             System.out.println("[5단계] 제재 알림 이메일 발송 시작");
             
             try {
                 emailService.sendSanctionNotice(memberEmail, warningType, endAt, reason);
                 System.out.println("[5단계] 이메일 발송 성공");
                 
             } catch (Exception e) {
                 System.out.println("[5단계] 이메일 발송 실패: " + e.getMessage());
                 // 이메일 실패해도 트랜잭션 롤백 안 함
             }
         }
            
            System.out.println("========================================");
            System.out.println("[Service] 신고 승인 처리 완료");
            System.out.println("  - 게시글 삭제됨");
            System.out.println("  - 작성자 경고 +1");
            System.out.println("  - 제재 타입: " + (warningType != null ? warningType : "없음"));
            System.out.println("  - 경고 기록 생성됨");
            System.out.println("========================================");
            
            return true;
            
        } catch (Exception e) {
            System.out.println("[Service 에러] " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
}