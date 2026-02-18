package fourcheetah.animale.web.controller.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;   // ✅ NEW (선택)
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.dto.board.ReplyDTO;
import fourcheetah.animale.web.service.board.ReplyService;
import jakarta.servlet.http.HttpSession;

@Controller
public class ReplyEditController {

    @Autowired
    private ReplyService replyService;

    @PostMapping("/replyEdit")
    public String replyEdit(
            ReplyDTO replyDTO,          // CHANGED: 커맨드 객체 바인딩(boardId, replyId, replyContent)
            BindingResult br,           // NEW: 타입 변환 오류 체크(ReplyDTO 바로 다음)
            HttpSession session,
            Model model
    ) {

        // 1) 로그인 체크
        Object memberIdObj = (session == null) ? null : session.getAttribute("memberId");
        if (session == null || memberIdObj == null) {
            System.out.println("[댓글 수정 로그] 실패: 로그인 세션 없음");
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
            System.out.println("[댓글 수정 로그] 실패: 세션 memberId 형변환 오류 memberIdObj=" + memberIdObj);
            return message(model, "로그인 정보가 올바르지 않습니다.", "/mainPage");
        }

        // 2) boardId 검증 (커맨드 바인딩 기반)
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[댓글 수정 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/mainPage");
        }

        Integer boardId = replyDTO.getBoardId(); // ✅ ReplyDTO에 boardId 있어야 함
        if (boardId == null || boardId <= 0) {
            return message(model, "잘못된 접근입니다.(게시글 번호 없음)", "/mainPage");
        }

        // 3) replyId 검증 (커맨드 바인딩 기반)
        if (br != null && br.hasFieldErrors("replyId")) {
            System.out.println("[댓글 수정 로그] 실패: replyId 타입 변환 오류");
            return message(model, "댓글 번호가 올바르지 않습니다.", "/boardDetail?boardId=" + boardId);
        }

        Integer replyId = replyDTO.getReplyId();
        if (replyId == null || replyId <= 0) {
            return message(model, "잘못된 댓글 접근입니다.", "/boardDetail?boardId=" + boardId);
        }

        // 4) replyContent 검증 (커맨드 바인딩 기반)
        String replyContent = replyDTO.getReplyContent(); // ✅ RequestParam 대신 DTO에서
        System.out.println("[댓글 수정 로그] replyContentParam=" + replyContent);

        if (replyContent == null || replyContent.trim().isEmpty()) {
            return message(model, "댓글 내용은 필수입니다.", "/boardDetail?boardId=" + boardId);
        }

        replyContent = replyContent.trim();

        if (replyContent.length() > 500) {
            return message(model, "댓글은 500자 이내로 작성해주세요.", "/boardDetail?boardId=" + boardId);
        }

        // 5) DTO 세팅 + condition(REPLY_UPDATE)
        replyDTO.setCondition("REPLY_UPDATE");
        replyDTO.setReplyId(replyId);
        replyDTO.setMemberId(memberId);          // ★본인 확인용
        replyDTO.setReplyContent(replyContent);  // trim 반영

        boolean result = replyService.update(replyDTO);

        if (!result) {
            System.out.println("[댓글 수정 로그] 실패: UPDATE 실패(권한/존재 여부 확인)");
            return message(model, "댓글 수정에 실패했습니다.", "/boardDetail?boardId=" + boardId);
        }

        // 6) 성공 redirect (POST 중복 제출 방지)
        System.out.println("[댓글 수정 로그] 성공: replyId=" + replyId);
        return "redirect:/boardDetail?boardId=" + boardId;
    }

    // message.jsp 뷰 렌더링 공통 처리
    private String message(Model model, String msg, String location) {
        model.addAttribute("msg", msg);
        model.addAttribute("location", location);
        return "message";
    }
}
