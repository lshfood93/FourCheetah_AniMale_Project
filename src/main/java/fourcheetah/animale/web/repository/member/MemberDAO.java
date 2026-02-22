package fourcheetah.animale.web.repository.member;

import java.sql.Timestamp;
import java.util.Collections;
import java.util.List;
import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.dto.member.MemberWarningDTO;

@Repository
public class MemberDAO {

	@Autowired
	private JdbcTemplate jdbcTemplate;

	/*
	 * ========================= SELECT_ONE (컨디션 분기) =========================
	 */

	private static final String SELECT_JOIN_NAME = "SELECT member_id AS MEMBER_ID " + "FROM MEMBER "
			+ "WHERE member_name = ?";

	private static final String SELECT_JOIN_NICKNAME = "SELECT member_id AS MEMBER_ID " + "FROM MEMBER "
			+ "WHERE member_nickname = ?";

	private static final String SELECT_MEMBER_EMAIL_CHECK = "SELECT member_id AS MEMBER_ID " + "FROM MEMBER "
			+ "WHERE member_email = ?";

	private static final String SELECT_MEMBER_AUTOLOGIN = "SELECT " + " member_id             AS MEMBER_ID, "
			+ " member_name           AS MEMBER_NAME, " + " member_password       AS MEMBER_PASSWORD, "
			+ " member_nickname       AS MEMBER_NICKNAME, " + " member_cash           AS MEMBER_CASH, "
			+ " member_role           AS MEMBER_ROLE, " + " member_profile_image  AS MEMBER_PROFILE_IMAGE, "
			+ " member_email          AS MEMBER_EMAIL, " + " valid_report_count    AS VALID_REPORT_COUNT, "
			+ " last_warning_at       AS LAST_WARNING_AT, " + " notice_pending        AS NOTICE_PENDING, "
			+ " notice_message        AS NOTICE_MESSAGE, " + " member_profile_color  AS MEMBER_PROFILE_COLOR, "
			+ " member_nickname_color AS MEMBER_NICKNAME_COLOR " + "FROM MEMBER " + "WHERE member_name = ? "
			+ "AND member_role IN ('ACTIVE','ADMIN')";

	private static final String SELECT_MEMBER_LOGIN = "SELECT " + " member_id             AS MEMBER_ID, "
	        + " member_name           AS MEMBER_NAME, " + " member_password       AS MEMBER_PASSWORD, "
	        + " member_nickname       AS MEMBER_NICKNAME, " + " member_cash           AS MEMBER_CASH, "
	        + " member_role           AS MEMBER_ROLE, " + " member_profile_image  AS MEMBER_PROFILE_IMAGE, "
	        + " member_email          AS MEMBER_EMAIL, " + " valid_report_count    AS VALID_REPORT_COUNT, "
	        + " last_warning_at       AS LAST_WARNING_AT, " + " notice_pending        AS NOTICE_PENDING, "
	        + " notice_message        AS NOTICE_MESSAGE, " + " member_profile_color  AS MEMBER_PROFILE_COLOR, "
	        + " member_nickname_color AS MEMBER_NICKNAME_COLOR " + "FROM MEMBER " + "WHERE member_name = ? "
	        + "AND member_role IN ('ACTIVE','ADMIN')";

	private static final String SELECT_MEMBER_MYPAGE = "SELECT " + " member_id             AS MEMBER_ID, "
			+ " member_name           AS MEMBER_NAME, " + " member_password       AS MEMBER_PASSWORD, "
			+ " member_nickname       AS MEMBER_NICKNAME, " + " member_cash           AS MEMBER_CASH, "
			+ " member_role           AS MEMBER_ROLE, " + " member_profile_image  AS MEMBER_PROFILE_IMAGE, "
			+ " member_email          AS MEMBER_EMAIL, " + " valid_report_count    AS VALID_REPORT_COUNT, "
			+ " last_warning_at       AS LAST_WARNING_AT, " + " notice_pending        AS NOTICE_PENDING, "
			+ " notice_message        AS NOTICE_MESSAGE, " + " member_profile_color  AS MEMBER_PROFILE_COLOR, "
			+ " member_nickname_color AS MEMBER_NICKNAME_COLOR " + "FROM MEMBER " + "WHERE member_id = ?";

