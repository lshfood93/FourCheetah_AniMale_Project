package fourcheetah.animale.web.service.admin;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.admin.CashChargeDTO;
import fourcheetah.animale.web.repository.admin.CashChargeDAO;

@Service
public class CashChargeServiceImpl implements CashChargeService {

	@Autowired
	private CashChargeDAO adminCashDAO;

	// ===== 고정 5개 =====
	@Override
	public List<CashChargeDTO> selectAll(CashChargeDTO dto) {
		return adminCashDAO.selectAll(dto);
	}

	@Override
	public CashChargeDTO selectOne(CashChargeDTO dto) {
		return adminCashDAO.selectOne(dto);
	}

	@Override
	public boolean insert(CashChargeDTO dto) {
		return false;
	}

	@Override
	public boolean update(CashChargeDTO dto) {
		return false;
	}

	@Override
	public boolean delete(CashChargeDTO dto) {
		return false;
	}

	// =========================
	// 대시보드 전용(컨트롤러 호출용)
	// =========================

	/** API1: 월별 충전 캐시 합계(연 기준) + 연 총합 */
	public Map<String, Object> getMonthlyCashChart(int year) {

		CashChargeDTO req = new CashChargeDTO();
		req.setYear(year);

		req.setCondition("ADMIN_CASH_MONTHLY_SUM");
		List<CashChargeDTO> rows = adminCashDAO.selectAll(req);

		List<Map<String, Object>> totalChargeByMonth = new ArrayList<>();
		for (CashChargeDTO r : rows) {
			totalChargeByMonth.add(Map.of("month", r.getMonthNum(), "amount", r.getSumAmount() // cash_amount SUM
			));
		}

		req.setCondition("ADMIN_CASH_YEAR_TOTAL");
		CashChargeDTO total = adminCashDAO.selectOne(req);
		long yearTotal = (total == null || total.getSumAmount() == null) ? 0L : total.getSumAmount();

		return Map.of("totalChargeByMonth", totalChargeByMonth, "yearTotalChargeAmount", yearTotal);
	}

	/** API2: 결제수단 비율(월 기준) + 전월 대비% */
	public Map<String, Object> getProviderRatio(int year, int month) {

		long thisMonthTotal = getMonthTotal(year, month);

		int lastYear = year;
		int lastMonth = month - 1;
		if (lastMonth == 0) {
			lastMonth = 12;
			lastYear = year - 1;
		}
		long lastMonthTotal = getMonthTotal(lastYear, lastMonth);

		// provider별 합계 조회
		CashChargeDTO req = new CashChargeDTO();
		req.setYear(year);
		req.setMonth(month);
		req.setCondition("ADMIN_CASH_PROVIDER_SUM");
		List<CashChargeDTO> providerRows = adminCashDAO.selectAll(req);

		List<Map<String, Object>> providerRatioList = new ArrayList<>();
		for (CashChargeDTO r : providerRows) {
			long amount = (r.getSumAmount() == null) ? 0L : r.getSumAmount();
			double ratio = (thisMonthTotal == 0L) ? 0.0 : (amount * 100.0 / thisMonthTotal);

			providerRatioList.add(Map.of("provider", r.getProvider(), "amount", amount, "ratio", round1(ratio)));
		}

		Map<String, Object> delta = calcDelta(thisMonthTotal, lastMonthTotal);

		return Map.of("providerRatioList", providerRatioList, "thisMonthTotal", thisMonthTotal, "lastMonthTotal",
				lastMonthTotal, "deltaPercent", delta.get("deltaPercent"), "deltaLabel", delta.get("deltaLabel"));
	}

	/** API3: 월 충전 증감(현재월 vs 전월) */
	public Map<String, Object> getMonthDelta(int year, int month) {

		long thisMonth = getMonthTotal(year, month);

		int lastYear = year;
		int lastMonth = month - 1;
		if (lastMonth == 0) {
			lastMonth = 12;
			lastYear = year - 1;
		}
		long last = getMonthTotal(lastYear, lastMonth);

		Map<String, Object> delta = calcDelta(thisMonth, last);

		return Map.of("thisMonthCharge", thisMonth, "lastMonthCharge", last, "deltaAmount", delta.get("deltaAmount"),
				"deltaPercent", delta.get("deltaPercent"), "deltaLabel", delta.get("deltaLabel"));
	}

	// =========================
	// 내부 유틸
	// =========================

	public int getCurrentYear() {
		return LocalDateTime.now().getYear();
	}

	public int getCurrentMonth() {
		return LocalDateTime.now().getMonthValue();
	}

	private long getMonthTotal(int year, int month) {
		CashChargeDTO req = new CashChargeDTO();
		req.setYear(year);
		req.setMonth(month);
		req.setCondition("ADMIN_CASH_MONTH_TOTAL");

		CashChargeDTO res = adminCashDAO.selectOne(req);
		return (res == null || res.getSumAmount() == null) ? 0L : res.getSumAmount();
	}

	private Map<String, Object> calcDelta(long thisMonth, long lastMonth) {
		long deltaAmount = thisMonth - lastMonth;

		// 핵심: 전월 0이면 '신규'
		if (lastMonth == 0L) {
			return Map.of("deltaAmount", deltaAmount, "deltaPercent", null, "deltaLabel",
					(thisMonth == 0L ? "SAME" : "NEW"));
		}

		double deltaPercent = (deltaAmount * 100.0 / lastMonth);

		return Map.of("deltaAmount", deltaAmount, "deltaPercent", round1(deltaPercent), "deltaLabel", "OK");
	}

	private Double round1(double v) {
		return Math.round(v * 10.0) / 10.0;
	}
}
