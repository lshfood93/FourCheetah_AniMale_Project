package fourcheetah.animale.web.repository.member;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.member.MemberWarningDTO;

/**
 * 회원 제재 이력 DAO (JdbcTemplate)
 * 
 * MEMBER_WARNING 테이블 접근
 */
@Repository
public class MemberWarningDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    /**
     * RowMapper - MEMBER_WARNING 테이블 매핑
     */
    private static class MemberWarningRowMapper implements RowMapper<MemberWarningDTO> {
        @Override
        public MemberWarningDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
            MemberWarningDTO dto = new MemberWarningDTO();
            
            dto.setWarningId(rs.getInt("warning_id"));
            dto.setMemberId(rs.getInt("member_id"));
            dto.setIssuedBy(rs.getInt("issued_by"));
            
            // source_report_id는 NULL 가능
            int sourceReportId = rs.getInt("source_report_id");
            if (!rs.wasNull()) {
                dto.setSourceReportId(sourceReportId);
            }
            
            dto.setWarningType(rs.getString("warning_type"));
            dto.setReason(rs.getString("reason"));
            
            // LocalDateTime 변환
            dto.setStartAt(rs.getObject("start_at", LocalDateTime.class));
            
            // end_at은 NULL 가능 (영구정지)
            LocalDateTime endAt = rs.getObject("end_at", LocalDateTime.class);
            if (endAt != null) {
                dto.setEndAt(endAt);
            }
            
            dto.setCreatedAt(rs.getObject("created_at", LocalDateTime.class));
            
            return dto;
        }
    }
    
    /**
     * 회원의 최신 제재 조회 (1건)
     * 
     * @param memberId 회원 ID
     * @return 최신 제재 정보 (없으면 null)
     */
    public MemberWarningDTO selectLatestWarning(int memberId) {
        System.out.println("[MemberWarningDAO] selectLatestWarning 실행 - memberId=" + memberId);
        
        String sql = "SELECT warning_id, member_id, issued_by, source_report_id, " +
                     "warning_type, reason, start_at, end_at, created_at " +
                     "FROM member_warning " +
                     "WHERE member_id = ? " +
                     "ORDER BY created_at DESC " +
                     "LIMIT 1";
        
        try {
            MemberWarningDTO result = jdbcTemplate.queryForObject(
                sql, 
                new MemberWarningRowMapper(), 
                memberId
            );
            
            System.out.println("[MemberWarningDAO] 조회 성공 - warningType=" + result.getWarningType());
            return result;
            
        } catch (Exception e) {
            // 제재 없음 (정상)
            System.out.println("[MemberWarningDAO] 제재 없음 (정상 회원)");
            return null;
        }
    }
    
    /**
     * 제재 이력 저장
     * 
     * @param dto 제재 정보
     * @return 성공 시 1, 실패 시 0
     */
    public int insertWarning(MemberWarningDTO dto) {
        System.out.println("[MemberWarningDAO] insertWarning 실행");
        System.out.println("  - memberId=" + dto.getMemberId());
        System.out.println("  - warningType=" + dto.getWarningType());
        System.out.println("  - issuedBy=" + dto.getIssuedBy());
        
        String sql = "INSERT INTO member_warning " +
                     "(member_id, issued_by, source_report_id, warning_type, reason, start_at, end_at, created_at) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
        
        try {
            int result = jdbcTemplate.update(
                sql,
                dto.getMemberId(),
                dto.getIssuedBy(),
                dto.getSourceReportId(),
                dto.getWarningType(),
                dto.getReason(),
                dto.getStartAt(),
                dto.getEndAt()
            );
            
            System.out.println("[MemberWarningDAO] 저장 성공 - result=" + result);
            return result;
            
        } catch (Exception e) {
            System.out.println("[MemberWarningDAO] 저장 실패 - " + e.getMessage());
            e.printStackTrace();
            return 0;
        }
    }
    
    /**
     * 회원의 활성 제재 개수 조회 (현재 진행 중인 정지)
     * 
     * @param memberId 회원 ID
     * @return 활성 제재 개수
     */
    public int selectActiveWarningCount(int memberId) {
        System.out.println("[MemberWarningDAO] selectActiveWarningCount 실행 - memberId=" + memberId);
        
        String sql = "SELECT COUNT(*) " +
                     "FROM member_warning " +
                     "WHERE member_id = ? " +
                     "AND (warning_type = 'BAN' OR (end_at IS NOT NULL AND end_at > NOW()))";
        
        try {
            Integer count = jdbcTemplate.queryForObject(sql, Integer.class, memberId);
            System.out.println("[MemberWarningDAO] 활성 제재 개수=" + count);
            return (count != null) ? count : 0;
            
        } catch (Exception e) {
            System.out.println("[MemberWarningDAO] 조회 실패 - " + e.getMessage());
            return 0;
        }
    }

    /**
     * ✅ NEW: WARNING_NEW → WARNING 업데이트 (최초 로그인 모달 확인 처리)
     * warning_type = 'WARNING_NEW' 인 레코드를 'WARNING' 으로 변경
     *
     * @param warningId 경고 ID
     */
    public void updateWarningConfirmed(int warningId) {
        System.out.println("[MemberWarningDAO] updateWarningConfirmed 실행 - warningId=" + warningId);

        String sql = "UPDATE member_warning SET warning_type = 'WARNING' WHERE warning_id = ? AND warning_type = 'WARNING_NEW'";

        try {
            int rows = jdbcTemplate.update(sql, warningId);
            System.out.println("[MemberWarningDAO] updateWarningConfirmed 완료 - rows=" + rows);
        } catch (Exception e) {
            System.out.println("[MemberWarningDAO] updateWarningConfirmed 실패 - " + e.getMessage());
        }
    }
}