	private static final String SELECT_MEMBER_ADMINPAGE = "SELECT " + " member_id             AS MEMBER_ID, "
			+ " member_name           AS MEMBER_NAME, " + " member_password       AS MEMBER_PASSWORD, "
			+ " member_nickname       AS MEMBER_NICKNAME, " + " member_cash           AS MEMBER_CASH, "
			+ " member_role           AS MEMBER_ROLE, " + " member_profile_image  AS MEMBER_PROFILE_IMAGE, "
			+ " member_email          AS MEMBER_EMAIL, " + " valid_report_count    AS VALID_REPORT_COUNT, "
			+ " last_warning_at       AS LAST_WARNING_AT, " + " notice_pending        AS NOTICE_PENDING, "
			+ " notice_message        AS NOTICE_MESSAGE, " + " member_profile_color  AS MEMBER_PROFILE_COLOR, "
			+ " member_nickname_color AS MEMBER_NICKNAME_COLOR " + "FROM MEMBER " + "WHERE member_id = ? "
			+ "AND member_role = 'ADMIN'";

	private static final String SELECT_PASSWORD_CHECK = "SELECT member_id AS MEMBER_ID, member_password AS MEMBER_PASSWORD "
	        + "FROM MEMBER " + "WHERE member_id = ?";

	private static final String SELECT_FIND_ID = "SELECT member_id AS MEMBER_ID " + "FROM MEMBER "
			+ "WHERE member_name = ?";

	private static final String SELECT_FIND_EMAIL = "SELECT member_email AS MEMBER_EMAIL " + "FROM MEMBER "
			+ "WHERE member_name = ?";

	private static final String SELECT_MEMBER_ID_EMAIL = "SELECT member_id AS MEMBER_ID, member_name AS MEMBER_NAME, member_email AS MEMBER_EMAIL "
			+ "FROM MEMBER " + "WHERE member_name = ?";

	private static final String SELECT_CASH = "SELECT member_cash AS MEMBER_CASH " + "FROM MEMBER "
			+ "WHERE member_id = ?";

	// 현재 활성화된 제재 조회 (추가!)
	private static final String SELECT_ACTIVE_WARNING = "SELECT warning_type, reason, start_at, end_at "
			+ "FROM member_warning " + "WHERE member_id = ? " + "AND start_at <= NOW() "
			+ "AND (end_at IS NULL OR end_at > NOW()) " + "ORDER BY start_at DESC LIMIT 1";

	/*
	 * ========================= SELECT_ALL =========================
	 */

	private static final String SELECT_MEMBER_LIST_ALL = "SELECT " + " member_id          AS MEMBER_ID, "
			+ " member_name        AS MEMBER_NAME, " + " member_nickname    AS MEMBER_NICKNAME, "
			+ " member_cash        AS MEMBER_CASH, " + " member_role        AS MEMBER_ROLE, "
			+ " member_email       AS MEMBER_EMAIL, " + " valid_report_count AS VALID_REPORT_COUNT, "
			+ " last_warning_at    AS LAST_WARNING_AT, " + " notice_pending     AS NOTICE_PENDING " + "FROM MEMBER "
			+ "ORDER BY member_id ASC";

	private static final String SELECT_MEMBER_LIST_ACTIVE = "SELECT " + " member_id          AS MEMBER_ID, "
			+ " member_name        AS MEMBER_NAME, " + " member_nickname    AS MEMBER_NICKNAME, "
			+ " member_cash        AS MEMBER_CASH, " + " member_role        AS MEMBER_ROLE, "
			+ " member_email       AS MEMBER_EMAIL, " + " valid_report_count AS VALID_REPORT_COUNT, "
			+ " last_warning_at    AS LAST_WARNING_AT, " + " notice_pending     AS NOTICE_PENDING " + "FROM MEMBER "
			+ "WHERE member_role = 'ACTIVE' " + "ORDER BY member_id ASC";

