package fourcheetah.animale.web.controller.board;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.aop.DeletedBoardCheck;
import fourcheetah.animale.web.aop.SanctionCheck;
import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.dto.board.BoardLikeDTO;
import fourcheetah.animale.web.dto.board.ReplyDTO;
import fourcheetah.animale.web.service.board.BoardLikeService;
import fourcheetah.animale.web.service.board.BoardService;
import fourcheetah.animale.web.service.board.ReplyService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@RestController
public class BoardApiController {

    @Autowired
    private BoardService boardService;

    @Autowired
    private BoardLikeService boardLikeService;

    @Autowired
    private ReplyService replyService;

    // =========================================================
    // 1) 좋아요 토글 API (POST /BoardLikeToggle)
    @SanctionCheck
    @DeletedBoardCheck
    @PostMapping("/BoardLikeToggle")
    public ResponseEntity<Map<String, Object>> toggleLike(
            BoardLikeDTO boardLikeDTO,  // boardId 바인딩
            BindingResult br,           // boardId 타입 변환 오류 체크
            BoardDTO boardDTO,
            HttpServletRequest request
    ) {

        System.out.println("[좋아요 토글 API] POST /BoardLikeToggle");

        // 1) 로그인 체크
        HttpSession session = request.getSession(false);
        Integer memberId = (session == null) ? null : (Integer) session.getAttribute("memberId");

        if (memberId == null) {
            System.out.println("[좋아요 토글 API] 로그인 없음 -> 401");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("result", "FAIL", "msg", "LOGIN_REQUIRED"));
        }

        // 2) boardId 검증
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[좋아요 토글 API] boardId 타입 변환 오류 -> 400, err=" + br.getFieldError("boardId"));
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("result", "FAIL", "msg", "INVALID_BOARD_ID"));
        }

        Integer boardId = boardLikeDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            System.out.println("[좋아요 토글 API] boardId 유효성 실패 -> 400, boardId=" + boardId);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("result", "FAIL", "msg", "INVALID_BOARD_ID"));
        }

        System.out.println("[좋아요 토글 API] memberId=[" + memberId + "], boardId=[" + boardId + "]");

        // 3) 게시글 존재 검증
        boardDTO.setCondition("BOARD_EXISTS");
        boardDTO.setBoardId(boardId);

        BoardDTO boardData = boardService.selectOne(boardDTO);
        if (boardData == null) {
            System.out.println("[좋아요 토글 API] 게시글 없음 -> 404, boardId=[" + boardId + "]");
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("result", "FAIL", "msg", "BOARD_NOT_FOUND"));
        }

        // 4) 좋아요 토글
        boardLikeDTO.setCondition("BOARD_LIKE_TOGGLE");
        boardLikeDTO.setBoardId(boardId);
        boardLikeDTO.setMemberId(memberId);

        boolean updated = boardLikeService.update(boardLikeDTO);
        if (!updated) {
            System.out.println("[좋아요 토글 API] 토글 실패 -> 500");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("result", "FAIL", "msg", "TOGGLE_FAILED"));
        }

        // 토글 직후 최종 상태
        int isLiked = boardLikeDTO.getIsLiked();

        // 5) 토글 후 좋아요 개수 조회
        boardLikeDTO.setCondition("BOARD_LIKE_COUNT");
        boardLikeDTO.setBoardId(boardId);

        BoardLikeDTO countData = boardLikeService.selectOne(boardLikeDTO);
        int likeCnt = (countData == null) ? 0 : countData.getLikeCnt();

        // 6) JSON 응답
        return ResponseEntity.ok(Map.of(
                "result", "OK",
                "isLiked", isLiked,
                "likeCnt", likeCnt
        ));
    }

    // =========================================================
    // 2) 좋아요 멤버 목록 API (GET /LikeMemberList)
    @GetMapping("/LikeMemberList")
    public Map<String, Object> likeMemberList(
            BoardDTO boardDTO,
            BindingResult br
    ) {

        System.out.println("[좋아요 멤버 목록 API 로그] GET 요청");

        Map<String, Object> res = new HashMap<>();

        // 1) boardId 검증
        if (br != null && br.hasFieldErrors("boardId")) {
            res.put("ok", false);
            res.put("message", "글 형식이 올바르지 않습니다.");
            res.put("users", new ArrayList<>());
            return res;
        }

        Integer boardId = boardDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            res.put("ok", false);
            res.put("message", "글 정보가 필요합니다.");
            res.put("users", new ArrayList<>());
            return res;
        }

        try {
            // 2) 조회 파라미터 구성
            boardDTO.setBoardId(boardId);
            boardDTO.setCondition("BOARD_LIKE_MEMBER_LIST");

            List<BoardDTO> likeMembers = boardService.selectAll(boardDTO);
            if (likeMembers == null) likeMembers = new ArrayList<>();

            // 3) JS 호환 키로 변환: memberNickname
            List<Map<String, Object>> users = new ArrayList<>();
            for (BoardDTO d : likeMembers) {
                Map<String, Object> u = new HashMap<>();
                u.put("memberNickname", d.getLikeMemberNickname());
                users.add(u);
            }

            res.put("ok", true);
            res.put("users", users);

            System.out.println("[좋아요 멤버 목록 API 로그] 조회완료 : boardId=[" + boardId + "], count=[" + users.size() + "]");
            return res;

        } catch (Exception e) {
            e.printStackTrace();
            res.put("ok", false);
            res.put("message", "목록 조회 중 서버 오류가 발생했습니다.");
            res.put("users", new ArrayList<>());
            return res;
        }
    }

    // =========================================================
    // 3) 댓글 정렬 API (GET /ReplyListOrder)
    // 호출 예) /ReplyListOrder?boardId=3&condition=REPLY_LIST_OLDEST
    @GetMapping(value = "/ReplyListOrder", produces = "application/json; charset=UTF-8")
    public ResponseEntity<?> replyListOrder(
            ReplyDTO replyDTO,
            BindingResult br
    ) {
        System.out.println("[댓글 정렬 API 로그] GET 요청 replyDTO=" + replyDTO);

        // 1) boardId 검증
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

    // =========================================================
    // 공통 유틸

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

        return RECENT;
    }
}
