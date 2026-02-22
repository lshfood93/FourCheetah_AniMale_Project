package fourcheetah.animale.web.controller.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.dto.board.ReplyDTO;
import fourcheetah.animale.web.service.board.ReplyService;
import fourcheetah.animale.web.aop.SanctionCheck;
import fourcheetah.animale.web.aop.DeletedBoardCheck;
import fourcheetah.animale.web.common.HtmlSanitizer; // ✅ 추가
import jakarta.servlet.http.HttpSession;

/** 댓글 통합 컨트롤러
 
* - 작성: POST /replyWrite
* - 수정: POST /replyEdit
* - 삭제: POST /replyDelete

**/
@Controller
public class ReplyController {

    @Autowired
    private ReplyService replyService;

    @Autowired
    private HtmlSanitizer htmlSanitizer; // ✅ 추가 (댓글 입력값 XSS 방어용)

    // =========================================================
    // 1) 댓글 작성 (POST /replyWrite)
    @SanctionCheck(allowTypes = {"WARNING"})  
    @DeletedBoardCheck  
    @PostMapping("/replyWrite")
    public String replyWrite(
            ReplyDTO replyDTO,
            BindingResult br,
            HttpSession session,
            Model model
    ) {

        // 1) 로그인 체크
        Integer memberId = getLoginMemberIdOrNull(session);
        if (memberId == null) {
            System.out.println("[댓글 작성 로그] 실패: 로그인 세션 없음");
            return message(model, "로그인이 필요한 기능입니다.", "/mainPage");
        }

        // 2) boardId 검증
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[댓글 작성 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/mainPage");
        }

        Integer boardId = replyDTO.getBoardId();
        System.out.println("[댓글 작성 로그] boardId=" + boardId);

        if (boardId == null || boardId <= 0) {
            return message(model, "잘못된 게시글 접근입니다.", "/mainPage");
        }

        // 3) replyContent 검증 + XSS 방어
        String rawReplyContent = replyDTO.getReplyContent();
        System.out.println("[댓글 작성 로그] replyContentParam=" + rawReplyContent);

        // ✅ 핵심: 댓글은 리치텍스트가 아니라 일반 텍스트 필드
        //    -> 태그 제거 + 제어문자 정리 + trim 적용
        String replyContent = htmlSanitizer.sanitizePlainText(rawReplyContent);

        // ✅ sanitize 결과 기준으로 빈값 검증
        if (replyContent.isEmpty()) {
            return message(model, "댓글 내용은 필수입니다.", "/boardDetail?boardId=" + boardId);
        }

        // ✅ sanitize 결과 기준으로 길이 검증 (기존 정책 500자 유지)
        if (replyContent.length() > 500) {
            return message(model, "댓글은 500자 이내로 작성해주세요.", "/boardDetail?boardId=" + boardId);
        }

        // 4) DTO 세팅 + INSERT
        replyDTO.setCondition("REPLY_INSERT");   // ✅ 기존 condition 유지
        replyDTO.setBoardId(boardId);
        replyDTO.setMemberId(memberId);
        replyDTO.setReplyContent(replyContent);  // ✅ sanitize된 값 저장

        boolean result = replyService.insert(replyDTO);

        if (!result) {
            System.out.println("[댓글 작성 로그] 실패: INSERT 실패");
            return message(model, "댓글 작성에 실패했습니다.", "/boardDetail?boardId=" + boardId);
        }

        System.out.println("[댓글 작성 로그] 성공: boardId=" + boardId);
        return "redirect:/boardDetail?boardId=" + boardId;
    }

    // =========================================================
    // 2) 댓글 수정 (POST /replyEdit)
    @SanctionCheck(allowTypes = {"WARNING"})  
    @PostMapping("/replyEdit")
    public String replyEdit(
            ReplyDTO replyDTO,
            BindingResult br,
            HttpSession session,
            Model model
    ) {

        // 1) 로그인 체크
        Integer memberId = getLoginMemberIdOrNull(session);
        if (memberId == null) {
            System.out.println("[댓글 수정 로그] 실패: 로그인 세션 없음");
            return message(model, "로그인이 필요한 기능입니다.", "/mainPage");
        }

        // 2) boardId 검증
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[댓글 수정 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/mainPage");
        }

        Integer boardId = replyDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            return message(model, "잘못된 접근입니다.(게시글 번호 없음)", "/mainPage");
        }

