package fourcheetah.animale.web.repository.board;

import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.board.ReplyDTO;
import fourcheetah.animale.web.service.board.ReplyService;

@Service
public class ReplyServiceImpl implements ReplyService {

	@Autowired
	private ReplyDAO replyDAO;

    @Override
    public ArrayList<ReplyDTO> selectAll(ReplyDTO replyDTO) {
        return replyDAO.selectAll(replyDTO);
    }

    @Override
    public boolean update(ReplyDTO replyDTO) {
        return replyDAO.update(replyDTO);
    }

    @Override
    public boolean delete(ReplyDTO replyDTO) {
        return replyDAO.delete(replyDTO);
    }

	@Override
	public boolean insert(ReplyDTO replyDTO) {
		return replyDAO.insert(replyDTO);
	}
}
