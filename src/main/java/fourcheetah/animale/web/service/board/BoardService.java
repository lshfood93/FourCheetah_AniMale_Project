package fourcheetah.animale.web.service.board;

import java.util.ArrayList;

import fourcheetah.animale.web.dto.board.BoardDTO;

public interface BoardService {

	BoardDTO selectOne(BoardDTO boardDTO);

	ArrayList<BoardDTO> selectAll(BoardDTO boardDTO);

	boolean insert(BoardDTO boardDTO);

	boolean update(BoardDTO boardDTO);

	boolean delete(BoardDTO boardDTO);
}
