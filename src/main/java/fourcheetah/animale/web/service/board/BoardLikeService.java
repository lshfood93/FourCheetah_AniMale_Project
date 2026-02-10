package fourcheetah.animale.web.service.board;

import fourcheetah.animale.web.dto.board.BoardLikeDTO;

public interface BoardLikeService {

	BoardLikeDTO selectOne(BoardLikeDTO boardLikeDTO);

	boolean update(BoardLikeDTO boardLikeDTO);
}
