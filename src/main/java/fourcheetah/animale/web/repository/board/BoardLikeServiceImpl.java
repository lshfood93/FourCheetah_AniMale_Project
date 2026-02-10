package fourcheetah.animale.web.repository.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.board.BoardLikeDTO;
import fourcheetah.animale.web.service.board.BoardLikeService;

@Service
public class BoardLikeServiceImpl implements BoardLikeService {

	@Autowired
	private BoardLikeDAO boardLikeDAO;

	@Override
	public boolean update(BoardLikeDTO boardLikeDTO) {
		return boardLikeDAO.update(boardLikeDTO);
	}

	@Override
	public BoardLikeDTO selectOne(BoardLikeDTO boardLikeDTO) {
		return boardLikeDAO.selectOne(boardLikeDTO);
	}
}
