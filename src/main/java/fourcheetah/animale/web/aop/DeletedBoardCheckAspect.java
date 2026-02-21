// DeletedBoardCheckAspect.java
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

@Aspect
@Component
public class DeletedBoardCheckAspect {

    private static final Logger logger = LoggerFactory.getLogger(DeletedBoardCheckAspect.class);

    @Autowired
    private BoardService boardService;

    @Before(
        // toggleLike는 BoardApiController에 있음 (수정)
        "execution(* fourcheetah.animale.web.controller.board.BoardApiController.toggleLike(..)) || " +
        "execution(* fourcheetah.animale.web.controller.board.UserReportController.reportBoard(..)) || " +
        "execution(* fourcheetah.animale.web.controller.board.BoardController.boardDelete(..)) || " +
        "execution(* fourcheetah.animale.web.controller.board.BoardController.boardEditPage(..)) || " +
        "execution(* fourcheetah.animale.web.controller.board.ReplyController.replyWrite(..))"
    )
    public void checkDeletedBoard(JoinPoint joinPoint) {

        String methodName = joinPoint.getSignature().getName();
        logger.info("[AOP] DeletedBoardCheck 실행 - {}", methodName);

        Integer boardId = extractBoardId(joinPoint);

        if (boardId == null) {
            logger.warn("[AOP] boardId를 찾을 수 없음");
            return;
        }

        logger.info("[AOP] boardId={}", boardId);

        BoardDTO boardDTO = new BoardDTO();
        boardDTO.setBoardId(boardId);
        boardDTO.setCondition("BOARD_DETAIL");

        BoardDTO board = boardService.selectOne(boardDTO);

        if (board == null) {
            logger.warn("[AOP] 게시글 없음 - boardId={}", boardId);
            throw new BoardDeletedException("존재하지 않는 게시글입니다.");
        }

        logger.info("[AOP] 게시글 조회 성공 - boardStatus: {}", board.getBoardStatus());

        if ("내용삭제".equals(board.getBoardStatus())) {
            logger.warn("[AOP] 삭제된 게시글 - 차단");
            throw new BoardDeletedException("삭제된 게시글입니다.");
        }

        logger.info("[AOP] 정상 게시글 - 통과");
    }

    private Integer extractBoardId(JoinPoint joinPoint) {
        Object[] args = joinPoint.getArgs();

        for (Object arg : args) {
            if (arg instanceof Integer) {
                return (Integer) arg;
            }
        }

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