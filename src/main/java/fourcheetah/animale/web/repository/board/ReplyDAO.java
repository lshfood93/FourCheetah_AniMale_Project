package fourcheetah.animale.web.repository.board;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.board.ReplyDTO;

@Repository
public class ReplyDAO {

	@Autowired
	private JdbcTemplate jdbcTemplate; // (유지) DI 받은 JdbcTemplate

	/*
	 * 변경 포인트 1) JDBCUtil/connect/disconnect 제거 → JdbcTemplate DI 2) Oracle
	 * SEQ.NEXTVAL 제거 → MySQL AUTO_INCREMENT 기반 insert 3) Oracle EXISTS 방식 유지 가능하지만,
	 * MySQL에선 UPDATE JOIN이 깔끔함 4) 컬럼/alias snake_case로 통일: writer_nickname
	 */

	// =========================================================
	// SELECT (최신순 / 오래된순)

	private static final String SELECT_REPLY_LIST_RECENT = 
			"SELECT " +
			"  r.reply_id, " +
			"  r.board_id, " +
			"  r.member_id, " +
			"  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' " +
			"       ELSE m.member_nickname END AS writer_nickname, " +
			"  m.member_profile_image AS writer_profile_image, " +
			"  r.reply_content, " +
			"  r.reply_created_at, " +
			"  r.reply_updated_at, " +
			
			// ⭐⭐⭐ isEdited 추가 ⭐⭐⭐
			"  CASE " +
			"    WHEN r.reply_updated_at IS NULL THEN 0 " +
			"    WHEN r.reply_created_at = r.reply_updated_at THEN 0 " +
			"    ELSE 1 " +
			"  END AS is_edited " +
			// ⭐⭐⭐ 추가 끝 ⭐⭐⭐
			
			"FROM reply r " +
			"JOIN member m ON m.member_id = r.member_id " +
			"WHERE r.board_id = ? " +
			"ORDER BY r.reply_id DESC";

	private static final String SELECT_REPLY_LIST_OLDEST = 
			"SELECT " +
			"  r.reply_id, " +
			"  r.board_id, " +
			"  r.member_id, " +
			"  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' " +
			"       ELSE m.member_nickname END AS writer_nickname, " +
			"  m.member_profile_image AS writer_profile_image, " +
			"  r.reply_content, " +
			"  r.reply_created_at, " +
			"  r.reply_updated_at, " +
			
			// ⭐⭐⭐ isEdited 추가 ⭐⭐⭐
			"  CASE " +
			"    WHEN r.reply_updated_at IS NULL THEN 0 " +
			"    WHEN r.reply_created_at = r.reply_updated_at THEN 0 " +
			"    ELSE 1 " +
			"  END AS is_edited " +
			// ⭐⭐⭐ 추가 끝 ⭐⭐⭐
			
			"FROM reply r " +
			"JOIN member m ON m.member_id = r.member_id " +
			"WHERE r.board_id = ? " +
			"ORDER BY r.reply_id ASC";

	// =========================================================
	// INSERT (MySQL AUTO_INCREMENT 전제)
	// reply_id는 AUTO_INCREMENT → INSERT 컬럼에서 제외
	private static final String INSERT_REPLY = "INSERT INTO reply (board_id, member_id, reply_content) "
			+ "VALUES (?, ?, ?)";

	// =========================================================
	// UPDATE (본인 수정)
	private static final String UPDATE_REPLY = "UPDATE reply " + "SET reply_content = ? "
			+ "WHERE reply_id = ? AND member_id = ?";

	// =========================================================
	// UPDATE (관리자 삭제 = 내용 치환)
	// MySQL: UPDATE JOIN으로 admin 권한 검증
	private static final String UPDATE_REPLY_ADMIN_DELETE = "UPDATE reply r "
			+ "JOIN member m ON m.member_id = ? AND m.member_role = 'ADMIN' "
			+ "SET r.reply_content = '관리자에 의해 삭제된 댓글입니다.' " + "WHERE r.reply_id = ?";