	/*
	 * ========================= INSERT / UPDATE / DELETE =========================
	 */

	private static final String INSERT_MEMBER_JOIN = "INSERT INTO MEMBER (member_name, member_password, member_nickname, member_profile_image, member_email) "
			+ "VALUES (?, ?, ?, ?, ?)";

	// 일반 유저: 캐시 차감/조건 있음
	private static final String UPDATE_NICKNAME = "UPDATE MEMBER "
			+ "SET member_nickname = ?, member_cash = member_cash - ? " + "WHERE member_id = ? AND member_cash >= ?";

	private static final String UPDATE_PROFILE_IMAGE = "UPDATE MEMBER "
			+ "SET member_profile_image = ?, member_cash = member_cash - ? "
			+ "WHERE member_id = ? AND member_cash >= ?";

	private static final String UPDATE_MEMBER_INFORM = "UPDATE MEMBER " + "SET "
			+ "  member_nickname = COALESCE(?, member_nickname), "
			+ "  member_profile_image = COALESCE(?, member_profile_image), "
			+ "  member_profile_color = COALESCE(?, member_profile_color), "
			+ "  member_nickname_color = COALESCE(?, member_nickname_color), " + "  member_cash = member_cash - ? "
			+ "WHERE member_id = ? AND member_cash >= ?";

	// 관리자: 캐시 차감/조건 없이 업데이트만
	private static final String ADMIN_UPDATE_NICKNAME = "UPDATE MEMBER " + "SET member_nickname = ? "
			+ "WHERE member_id = ?";

	private static final String ADMIN_UPDATE_PROFILE_IMAGE = "UPDATE MEMBER " + "SET member_profile_image = ? "
			+ "WHERE member_id = ?";

	private static final String ADMIN_UPDATE_MEMBER_INFORM = "UPDATE MEMBER " + "SET "
			+ "  member_nickname = COALESCE(?, member_nickname), "
			+ "  member_profile_image = COALESCE(?, member_profile_image), "
			+ "  member_profile_color = COALESCE(?, member_profile_color), "
			+ "  member_nickname_color = COALESCE(?, member_nickname_color) " + "WHERE member_id = ?";

	private static final String UPDATE_PASSWORD = "UPDATE MEMBER " + "SET member_password = ? " + "WHERE member_id = ?";

	private static final String UPDATE_CASH_PLUS = "UPDATE MEMBER " + "SET member_cash = member_cash + ? "
			+ "WHERE member_id = ?";

	private static final String UPDATE_CASH_MINUS = "UPDATE MEMBER " + "SET member_cash = member_cash - ? "
			+ "WHERE member_id = ? AND member_cash >= ?";

	private static final String UPDATE_WITHDRAWN = "UPDATE MEMBER " + "SET member_role = 'WITHDRAWN' "
			+ "WHERE member_id = ?";

	private static final String UPDATE_COLORS = "UPDATE MEMBER "
			+ "SET member_profile_color = ?, member_nickname_color = ?, member_cash = member_cash - ? "
			+ "WHERE member_id = ? AND member_cash >= ?";

	private static final String UPDATE_NOTICE_SET = "UPDATE MEMBER " + "SET notice_pending='Y', notice_message=? "
			+ "WHERE member_id = ?";

	private static final String UPDATE_NOTICE_CLEAR = "UPDATE MEMBER " + "SET notice_pending='N', notice_message=NULL "
			+ "WHERE member_id = ? AND notice_pending='Y'";

	private static final String DELETE_MEMBER = "DELETE FROM MEMBER WHERE member_id = ?";

	/*
	 * ========================= RowMapper =========================
	 */

	private static final RowMapper<MemberDTO> ID_ONLY_ROW_MAPPER = (rs, rowNum) -> {
		MemberDTO data = new MemberDTO();
		data.setMemberId(rs.getInt("MEMBER_ID"));
		return data;
	};
	
