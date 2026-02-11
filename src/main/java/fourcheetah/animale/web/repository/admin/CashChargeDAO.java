package fourcheetah.animale.web.repository.admin;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.admin.CashChargeDTO;

@Repository
public class CashChargeDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    // =========================================================
    // SQL (final)
    private static final String SELECT_ALL_LIST =
        "SELECT * FROM CASH_CHARGE ORDER BY charge_id DESC";

    private static final String SELECT_ONE_BY_ID =
        "SELECT * FROM CASH_CHARGE WHERE charge_id=?";

    // 올해 월별 합계 (APPROVED 기준)
    private static final String DASHBOARD_YEAR_MONTHLY_SUM =
        "SELECT " +
        "  MONTH(approved_at) as month, " +
        "  IFNULL(SUM(cash_amount),0) as total " +
        "FROM CASH_CHARGE " +
        "WHERE status='APPROVED' " +
        "  AND YEAR(approved_at)=? " +
        "GROUP BY MONTH(approved_at) " +
        "ORDER BY MONTH(approved_at)";

    // 이번달 수단별 합계
    private static final String DASHBOARD_THIS_MONTH_BY_PROVIDER =
        "SELECT provider, " +
        "       IFNULL(SUM(cash_amount),0) as total " +
        "FROM CASH_CHARGE " +
        "WHERE status='APPROVED' " +
        "  AND YEAR(approved_at)=? " +
        "  AND MONTH(approved_at)=? " +
        "GROUP BY provider";

    // 특정월 합계 (thisMonth/lastMonth용)
    private static final String DASHBOARD_MONTH_SUM =
        "SELECT IFNULL(SUM(cash_amount),0) " +
        "FROM CASH_CHARGE " +
        "WHERE status='APPROVED' " +
        "  AND YEAR(approved_at)=? " +
        "  AND MONTH(approved_at)=?";

    // insert
    private static final String INSERT =
        "INSERT INTO cash_charge " +
        "(member_id, provider, amount, cash_amount, status, partner_order_id, approved_at) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?)";

    // 상태 업데이트
    private static final String UPDATE_STATUS_APPROVED_AT =
        "UPDATE CASH_CHARGE " +
        "SET status=?, approved_at=? " +
        "WHERE charge_id=?";

    // delete
    private static final String DELETE_BY_ID =
        "DELETE FROM CASH_CHARGE WHERE charge_id=?";

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
            return jdbcTemplate.query(DASHBOARD_YEAR_MONTHLY_SUM, (rs, rowNum) -> {
                CashChargeDTO row = new CashChargeDTO();
                row.setMonth(rs.getInt("month"));
                row.setCashAmount(rs.getInt("total")); // total을 cashAmount에 담아 전달
                return row;
            }, dto.getYear());
        }

        // (2) 대시보드: 이번달 수단별 합계
        if ("DASHBOARD_THIS_MONTH_BY_PROVIDER".equals(dto.getCondition())) {
            return jdbcTemplate.query(DASHBOARD_THIS_MONTH_BY_PROVIDER, (rs, rowNum) -> {
                CashChargeDTO row = new CashChargeDTO();
                row.setProvider(rs.getString("provider"));
                row.setCashAmount(rs.getInt("total")); // total을 cashAmount에 담아 전달
                return row;
            }, dto.getYear(), dto.getMonth());
        }

        // (3) 기본: 전체 충전 내역 리스트
        return jdbcTemplate.query(SELECT_ALL_LIST, new CashChargeRowMapper());
    }

    // =========================================================
    // SELECT_ONE
    public CashChargeDTO selectOne(CashChargeDTO dto) {

        // (1) PK로 한 건 조회
        if ("CHARGE_SELECT_ONE".equals(dto.getCondition())) {
            return jdbcTemplate.queryForObject(SELECT_ONE_BY_ID, new CashChargeRowMapper(), dto.getChargeId());
        }

        // (2) 대시보드: 특정월 합계 (thisMonth/lastMonth용)
        if ("DASHBOARD_MONTH_SUM".equals(dto.getCondition())) {
            Integer total = jdbcTemplate.queryForObject(
                DASHBOARD_MONTH_SUM,
                Integer.class,
                dto.getYear(),
                dto.getMonth()
            );

            CashChargeDTO result = new CashChargeDTO();
            result.setCashAmount(total == null ? 0 : total);
            return result;
        }

        return null;
    }

    // =========================================================
    // INSERT
    public boolean insert(CashChargeDTO dto) {

        int result = jdbcTemplate.update(
            INSERT,
            dto.getMemberId(),
            dto.getProvider(),
            dto.getAmount(),
            dto.getCashAmount(),
            dto.getStatus(),
            dto.getPartnerOrderId(),
            dto.getApprovedAt() // null 가능
        );

        return result > 0;
    }

    // =========================================================
    // UPDATE
    public boolean update(CashChargeDTO dto) {

        if ("CHARGE_UPDATE_STATUS".equals(dto.getCondition())) {
            int result = jdbcTemplate.update(
                UPDATE_STATUS_APPROVED_AT,
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

        return jdbcTemplate.update(DELETE_BY_ID, dto.getChargeId()) > 0;
    }
}
