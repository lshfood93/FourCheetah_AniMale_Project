package fourcheetah.animale.web.repository.admin;

import java.util.Collections;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.admin.CashChargeDTO;

@Repository
public class CashChargeDAO {

	@Autowired
	private JdbcTemplate jdbcTemplate;

	/*
	 * ========================= SQL (집계 기준: cash_amount) status='APPROVED' +
	 * approved_at 연/월 기준 =========================
	 */

	// ✅ 핵심: 1~12월 모두 나오도록(없는 달 0)
	private static final String SELECT_CASH_BY_MONTH = "WITH RECURSIVE m AS ( " + "  SELECT 1 AS month_num "
			+ "  UNION ALL SELECT month_num + 1 FROM m WHERE month_num < 12 " + "), agg AS ( "
			+ "  SELECT MONTH(approved_at) AS month_num, SUM(cash_amount) AS sum_amount " + "  FROM cash_charge "
			+ "  WHERE status='APPROVED' " + "    AND approved_at IS NOT NULL " + "    AND YEAR(approved_at)=? "
			+ "  GROUP BY MONTH(approved_at) " + ") "
			+ "SELECT m.month_num AS MONTH_NUM, COALESCE(agg.sum_amount,0) AS SUM_AMOUNT "
			+ "FROM m LEFT JOIN agg ON agg.month_num = m.month_num " + "ORDER BY m.month_num ASC";

	private static final String SELECT_YEAR_TOTAL = "SELECT COALESCE(SUM(cash_amount),0) AS SUM_AMOUNT "
			+ "FROM cash_charge " + "WHERE status='APPROVED' " + "  AND approved_at IS NOT NULL "
			+ "  AND YEAR(approved_at)=?";

	private static final String SELECT_MONTH_TOTAL = "SELECT COALESCE(SUM(cash_amount),0) AS SUM_AMOUNT "
			+ "FROM cash_charge " + "WHERE status='APPROVED' " + "  AND approved_at IS NOT NULL "
			+ "  AND YEAR(approved_at)=? AND MONTH(approved_at)=?";

	private static final String SELECT_PROVIDER_SUM_BY_MONTH = "SELECT provider AS PROVIDER, COALESCE(SUM(cash_amount),0) AS SUM_AMOUNT "
			+ "FROM cash_charge " + "WHERE status='APPROVED' " + "  AND approved_at IS NOT NULL "
			+ "  AND YEAR(approved_at)=? AND MONTH(approved_at)=? " + "GROUP BY provider";

	/*
	 * ========================= RowMapper =========================
	 */

	private static final RowMapper<CashChargeDTO> MONTH_SUM_ROW_MAPPER = (rs, rowNum) -> {
		CashChargeDTO d = new CashChargeDTO();
		d.setMonthNum(rs.getInt("MONTH_NUM"));
		d.setSumAmount(rs.getLong("SUM_AMOUNT"));
		return d;
	};

	private static final RowMapper<CashChargeDTO> PROVIDER_SUM_ROW_MAPPER = (rs, rowNum) -> {
		CashChargeDTO d = new CashChargeDTO();
		d.setProvider(rs.getString("PROVIDER"));
		d.setSumAmount(rs.getLong("SUM_AMOUNT"));
		return d;
	};

	/*
	 * ========================= SELECT_ALL (조건 분기) =========================
	 */
	public List<CashChargeDTO> selectAll(CashChargeDTO dto) {
		if (dto == null)
			return Collections.emptyList();

		String condition = dto.getCondition();

		try {
			if ("ADMIN_CASH_MONTHLY_SUM".equals(condition)) {
				return jdbcTemplate.query(SELECT_CASH_BY_MONTH, MONTH_SUM_ROW_MAPPER, dto.getYear());
			}

			if ("ADMIN_CASH_PROVIDER_SUM".equals(condition)) {
				return jdbcTemplate.query(SELECT_PROVIDER_SUM_BY_MONTH, PROVIDER_SUM_ROW_MAPPER, dto.getYear(),
						dto.getMonth());
			}

			return Collections.emptyList();

		} catch (Exception e) {
			e.printStackTrace();
			return Collections.emptyList();
		}
	}

	/*
	 * ========================= SELECT_ONE (조건 분기) =========================
	 */
	public CashChargeDTO selectOne(CashChargeDTO dto) {
		if (dto == null)
			return null;

		String condition = dto.getCondition();

		try {
			if ("ADMIN_CASH_YEAR_TOTAL".equals(condition)) {
				Long sum = jdbcTemplate.queryForObject(SELECT_YEAR_TOTAL, Long.class, dto.getYear());
				CashChargeDTO res = new CashChargeDTO();
				res.setSumAmount(sum == null ? 0L : sum);
				return res;
			}

			if ("ADMIN_CASH_MONTH_TOTAL".equals(condition)) {
				Long sum = jdbcTemplate.queryForObject(SELECT_MONTH_TOTAL, Long.class, dto.getYear(), dto.getMonth());
				CashChargeDTO res = new CashChargeDTO();
				res.setSumAmount(sum == null ? 0L : sum);
				return res;
			}

			return null;

		} catch (EmptyResultDataAccessException e) {
			return null;
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	/*
	 * ========================= INSERT / UPDATE / DELETE - 관리자 대시보드는 조회 전용이라 false
	 * 처리 =========================
	 */
	public boolean insert(CashChargeDTO dto) {
		return false;
	}

	public boolean update(CashChargeDTO dto) {
		return false;
	}

	public boolean delete(CashChargeDTO dto) {
		return false;
	}
}
