package fourcheetah.animale.web.controller.board;

import java.util.Collections;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.dto.board.BoardLikeDTO;
import fourcheetah.animale.web.dto.board.ReplyDTO;
import fourcheetah.animale.web.service.board.BoardLikeService;
import fourcheetah.animale.web.service.board.BoardService;
import fourcheetah.animale.web.service.board.ReplyService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@Controller
public class BoardDetailController {

    @Autowired
    private BoardService boardService;

    @Autowired
    private ReplyService replyService;

    @Autowired
    private BoardLikeService boardLikeSerivce;

    @GetMapping("/boardDetail")
    public String boardDetail(
            BoardDTO boardDTO,                 // 커맨드 객체 바인딩
            BindingResult br,                  // 타입 변환 오류 체크 (boardDTO 바로 다음)
            BoardLikeDTO boardLikeDTO,
            ReplyDTO replyDTO,
            HttpServletRequest request,
            HttpServletResponse response,
            Model model
    ) {
        model.addAttribute("activeMenu", "COMMUNITY");

        // ==============================
        // 0) boardId 유효성 (DTO 바인딩 기반)
        // ==============================
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[게시글 상세보기 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/main"); // ✅ CHANGED (뷰 렌더링)
        }

        Integer boardId = boardDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            System.out.println("[게시글 상세보기 로그] 실패: boardId 유효성 검증 실패");
            return message(model, "잘못된 게시글 접근입니다.", "/main"); // ✅ CHANGED
        }

        // ==============================
        // 1) 조회수 쿠키 검사 & 증가
        // ==============================
        String cookieName = "board_view_" + boardId;
        boolean isViewed = hasCookie(request.getCookies(), cookieName);
        System.out.println("[게시글 상세보기 로그] 쿠키 검사 name=[" + cookieName + "], isViewed=[" + isViewed + "]");

        if (!isViewed) {
            boardDTO.setBoardId(boardId);
            boardDTO.setCondition("UPDATE_BOARD_VIEWS");

            boolean isUpdated = boardService.update(boardDTO);

            if (isUpdated) {
                System.out.println("[게시글 상세보기 로그] 조회수 증가 성공 : boardId=" + boardId);

                Cookie viewCookie = new Cookie(cookieName, cookieName);
                viewCookie.setMaxAge(60 * 60 * 24); // 1일
                viewCookie.setPath("/");
                viewCookie.setHttpOnly(true);
                response.addCookie(viewCookie);
            } else {
                System.out.println("[게시글 상세보기 로그] 조회수 증가 실패 : boardId=" + boardId);
            }
        }

        // ==============================
        // 2) 게시글 상세 조회(selectOne)
        // ==============================
        boardDTO.setBoardId(boardId);
        boardDTO.setCondition("BOARD_DETAIL");

        BoardDTO boardData = boardService.selectOne(boardDTO);
        if (boardData == null) {
            System.out.println("[게시글 상세보기 로그] 실패: 게시글 없음 boardId=" + boardId);
            return message(model, "존재하지 않는 게시글입니다.", "/main"); // ✅ CHANGED
        }

        // ==============================
        // 3) 좋아요 개수
        // ==============================
        boardLikeDTO.setBoardId(boardId);
        boardLikeDTO.setCondition("BOARD_LIKE_COUNT");

        BoardLikeDTO likeCountRes = boardLikeSerivce.selectOne(boardLikeDTO);
        int likeCount = (likeCountRes == null) ? 0 : likeCountRes.getLikeCnt();
        model.addAttribute("likeCount", likeCount);

        // ==============================
        // 4) 내가 눌렀는지(로그인 시에만)
        // ==============================
        boolean likedByMe = false;

        HttpSession session = request.getSession(false);
        Integer memberId = getLoginMemberIdOrNull(session); // ✅ CHANGED: 안전 파싱

        if (memberId != null) {
            boardLikeDTO.setBoardId(boardId);
            boardLikeDTO.setMemberId(memberId);
            boardLikeDTO.setCondition("BOARD_LIKE_CHECK");

            BoardLikeDTO checkRes = boardLikeSerivce.selectOne(boardLikeDTO);
            likedByMe = (checkRes != null && checkRes.getIsLiked() > 0);
        }
        model.addAttribute("likedByMe", likedByMe);

        // ==============================
        // 5) 댓글 목록(selectAll)
        // ==============================
        replyDTO.setBoardId(boardId);
        replyDTO.setCondition("REPLY_LIST_RECENT");

        List<ReplyDTO> replyList = replyService.selectAll(replyDTO);
        if (replyList == null) replyList = Collections.emptyList();

        System.out.println("[게시글 상세보기 로그] 댓글 조회 완료 : count=[" + replyList.size() + "]");

        model.addAttribute("boardData", boardData);
        model.addAttribute("replyList", replyList);

        return "boarddetail";
    }

    // ✅ NEW: message.jsp 뷰 렌더링 공통 처리
    private String message(Model model, String msg, String location) {
        model.addAttribute("msg", msg);
        model.addAttribute("location", location);
        return "message";
    }

    // NEW: 세션 memberId 안전 파싱 (없거나 이상하면 null)
    private Integer getLoginMemberIdOrNull(HttpSession session) {
        if (session == null) return null;

        Object memberIdObj = session.getAttribute("memberId");
        if (memberIdObj == null) return null;

        try {
            if (memberIdObj instanceof Integer) {
                return (Integer) memberIdObj;
            }
            return Integer.parseInt(String.valueOf(memberIdObj));
        } catch (Exception e) {
            System.out.println("[로그인 체크] memberId 형변환 실패 memberIdObj=" + memberIdObj);
            return null;
        }
    }

    private boolean hasCookie(Cookie[] cookies, String name) {
        if (cookies == null) return false;
        for (Cookie c : cookies) {
            if (name.equals(c.getName())) return true;
        }
        return false;
    }
}
