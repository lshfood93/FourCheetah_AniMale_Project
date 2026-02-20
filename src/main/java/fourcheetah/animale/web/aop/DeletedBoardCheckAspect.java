package fourcheetah.animale.web.aop;

import jakarta.servlet.http.HttpServletRequest; 

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.exception.BoardDeletedException;
import fourcheetah.animale.web.service.board.BoardService;

/**
 * 삭제된 게시글 체크 AOP
 * 
 * board_status='내용삭제'인 게시글에 대한 접근을 차단합니다.
 * 
 * 차단 대상:
 * - 좋아요 (toggleLike)
 * - 신고 (reportBoard)
 * - 삭제 (boardDeleste)
 * - 수정 (boardEditPage)
 * - 댓글 작성 (replyWrite)
 * 
 * 적용 대상:
 * - 모든 사용자 (제재 여부 무관)
 * - 삭제된 게시글 자체를 차단
 */
@Aspect
@Component
public class DeletedBoardCheckAspect {
    
    private static final Logger logger = LoggerFactory.getLogger(DeletedBoardCheckAspect.class);
    
    @Autowired
    private BoardService boardService;
    
    /**
     * 삭제된 게시글 체크 - @Before 방식
     * 
     * 삭제된 게시글이면 예외를 던져서 메서드 실행을 막습니다.
     * 정상 게시글이면 아무것도 하지 않고 메서드가 실행됩니다.
     */
    @Before(
        "execution(* fourcheetah.animale.web.controller.board.BoardController.toggleLike(..)) || " +
        "execution(* fourcheetah.animale.web.controller.board.UserReportController.reportBoard(..)) || " +
        "execution(* fourcheetah.animale.web.controller.board.BoardController.boardDelete(..)) || " +
        "execution(* fourcheetah.animale.web.controller.board.BoardController.boardEditPage(..)) || " +
        "execution(* fourcheetah.animale.web.controller.board.ReplyController.replyWrite(..))"
    )
    public void checkDeletedBoard(JoinPoint joinPoint) {
        
        String methodName = joinPoint.getSignature().getName();
        logger.info("[AOP] DeletedBoardCheck 실행 - {}", methodName);
        
        // 1. boardId 가져오기
        Integer boardId = extractBoardId(joinPoint);
        
        if (boardId == null) {
            logger.warn("[AOP] boardId를 찾을 수 없음");
            return; // boardId가 없으면 체크 스킵
        }
        
        logger.info("[AOP] boardId={}", boardId);
        
        // 2. 게시글 상태 확인
        BoardDTO boardDTO = new BoardDTO();
        boardDTO.setBoardId(boardId);
        boardDTO.setCondition("BOARD_DETAIL");
        
        BoardDTO board = boardService.selectOne(boardDTO);
        
        if (board == null) {
            logger.warn("[AOP] 게시글 없음 - boardId={}", boardId);
            throw new BoardDeletedException("존재하지 않는 게시글입니다.");
        }
        
        logger.info("[AOP] 게시글 조회 성공 - boardStatus: {}", board.getBoardStatus());
        
        // 3. 삭제 여부 확인
        if ("내용삭제".equals(board.getBoardStatus())) {
            logger.warn("[AOP] 삭제된 게시글 - 차단");
            throw new BoardDeletedException("삭제된 게시글입니다.");
        }
        
        logger.info("[AOP] 정상 게시글 - 통과");
        // 정상 게시글이면 그냥 return (메서드 실행됨)
    }
    
    /**
     * 메서드 파라미터에서 boardId 추출
     */
    private Integer extractBoardId(JoinPoint joinPoint) {
        Object[] args = joinPoint.getArgs();
        
        // 1. Integer 타입 파라미터 찾기
        for (Object arg : args) {
            if (arg instanceof Integer) {
                return (Integer) arg;
            }
        }
        
        // 2. HttpServletRequest에서 추출
        for (Object arg : args) {
            if (arg instanceof HttpServletRequest) {
                HttpServletRequest request = (HttpServletRequest) arg;
                String boardIdParam = request.getParameter("boardId");
                if (boardIdParam != null) {
                    try {
                        return Integer.parseInt(boardIdParam);
                    } catch (NumberFormatException e) {
                        logger.warn("[AOP] boardId 파싱 실패: {}", boardIdParam);
                    }
                }
            }
        }
        
        // 3. RequestContextHolder에서 추출 (최후 수단)
        try {
            ServletRequestAttributes attributes = 
                (ServletRequestAttributes) RequestContextHolder.currentRequestAttributes();
            HttpServletRequest request = attributes.getRequest();
            String boardIdParam = request.getParameter("boardId");
            if (boardIdParam != null) {
                return Integer.parseInt(boardIdParam);
            }
        } catch (Exception e) {
            logger.warn("[AOP] RequestContextHolder에서 boardId 추출 실패", e);
        }
        
        return null;
    }
}