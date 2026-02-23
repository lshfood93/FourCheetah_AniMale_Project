package fourcheetah.animale.web.service.admin;

import java.time.LocalDateTime;
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
    
    //  결제 승인 트랜잭션 처리(READY -> APPROVED + MEMBER 캐시 증가)
    boolean approveChargeTx(int memberId, String partnerOrderId, int approvedTotal, LocalDateTime approvedAt);
    
 //  
    boolean approveTossTx(int memberId, String orderId, String paymentKey, int amountFromQuery);

	boolean cancelReadyTx(int memberId, String orderId, String provider);

	boolean failReadyTx(int memberId, String orderId, String provider);
    
}
