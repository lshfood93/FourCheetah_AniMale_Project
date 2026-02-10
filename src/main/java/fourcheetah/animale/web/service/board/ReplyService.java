package fourcheetah.animale.web.service.board;

import java.util.ArrayList;

import fourcheetah.animale.web.dto.board.ReplyDTO;

public interface ReplyService {
	
    ArrayList<ReplyDTO> selectAll(ReplyDTO replyDTO);

    boolean insert(ReplyDTO replyDTO);

    boolean update(ReplyDTO replyDTO);

    boolean delete(ReplyDTO replyDTO);
}