	// CHANGED: 비밀번호 검증용 (member_id + member_password만 조회)
	private static final RowMapper<MemberDTO> ID_PASSWORD_ROW_MAPPER = (rs, rowNum) -> {
	    MemberDTO data = new MemberDTO();
	    data.setMemberId(rs.getInt("MEMBER_ID"));
	    data.setMemberPassword(rs.getString("MEMBER_PASSWORD"));
	    return data;
	};

	private static final RowMapper<MemberDTO> FULL_ROW_MAPPER = (rs, rowNum) -> {
		MemberDTO data = new MemberDTO();
		data.setMemberId(rs.getInt("MEMBER_ID"));
		data.setMemberName(rs.getString("MEMBER_NAME"));
		data.setMemberPassword(rs.getString("MEMBER_PASSWORD"));
		data.setMemberNickname(rs.getString("MEMBER_NICKNAME"));
		data.setMemberCash(rs.getInt("MEMBER_CASH"));
		data.setMemberRole(rs.getString("MEMBER_ROLE"));
		data.setMemberProfileImage(rs.getString("MEMBER_PROFILE_IMAGE"));
		data.setMemberEmail(rs.getString("MEMBER_EMAIL"));

		data.setValidReportCount(rs.getInt("VALID_REPORT_COUNT"));
		data.setNoticePending(rs.getString("NOTICE_PENDING"));
		data.setNoticeMessage(rs.getString("NOTICE_MESSAGE"));
		data.setMemberProfileColor(rs.getString("MEMBER_PROFILE_COLOR"));
		data.setMemberNicknameColor(rs.getString("MEMBER_NICKNAME_COLOR"));

		Timestamp ts = rs.getTimestamp("LAST_WARNING_AT");
		data.setLastWarningAt(ts == null ? null : ts.toLocalDateTime());

		return data;
	};

	private static final RowMapper<MemberDTO> LIST_ROW_MAPPER = (rs, rowNum) -> {
		MemberDTO data = new MemberDTO();
		data.setMemberId(rs.getInt("MEMBER_ID"));
		data.setMemberName(rs.getString("MEMBER_NAME"));
		data.setMemberNickname(rs.getString("MEMBER_NICKNAME"));
		data.setMemberCash(rs.getInt("MEMBER_CASH"));
		data.setMemberRole(rs.getString("MEMBER_ROLE"));
		data.setMemberEmail(rs.getString("MEMBER_EMAIL"));
		data.setValidReportCount(rs.getInt("VALID_REPORT_COUNT"));
		data.setNoticePending(rs.getString("NOTICE_PENDING"));

		Timestamp ts = rs.getTimestamp("LAST_WARNING_AT");
		data.setLastWarningAt(ts == null ? null : ts.toLocalDateTime());

		return data;
	};

	private static final RowMapper<MemberDTO> ID_EMAIL_ROW_MAPPER = (rs, rowNum) -> {
		MemberDTO data = new MemberDTO();
		data.setMemberId(rs.getInt("MEMBER_ID"));
		data.setMemberName(rs.getString("MEMBER_NAME"));
		data.setMemberEmail(rs.getString("MEMBER_EMAIL"));
		return data;
	};

	/*
	 * ========================= SELECT_ALL =========================
	 */
	public List<MemberDTO> selectAll(MemberDTO dto) {
		if (dto == null)
			return Collections.emptyList();

		String condition = dto.getCondition();

		try {
			if ("MEMBER_LIST_ALL".equals(condition)) {
				return jdbcTemplate.query(SELECT_MEMBER_LIST_ALL, LIST_ROW_MAPPER);
			}
			if ("MEMBER_LIST_ACTIVE".equals(condition)) {
				return jdbcTemplate.query(SELECT_MEMBER_LIST_ACTIVE, LIST_ROW_MAPPER);
			}
			return Collections.emptyList();

		} catch (Exception e) {
			e.printStackTrace();
			return Collections.emptyList();
		}
	}

