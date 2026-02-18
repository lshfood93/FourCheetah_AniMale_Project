package fourcheetah.animale.web.controller.board;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.service.board.BoardService;
import jakarta.servlet.http.HttpSession;

@Controller
public class MyPostPageController {

    @Autowired
    private BoardService boardService; // 서비스 DI

    @GetMapping("/myPostPage") // 기존 myPostPage.do 대응
    public String myPostPage(HttpSession session, Model model, BoardDTO boardDTO) {

        // 1) 세션 체크
        if (session == null) {
            System.out.println("[내 글보기 이동 로그] 세션 없음 : 로그인 필요");
            model.addAttribute("msg", "로그인 정보가 없습니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        // 2) memberId 꺼내기 + 유효성
        Integer memberId = (Integer) session.getAttribute("memberId");
        System.out.println("[내 글보기 이동 로그] 세션 확인 : memberId=[" + memberId + "]");

        if (memberId == null) {
            System.out.println("[내 글보기 이동 로그] memberId 없음 : 로그인 필요");
            model.addAttribute("msg", "로그인 정보가 없습니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        // 3) 내가 좋아요 누른 글 목록
        boardDTO.setCondition("MY_BOARD_LIKE_LIST");
        boardDTO.setMemberId(memberId);

        List<BoardDTO> myBoardLikeList = boardService.selectAll(boardDTO);
        System.out.println("[내 글보기 이동 로그] 좋아요글 조회 완료: count=[" + myBoardLikeList.size() + "]");
        model.addAttribute("myBoardLikeList", myBoardLikeList);

        // 4) 내가 작성한 글 목록
       
        boardDTO.setCondition("MY_BOARD_WRITE_LIST");
        boardDTO.setMemberId(memberId);

        List<BoardDTO> myBoardWriteList = boardService.selectAll(boardDTO);
        System.out.println("[내 글보기 이동 로그] 작성글 조회 완료 : count=[" + myBoardWriteList.size() + "]");
        model.addAttribute("myBoardWriteList", myBoardWriteList);

        // 5) 화면 이동 (forward 느낌 = 뷰 반환)
        return "mypost";
    }
}
