package fourcheetah.animale.web.controller.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import fourcheetah.animale.web.aop.SanctionCheck;
import fourcheetah.animale.web.aop.DeletedBoardCheck;
import fourcheetah.animale.web.service.board.UserReportService;
import jakarta.servlet.http.HttpSession;

import java.util.*;

/**
 * 사용자 신고 컨트롤러
 */
@Controller
public class UserReportController {

    @Autowired
    private UserReportService userReportService;

    /**
     * 게시글 신고 (AJAX)
     * 
     * POST /report/board
     * 파라미터: boardId, reasonCode
     * 응답: JSON {ok: "메시지"} 또는 {fail: "메시지"}
     */
    // 신고 (제재 회원 중 WARNING만 허용 + 삭제된 게시글 차단)
    @SanctionCheck(allowTypes = {"WARNING"})
    @DeletedBoardCheck
    @PostMapping("/report/board")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> reportBoard(
            @RequestParam int boardId,
            @RequestParam String reasonCode,
            HttpSession session) {
        
        System.out.println("========================================");
        System.out.println("[사용자 신고] 요청");
        System.out.println("[파라미터] boardId=" + boardId + ", reasonCode=" + reasonCode);
        
        Map<String, Object> response = new HashMap<>();
        
        try {
            // 1. 로그인 체크
            Integer memberId = (Integer) session.getAttribute("memberId");
            
            if (memberId == null) {
                System.out.println("[사용자 신고] 로그인 필요");
                response.put("fail", "로그인이 필요한 기능입니다.");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }
            
            System.out.println("[사용자 신고] 신고자 memberId=" + memberId);
            
            // 2. 파라미터 검증
            if (boardId <= 0) {
                System.out.println("[사용자 신고] 잘못된 boardId");
                response.put("fail", "잘못된 게시글입니다.");
                return ResponseEntity.badRequest().body(response);
            }
            
            if (reasonCode == null || reasonCode.trim().isEmpty()) {
                System.out.println("[사용자 신고] 신고 사유 없음");
                response.put("fail", "신고 사유를 선택해주세요.");
                return ResponseEntity.badRequest().body(response);
            }
            
            // 3. 신고 사유 코드 검증
            String trimmedReasonCode = reasonCode.trim().toUpperCase();
            List<String> validReasonCodes = Arrays.asList("SPAM", "ABUSE", "OBSCENE", "ILLEGAL", "ETC");
            
            if (!validReasonCodes.contains(trimmedReasonCode)) {
                System.out.println("[사용자 신고] 잘못된 신고 사유 코드: " + reasonCode);
                response.put("fail", "올바른 신고 사유를 선택해주세요.");
                return ResponseEntity.badRequest().body(response);
            }
            
            System.out.println("[사용자 신고] 파라미터 검증 완료");
            System.out.println("[사용자 신고] Service.reportBoard() 호출");
            
            // 4. Service 호출
            boolean result = userReportService.reportBoard(boardId, memberId, trimmedReasonCode);
            
            if (result) {
                response.put("ok", "신고가 접수되었습니다. 검토 후 조치하겠습니다.");
                System.out.println("[사용자 신고] 성공");
                return ResponseEntity.ok(response);
            } else {
                response.put("fail", "이미 신고한 게시글입니다.");
                System.out.println("[사용자 신고] 실패 - 중복 신고");
                return ResponseEntity.ok(response);
            }
            
        } catch (Exception e) {
            System.out.println("[사용자 신고 에러] " + e.getMessage());
            e.printStackTrace();
            response.put("fail", "신고 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        } finally {
            System.out.println("========================================");
        }
    }
}