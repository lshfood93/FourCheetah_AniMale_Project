package fourcheetah.animale.web.controller.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;                      // ✅ CHANGED
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.service.board.BoardService;
import jakarta.servlet.http.HttpSession;

@Controller
public class BoardDeleteController {

    @Autowired
    private BoardService boardService;

    @PostMapping("/boardDelete")
    public String deleteBoard(
            BoardDTO boardDTO,          // 커맨드객체 바인딩
            BindingResult br,           // 변환 오류 체크
            HttpSession session,
            Model model                 // ✅ CHANGED: RedirectAttributes -> Model
    ) {

        // 1) 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            System.out.println("[게시글 삭제 로그] 실패: 로그인 세션 없음");
            return message(model, "로그인이 필요한 기능입니다.", "/mainPage"); // ✅ CHANGED
        }

        // ⚠️ memberId가 Integer가 아닐 수 있으면(문자열로 들어오는 경우) 안전 파싱 권장
        int loginMemberId;
        try {
            Object memberIdObj = session.getAttribute("memberId");
            if (memberIdObj instanceof Integer) {
                loginMemberId = (Integer) memberIdObj;
            } else {
                loginMemberId = Integer.parseInt(String.valueOf(memberIdObj));
            }
        } catch (Exception e) {
            System.out.println("[게시글 삭제 로그] 실패: memberId 형변환 오류");
            return message(model, "로그인 정보가 올바르지 않습니다.", "/mainPage");
        }

        String memberRole = (String) session.getAttribute("memberRole");
        System.out.println("[게시글 삭제 로그] 로그인 memberId=" + loginMemberId + ", role=" + memberRole);

        // 2) boardId 유효성 검사 (DTO 바인딩 기반)
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[게시글 삭제 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/boardList"); // ✅ CHANGED
        }

        Integer boardId = boardDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            System.out.println("[게시글 삭제 로그] 실패: boardId 없음/0이하");
            return message(model, "잘못된 게시글 접근입니다.", "/boardList"); // ✅ CHANGED
        }

        // 3) 게시글 존재 확인 (BOARD_DETAIL)
        boardDTO.setCondition("BOARD_DETAIL");
        boardDTO.setBoardId(boardId);

        BoardDTO boardData = boardService.selectOne(boardDTO);
        if (boardData == null) {
            System.out.println("[게시글 삭제 로그] 실패: 존재하지 않는 게시글 boardId=" + boardId);
            return message(model, "존재하지 않는 게시글입니다.", "/boardList"); // ✅ CHANGED
        }

        // 4) 권한 체크 (작성자 본인 OR 관리자)
        boolean isWriter = (boardData.getMemberId() == loginMemberId);
        boolean isAdmin  = "ADMIN".equals(memberRole);

        if (!isWriter && !isAdmin) {
            return message(model, "삭제 권한이 없습니다.", "/boardDetail?boardId=" + boardId); // ✅ CHANGED
        }

        // 5) 삭제 호출
        int deleteMemberId = isAdmin ? boardData.getMemberId() : loginMemberId;

        boardDTO.setCondition("BOARD_DELETE");
        boardDTO.setBoardId(boardId);
        boardDTO.setMemberId(deleteMemberId);

        boolean result = boardService.delete(boardDTO);
        if (!result) {
            System.out.println("[게시글 삭제 로그] 실패: DELETE 실패 boardId=" + boardId);
            return message(model, "게시글 삭제에 실패했습니다.", "/boardDetail?boardId=" + boardId); // ✅ CHANGED
        }

        // 6) 성공 처리
        System.out.println("[게시글 삭제 로그] 성공: boardId=" + boardId);
        return message(
                model,
                "게시글이 삭제되었습니다.",
                "/boardList?boardCategory=" + boardData.getBoardCategory()
        ); // ✅ CHANGED
    }

    // ✅ NEW: message.jsp 렌더링 공통 처리
    private String message(Model model, String msg, String location) {
        model.addAttribute("msg", msg);
        model.addAttribute("location", location);
        return "message"; // message.jsp
    }
}