        // 3) replyId 검증
        if (br != null && br.hasFieldErrors("replyId")) {
            System.out.println("[댓글 수정 로그] 실패: replyId 타입 변환 오류");
            return message(model, "댓글 번호가 올바르지 않습니다.", "/boardDetail?boardId=" + boardId);
        }

        Integer replyId = replyDTO.getReplyId();
        if (replyId == null || replyId <= 0) {
            return message(model, "잘못된 댓글 접근입니다.", "/boardDetail?boardId=" + boardId);
        }

        // 4) replyContent 검증 + XSS 방어
        String rawReplyContent = replyDTO.getReplyContent();
        System.out.println("[댓글 수정 로그] replyContentParam=" + rawReplyContent);

        // ✅ 핵심: 수정도 작성과 동일 정책 적용
        String replyContent = htmlSanitizer.sanitizePlainText(rawReplyContent);

        // ✅ sanitize 결과 기준 검증
        if (replyContent.isEmpty()) {
            return message(model, "댓글 내용은 필수입니다.", "/boardDetail?boardId=" + boardId);
        }

        if (replyContent.length() > 500) {
            return message(model, "댓글은 500자 이내로 작성해주세요.", "/boardDetail?boardId=" + boardId);
        }

        // 5) UPDATE
        replyDTO.setCondition("REPLY_UPDATE");   // ✅ 기존 condition 유지
        replyDTO.setReplyId(replyId);
        replyDTO.setMemberId(memberId);          // 본인 확인용
        replyDTO.setReplyContent(replyContent);  // ✅ sanitize 반영

        boolean result = replyService.update(replyDTO);

        if (!result) {
            System.out.println("[댓글 수정 로그] 실패: UPDATE 실패(권한/존재 여부 확인)");
            return message(model, "댓글 수정에 실패했습니다.", "/boardDetail?boardId=" + boardId);
        }

        System.out.println("[댓글 수정 로그] 성공: replyId=" + replyId);
        return "redirect:/boardDetail?boardId=" + boardId;
    }

    // =========================================================
    // 3) 댓글 삭제 (POST /replyDelete)
    @SanctionCheck(allowTypes = {"WARNING"})  
    @PostMapping("/replyDelete")
    public String replyDelete(
            ReplyDTO replyDTO,
            BindingResult br,
            HttpSession session,
            Model model
    ) {

        // 1) 로그인 체크
        Integer memberId = getLoginMemberIdOrNull(session);
        if (memberId == null) {
            System.out.println("[댓글 삭제 로그] 실패: 로그인 세션 없음");
            return message(model, "로그인이 필요한 기능입니다.", "/mainPage");
        }

        String memberRole = (String) session.getAttribute("memberRole");
        boolean isAdmin = "ADMIN".equals(memberRole);

        // 2) boardId 검증
        if (br != null && br.hasFieldErrors("boardId")) {
            System.out.println("[댓글 삭제 로그] 실패: boardId 타입 변환 오류");
            return message(model, "게시글 번호가 올바르지 않습니다.", "/mainPage");
        }

        Integer boardId = replyDTO.getBoardId();
        if (boardId == null || boardId <= 0) {
            return message(model, "잘못된 접근입니다.(게시글 번호 없음)", "/mainPage");
        }

        // 3) replyId 검증
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
            replyDTO.setMemberId(memberId); // admin 검증/로그용(구조 유지)
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

        System.out.println("[댓글 삭제 로그] 성공: replyId=" + replyId + ", isAdmin=" + isAdmin);
        return "redirect:/boardDetail?boardId=" + boardId;
    }

    // =========================================================
    // 공통 유틸

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

    private String message(Model model, String msg, String location) {
        model.addAttribute("msg", msg);
        model.addAttribute("location", location);
        return "message";
    }
}