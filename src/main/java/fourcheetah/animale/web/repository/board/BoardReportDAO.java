package fourcheetah.animale.web.repository.board;

import java.sql.Timestamp;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import fourcheetah.animale.web.dto.board.BoardReportDTO;

@Repository
public class BoardReportDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /* =========================
       SQL 쿼리
       ========================= */

    // 신고 목록 조회 (관리자) - 오래된 순
    private static final String SELECT_REPORT_LIST_ASC =
        "SELECT " +
        "  br.board_id, " +
        "  b.member_id AS board_writer_id, " +
        "  m.member_nickname AS board_writer_nickname, " +
        "  b.board_title, " +
        "  b.board_content, " +
        "  COUNT(br.report_id) AS report_count, " +
        "  MIN(br.created_at) AS created_at " +
        "FROM board_report br " +
        "JOIN board b ON br.board_id = b.board_id " +
        "JOIN member m ON b.member_id = m.member_id " +
        "WHERE br.status = 'PENDING' " +
        "GROUP BY br.board_id, b.member_id, m.member_nickname, b.board_title, b.board_content " +
        "ORDER BY created_at ASC " +
        "LIMIT ? OFFSET ?";

    // 신고 목록 조회 (관리자) - 최신순
    private static final String SELECT_REPORT_LIST_DESC =
        "SELECT " +
        "  br.board_id, " +
        "  b.member_id AS board_writer_id, " +
        "  m.member_nickname AS board_writer_nickname, " +
        "  b.board_title, " +
        "  b.board_content, " +
        "  COUNT(br.report_id) AS report_count, " +
        "  MIN(br.created_at) AS created_at " +
        "FROM board_report br " +
        "JOIN board b ON br.board_id = b.board_id " +
        "JOIN member m ON b.member_id = m.member_id " +
        "WHERE br.status = 'PENDING' " +
        "GROUP BY br.board_id, b.member_id, m.member_nickname, b.board_title, b.board_content " +
        "ORDER BY created_at DESC " +
        "LIMIT ? OFFSET ?";

    // ✅ boardId로 단건 조회 (신고 승인 처리용)
    private static final String SELECT_REPORT_BY_BOARD_ID =
        "SELECT " +
        "  br.board_id, " +
        "  b.member_id AS board_writer_id, " +
        "  m.member_nickname AS board_writer_nickname, " +
        "  b.board_title, " +
        "  b.board_content, " +
        "  COUNT(br.report_id) AS report_count, " +
        "  MIN(br.created_at) AS created_at " +
        "FROM board_report br " +
        "JOIN board b ON br.board_id = b.board_id " +
        "JOIN member m ON b.member_id = m.member_id " +
        "WHERE br.status = 'PENDING' AND br.board_id = ? " +
        "GROUP BY br.board_id, b.member_id, m.member_nickname, b.board_title, b.board_content";

    // 신고 목록 총 개수
    private static final String COUNT_REPORT_LIST =
        "SELECT COUNT(DISTINCT br.board_id) " +
        "FROM board_report br " +
        "WHERE br.status = 'PENDING'";

    // 중복 신고 체크
    private static final String CHECK_DUPLICATE_REPORT =
        "SELECT COUNT(*) " +
        "FROM board_report " +
        "WHERE board_id = ? AND reporter_member_id = ?";

    // 신고 접수
    private static final String INSERT_BOARD_REPORT =
        "INSERT INTO board_report " +
        "(board_id, reporter_member_id, reason_code, status, created_at) " +
        "VALUES (?, ?, ?, 'PENDING', NOW())";

    // 신고 승인 - 게시글 삭제
    private static final String UPDATE_BOARD_DELETE =
        "UPDATE board " +
        "SET board_status = '내용삭제', " +
        "    board_title = CASE " +
        "        WHEN board_title NOT LIKE '[삭제됨]%' " +
        "        THEN CONCAT('[삭제됨] ', board_title) " +
        "        ELSE board_title " +
        "    END, " +
        "    board_content = '신고 요청으로 삭제된 게시글입니다.', " +
        "    content_deleted_at = NOW() " +
        "WHERE board_id = ?";

    // 신고 승인 - PENDING -> APPROVED
    private static final String UPDATE_REPORT_APPROVE =
        "UPDATE board_report " +
        "SET status = 'APPROVED', handled_by = ?, handled_at = NOW() " +
        "WHERE board_id = ? AND status = 'PENDING'";

    // 신고 반려
    private static final String UPDATE_REPORT_REJECT =
        "UPDATE board_report " +
        "SET status = 'REJECTED', handled_by = ?, handled_at = NOW() " +
        "WHERE board_id = ? AND status = 'PENDING'";

    // 작성자 경고 횟수 +1
    private static final String UPDATE_MEMBER_WARNING =
        "UPDATE member " +
        "SET valid_report_count = valid_report_count + 1, " +
        "    last_warning_at = NOW() " +
        "WHERE member_id = ?";

    // 현재 유효 신고 횟수 조회
    private static final String SELECT_VALID_REPORT_COUNT =
        "SELECT valid_report_count " +
        "FROM member " +
        "WHERE member_id = ?";

    // member_warning 테이블에 제재 기록 INSERT
    private static final String INSERT_MEMBER_WARNING =
        "INSERT INTO member_warning " +
        "(member_id, issued_by, source_report_id, warning_type, reason, start_at, end_at) " +
        "SELECT " +
        "  ?, " +
        "  ?, " +
        "  report_id, " +
        "  CASE " +
        "    WHEN ? >= 6 THEN 'BAN' " +
        "    WHEN ? = 5 THEN 'SUSPEND_30D' " +
        "    WHEN ? = 3 THEN 'SUSPEND_7D' " +
        "    ELSE 'WARNING' " +
        "  END, " +
        "  CASE " +
        "    WHEN ? >= 6 THEN '신고 누적 6회 이상 - 영구 정지' " +
        "    WHEN ? = 5 THEN '신고 누적 5회 - 30일 정지' " +
        "    WHEN ? = 3 THEN '신고 누적 3회 - 7일 정지' " +
        "    ELSE '게시글 신고 승인' " +
        "  END, " +
        "  NOW(), " +
        "  CASE " +
        "    WHEN ? >= 6 THEN NULL " +
        "    WHEN ? = 5 THEN DATE_ADD(NOW(), INTERVAL 30 DAY) " +
        "    WHEN ? = 3 THEN DATE_ADD(NOW(), INTERVAL 7 DAY) " +
        "    ELSE DATE_ADD(NOW(), INTERVAL 1 DAY) " +
        "  END " +
        "FROM board_report " +
        "WHERE board_id = ? AND status = 'PENDING' " +
        "LIMIT 1";

    // 알림 생성 (3회 이상)
    private static final String UPDATE_MEMBER_NOTICE =
        "UPDATE member " +
        "SET notice_pending = 'Y', " +
        "    notice_message = CONCAT('신고 누적 ', valid_report_count, '회. 주의하세요.') " +
        "WHERE member_id = ? AND valid_report_count >= 3";

    /* =========================
       RowMapper
       ========================= */

    private static final RowMapper<BoardReportDTO> BoardReportRowMapper = (rs, rowNum) -> {
        BoardReportDTO dto = new BoardReportDTO();
        dto.setBoardId(rs.getInt("board_id"));
        dto.setBoardWriterId(rs.getInt("board_writer_id"));
        dto.setBoardWriterNickname(rs.getString("board_writer_nickname"));
        dto.setBoardTitle(rs.getString("board_title"));
        dto.setBoardContent(rs.getString("board_content"));
        dto.setReportCount(rs.getInt("report_count"));

        Timestamp ts = rs.getTimestamp("created_at");
        dto.setCreatedAt(ts == null ? null : ts.toLocalDateTime());

        return dto;
    };

    /* =========================
       SELECT_ALL (신고 목록 조회)
       ========================= */

    public List<BoardReportDTO> selectAll(BoardReportDTO dto) {
        if (dto == null) {
            return List.of();
        }

        int pageSize = dto.getPageSize();
        int currentPage = dto.getPage();
        int offset = (currentPage - 1) * pageSize;

        String sortOrder = dto.getSortOrder();
        String sql = "asc".equalsIgnoreCase(sortOrder) ?
                     SELECT_REPORT_LIST_ASC : SELECT_REPORT_LIST_DESC;

        System.out.println("[DAO] 신고 목록 조회 - 페이지: " + currentPage +
                           ", 정렬: " + sortOrder);

        try {
            return jdbcTemplate.query(sql, BoardReportRowMapper, pageSize, offset);
        } catch (Exception e) {
            System.out.println("[DAO 에러] 신고 목록 조회: " + e.getMessage());
            e.printStackTrace();
            return List.of();
        }
    }

    // ✅ boardId로 단건 조회 (신고 승인 처리 전 작성자 ID 확인용)
    public BoardReportDTO selectOneByBoardId(int boardId) {
        System.out.println("[DAO] selectOneByBoardId 실행 - boardId=" + boardId);
        try {
            return jdbcTemplate.queryForObject(
                SELECT_REPORT_BY_BOARD_ID,
                BoardReportRowMapper,
                boardId
            );
        } catch (EmptyResultDataAccessException e) {
            System.out.println("[DAO] 해당 boardId의 PENDING 신고 없음 - boardId=" + boardId);
            return null;
        } catch (Exception e) {
            System.out.println("[DAO 에러] selectOneByBoardId: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    public int getTotalCount() {
        try {
            Integer count = jdbcTemplate.queryForObject(COUNT_REPORT_LIST, Integer.class);
            return count != null ? count : 0;
        } catch (Exception e) {
            System.out.println("[DAO 에러] 신고 개수 조회: " + e.getMessage());
            return 0;
        }
    }

    /* =========================
       사용자 신고 접수
       ========================= */

    public boolean isDuplicateReport(int boardId, int reporterMemberId) {
        try {
            Integer count = jdbcTemplate.queryForObject(
                CHECK_DUPLICATE_REPORT,
                Integer.class,
                boardId,
                reporterMemberId
            );
            return count != null && count > 0;
        } catch (Exception e) {
            System.out.println("[DAO 에러] 중복 신고 체크: " + e.getMessage());
            return false;
        }
    }

    public boolean insertReport(int boardId, int reporterMemberId, String reasonCode) {
        try {
            int rows = jdbcTemplate.update(
                INSERT_BOARD_REPORT,
                boardId,
                reporterMemberId,
                reasonCode
            );
            System.out.println("[DAO] 신고 접수 완료 - rows=" + rows);
            return rows > 0;
        } catch (Exception e) {
            System.out.println("[DAO 에러] 신고 접수: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    /* =========================
       관리자 신고 처리
       ========================= */

    @Transactional
    public boolean approveReport(int boardId, int boardWriterId, int handledBy) {
        System.out.println("[DAO] 신고 승인 트랜잭션 시작");
        System.out.println("  - boardId=" + boardId);
        System.out.println("  - writerId=" + boardWriterId);
        System.out.println("  - handledBy=" + handledBy);

        try {
            Integer currentCount = jdbcTemplate.queryForObject(
                SELECT_VALID_REPORT_COUNT,
                Integer.class,
                boardWriterId
            );

            int newCount = (currentCount != null ? currentCount : 0) + 1;
            System.out.println("[DAO] 현재 신고 횟수: " + currentCount + " → 신규: " + newCount);

            int rows1 = jdbcTemplate.update(UPDATE_BOARD_DELETE, boardId);
            System.out.println("[DAO] 게시글 상태 변경 - rows=" + rows1);

            int rows2 = jdbcTemplate.update(UPDATE_REPORT_APPROVE, handledBy, boardId);
            System.out.println("[DAO] 신고 승인 - rows=" + rows2);

            int rows3 = jdbcTemplate.update(UPDATE_MEMBER_WARNING, boardWriterId);
            System.out.println("[DAO] 작성자 경고 +1 - rows=" + rows3);

            int rows4 = jdbcTemplate.update(
                INSERT_MEMBER_WARNING,
                boardWriterId,
                handledBy,
                newCount, newCount, newCount,
                newCount, newCount, newCount,
                newCount, newCount, newCount,
                boardId
            );
            System.out.println("[DAO] 제재 기록 생성 - rows=" + rows4);

            if (newCount >= 3) {
                int rows5 = jdbcTemplate.update(UPDATE_MEMBER_NOTICE, boardWriterId);
                System.out.println("[DAO] 알림 생성 - rows=" + rows5);
            }

            System.out.println("[DAO] 신고 승인 트랜잭션 완료");
            return true;

        } catch (Exception e) {
            System.out.println("[DAO 에러] " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("신고 승인 처리 실패", e);
        }
    }

    @Transactional
    public boolean rejectReport(int boardId, int handledBy) {
        System.out.println("[DAO] 신고 반려 - boardId=" + boardId);

        try {
            int rows = jdbcTemplate.update(UPDATE_REPORT_REJECT, handledBy, boardId);
            System.out.println("[DAO] 신고 반려 - rows=" + rows);
            return rows > 0;
        } catch (Exception e) {
            System.out.println("[DAO 에러] 신고 반려: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("신고 반려 처리 실패", e);
        }
    }
}