package fourcheetah.animale.web.service.board;

import java.util.ArrayList;

import fourcheetah.animale.web.dto.board.BoardDTO;

public interface BoardService {

	BoardDTO selectOne(BoardDTO boardDTO);

	ArrayList<BoardDTO> selectAll(BoardDTO boardDTO);

<<<<<<< HEAD
	Integer insertReturnId(BoardDTO boardDTO);
=======
	boolean insert(BoardDTO boardDTO);
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871

	boolean update(BoardDTO boardDTO);

	boolean delete(BoardDTO boardDTO);
}
