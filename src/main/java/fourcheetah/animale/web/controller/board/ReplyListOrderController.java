package fourcheetah.animale.web.controller.board;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult; // ✅ NEW
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.board.ReplyDTO;
import fourcheetah.animale.web.service.board.ReplyService;

@RestController
public class ReplyListOrderController {

    @Autowired
    private ReplyService replyService;

    // CHANGED: @RequestParam Map 제거 → ReplyDTO 커맨드 바인딩
    // 호출 예) /ReplyListOrder?boardId=3&condition=REPLY_LIST_OLDEST
    @GetMapping(value = "/ReplyListOrder", produces = "application/json; charset=UTF-8")
    public ResponseEntity<?> replyListOrder(
            ReplyDTO replyDTO,     // ✅ CHANGED: boardId/condition 여기로 바인딩
            BindingResult br       // ✅ NEW: 바인딩/타입 변환 오류 체크(ReplyDTO 바로 다음!)
    ) {
        System.out.println("[댓글 정렬 API 로그] GET 요청 replyDTO=" + replyDTO);

        // 1) boardId 검증 (커맨드 바인딩 기반)
        // boardId=abc 같은 타입 변환 오류
        if (br != null && br.hasFieldErrors("boardId")) {
            return badRequest("boardId가 올바르지 않습니다.");
        }

        Integer boardId = replyDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            return badRequest("boardId가 올바르지 않습니다.");
        }

        // 2) condition 정리(화이트리스트) - 기본값 recent
        String condition = normalizeCondition(replyDTO.getCondition());
        System.out.println("[댓글 정렬 API 로그] boardId=" + boardId + ", condition=" + condition);

        // 3) 댓글 조회
        replyDTO.setBoardId(boardId);
        replyDTO.setCondition(condition);

        List<ReplyDTO> replyList = replyService.selectAll(replyDTO);
        if (replyList == null) replyList = Collections.emptyList();

        System.out.println("[댓글 정렬 API 로그] 댓글 조회 완료 count=" + replyList.size());

        // 4) 성공: JSON 배열(List) 반환
        return ResponseEntity.ok(replyList);
    }

    // ===================== 공통 유틸 =====================

    private ResponseEntity<Map<String, Object>> badRequest(String message) {
        Map<String, Object> body = new HashMap<>();
        body.put("success", false);
        body.put("message", message);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    private String normalizeCondition(String condition) {
        final String RECENT = "REPLY_LIST_RECENT";
        final String OLDEST = "REPLY_LIST_OLDEST";

        if (condition == null) return RECENT;
        condition = condition.trim().toUpperCase();

        if (OLDEST.equals(condition)) return OLDEST;
        if (RECENT.equals(condition)) return RECENT;

        // 어떤 값이 와도 안전하게 기본값(RECENT)
        return RECENT;
    }
}
