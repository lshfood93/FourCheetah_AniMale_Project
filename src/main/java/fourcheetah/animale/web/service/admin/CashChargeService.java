package fourcheetah.animale.web.service.admin;

import java.util.List;

import fourcheetah.animale.web.dto.admin.CashChargeDTO;

public interface CashChargeService {
	
	List<CashChargeDTO> selectAll(CashChargeDTO dto);
    CashChargeDTO selectOne(CashChargeDTO dto);

    boolean insert(CashChargeDTO dto);
    boolean update(CashChargeDTO dto);
    boolean delete(CashChargeDTO dto);

}
