package fourcheetah.animale.web.repository.admin;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.admin.CashChargeDTO;

@Repository
public class CashChargeDAO {

	@Autowired
    private JdbcTemplate jdbcTemplate;

    // =========================================================
    // RowMapper
    private static class CashChargeRowMapper implements RowMapper<CashChargeDTO> {
        @Override
        public CashChargeDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
            CashChargeDTO dto = new CashChargeDTO();
            dto.setChargeId(rs.getInt("charge_id"));
            dto.setMemberId(rs.getInt("member_id"));
            dto.setProvider(rs.getString("provider"));
            dto.setAmount(rs.getInt("amount"));
            dto.setCashAmount(rs.getInt("cash_amount"));
            dto.setStatus(rs.getString("status"));
            dto.setPartnerOrderId(rs.getString("partner_order_id"));

            // approved_at / created_at nullable 고려
            if (rs.getTimestamp("approved_at") != null) {
                dto.setApprovedAt(rs.getTimestamp("approved_at").toLocalDateTime());
            }
            if (rs.getTimestamp("created_at") != null) {
                dto.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
            }
            return dto;
        }
    }

    // =========================================================
    // SELECT_ALL
    public List<CashChargeDTO> selectAll(CashChargeDTO dto) {

        // (1) 대시보드: 올해 월별 합계 (APPROVED 기준)
        if ("DASHBOARD_YEAR_MONTHLY_SUM".equals(dto.getCondition())) {

            String sql = """
                SELECT 
                  0 as charge_id,
                  0 as member_id,
                  '' as provider,
                  0 as amount,
                  IFNULL(SUM(cash_amount),0) as cash_amount,
                  '' as status,
                  '' as partner_order_id,
                  NULL as approved_at,
                  NULL as created_at
                FROM CASH_CHARGE
                WHERE status='APPROVED'
                  AND YEAR(approved_at)=?
                GROUP BY MONTH(approved_at)
                ORDER BY MONTH(approved_at)
            """;

            // ⚠️ 위 SQL은 월 정보를 잃기 때문에 실제로는 month 컬럼이 필요함
            // 그래서 아래처럼 month를 같이 뽑아야 정상. (하지만 DTO에 month가 있긴 함)
            // -> DTO 스타일 유지 위해 "selectAll + month 세팅" 버전으로 재작성

            String sql2 = """
                SELECT 
                  MONTH(approved_at) as month,
                  IFNULL(SUM(cash_amount),0) as total
                FROM CASH_CHARGE
                WHERE status='APPROVED'
                  AND YEAR(approved_at)=?
                GROUP BY MONTH(approved_at)
                ORDER BY MONTH(approved_at)
            """;

            return jdbcTemplate.query(sql2, (rs, rowNum) -> {
                CashChargeDTO row = new CashChargeDTO();
                row.setMonth(rs.getInt("month"));
                row.setCashAmount(rs.getInt("total")); // total을 cashAmount에 담아 전달
                return row;
            }, dto.getYear());
        }

        // (2) 대시보드: 이번달 수단별 합계
        if ("DASHBOARD_THIS_MONTH_BY_PROVIDER".equals(dto.getCondition())) {

            String sql = """
                SELECT provider,
                       IFNULL(SUM(cash_amount),0) as total
                FROM CASH_CHARGE
                WHERE status='APPROVED'
                  AND YEAR(approved_at)=?
                  AND MONTH(approved_at)=?
                GROUP BY provider
            """;

            return jdbcTemplate.query(sql, (rs, rowNum) -> {
                CashChargeDTO row = new CashChargeDTO();
                row.setProvider(rs.getString("provider"));
                row.setCashAmount(rs.getInt("total")); // total을 cashAmount에 담아 전달
                return row;
            }, dto.getYear(), dto.getMonth());
        }

        // (3) 기본: 전체 충전 내역 리스트
        String sql = "SELECT * FROM CASH_CHARGE ORDER BY charge_id DESC";
        return jdbcTemplate.query(sql, new CashChargeRowMapper());
    }

    // =========================================================
    // SELECT_ONE
    public CashChargeDTO selectOne(CashChargeDTO dto) {

        // (1) PK로 한 건 조회
        if ("CHARGE_SELECT_ONE".equals(dto.getCondition())) {
            String sql = "SELECT * FROM CASH_CHARGE WHERE charge_id=?";
            return jdbcTemplate.queryForObject(sql, new CashChargeRowMapper(), dto.getChargeId());
        }

        // (2) 대시보드: 특정월 합계 (thisMonth/lastMonth용)
        if ("DASHBOARD_MONTH_SUM".equals(dto.getCondition())) {
            String sql = """
                SELECT IFNULL(SUM(cash_amount),0)
                FROM CASH_CHARGE
                WHERE status='APPROVED'
                  AND YEAR(approved_at)=?
                  AND MONTH(approved_at)=?
            """;

            Integer total = jdbcTemplate.queryForObject(sql, Integer.class, dto.getYear(), dto.getMonth());

            CashChargeDTO result = new CashChargeDTO();
            result.setCashAmount(total == null ? 0 : total);
            return result;
        }

        return null;
    }

    // =========================================================
    // INSERT
 // DAO
    public boolean insert(CashChargeDTO dto) {

        // 예시: approved_at은 NULL 가능, created_at은 DEFAULT로 DB가 처리
        String sql =
            "INSERT INTO cash_charge " +
            "(member_id, provider, amount, cash_amount, status, partner_order_id, approved_at) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?)";

        int result = jdbcTemplate.update(
            sql,
            dto.getMemberId(),
            dto.getProvider(),         // "KAKAOPAY" / "TOSSPAY"
            dto.getAmount(),
            dto.getCashAmount(),
            dto.getStatus(),           // "READY" / "APPROVED" / ...
            dto.getPartnerOrderId(),
            dto.getApprovedAt()        // null 가능
        );

        return result > 0;
    }
    // =========================================================
    // UPDATE
    public boolean update(CashChargeDTO dto) {

        // (1) 상태 변경(READY -> APPROVED 등)
        if ("CHARGE_UPDATE_STATUS".equals(dto.getCondition())) {

            String sql = """
                UPDATE CASH_CHARGE
                SET status=?,
                    approved_at=?
                WHERE charge_id=?
            """;

            int result = jdbcTemplate.update(sql,
                    dto.getStatus(),
                    dto.getApprovedAt(),
                    dto.getChargeId()
            );

            return result > 0;
        }

        return false;
    }

    // =========================================================
    // DELETE
    public boolean delete(CashChargeDTO dto) {

        if (!"CHARGE_DELETE".equals(dto.getCondition())) {
            return false;
        }

        String sql = "DELETE FROM CASH_CHARGE WHERE charge_id=?";
        return jdbcTemplate.update(sql, dto.getChargeId()) > 0;
    }
}
