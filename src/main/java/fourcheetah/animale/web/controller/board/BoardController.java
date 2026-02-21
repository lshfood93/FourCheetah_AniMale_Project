package fourcheetah.animale.web.controller.board;

import java.util.Collections;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.dto.board.BoardLikeDTO;
import fourcheetah.animale.web.dto.board.ReplyDTO;
import fourcheetah.animale.web.service.board.BoardLikeService;
import fourcheetah.animale.web.service.board.BoardService;
import fourcheetah.animale.web.service.board.ReplyService;
import fourcheetah.animale.web.repository.board.BoardReportDAO;
import fourcheetah.animale.web.aop.SanctionCheck;
import fourcheetah.animale.web.aop.DeletedBoardCheck;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;


/**
 * 게시글 통합 컨트롤러
 * 
 * 기능:
 * - 목록: GET /boardList
 * - 상세: GET /boardDetail
 * - 작성: GET/POST /boardWritePage, boardWrite
 * - 수정: GET/POST /boardEditPage, boardEdit
 * - 삭제: POST /boardDelete
 * - 내 글 보기: GET /myPostPage
 * 
 * 통합 이전:
 * - BoardListController
 * - BoardDetailController
 * - BoardWriteController
 * - BoardEditController
 * - BoardDeleteController
 * - MyPostPageController
 */

@Controller
public class BoardController {

    @Autowired
    private BoardService boardService;

    @Autowired
    private ReplyService replyService;

    @Autowired
    private BoardLikeService boardLikeService;

    @Autowired
    private BoardReportDAO boardReportDAO;  // ✅ NEW: 신고 여부 체크용

    // =========================================================
    // 1) 게시글 삭제 (POST /boardDelete)
    @SanctionCheck                      
    @DeletedBoardCheck(allowAdmin = true) 
    @PostMapping("/boardDelete")
    public String deleteBoard(
            BoardDTO boardDTO,
            BindingResult br,
            HttpSession session,
            Model model
    ) {

        // 1) 로그인 체크
        Integer loginMemberId = getLoginMemberIdOrNull(session);
        if (loginMemberId == null) {
            System.out.println("[게시글 삭제 로그] 실패: 로그인 세션 없음/파싱 실패");
            return message(model, "로그인이 필요한 기능입니다.", "/mainPage");
        }

        String memberRole = (String) session.getAttribute("memberRole");
        System.out.println("[게시글 삭제 로그] 로그인 memberId=" + loginMemberId + ", role=" + memberRole);

        // 2) boardId 유효성
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[게시글 삭제 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/boardList");
        }

        Integer boardId = boardDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            System.out.println("[게시글 삭제 로그] 실패: boardId 없음/0이하");
            return message(model, "잘못된 게시글 접근입니다.", "/boardList");
        }

        // 3) 게시글 존재 확인
        boardDTO.setCondition("BOARD_DETAIL");
        boardDTO.setBoardId(boardId);

        BoardDTO boardData = boardService.selectOne(boardDTO);
        if (boardData == null) {
            System.out.println("[게시글 삭제 로그] 실패: 존재하지 않는 게시글 boardId=" + boardId);
            return message(model, "존재하지 않는 게시글입니다.", "/boardList");
        }

        // 4) 권한 체크 (작성자 OR 관리자)
        boolean isWriter = (boardData.getMemberId() == loginMemberId);
        boolean isAdmin  = "ADMIN".equals(memberRole);

        if (!isWriter && !isAdmin) {
            return message(model, "삭제 권한이 없습니다.", "/boardDetail?boardId=" + boardId);
        }

        // 5) 삭제 호출
        int deleteMemberId = isAdmin ? boardData.getMemberId() : loginMemberId;

        boardDTO.setCondition("BOARD_DELETE");
        boardDTO.setBoardId(boardId);
        boardDTO.setMemberId(deleteMemberId);

        boolean result = boardService.delete(boardDTO);
        if (!result) {
            System.out.println("[게시글 삭제 로그] 실패: DELETE 실패 boardId=" + boardId);
            return message(model, "게시글 삭제에 실패했습니다.", "/boardDetail?boardId=" + boardId);
        }

