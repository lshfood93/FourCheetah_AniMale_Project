package fourcheetah.animale.web.service.admin;

import java.util.List;
import java.util.Map;

import fourcheetah.animale.web.dto.admin.CashChargeDTO;

public interface CashChargeService {

	
	boolean insert(CashChargeDTO dto);
	
    boolean update(CashChargeDTO dto);

    boolean delete(CashChargeDTO dto);

    CashChargeDTO selectOne(CashChargeDTO dto);

    List<CashChargeDTO> selectAll(CashChargeDTO dto);

    // 대시보드용(집계)
    Map<String, Object> getDashboardSummary(int year, int month);
}
