package fourcheetah.animale.web.controller.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;      // ✅ NEW (선택)
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.dto.board.ReplyDTO;
import fourcheetah.animale.web.service.board.ReplyService;
import jakarta.servlet.http.HttpSession;

@Controller
public class ReplyDeleteController {

    @Autowired
    private ReplyService replyService;

    @PostMapping("/replyDelete")
    public String replyDelete(
            ReplyDTO replyDTO,          // CHANGED: 커맨드 객체 바인딩(boardId, replyId를 여기서 받음)
            BindingResult br,           // NEW: 타입 변환 오류 체크(ReplyDTO 바로 다음)
            HttpSession session,        // CHANGED: request 대신 session 직접 받기
            Model model
    ) {

        // 1) 로그인 체크
        Object memberIdObj = (session != null) ? session.getAttribute("memberId") : null;
        if (session == null || memberIdObj == null) {
            System.out.println("[댓글 삭제 로그] 실패: 로그인 세션 없음");
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
            System.out.println("[댓글 삭제 로그] 실패: 세션 memberId 형변환 오류 memberIdObj=" + memberIdObj);
            return message(model, "로그인 정보가 올바르지 않습니다.", "/mainPage");
        }

        String memberRole = (String) session.getAttribute("memberRole");
        boolean isAdmin = "ADMIN".equals(memberRole);

        // 2) boardId 검증 (커맨드 바인딩 기반)
        // - 만약 boardId가 "abc" 같은 값이면 br.hasFieldErrors("boardId")로 잡힘(필드 타입이 Integer/int인 경우)
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[댓글 삭제 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/mainPage");
        }

        Integer boardId = replyDTO.getBoardId(); // ✅ ReplyDTO에 boardId 있어야 함
        if (boardId == null || boardId <= 0) {
            return message(model, "잘못된 접근입니다.(게시글 번호 없음)", "/mainPage");
        }

        // 3) replyId 검증 (커맨드 바인딩 기반)
        if (br != null && br.hasFieldErrors("replyId")) {
            System.out.println("[댓글 삭제 로그] 실패: replyId 타입 변환 오류");
            return message(model, "댓글 번호가 올바르지 않습니다.", "/boardDetail?boardId=" + boardId);
        }

        Integer replyId = replyDTO.getReplyId();
        if (replyId == null || replyId <= 0) {
            return message(model, "잘못된 댓글 접근입니다.", "/boardDetail?boardId=" + boardId);
        }

        // 4) 관리자/일반회원 분기
        boolean result;

        if (isAdmin) {
            // 관리자: UPDATE로 내용 치환
            replyDTO.setCondition("REPLY_ADMIN_DELETE");
            replyDTO.setMemberId(memberId); // admin 검증/로그용(기존 구조 유지)

            result = replyService.update(replyDTO);
            System.out.println("[댓글 삭제 로그] 관리자 삭제(내용치환) 실행: replyId=" + replyId);

        } else {
            // 일반회원: 물리삭제(본인만)
            replyDTO.setCondition("REPLY_DELETE");
            replyDTO.setMemberId(memberId);

            result = replyService.delete(replyDTO);
            System.out.println("[댓글 삭제 로그] 본인 삭제(물리삭제) 실행: replyId=" + replyId);
        }

        if (!result) {
            System.out.println("[댓글 삭제 로그] 실패: 삭제 처리 실패(권한/존재 여부 확인)");
            return message(model, "댓글 삭제에 실패했습니다.", "/boardDetail?boardId=" + boardId);
        }

        // 5) 성공 redirect (POST 중복 제출 방지)
        System.out.println("[댓글 삭제 로그] 성공: replyId=" + replyId + ", isAdmin=" + isAdmin);
        return "redirect:/boardDetail?boardId=" + boardId;
    }

    // message.jsp 뷰 렌더링 공통 처리
    private String message(Model model, String msg, String location) {
        model.addAttribute("msg", msg);
        model.addAttribute("location", location);
        return "message";
    }
}