        // 6) 성공
        System.out.println("[게시글 삭제 로그] 성공: boardId=" + boardId);
        return message(model, "게시글이 삭제되었습니다.",
                "/boardList?boardCategory=" + boardData.getBoardCategory());
    }

    // =========================================================
    // 2) 게시글 상세 (GET /boardDetail)
    @GetMapping("/boardDetail")
    public String boardDetail(
            BoardDTO boardDTO,
            BindingResult br,
            BoardLikeDTO boardLikeDTO,
            ReplyDTO replyDTO,
            HttpServletRequest request,
            HttpServletResponse response,
            Model model
    ) {
        model.addAttribute("activeMenu", "COMMUNITY");

        // 0) boardId 유효성
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[게시글 상세보기 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/main");
        }

        Integer boardId = boardDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            System.out.println("[게시글 상세보기 로그] 실패: boardId 유효성 검증 실패");
            return message(model, "잘못된 게시글 접근입니다.", "/main");
        }

        // 1) 조회수 쿠키 검사 & 증가
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

        // 2) 게시글 상세 조회
        // ⭐⭐⭐ 로그인 사용자 ID 가져오기 (isLiked, isReported 계산용) 
        HttpSession session = request.getSession(false);
        // [FIX] Integer로 받기 (null 허용)
        Integer currentMemberId = (session != null) ? (Integer) session.getAttribute("memberId") : null;
        
        boardDTO.setBoardId(boardId);
        boardDTO.setCondition("BOARD_DETAIL");
        boardDTO.setMemberId(currentMemberId != null ? currentMemberId : 0);

        BoardDTO boardData = boardService.selectOne(boardDTO);
        if (boardData == null) {
            System.out.println("[게시글 상세보기 로그] 실패: 게시글 없음 boardId=" + boardId);
            return message(model, "존재하지 않는 게시글입니다.", "/main");
        }

        // ✅ NEW: 관리자 신고 승인으로 삭제된 게시글 - 목록으로 redirect + 모달 플래그
        if ("내용삭제".equals(boardData.getBoardStatus())) {
            System.out.println("[게시글 상세보기 로그] 내용삭제 게시글 접근 차단 - boardId=" + boardId);
            if (session == null) session = request.getSession(true);
            session.setAttribute("deletedBoardRedirect", true);
            String category = boardData.getBoardCategory();
            if (category == null || category.trim().isEmpty()) category = "ANIME";
            return "redirect:/boardList?boardCategory=" + category;
        }

        // 3) 좋아요 개수
        boardLikeDTO.setBoardId(boardId);
        boardLikeDTO.setCondition("BOARD_LIKE_COUNT");

        BoardLikeDTO likeCountRes = boardLikeService.selectOne(boardLikeDTO);
        int likeCount = (likeCountRes == null) ? 0 : likeCountRes.getLikeCnt();
        model.addAttribute("likeCount", likeCount);

        // 4) 내가 눌렀는지(로그인 시에만)
        boolean likedByMe = false;

        Integer memberId = currentMemberId;  // ⭐ 위에서 이미 가져온 memberId 재사용

        if (memberId != null) {
            boardLikeDTO.setBoardId(boardId);
            boardLikeDTO.setMemberId(memberId);
            boardLikeDTO.setCondition("BOARD_LIKE_CHECK");

            BoardLikeDTO checkRes = boardLikeService.selectOne(boardLikeDTO);
            likedByMe = (checkRes != null && checkRes.getIsLiked() > 0);
        }
        
        model.addAttribute("isLiked", likedByMe);

        // ✅ NEW: 내가 신고한 게시글인지 (신고버튼 비활성화용)
        boolean isReported = false;
        if (memberId != null) {
            isReported = boardReportDAO.isReportedByMember(boardId, memberId);
        }
        model.addAttribute("isReported", isReported);
        System.out.println("[게시글 상세보기 로그] isReported=" + isReported);

        // 5) 댓글 목록
        replyDTO.setBoardId(boardId);
        replyDTO.setCondition("REPLY_LIST_RECENT");

        List<ReplyDTO> replyList = replyService.selectAll(replyDTO);
        if (replyList == null) replyList = Collections.emptyList();

        System.out.println("[게시글 상세보기 로그] 댓글 조회 완료 : count=[" + replyList.size() + "]");

        model.addAttribute("boardData", boardData);
        model.addAttribute("replyList", replyList);

        return "boarddetail";
    }

    // =========================================================
    // 3) 수정 폼 진입 (GET /boardEditPage)
    @SanctionCheck                          
    @DeletedBoardCheck(allowAdmin = true)
    @GetMapping("/boardEditPage")
    public String boardEditPage(
            HttpServletRequest request,
            Model model,
            BoardDTO boardDTO,
            BindingResult br
    ) {
        HttpSession session = request.getSession(false);

        Integer loginMemberId = getLoginMemberIdOrNull(session);
        if (loginMemberId == null) {
            return message(model, "로그인이 필요한 기능입니다.", "mainPage");
        }

        String memberRole = (String) session.getAttribute("memberRole");

        if (br != null && br.hasFieldErrors("boardId")) {
            return message(model, "게시글 번호가 올바르지 않습니다.", "boardList");
        }

        Integer boardId = boardDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            return message(model, "잘못된 게시글 접근입니다.", "boardList");
        }

        // 게시글 존재 확인
        boardDTO.setCondition("BOARD_DETAIL");
        BoardDTO boardData = boardService.selectOne(boardDTO);

        if (boardData == null) {
            return message(model, "존재하지 않는 게시글입니다.", "boardList");
        }

        // 권한 체크
        boolean isWriter = (boardData.getMemberId() == loginMemberId);
        boolean isAdmin = "ADMIN".equals(memberRole);

        if (!isWriter && !isAdmin) {
            return message(model, "수정 권한이 없습니다.", "boardDetail?boardId=" + boardId);
        }

        model.addAttribute("type", "BOARD");
        model.addAttribute("boardData", boardData);
        return "edit";
    }

    // =========================================================
    // 4) 수정 처리 (POST /boardEdit)
    @SanctionCheck                   
    @DeletedBoardCheck(allowAdmin = true) 
    @PostMapping("/boardEdit")
    public String boardEdit(
            HttpServletRequest request,
            Model model,
            BoardDTO boardDTO,
            BindingResult br
    ) {
        HttpSession session = request.getSession(false);

        Integer loginMemberId = getLoginMemberIdOrNull(session);
        if (loginMemberId == null) {
            return message(model, "로그인이 필요한 기능입니다.", "mainPage");
        }

        String memberRole = (String) session.getAttribute("memberRole");

        if (br != null && br.hasFieldErrors("boardId")) {
            return message(model, "게시글 번호가 올바르지 않습니다.", "boardList");
        }

        Integer boardId = boardDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            return message(model, "잘못된 게시글 접근입니다.", "boardList");
        }

        // 게시글 존재 확인
        boardDTO.setBoardId(boardId);
        boardDTO.setCondition("BOARD_DETAIL");

        BoardDTO boardData = boardService.selectOne(boardDTO);
        if (boardData == null) {
            return message(model, "존재하지 않는 게시글입니다.", "boardList");
        }

        // 권한 체크
        boolean isWriter = (boardData.getMemberId() == loginMemberId);
        boolean isAdmin = "ADMIN".equals(memberRole);

        if (!isWriter && !isAdmin) {
            return message(model, "수정 권한이 없습니다.", "boardDetail?boardId=" + boardId);
        }

        // 제목/내용 검증
        String title = boardDTO.getBoardTitle();
        String content = boardDTO.getBoardContent();

        if (title == null || title.trim().isEmpty()) {
            return message(model, "제목은 필수입니다.", "boardEdit?boardId=" + boardId);
        }
        title = title.trim();
        if (title.length() > 255) {
            return message(model, "제목은 255자 이내로 작성해주세요.", "boardEdit?boardId=" + boardId);
        }

        if (content == null || content.trim().isEmpty()) {
            return message(model, "내용은 필수입니다.", "boardEdit?boardId=" + boardId);
        }
        content = content.trim();
        if (content.length() > 100000) {
            return message(model, "내용이 너무 깁니다.", "boardEdit?boardId=" + boardId);
        }

        // UPDATE 호출
        boardDTO.setCondition("BOARD_UPDATE");
        boardDTO.setBoardId(boardId);
        boardDTO.setBoardTitle(title);
        boardDTO.setBoardContent(content);

        // 관리자면 작성자 memberId로 update (WHERE 통과)
        boardDTO.setMemberId(isAdmin ? boardData.getMemberId() : loginMemberId);

        boolean result = boardService.update(boardDTO);
        if (!result) {
            return message(model, "게시글 수정에 실패했습니다.", "boardDetail?boardId=" + boardId);
        }

        return "redirect:/boardDetail?boardId=" + boardId;
    }

    // =========================================================
    // 5) 게시판 리스트 (GET /boardList)
    @GetMapping("/boardList")
    public String boardList(
            BoardDTO boardDTO,
            BindingResult br,
            HttpServletRequest request,
            Model model
    ) {

        model.addAttribute("activeMenu", "COMMUNITY");

        // ✅ NEW: 삭제된 게시글 접근 redirect 플래그 처리 (board.jsp에서 모달 표시)
        HttpSession session = request.getSession(false);
        if (session != null && Boolean.TRUE.equals(session.getAttribute("deletedBoardRedirect"))) {
            session.removeAttribute("deletedBoardRedirect");
            model.addAttribute("deletedBoardRedirect", true);
        }

        // 1) category 필수 검증
        String category = boardDTO.getBoardCategory();

        if (category == null || category.trim().isEmpty()) {
            System.out.println("[게시판 리스트 로그] category 없음/빈값 → 메인으로 리다이렉트");
            return "redirect:/mainPage";
        }

        category = category.trim().toUpperCase();
        boardDTO.setBoardCategory(category);
        System.out.println("[게시판 리스트 로그] category=[" + category + "]");

        // 2) 검색 파라미터
        String condition = boardDTO.getCondition();
        String keyword   = boardDTO.getKeyword();

        boolean isSearch =
                "BOARD_SEARCH_TITLE".equals(condition) ||
                "BOARD_SEARCH_WRITER".equals(condition) ||
                "BOARD_SEARCH_CONTENT".equals(condition);

        if (keyword != null) {
            keyword = keyword.trim();
            if (keyword.isEmpty()) keyword = null;
        }
        boardDTO.setKeyword(keyword);

        if (isSearch && keyword == null) {
            return message(model, "검색어가 없습니다.", "/boardList?boardCategory=" + category);
        }

        // 3) 공지 리스트
        boardDTO.setBoardCategory(category);
        boardDTO.setCondition("BOARD_NOTICE_LIST");

        List<BoardDTO> noticeList = boardService.selectAll(boardDTO);

        // 4) 일반 리스트
        if (isSearch) {
            boardDTO.setCondition(condition);
            boardDTO.setKeyword(keyword);
        } else {
            boardDTO.setCondition("CATEGORY_LIST");
            condition = "CATEGORY_LIST";
            boardDTO.setKeyword(null);
        }

        List<BoardDTO> boardList = boardService.selectAll(boardDTO);

        // 5) JSP 전달
        model.addAttribute("noticeList", noticeList);
        model.addAttribute("boardList", boardList);
        model.addAttribute("boardCategory", category);

        model.addAttribute("condition", condition);
        model.addAttribute("keyword", keyword);

        return "board";
    }

    // =========================================================
    // 6) 글쓰기 진입 검증 + redirect (GET /boardWritePage)
    @SanctionCheck                     
    @GetMapping("/boardWritePage")
    public String boardWritePage(
            BoardDTO boardDTO,
            BindingResult br,
            HttpServletRequest request,
            Model model
    ) {
        HttpSession session = request.getSession(false);

        Integer loginMemberId = getLoginMemberIdOrNull(session);
        if (loginMemberId == null) {
            System.out.println("[글쓰기 이동 로그] 실패: 로그인 세션 없음");
            return message(model, "로그인이 필요한 기능입니다.", "/login");
        }

        String type = boardDTO.getType();
        if (type == null || type.trim().isEmpty()) type = "BOARD";
        type = type.trim().toUpperCase();

        boolean isBoard = "BOARD".equals(type);
        boolean isNews  = "NEWS".equals(type);

        if (!isBoard && !isNews) {
            return message(model, "잘못된 글쓰기 접근입니다.", "/mainPage");
        }

        if (isBoard) {
            String category = boardDTO.getBoardCategory();
            if (category == null || category.trim().isEmpty()) category = "ANIME";
            category = category.trim().toUpperCase();

            return "redirect:/write?type=BOARD&boardCategory=" + category;
        }

        return "redirect:/write?type=NEWS";
    }

    // =========================================================
    // 7) write.jsp 렌더링 (GET /write)
    @SanctionCheck  
    @GetMapping("/write")
    public String writePage(
            BoardDTO boardDTO,
            HttpServletRequest request,
            Model model
    ) {

        HttpSession session = request.getSession(false);

        Integer loginMemberId = getLoginMemberIdOrNull(session);
        if (loginMemberId == null) {
            System.out.println("[글쓰기 화면 로그] 실패: 로그인 세션 없음");
            return message(model, "로그인이 필요한 기능입니다.", "/login");
        }

        model.addAttribute("activeMenu", "COMMUNITY");

        String type = boardDTO.getType();
        type = (type == null || type.trim().isEmpty()) ? "BOARD" : type.trim().toUpperCase();

        boolean isBoard = "BOARD".equals(type);
        boolean isNews  = "NEWS".equals(type);

        if (!isBoard && !isNews) {
            return message(model, "잘못된 글쓰기 접근입니다.", "/mainPage");
        }

        model.addAttribute("type", type);

        if (isBoard) {
            String category = boardDTO.getBoardCategory();
            if (category == null || category.trim().isEmpty()) category = "ANIME";
            model.addAttribute("boardCategory", category.trim().toUpperCase());
        }

        return "write";
    }

    // =========================================================
    // 8) 글쓰기 처리 (POST /boardWrite)
    @SanctionCheck  
    @PostMapping("/boardWrite")
    public String boardWrite(
            BoardDTO boardDTO,
            BindingResult br,
            HttpSession session,
            Model model
    ) {

        Integer memberId = getLoginMemberIdOrNull(session);
        if (memberId == null) {
            System.out.println("[게시글 작성 로그] 실패: 로그인 세션 없음");
            return message(model, "로그인이 필요한 기능입니다.", "/mainPage");
        }

        String memberRole = (String) (session != null ? session.getAttribute("memberRole") : null);
        System.out.println("[게시글 작성 로그] 로그인 memberId=" + memberId + ", role=" + memberRole);

        String category = boardDTO.getBoardCategory();
        String title = boardDTO.getBoardTitle();
        String content = boardDTO.getBoardContent();

        if (category == null || category.trim().isEmpty()) {
            return message(model, "게시판 카테고리가 올바르지 않습니다.", "/mainPage");
        }
        category = category.trim();
        boardDTO.setBoardCategory(category);

        if (title == null || title.trim().isEmpty()) {
            return message(model, "제목은 필수입니다.", "/boardWritePage?boardCategory=" + category);
        }
        title = title.trim();
        if (title.length() > 255) {
            return message(model, "제목은 255자 이내로 작성해주세요.", "/boardWritePage?boardCategory=" + category);
        }
        boardDTO.setBoardTitle(title);

        if (content == null || content.trim().isEmpty()) {
            return message(model, "내용은 필수입니다.", "/boardWritePage?boardCategory=" + category);
        }
        content = content.trim();
        if (content.length() > 100000) {
            return message(model, "내용이 너무 깁니다.", "/boardWritePage?boardCategory=" + category);
        }
        boardDTO.setBoardContent(content);

        // 최소 XSS 방어(기존 유지)
        String lowerContent = content.toLowerCase();
        if (lowerContent.contains("<script") || lowerContent.contains("javascript:")) {
            return message(model, "허용되지 않는 내용이 포함되어 있습니다.", "/boardWritePage?boardCategory=" + category);
        }

        // INSERT 호출
        boardDTO.setMemberId(memberId);
        boardDTO.setCondition("BOARD_INSERT");

        boolean inserted = boardService.insert(boardDTO);
        Integer newBoardId = boardDTO.getBoardId(); // DAO가 generatedId를 DTO에 세팅하는 구조여야 함

        if (!inserted || newBoardId == null || newBoardId <= 0) {
            return message(model, "게시글 작성에 실패했습니다.", "/boardList?boardCategory=" + category);
        }

        return "redirect:/boardDetail?boardId=" + newBoardId;
    }

    // =========================================================
    // 9) 마이페이지 - 내 글/좋아요 글 (GET /myPostPage)
    @GetMapping("/myPostPage")
    public String myPostPage(HttpSession session, Model model, BoardDTO boardDTO) {

        Integer memberId = getLoginMemberIdOrNull(session);
        if (memberId == null) {
            System.out.println("[내 글보기 이동 로그] memberId 없음 : 로그인 필요");
            return message(model, "로그인 정보가 없습니다.", "/login");
        }

        // 좋아요 누른 글
        boardDTO.setCondition("MY_BOARD_LIKE_LIST");
        boardDTO.setMemberId(memberId);

        List<BoardDTO> myBoardLikeList = boardService.selectAll(boardDTO);
        model.addAttribute("myBoardLikeList", myBoardLikeList);

        // 작성한 글
        boardDTO.setCondition("MY_BOARD_WRITE_LIST");
        boardDTO.setMemberId(memberId);

        List<BoardDTO> myBoardWriteList = boardService.selectAll(boardDTO);
        model.addAttribute("myBoardWriteList", myBoardWriteList);

        return "mypost";
    }

    // =========================================================
    // 공통 유틸

    private String message(Model model, String msg, String location) {
        model.addAttribute("msg", msg);
        model.addAttribute("location", location);
        return "message";
    }

    private Integer getLoginMemberIdOrNull(HttpSession session) {
        if (session == null) return null;

        Object memberIdObj = session.getAttribute("memberId");
        if (memberIdObj == null) return null;

        try {
            if (memberIdObj instanceof Integer) return (Integer) memberIdObj;
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