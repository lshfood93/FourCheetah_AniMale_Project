package fourcheetah.animale.web.service.admin;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.admin.CashChargeDTO;
import fourcheetah.animale.web.repository.admin.CashChargeDAO;

@Service
public class CashChargeServiceImpl implements CashChargeService {

	@Autowired
    private CashChargeDAO cashChargeDAO;

	@Override
	public boolean insert(CashChargeDTO dto) {
	    return cashChargeDAO.insert(dto);
	}

    @Override
    public boolean update(CashChargeDTO dto) {
        return cashChargeDAO.update(dto);
    }

    @Override
    public boolean delete(CashChargeDTO dto) {
        return cashChargeDAO.delete(dto);
    }

    @Override
    public CashChargeDTO selectOne(CashChargeDTO dto) {
        return cashChargeDAO.selectOne(dto);
    }

    @Override
    public List<CashChargeDTO> selectAll(CashChargeDTO dto) {
        return cashChargeDAO.selectAll(dto);
    }

    // =========================================================
    // 대시보드 집계: JSP에 바로 쓸 수 있는 map 형태로 반환
    @Override
    public Map<String, Object> getDashboardSummary(int year, int month) {

        Map<String, Object> result = new HashMap<>();

        // 이번달 합계
        CashChargeDTO thisMonthReq = new CashChargeDTO();
        thisMonthReq.setCondition("DASHBOARD_MONTH_SUM");
        thisMonthReq.setYear(year);
        thisMonthReq.setMonth(month);

        int thisMonthTotal = cashChargeDAO.selectOne(thisMonthReq).getCashAmount();

        // 전월 합계
        int prevMonth = (month == 1) ? 12 : month - 1;
        int prevYear = (month == 1) ? year - 1 : year;

        CashChargeDTO lastMonthReq = new CashChargeDTO();
        lastMonthReq.setCondition("DASHBOARD_MONTH_SUM");
        lastMonthReq.setYear(prevYear);
        lastMonthReq.setMonth(prevMonth);

        int lastMonthTotal = cashChargeDAO.selectOne(lastMonthReq).getCashAmount();

        // 증감률 계산
        double momPercent = 0;
        if (lastMonthTotal != 0) {
            momPercent = ((double)(thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
        }

        // 수단별 비중
        CashChargeDTO providerReq = new CashChargeDTO();
        providerReq.setCondition("DASHBOARD_THIS_MONTH_BY_PROVIDER");
        providerReq.setYear(year);
        providerReq.setMonth(month);

        List<CashChargeDTO> providerList = cashChargeDAO.selectAll(providerReq);

        // 연간 월별
        CashChargeDTO yearReq = new CashChargeDTO();
        yearReq.setCondition("DASHBOARD_YEAR_MONTHLY_SUM");
        yearReq.setYear(year);

        List<CashChargeDTO> yearMonthly = cashChargeDAO.selectAll(yearReq);

        result.put("thisMonthTotal", thisMonthTotal);
        result.put("lastMonthTotal", lastMonthTotal);
        result.put("momPercent", momPercent);
        result.put("providerList", providerList);   // provider+cashAmount(total)
        result.put("yearMonthly", yearMonthly);     // month+cashAmount(total)

        return result;
    }
}