	// =========================================================
	// DELETE (본인 or 관리자)
	// MySQL에선 EXISTS도 되지만, 명확하게 "관리자면 무조건 삭제" / "아니면 본인만"으로 분기하는 게 안정적
	// → 너 ReplyDeleteAction도 이미 isAdmin 분기해서 update/delete 따로 호출하니까
	// → 여기선 "본인만 삭제"로 두는 게 맞음.
	private static final String DELETE_REPLY = "DELETE FROM reply WHERE reply_id = ? AND member_id = ?";

	// =========================================================
	// SELECT_ALL: 댓글 목록

	public ArrayList<ReplyDTO> selectAll(ReplyDTO dto) {

		String condition = dto.getCondition();

		String sql;
		if ("REPLY_LIST_RECENT".equals(condition)) {
			sql = SELECT_REPLY_LIST_RECENT;
		} else if ("REPLY_LIST_OLDEST".equals(condition)) {
			sql = SELECT_REPLY_LIST_OLDEST;
		} else {
			return new ArrayList<>();
		}

		List<ReplyDTO> list = jdbcTemplate.query(sql, (rs, rowNum) -> {
			ReplyDTO data = new ReplyDTO();
			data.setReplyId(rs.getInt("reply_id"));
			data.setBoardId(rs.getInt("board_id"));
			data.setMemberId(rs.getInt("member_id"));
			data.setWriterNickname(rs.getString("writer_nickname"));
			data.setWriterProfileImage(rs.getString("writer_profile_image"));
			data.setReplyContent(rs.getString("reply_content"));
			data.setReplyCreatedAt(rs.getString("reply_created_at"));
			data.setReplyUpdatedAt(rs.getString("reply_updated_at"));
			
			// ⭐⭐⭐ isEdited 추가 ⭐⭐⭐
			data.setIsEdited(rs.getInt("is_edited"));
			
			return data;
		}, dto.getBoardId());

		return new ArrayList<>(list);
	}

	// =========================================================
	// INSERT: 댓글 작성
	// 너 Service 인터페이스가 5개 유지라면,
	// insert() 대신 insertReturnId()로 통일하는 편이 가장 깔끔함.
	// (필요 없으면 반환값 무시하면 됨)

	public boolean insert(ReplyDTO dto) {

		if (!"REPLY_INSERT".equals(dto.getCondition())) {
			return false;
		}

		int rows = jdbcTemplate.update(INSERT_REPLY, dto.getBoardId(), dto.getMemberId(), dto.getReplyContent());

		return rows > 0;
	}

	// =========================================================
	// UPDATE: 댓글 수정(본인) / 관리자 삭제(내용 치환)

	public boolean update(ReplyDTO dto) {

		String condition = dto.getCondition();

		int rows;

		// 1) 본인 댓글 수정
		if ("REPLY_UPDATE".equals(condition)) {
			rows = jdbcTemplate.update(UPDATE_REPLY, dto.getReplyContent(), dto.getReplyId(), dto.getMemberId());
		}
		// 2) 관리자 삭제(내용 치환)
		else if ("REPLY_ADMIN_DELETE".equals(condition)) {
			rows = jdbcTemplate.update(UPDATE_REPLY_ADMIN_DELETE, dto.getMemberId(), // 요청자 member_id로 ADMIN 검증
					dto.getReplyId());
		} else {
			return false;
		}

		return rows > 0;
	}

	// =========================================================
	// DELETE: 댓글 삭제(본인만)
	// 관리자 삭제는 update(REPLY_ADMIN_DELETE)로 처리하는 현재 정책에 맞춤

	public boolean delete(ReplyDTO dto) {

		if (!"REPLY_DELETE".equals(dto.getCondition())) {
			return false;
		}

		int rows = jdbcTemplate.update(DELETE_REPLY, dto.getReplyId(), dto.getMemberId());

		return rows > 0;
	}

}