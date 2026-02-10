package fourcheetah.animale.web.controller.board;

import jakarta.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;   // ✅ NEW (선택)
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.dto.board.ReplyDTO;
import fourcheetah.animale.web.service.board.ReplyService;

@Controller
public class ReplyWriteController {

    @Autowired
    private ReplyService replyService;

    @PostMapping("/replyWrite")
    public String replyWrite(
            ReplyDTO replyDTO,       // ✅ CHANGED: 커맨드 객체 바인딩(boardId, replyContent)
            BindingResult br,        // ✅ NEW: 타입 변환 오류 체크(ReplyDTO 바로 다음)
            HttpSession session,
            Model model
    ) {

        // 1) 로그인 체크
        Object memberIdObj = (session == null) ? null : session.getAttribute("memberId");
        if (session == null || memberIdObj == null) {
            System.out.println("[댓글 작성 로그] 실패: 로그인 세션 없음");
            return message(model, "로그인이 필요한 기능입니다.", "/mainPage");
        }

        int memberId;
        try {
            if (memberIdObj instanceof Integer) {
                memberId = (Integer) memberIdObj;
            } else {
                memberId = Integer.parseInt(String.valueOf(memberIdObj));
            }
        } catch (Exception e) {
            System.out.println("[댓글 작성 로그] 실패: 세션 memberId 형변환 오류 memberIdObj=" + memberIdObj);
            return message(model, "로그인 정보가 올바르지 않습니다.", "/mainPage");
        }

        // 2) boardId 검증 (커맨드 바인딩 기반)
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[댓글 작성 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/mainPage");
        }

        Integer boardId = replyDTO.getBoardId();
        System.out.println("[댓글 작성 로그] boardId=" + boardId);

        if (boardId == null || boardId <= 0) {
            return message(model, "잘못된 게시글 접근입니다.", "/mainPage");
        }

        // 3) replyContent 검증 (커맨드 바인딩 기반)
        String replyContent = replyDTO.getReplyContent();
        System.out.println("[댓글 작성 로그] replyContentParam=" + replyContent);

        if (replyContent == null || replyContent.trim().isEmpty()) {
            return message(model, "댓글 내용은 필수입니다.", "/boardDetail?boardId=" + boardId);
        }

        replyContent = replyContent.trim();

        if (replyContent.length() > 500) {
            return message(model, "댓글은 500자 이내로 작성해주세요.", "/boardDetail?boardId=" + boardId);
        }

        // 4) DTO 세팅 + condition
        replyDTO.setCondition("REPLY_INSERT");
        replyDTO.setBoardId(boardId);
        replyDTO.setMemberId(memberId);
        replyDTO.setReplyContent(replyContent); // trim 반영

        // 5) insert 실행
        boolean result = replyService.insert(replyDTO);

        if (!result) {
            System.out.println("[댓글 작성 로그] 실패: INSERT 실패");
            return message(model, "댓글 작성에 실패했습니다.", "/boardDetail?boardId=" + boardId);
        }

        // 6) 성공 redirect (중복등록 방지)
        System.out.println("[댓글 작성 로그] 성공: boardId=" + boardId);
        return "redirect:/boardDetail?boardId=" + boardId;
    }

    // message.jsp 뷰 렌더링 공통 처리
    private String message(Model model, String msg, String location) {
        model.addAttribute("msg", msg);
        model.addAttribute("location", location);
        return "message";
    }
}
