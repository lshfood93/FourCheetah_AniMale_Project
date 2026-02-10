package fourcheetah.animale.web.controller.board;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.BindingResult;   // ✅ NEW
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.service.board.BoardService;

@RestController
public class LikeMemberListController {

    @Autowired
    private BoardService boardService;

    @GetMapping("/LikeMemberList")
    public Map<String, Object> likeMemberList(
            BoardDTO boardDTO,        // CHANGED: boardId를 커맨드 객체로 바인딩 받음
            BindingResult br          // NEW: 타입 변환 오류 체크(BoardDTO 바로 다음)
    ) {

        System.out.println("[좋아요 멤버 목록 API 로그] GET 요청");

        Map<String, Object> res = new HashMap<>();

        // =========================================================
        // 1) boardId 검증 (커맨드 바인딩 기반)
        // boardId=abc 같은 타입 변환 오류
        if (br != null && br.hasFieldErrors("boardId")) {
            res.put("ok", false);
            res.put("message", "글 형식이 올바르지 않습니다.");
            res.put("users", new ArrayList<>());
            return res;
        }

        Integer boardId = boardDTO.getBoardId(); // ✅ @RequestParam 대신 DTO에서 꺼냄
        if (boardId == null || boardId <= 0) {
            res.put("ok", false);
            res.put("message", "글 정보가 필요합니다.");
            res.put("users", new ArrayList<>());
            return res;
        }

        try {
            // =========================================================
            // 2) 조회 파라미터 구성
            boardDTO.setBoardId(boardId);
            boardDTO.setCondition("BOARD_LIKE_MEMBER_LIST");

            List<BoardDTO> likeMembers = boardService.selectAll(boardDTO);
            if (likeMembers == null) likeMembers = new ArrayList<>();

            // =========================================================
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
}