	/*
	 * ========================= SELECT_ONE =========================
	 */
	public MemberDTO selectOne(MemberDTO dto) {
		if (dto == null)
			return null;

		String condition = dto.getCondition();

		try {
			if ("JOIN_NAME".equals(condition)) {
				return jdbcTemplate.queryForObject(SELECT_JOIN_NAME, ID_ONLY_ROW_MAPPER, dto.getMemberName());
			}
			if ("JOIN_NICKNAME".equals(condition)) {
				return jdbcTemplate.queryForObject(SELECT_JOIN_NICKNAME, ID_ONLY_ROW_MAPPER, dto.getMemberNickname());
			}
			if ("MEMBER_EMAIL_CHECK".equals(condition)) {
				return jdbcTemplate.queryForObject(SELECT_MEMBER_EMAIL_CHECK, ID_ONLY_ROW_MAPPER, dto.getMemberEmail());
			}

			if ("MEMBER_AUTOLOGIN".equals(condition)) {
				return jdbcTemplate.queryForObject(SELECT_MEMBER_AUTOLOGIN, FULL_ROW_MAPPER, dto.getMemberName());
			}

			if ("MEMBER_LOGIN".equals(condition)) {
			    // 비밀번호 비교는 Service에서 matches()로 처리
			    // DAO는 사용자 조회만 담당
			    return jdbcTemplate.queryForObject(SELECT_MEMBER_LOGIN, FULL_ROW_MAPPER, dto.getMemberName());
			}

			if ("MEMBER_MYPAGE".equals(condition)) {
				return jdbcTemplate.queryForObject(SELECT_MEMBER_MYPAGE, FULL_ROW_MAPPER, dto.getMemberId());
			}

			if ("MEMBER_ADMINPAGE".equals(condition)) {
				return jdbcTemplate.queryForObject(SELECT_MEMBER_ADMINPAGE, FULL_ROW_MAPPER, dto.getMemberId());
			}

			if ("MEMBER_PASSWORD_CHECK".equals(condition)) {
			    // 비밀번호 비교는 Service에서 matches()로 처리
			    // DAO는 저장된 비밀번호(해시) 조회만 담당
			    return jdbcTemplate.queryForObject(SELECT_PASSWORD_CHECK, ID_PASSWORD_ROW_MAPPER, dto.getMemberId());
			}

			if ("MEMBER_FIND_ID".equals(condition)) {
				return jdbcTemplate.queryForObject(SELECT_FIND_ID, ID_ONLY_ROW_MAPPER, dto.getMemberName());
			}

			if ("MEMBER_FIND_EMAIL".equals(condition)) {
				String email = jdbcTemplate.queryForObject(SELECT_FIND_EMAIL, String.class, dto.getMemberName());
				MemberDTO data = new MemberDTO();
				data.setMemberEmail(email);
				return data;
			}

			if ("MEMBER_ID_EMAIL".equals(condition)) {
				return jdbcTemplate.queryForObject(SELECT_MEMBER_ID_EMAIL, ID_EMAIL_ROW_MAPPER, dto.getMemberName());
			}

			if ("MEMBER_CASH_SELECT".equals(condition)) {
				Integer cash = jdbcTemplate.queryForObject(SELECT_CASH, Integer.class, dto.getMemberId());
				MemberDTO data = new MemberDTO();
				data.setMemberCash(cash == null ? 0 : cash);
				return data;
			}

			return null;

		} catch (EmptyResultDataAccessException e) {
			return null;
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	/**
	 * 현재 활성화된 제재 정보 조회 (추가!)
	 */

	/*
	 * public MemberDTO selectActiveWarning(int memberId) { try { return
	 * jdbcTemplate.queryForObject( SELECT_ACTIVE_WARNING, (rs, rowNum) -> {
	 * MemberDTO dto = new MemberDTO();
	 * dto.setMemberStatus(rs.getString("warning_type"));
	 * dto.setSanctionReason(rs.getString("reason"));
	 * 
	 * Timestamp endTime = rs.getTimestamp("end_at"); if (endTime == null) {
	 * dto.setSanctionEndAt("영구 정지"); } else {
	 * dto.setSanctionEndAt(endTime.toString()); }
	 * 
	 * return dto; }, memberId ); } catch (EmptyResultDataAccessException e) {
	 * return null; // 제재 없음 } catch (Exception e) {
	 * System.out.println("[MemberDAO] 제재 조회 에러: " + e.getMessage());
	 * e.printStackTrace(); return null; } }
	 * 
	 */
	/*
	 * ========================= INSERT =========================
	 */
	public boolean insert(MemberDTO dto) {
		if (dto == null)
			return false;
		if (!"MEMBER_JOIN".equals(dto.getCondition()))
			return false;

		try {
			int result = jdbcTemplate.update(INSERT_MEMBER_JOIN, dto.getMemberName(), dto.getMemberPassword(),
					dto.getMemberNickname(), dto.getMemberProfileImage(), dto.getMemberEmail());
			return result > 0;

		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
	}

	/*
	 * ========================= UPDATE =========================
	 */
	public boolean update(MemberDTO dto) {
		if (dto == null)
			return false;

		String condition = dto.getCondition();

		try {
			// 일반 회원 (캐시 차감/검증)
			if ("MEMBER_NICKNAME_UPDATE".equals(condition)) {
				int pay = dto.getMemberPayCash();
				int result = jdbcTemplate.update(UPDATE_NICKNAME, dto.getMemberNickname(), pay, dto.getMemberId(), pay);
				return result > 0;
			}

			if ("MEMBER_PROFILE_UPDATE".equals(condition)) {
				int pay = dto.getMemberPayCash();
				int result = jdbcTemplate.update(UPDATE_PROFILE_IMAGE, dto.getMemberProfileImage(), pay,
						dto.getMemberId(), pay);
				return result > 0;
			}

			if ("MEMBER_INFORM_UPDATE".equals(condition)) {
				int pay = dto.getMemberPayCash();
				int result = jdbcTemplate.update(UPDATE_MEMBER_INFORM, dto.getMemberNickname(),
						dto.getMemberProfileImage(), dto.getMemberProfileColor(), dto.getMemberNicknameColor(), pay,
						dto.getMemberId(), pay);
				return result > 0;
			}

			// 관리자 (무료: 캐시 조건 없이)
			if ("ADMIN_MEMBER_NICKNAME_UPDATE".equals(condition)) {
				int result = jdbcTemplate.update(ADMIN_UPDATE_NICKNAME, dto.getMemberNickname(), dto.getMemberId());
				return result > 0;
			}

			if ("ADMIN_MEMBER_PROFILE_UPDATE".equals(condition)) {
				int result = jdbcTemplate.update(ADMIN_UPDATE_PROFILE_IMAGE, dto.getMemberProfileImage(),
						dto.getMemberId());
				return result > 0;
			}

			if ("ADMIN_MEMBER_INFORM_UPDATE".equals(condition)) {
				int result = jdbcTemplate.update( ADMIN_UPDATE_MEMBER_INFORM,
	                    dto.getMemberNickname(),
	                    dto.getMemberProfileImage(),
	                    dto.getMemberProfileColor(),
	                    dto.getMemberNicknameColor(),
	                    dto.getMemberId());
				return result > 0;
			}

			if ("MEMBER_PASSWORD_UPDATE".equals(condition)) {
				int result = jdbcTemplate.update(UPDATE_PASSWORD, dto.getMemberPassword(), dto.getMemberId());
				return result > 0;
			}

			if ("MEMBER_CASH_PLUS".equals(condition)) {
				int result = jdbcTemplate.update(UPDATE_CASH_PLUS, dto.getMemberPayCash(), dto.getMemberId());
				return result > 0;
			}

			if ("MEMBER_CASH_MINUS".equals(condition)) {
				int pay = dto.getMemberPayCash();
				int result = jdbcTemplate.update(UPDATE_CASH_MINUS, pay, dto.getMemberId(), pay);
				return result > 0;
			}

			if ("MEMBER_WITHDRAWN".equals(condition)) {
				int result = jdbcTemplate.update(UPDATE_WITHDRAWN, dto.getMemberId());
				return result > 0;
			}

			if ("MEMBER_COLOR_UPDATE".equals(condition)) {
			    int pay = dto.getMemberPayCash();
			    int result = jdbcTemplate.update(UPDATE_COLORS,
			        dto.getMemberProfileColor(),
			        dto.getMemberNicknameColor(),
			        pay,
			        dto.getMemberId(),
			        pay);
			    return result > 0;
			}

			if ("MEMBER_NOTICE_SET".equals(condition)) {
				int result = jdbcTemplate.update(UPDATE_NOTICE_SET, dto.getNoticeMessage(), dto.getMemberId());
				return result > 0;
			}

			if ("MEMBER_NOTICE_CLEAR".equals(condition)) {
				int result = jdbcTemplate.update(UPDATE_NOTICE_CLEAR, dto.getMemberId());
				return result > 0;
			}
			if ("UPDATE_DECORATION".equals(condition)) {
				StringBuilder sql = new StringBuilder("UPDATE member SET ");
				List<Object> params = new ArrayList<>();

				boolean hasNickname = dto.getMemberNicknameColor() != null;
				boolean hasBorder = dto.getMemberProfileColor() != null;

				if (hasNickname) {
					sql.append("member_nickname_color = ?");
					params.add(dto.getMemberNicknameColor());
				}

				if (hasBorder) {
					if (hasNickname)
						sql.append(", ");
					sql.append("member_profile_color = ?");
					params.add(dto.getMemberProfileColor());
				}

				if (hasNickname || hasBorder) {
					sql.append(", member_cash = member_cash - ?");
					params.add(dto.getMemberPayCash());
				}

				sql.append(" WHERE member_id = ?");
				params.add(dto.getMemberId());

				int rows = jdbcTemplate.update(sql.toString(), params.toArray());
				return rows > 0;
			}

			if ("UPDATE_ADMIN_DECORATION".equals(condition)) {
				StringBuilder sql = new StringBuilder("UPDATE member SET ");
				List<Object> params = new ArrayList<>();

				boolean hasNickname = dto.getMemberNicknameColor() != null;
				boolean hasBorder = dto.getMemberProfileColor() != null;

				if (hasNickname) {
					sql.append("member_nickname_color = ?");
					params.add(dto.getMemberNicknameColor());
				}

				if (hasBorder) {
					if (hasNickname)
						sql.append(", ");
					sql.append("member_profile_color = ?");
					params.add(dto.getMemberProfileColor());
				}

				sql.append(" WHERE member_id = ?");
				params.add(dto.getMemberId());

				int rows = jdbcTemplate.update(sql.toString(), params.toArray());
				return rows > 0;
			}

			return false;

		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
	}

	/*
	 * ========================= DELETE =========================
	 */
	public boolean delete(MemberDTO dto) {
		if (dto == null)
			return false;
		if (!"MEMBER_DELETE".equals(dto.getCondition()))
			return false;

		try {
			int result = jdbcTemplate.update(DELETE_MEMBER, dto.getMemberId());
			return result > 0;

		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
	}

	/**
	 * 활성 제재 조회 (로그인 시 사용)
	 */
	public MemberWarningDTO selectActiveWarning(int memberId) {
		System.out.println("[MemberDAO] selectActiveWarning 실행 - memberId=" + memberId);

		String sql = "SELECT warning_type, reason, start_at, end_at " + "FROM member_warning " + "WHERE member_id = ? "
				+ "AND start_at <= NOW() " + "AND (end_at IS NULL OR end_at > NOW()) " + "ORDER BY start_at DESC "
				+ "LIMIT 1";

		try {
			return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> {
				MemberWarningDTO dto = new MemberWarningDTO();
				dto.setWarningType(rs.getString("warning_type"));
				dto.setReason(rs.getString("reason"));

				Timestamp startTime = rs.getTimestamp("start_at");
				dto.setStartAt(startTime == null ? null : startTime.toLocalDateTime());

				Timestamp endTime = rs.getTimestamp("end_at");
				dto.setEndAt(endTime == null ? null : endTime.toLocalDateTime());

				return dto;
			}, memberId);
		} catch (EmptyResultDataAccessException e) {
			return null;
		} catch (Exception e) {
			System.out.println("[MemberDAO] 제재 조회 에러: " + e.getMessage());
			e.printStackTrace();
			return null;
		}
	}
}