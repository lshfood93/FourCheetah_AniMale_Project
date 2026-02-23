package fourcheetah.animale.web.repository.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import fourcheetah.animale.web.dto.board.BoardLikeDTO;

@Repository
public class BoardLikeDAO {

	@Autowired
	private JdbcTemplate jdbcTemplate; // DI 받은 JdbcTemplate


	/*
	 * MySQL 전제 - board_like.board_like_id : AUTO_INCREMENT PK - 중복 좋아요 방지:
	 * UNIQUE(board_id, member_id) - Oracle 문법(SEQ.NEXTVAL/DUAL/EXISTS) 제거
	 */

	// 좋아요 개수
	private static final String SELECT_BOARD_LIKE_COUNT = "SELECT COUNT(*) " + "FROM board_like "
			+ "WHERE board_id = ?";

	// 내가 눌렀는지(0/1 처럼 사용: count 결과)
	private static final String SELECT_BOARD_LIKE_CHECK = "SELECT COUNT(*) " + "FROM board_like "
			+ "WHERE board_id = ? " + "  AND member_id = ?";

	// 좋아요 추가(중복이면 무시) MySQL
	private static final String INSERT_BOARD_LIKE_IGNORE = "INSERT IGNORE INTO board_like (board_id, member_id) "
			+ "VALUES (?, ?)";

	// 좋아요 취소
	private static final String DELETE_BOARD_LIKE = "DELETE FROM board_like " + "WHERE board_id = ? "
			+ "  AND member_id = ?";

	// =========================================================
	// SELECT_ONE (COUNT / CHECK)

	public BoardLikeDTO selectOne(BoardLikeDTO dto) {
		String condition = dto.getCondition();
		if (condition == null)
			return null;

		try {
			if ("BOARD_LIKE_COUNT".equals(condition)) {
				Integer cnt = jdbcTemplate.queryForObject(SELECT_BOARD_LIKE_COUNT, Integer.class, dto.getBoardId());

				BoardLikeDTO data = new BoardLikeDTO();
				data.setBoardId(dto.getBoardId());
				data.setLikeCnt(cnt == null ? 0 : cnt);
				return data;
			}

			if ("BOARD_LIKE_CHECK".equals(condition)) {
				Integer cnt = jdbcTemplate.queryForObject(SELECT_BOARD_LIKE_CHECK, Integer.class, dto.getBoardId(),
						dto.getMemberId());

				BoardLikeDTO data = new BoardLikeDTO();
				data.setBoardId(dto.getBoardId());
				data.setMemberId(dto.getMemberId());
				data.setIsLiked((cnt != null && cnt > 0) ? 1 : 0); // 0 또는 1처럼 사용
				return data;
			}

			return null;

		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	// =========================================================
	// UPDATE (TOGGLE)
	// - 이미 좋아요면 DELETE
	// - 아니면 INSERT
	//
	// 트랜잭션: 서비스에 @Transactional 걸어도 되고
	// 여기 DAO에 걸어도 됨(아래는 DAO에 적용)

	@Transactional
	public boolean update(BoardLikeDTO dto) {
		if (dto == null || !"BOARD_LIKE_TOGGLE".equals(dto.getCondition())) {
			return false;
		}

		try {
			// 1) 먼저 INSERT 시도 (중복이면 0 반환)
			int inserted = jdbcTemplate.update(INSERT_BOARD_LIKE_IGNORE, dto.getBoardId(), dto.getMemberId());

			if (inserted > 0) {
				// 좋아요 추가 성공
				dto.setIsLiked(1);
				return true;
			}

			// 2) inserted == 0 이면 이미 존재(중복) → DELETE로 토글 취소
			int deleted = jdbcTemplate.update(DELETE_BOARD_LIKE, dto.getBoardId(), dto.getMemberId());

			if (deleted > 0) {
				dto.setIsLiked(0);
				return true;
			}

			return false;

		} catch (Exception e) {
			e.printStackTrace();
			// @Transactional 이므로 RuntimeException 던지면 롤백 확실
			throw new RuntimeException(e);
		}
	}
}
