package fourcheetah.animale.web.controller.board;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.service.board.BoardService;

@Controller
public class BoardListController {

    @Autowired
    private BoardService boardService;

    @GetMapping("/boardList")
    public String boardList(
            BoardDTO boardDTO,          // 커맨드 객체 바인딩
            BindingResult br,           // (선택) 변환 오류 체크
            Model model
    ) {


        model.addAttribute("activeMenu", "COMMUNITY");

        // =========================================================
        // 1) category(=boardCategory) 필수 파라미터 검증
        String category = boardDTO.getBoardCategory();

        if (category == null || category.trim().isEmpty()) {
            System.out.println("[게시판 리스트 로그] category 없음/빈값 → 메인으로 리다이렉트");
            return "redirect:/mainPage"; // ✅ 유지: 이건 메시지 필요 없이 바로 메인으로 보내는 케이스
        }

        category = category.trim().toUpperCase();
        boardDTO.setBoardCategory(category);
        System.out.println("[게시판 리스트 로그] category=[" + category + "]");

        // =========================================================
        // 2) 검색 파라미터 수신(커맨드 객체)
        String condition = boardDTO.getCondition();
        String keyword   = boardDTO.getKeyword();

        System.out.println("[게시판 리스트 로그] condition=[" + condition + "]");
        System.out.println("[게시판 리스트 로그] keyword(raw)=[" + keyword + "]");

        // =========================================================
        // 3) 검색 여부 판단(화이트리스트) + keyword 정리(trim)
        boolean isSearch =
                "BOARD_SEARCH_TITLE".equals(condition) ||
                "BOARD_SEARCH_WRITER".equals(condition) ||
                "BOARD_SEARCH_CONTENT".equals(condition);

        if (keyword != null) {
            keyword = keyword.trim();
            if (keyword.isEmpty()) {
                keyword = null;
            }
        }
        boardDTO.setKeyword(keyword);

        System.out.println("[게시판 리스트 로그] isSearch=[" + isSearch + "], keyword(trim)=[" + keyword + "]");

        // CHANGED: 검색인데 키워드가 없으면 message.jsp "뷰 렌더링"으로 차단
        if (isSearch && keyword == null) {
            System.out.println("[게시판 리스트 로그] 검색 요청인데 keyword 없음 → message.jsp 렌더링");
            return message(model, "검색어가 없습니다.", "/boardList?boardCategory=" + category);
        }

        // =========================================================
        // 4) 공지 리스트 조회
        boardDTO.setBoardCategory(category);
        boardDTO.setCondition("BOARD_NOTICE_LIST");

        List<BoardDTO> noticeList = boardService.selectAll(boardDTO);
        System.out.println("[게시판 리스트 로그] 공지 조회 완료 : noticeCount=[" + (noticeList == null ? 0 : noticeList.size()) + "]");

        // =========================================================
        // 5) 일반 리스트(검색/전체글보기)
        if (isSearch) {
            boardDTO.setCondition(condition);
            boardDTO.setKeyword(keyword);
        } else {
            boardDTO.setCondition("CATEGORY_LIST");
            condition = "CATEGORY_LIST";
            boardDTO.setKeyword(null);
        }

        System.out.println("[게시판 리스트 로그] DAO condition=[" + boardDTO.getCondition()
                + "], category=[" + category + "], keyword=[" + boardDTO.getKeyword() + "]");

        List<BoardDTO> boardList = boardService.selectAll(boardDTO);
        System.out.println("[게시판 리스트 로그] 일반/검색 조회 완료 : count=[" + (boardList == null ? 0 : boardList.size()) + "]");

        // =========================================================
        // 6) JSP로 전달 (검색 상태 유지 포함)
        model.addAttribute("noticeList", noticeList);
        model.addAttribute("boardList", boardList);
        model.addAttribute("category", category);

        model.addAttribute("condition", condition);
        model.addAttribute("keyword", keyword);

        return "board";
    }

    //  NEW: message.jsp 뷰 렌더링 공통 처리
    private String message(Model model, String msg, String location) {
        model.addAttribute("msg", msg);
        model.addAttribute("location", location);
        return "message";
    }
}
