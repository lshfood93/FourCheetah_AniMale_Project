package fourcheetah.animale.web.repository.board;

import java.sql.Timestamp;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
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

    // 신고 승인 - 게시글 삭제 (board_status 변경 + 제목/내용 변경)
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

    // 신고 승인 - 해당 게시글의 모든 PENDING 신고 APPROVED로 변경
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
        "  ?, " +                                    // member_id
        "  ?, " +                                    // issued_by (관리자)
        "  report_id, " +                            // source_report_id
        "  CASE " +
        "    WHEN ? >= 7 THEN 'BAN' " +
        "    WHEN ? >= 5 THEN 'SUSPEND_30D' " +
        "    WHEN ? >= 3 THEN 'SUSPEND_7D' " +
        "    ELSE 'WARNING' " +
        "  END, " +                                  // warning_type
        "  CASE " +
        "    WHEN ? >= 7 THEN '신고 누적 7회 이상 - 영구 정지' " +
        "    WHEN ? >= 5 THEN '신고 누적 5~6회 - 30일 정지' " +
        "    WHEN ? >= 3 THEN '신고 누적 3~4회 - 7일 정지' " +
        "    ELSE '게시글 신고 승인' " +
        "  END, " +                                  // reason
        "  NOW(), " +                                // start_at
        "  CASE " +
        "    WHEN ? >= 7 THEN NULL " +
        "    WHEN ? >= 5 THEN DATE_ADD(NOW(), INTERVAL 30 DAY) " +
        "    WHEN ? >= 3 THEN DATE_ADD(NOW(), INTERVAL 7 DAY) " +
        "    ELSE DATE_ADD(NOW(), INTERVAL 1 DAY) " +
        "  END " +                                   // end_at
        "FROM board_report " +
        "WHERE board_id = ? AND status = 'PENDING' " +
        "LIMIT 1";

    // 신고 상세 조회 (boardId로 단건 조회)
    private static final String SELECT_REPORT_DETAIL =
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
        "WHERE br.board_id = ? AND br.status = 'PENDING' " +
        "GROUP BY br.board_id, b.member_id, m.member_nickname, b.board_title, b.board_content " +
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
        dto.setBoardTitle(rs.getString("board_title"));
        dto.setBoardContent(rs.getString("board_content"));
        dto.setReportCount(rs.getInt("report_count"));
        dto.setBoardWriterNickname(rs.getString("board_writer_nickname"));

        Timestamp ts = rs.getTimestamp("created_at");
        dto.setCreatedAt(ts == null ? null : ts.toLocalDateTime());

        return dto;
    };

    /* =========================
       SELECT_ALL (신고 목록 조회)
       ========================= */

    /**
     * 신고 목록 조회 (페이징 + 정렬)
     */
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

    /**
     * 신고 목록 총 개수
     */
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

    /**
     * 중복 신고 체크
     */
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

    /**
     * 신고 접수
     */
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

    /**
     * 신고 승인 (트랜잭션)
     * 1. 게시글 상태 변경
     * 2. 신고 승인
     * 3. 작성자 경고 +1
     * 4. member_warning 테이블에 제재 기록
     * 5. 알림 생성 (3회 이상)
     */
    @Transactional
    public boolean approveReport(int boardId, int boardWriterId, int handledBy) {
        System.out.println("[DAO] 신고 승인 트랜잭션 시작");
        System.out.println("  - boardId=" + boardId);
        System.out.println("  - writerId=" + boardWriterId);
        System.out.println("  - handledBy=" + handledBy);

        try {
            // 1. PENDING 행 락 + 중복 승인 방지 (SELECT FOR UPDATE)
            //    동시 요청이 와도 첫 번째 트랜잭션이 끝날 때까지 두 번째는 대기
            //    첫 번째 완료 후 PENDING 없으면 두 번째는 중단
            Integer pendingCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM board_report WHERE board_id = ? AND status = 'PENDING' FOR UPDATE",
                Integer.class, boardId
            );
            if (pendingCount == null || pendingCount == 0) {
                System.out.println("[DAO] 이미 처리된 게시글 (중복 요청 차단) - 승인 중단 boardId=" + boardId);
                return false;
            }

            // 2. 현재 유효 신고 횟수 조회
            Integer currentCount = jdbcTemplate.queryForObject(
                SELECT_VALID_REPORT_COUNT,
                Integer.class,
                boardWriterId
            );

            int newCount = (currentCount != null ? currentCount : 0) + 1;
            System.out.println("[DAO] 현재 신고 횟수: " + currentCount + " → 신규: " + newCount);

            // 3. 게시글 상태 변경 (board_status = '내용삭제')
            int rows1 = jdbcTemplate.update(UPDATE_BOARD_DELETE, boardId);
            System.out.println("[DAO] 게시글 상태 변경 - rows=" + rows1);

            // ✅ FIX: INSERT_MEMBER_WARNING이 status='PENDING' 참조하므로 UPDATE_REPORT_APPROVE 전에 실행
            // 4. member_warning 테이블에 제재 기록 (PENDING 상태 참조)
            int rows4 = jdbcTemplate.update(
                INSERT_MEMBER_WARNING,
                boardWriterId,      // member_id
                handledBy,          // issued_by
                newCount,           // warning_type 판단 (>= 7)
                newCount,           // warning_type 판단 (>= 5)
                newCount,           // warning_type 판단 (>= 3)
                newCount,           // reason 판단 (>= 7)
                newCount,           // reason 판단 (>= 5)
                newCount,           // reason 판단 (>= 3)
                newCount,           // end_at 판단 (>= 7)
                newCount,           // end_at 판단 (>= 5)
                newCount,           // end_at 판단 (>= 3)
                boardId             // source_report_id 조회용
            );
            System.out.println("[DAO] 제재 기록 생성 - rows=" + rows4);

            // 5. 신고 승인 (PENDING → APPROVED) - INSERT_MEMBER_WARNING 이후 실행
            int rows2 = jdbcTemplate.update(UPDATE_REPORT_APPROVE, handledBy, boardId);
            System.out.println("[DAO] 신고 승인 - rows=" + rows2);

            // 6. 작성자 경고 +1
            int rows3 = jdbcTemplate.update(UPDATE_MEMBER_WARNING, boardWriterId);
            System.out.println("[DAO] 작성자 경고 +1 - rows=" + rows3);

            // 7. 알림 생성 (3회 이상)

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

    /**
     * 신고 반려
     */
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

    /**
     * 신고 상세 조회 (boardId 단건)
     */
    public BoardReportDTO selectReportDetail(int boardId) {
        System.out.println("[DAO] 신고 상세 조회 - boardId=" + boardId);
        try {
            List<BoardReportDTO> result = jdbcTemplate.query(
                SELECT_REPORT_DETAIL, BoardReportRowMapper, boardId
            );
            return result.isEmpty() ? null : result.get(0);
        } catch (Exception e) {
            System.out.println("[DAO 에러] 신고 상세 조회: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    /**
     * 내가 신고한 게시글인지 체크 (신고버튼 비활성화용)
     */
    public boolean isReportedByMember(int boardId, int memberId) {
        try {
            Integer count = jdbcTemplate.queryForObject(
                CHECK_DUPLICATE_REPORT,
                Integer.class,
                boardId,
                memberId
            );
            return count != null && count > 0;
        } catch (Exception e) {
            System.out.println("[DAO 에러] isReportedByMember: " + e.getMessage());
            return false;
        }
    }
}