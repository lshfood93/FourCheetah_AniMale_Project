package fourcheetah.animale.web.repository.admin;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.admin.CashStatsDTO;
import fourcheetah.animale.web.dto.admin.CashChargeDTO;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;

/**
 * 관리자 캐시 통계 DAO (DTO + RowMapper 사용)
 */
@Repository
public class AdminCashDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    // =========================================================
    // SQL 쿼리 상수
    // =========================================================
    
    private static final String SELECT_MONTHLY_STATS = 
        "SELECT " +
        "  COALESCE(SUM(cash_amount), 0) AS total_amount, " +
        "  COALESCE(COUNT(*), 0) AS charge_count, " +
        "  COALESCE(ROUND(AVG(cash_amount)), 0) AS avg_amount, " +
        "  COALESCE(COUNT(DISTINCT member_id), 0) AS unique_users, " +
        "  COALESCE(SUM(CASE WHEN provider = 'KAKAOPAY' THEN cash_amount ELSE 0 END), 0) AS kakaopay_amount, " +
        "  COALESCE(SUM(CASE WHEN provider = 'TOSSPAY' THEN cash_amount ELSE 0 END), 0) AS tosspay_amount " +
        "FROM cash_charge " +
        "WHERE status = 'APPROVED' " +
        "  AND YEAR(approved_at) = ? " +
        "  AND MONTH(approved_at) = ?";
    
    private static final String SELECT_TOP_CHARGERS = 
        "SELECT " +
        "  cc.member_id, " +
        "  m.member_nickname, " +
        "  m.member_name, " +
        "  m.member_email, " +
        "  SUM(cc.cash_amount) AS total_amount, " +
        "  COUNT(*) AS charge_count " +
        "FROM cash_charge cc " +
        "JOIN member m ON m.member_id = cc.member_id " +
        "WHERE cc.status = 'APPROVED' " +
        "GROUP BY cc.member_id, m.member_nickname, m.member_name, m.member_email " +
        "ORDER BY total_amount DESC " +
        "LIMIT ?";
    
    // =========================================================
    // RowMapper 정의
    // =========================================================
    
    /**
     * CashStatsDTO용 RowMapper
     */
    private static class CashStatsRowMapper implements RowMapper<CashStatsDTO> {
        @Override
        public CashStatsDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
            CashStatsDTO dto = new CashStatsDTO();
            dto.setTotalAmount(rs.getInt("total_amount"));
            dto.setChargeCount(rs.getInt("charge_count"));
            dto.setAvgAmount(rs.getInt("avg_amount"));
            dto.setUniqueUsers(rs.getInt("unique_users"));
            dto.setKakaopayAmount(rs.getInt("kakaopay_amount"));
            dto.setTosspayAmount(rs.getInt("tosspay_amount"));
            return dto;
        }
    }
    
    /**
     * CashChargeDTO용 RowMapper (순위 조회용)
     */
    private static class CashChargeRowMapper implements RowMapper<CashChargeDTO> {
        @Override
        public CashChargeDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
            CashChargeDTO dto = new CashChargeDTO();
            dto.setMemberId(rs.getInt("member_id"));
            dto.setMemberNickname(rs.getString("member_nickname"));
            dto.setMemberName(rs.getString("member_name"));
            dto.setMemberEmail(rs.getString("member_email"));
            dto.setTotalAmount(rs.getInt("total_amount"));
            dto.setChargeCount(rs.getInt("charge_count"));
            dto.setRanking(rowNum + 1);  // 순위는 rowNum + 1
            return dto;
        }
    }
    
    // =========================================================
    // 메서드
    // =========================================================
    
    /**
     * DB 연결 테스트
     */
    public int testConnection() {
        System.out.println("[DAO] DB 연결 테스트");
        
        try {
            String sql = "SELECT COUNT(*) FROM cash_charge";
            Integer count = jdbcTemplate.queryForObject(sql, Integer.class);
            System.out.println("[DAO] cash_charge 테이블 행 수: " + count);
            return count != null ? count : 0;
        } catch (Exception e) {
            System.out.println("[DAO 에러] " + e.getMessage());
            e.printStackTrace();
            return 0;
        }
    }
    
    /**
     * 월별 통계 조회 (DTO 반환)
     * @param year 연도
     * @param month 월
     * @return 월별 통계 DTO
     */
    public CashStatsDTO selectMonthlyStats(int year, int month) {
        System.out.println("[DAO] 월별 통계 조회 - year=" + year + ", month=" + month);
        
        try {
            CashStatsDTO dto = jdbcTemplate.queryForObject(
                SELECT_MONTHLY_STATS,
                new CashStatsRowMapper(),
                year,
                month
            );
            
            // year, month 설정
            dto.setYear(year);
            dto.setMonth(month);
            
            System.out.println("[DAO] 월별 통계 조회 완료 - total=" + dto.getTotalAmount());
            
            return dto;
            
        } catch (EmptyResultDataAccessException e) {
            System.out.println("[DAO] 데이터 없음 - 빈 DTO 반환");
            
            // 데이터 없으면 빈 DTO 반환
            CashStatsDTO empty = new CashStatsDTO();
            empty.setYear(year);
            empty.setMonth(month);
            empty.setTotalAmount(0);
            empty.setChargeCount(0);
            empty.setAvgAmount(0);
            empty.setUniqueUsers(0);
            empty.setKakaopayAmount(0);
            empty.setTosspayAmount(0);
            
            return empty;
            
        } catch (Exception e) {
            System.out.println("[DAO 에러] " + e.getMessage());
            e.printStackTrace();
            
            // 에러 시 빈 DTO 반환
            CashStatsDTO empty = new CashStatsDTO();
            empty.setYear(year);
            empty.setMonth(month);
            empty.setTotalAmount(0);
            empty.setChargeCount(0);
            empty.setAvgAmount(0);
            empty.setUniqueUsers(0);
            empty.setKakaopayAmount(0);
            empty.setTosspayAmount(0);
            
            return empty;
        }
    }
    
    /**
     * 충전 순위 Top N 조회 (DTO 리스트 반환)
     * @param limit 조회 건수
     * @return 충전 순위 DTO 리스트
     */
    public List<CashChargeDTO> selectTopChargers(int limit) {
        System.out.println("[DAO] 충전 순위 조회 - limit=" + limit);
        
        try {
            List<CashChargeDTO> list = jdbcTemplate.query(
                SELECT_TOP_CHARGERS,
                new CashChargeRowMapper(),
                limit
            );
            
            System.out.println("[DAO] 충전 순위 조회 완료 - count=" + list.size());
            
            return list;
            
        } catch (Exception e) {
            System.out.println("[DAO 에러] " + e.getMessage());
            e.printStackTrace();
            
            return new ArrayList<>();
        }
    }
    
    /**
     * 충전 순위 Top 10 (기본값)
     */
    public List<CashChargeDTO> selectTopChargers() {
        return selectTopChargers(10);
    }
}