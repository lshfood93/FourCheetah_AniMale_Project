package fourcheetah.animale.web.controller.board;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;            // ✅ NEW
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.dto.board.BoardLikeDTO;
import fourcheetah.animale.web.service.board.BoardLikeService;
import fourcheetah.animale.web.service.board.BoardService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@RestController
public class BoardLikeToggleController {

    @Autowired
    private BoardService boardService;

    @Autowired
    private BoardLikeService boardLikeService;

    @PostMapping("/BoardLikeToggle")
    public ResponseEntity<Map<String, Object>> toggle(
            BoardLikeDTO boardLikeDTO,      // CHANGED: boardId를 여기로 커맨드 바인딩
            BindingResult br,               // NEW: boardId 변환 오류 체크 (DTO 바로 다음)
            BoardDTO boardDTO,              // 유지: new 없이 인자로 받아서 사용
            HttpServletRequest request
    ) {

        System.out.println("[좋아요 토글 API] POST /BoardLikeToggle");

        // =========================================================
        // 1) 로그인 체크 (세션에서 memberId)
        HttpSession session = request.getSession(false);
        Integer memberId = (session == null) ? null : (Integer) session.getAttribute("memberId");

        if (memberId == null) {
            System.out.println("[좋아요 토글 API] 로그인 없음 -> 401");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("result", "FAIL", "msg", "LOGIN_REQUIRED"));
        }

        // =========================================================
        // 2) boardId 검증 (커맨드 바인딩 기반)
        // 예: boardId=abc 같은 타입 변환 오류
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[좋아요 토글 API] boardId 타입 변환 오류 -> 400, err=" + br.getFieldError("boardId"));
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("result", "FAIL", "msg", "INVALID_BOARD_ID"));
        }

        Integer boardId = boardLikeDTO.getBoardId(); // ✅ CHANGED: @RequestParam 대신 DTO에서 꺼냄
        if (boardId == null || boardId <= 0) {
            System.out.println("[좋아요 토글 API] boardId 유효성 실패 -> 400, boardId=" + boardId);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("result", "FAIL", "msg", "INVALID_BOARD_ID"));
        }

        System.out.println("[좋아요 토글 API] memberId=[" + memberId + "], boardId=[" + boardId + "]");

        // =========================================================
        // 3) 게시글 존재 검증 (BOARD_EXISTS)
        boardDTO.setCondition("BOARD_EXISTS");
        boardDTO.setBoardId(boardId);

        BoardDTO boardData = boardService.selectOne(boardDTO);
        if (boardData == null) {
            System.out.println("[좋아요 토글 API] 게시글 없음 -> 404, boardId=[" + boardId + "]");
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("result", "FAIL", "msg", "BOARD_NOT_FOUND"));
        }

        // =========================================================
        // 4) 좋아요 토글 실행 (BOARD_LIKE_TOGGLE)
        boardLikeDTO.setCondition("BOARD_LIKE_TOGGLE");
        boardLikeDTO.setBoardId(boardId);
        boardLikeDTO.setMemberId(memberId);

        boolean updated = boardLikeService.update(boardLikeDTO);
        if (!updated) {
            System.out.println("[좋아요 토글 API] 토글 실패 -> 500");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("result", "FAIL", "msg", "TOGGLE_FAILED"));
        }

        // 토글 직후 최종 상태 보관 (count 조회 전에 저장)
        int isLiked = boardLikeDTO.getIsLiked();

        // =========================================================
        // 5) 토글 후 좋아요 개수 조회 (BOARD_LIKE_COUNT)
        boardLikeDTO.setCondition("BOARD_LIKE_COUNT");
        boardLikeDTO.setBoardId(boardId);

        BoardLikeDTO countData = boardLikeService.selectOne(boardLikeDTO);
        int likeCnt = (countData == null) ? 0 : countData.getLikeCnt();

        // =========================================================
        // 6) JSON 응답
        return ResponseEntity.ok(Map.of(
                "result", "OK",
                "isLiked", isLiked,
                "likeCnt", likeCnt
        ));
    }
}
