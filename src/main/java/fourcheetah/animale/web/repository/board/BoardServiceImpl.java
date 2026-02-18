package fourcheetah.animale.web.repository.board;

import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.service.board.BoardService;

@Service
public class BoardServiceImpl implements BoardService{
	
	@Autowired
	private BoardDAO boardDAO;
	
	@Override
	public boolean update(BoardDTO boardDTO) {
		return boardDAO.update(boardDTO);
	}

	@Override
	public BoardDTO selectOne(BoardDTO boardDTO) {
		
		return boardDAO.selectOne(boardDTO);
	}

	@Override
	public ArrayList<BoardDTO> selectAll(BoardDTO boardDTO) {

		return boardDAO.selectAll(boardDTO);
	}

	@Override
	public Integer insertReturnId(BoardDTO boardDTO) {

		return boardDAO.insertReturnId(boardDTO);
	}

	@Override
	public boolean delete(BoardDTO boardDTO) {

		return boardDAO.delete(boardDTO);
	}
	
}
