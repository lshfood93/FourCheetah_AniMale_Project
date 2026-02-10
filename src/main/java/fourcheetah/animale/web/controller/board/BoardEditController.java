package fourcheetah.animale.web.controller.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult; // [추가]
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.service.board.BoardService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@Controller
public class BoardEditController {

    @Autowired
    private BoardService boardService;

    // 수정 폼 페이지 진입(GET)
    @GetMapping("/boardEditPage")
    public String boardEditPage(
            HttpServletRequest request,
            Model model,
            BoardDTO boardDTO, // [수정] 커맨드객체로 받기
            BindingResult br                                 // [추가] boardDTO 바로 다음에 위치!
    ) {

        // 1) 로그인 체크
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "mainPage");
            return "message";
        }

        int loginMemberId = (int) session.getAttribute("memberId");
        String memberRole = (String) session.getAttribute("memberRole");

        // 2) boardId 바인딩/유효성 검사
        // [삭제] @RequestParam boardIdParam 파싱 로직 전부 제거
        if (br.hasFieldErrors("boardId")) { // [추가] boardId 타입 변환 오류
            model.addAttribute("msg", "게시글 번호가 올바르지 않습니다.");
            model.addAttribute("location", "boardList");
            return "message";
        }

        Integer boardId = boardDTO.getBoardId(); // [수정]
        if (boardId == null || boardId <= 0) {
            model.addAttribute("msg", "잘못된 게시글 접근입니다.");
            model.addAttribute("location", "boardList");
            return "message";
        }

        // 3) 게시글 존재 확인
        boardDTO.setCondition("BOARD_DETAIL");
        BoardDTO boardData = boardService.selectOne(boardDTO);

        if (boardData == null) {
            model.addAttribute("msg", "존재하지 않는 게시글입니다.");
            model.addAttribute("location", "boardList");
            return "message";
        }

        // 4) 권한 체크
        boolean isWriter = (boardData.getMemberId() == loginMemberId);
        boolean isAdmin = "ADMIN".equals(memberRole);

        if (!isWriter && !isAdmin) {
            model.addAttribute("msg", "수정 권한이 없습니다.");
            model.addAttribute("location", "boardDetail?boardId=" + boardId);
            return "message";
        }

        // 5) 수정 폼에 뿌릴 데이터
        model.addAttribute("boardData", boardData);
        return "edit";
    }

    // 수정 처리(POST)
    @PostMapping("/boardEdit")
    public String boardEdit(
            HttpServletRequest request,
            Model model,
            BoardDTO boardDTO, // [수정] boardId/title/content 모두 DTO로 바인딩
            BindingResult br                                 // [추가] boardDTO 바로 다음!
    ) {

        // 1) 로그인 체크
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "mainPage");
            return "message";
        }

        int loginMemberId = (int) session.getAttribute("memberId");
        String memberRole = (String) session.getAttribute("memberRole");

        // 2) boardId 타입 변환 오류 체크
        if (br.hasFieldErrors("boardId")) { // [추가]
            model.addAttribute("msg", "게시글 번호가 올바르지 않습니다.");
            model.addAttribute("location", "boardList");
            return "message";
        }

        Integer boardId = boardDTO.getBoardId(); // [수정]
        if (boardId == null || boardId <= 0) {
            model.addAttribute("msg", "잘못된 게시글 접근입니다.");
            model.addAttribute("location", "boardList");
            return "message";
        }

        // 3) 게시글 존재 확인
        boardDTO.setBoardId(boardId);
        boardDTO.setCondition("BOARD_DETAIL");

        BoardDTO boardData = boardService.selectOne(boardDTO);
        if (boardData == null) {
            model.addAttribute("msg", "존재하지 않는 게시글입니다.");
            model.addAttribute("location", "boardList");
            return "message";
        }

        // 4) 권한 체크
        boolean isWriter = (boardData.getMemberId() == loginMemberId);
        boolean isAdmin = "ADMIN".equals(memberRole);

        if (!isWriter && !isAdmin) {
            model.addAttribute("msg", "수정 권한이 없습니다.");
            model.addAttribute("location", "boardDetail?boardId=" + boardId);
            return "message";
        }

        // 5) 제목/내용 유효성 검사 (DTO에서 꺼내서 검사)
        String title = boardDTO.getBoardTitle();     // [수정] @RequestParam 제거
        String content = boardDTO.getBoardContent(); // [수정] @RequestParam 제거

        if (title == null || title.trim().isEmpty()) {
            model.addAttribute("msg", "제목은 필수입니다.");
            model.addAttribute("location", "boardEdit?boardId=" + boardId);
            return "message";
        }
        title = title.trim();
        if (title.length() > 255) {
            model.addAttribute("msg", "제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "boardEdit?boardId=" + boardId);
            return "message";
        }

        if (content == null || content.trim().isEmpty()) {
            model.addAttribute("msg", "내용은 필수입니다.");
            model.addAttribute("location", "boardEdit?boardId=" + boardId);
            return "message";
        }
        content = content.trim();
        if (content.length() > 100000) {
            model.addAttribute("msg", "내용이 너무 깁니다.");
            model.addAttribute("location", "boardEdit?boardId=" + boardId);
            return "message";
        }

        // 6) UPDATE 호출 준비
        boardDTO.setCondition("BOARD_UPDATE");
        boardDTO.setBoardId(boardId);
        boardDTO.setBoardTitle(title);
        boardDTO.setBoardContent(content);

        // 관리자면 작성자 memberId로 update해야 WHERE 통과
        boardDTO.setMemberId(isAdmin ? boardData.getMemberId() : loginMemberId);

        boolean result = boardService.update(boardDTO);
        if (!result) {
            model.addAttribute("msg", "게시글 수정에 실패했습니다.");
            model.addAttribute("location", "boardDetail?boardId=" + boardId);
            return "message";
        }

        // 7) 성공 redirect
        return "redirect:/boardDetail?boardId=" + boardId;
    }
}
