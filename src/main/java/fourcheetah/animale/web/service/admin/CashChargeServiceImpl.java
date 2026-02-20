package fourcheetah.animale.web.service.admin;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import fourcheetah.animale.web.controller.member.TossPaymentsClient;
import fourcheetah.animale.web.dto.admin.CashChargeDTO;
import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.admin.CashChargeDAO;
import fourcheetah.animale.web.service.member.MemberService;

@Service
public class CashChargeServiceImpl implements CashChargeService {

	@Autowired
    private CashChargeDAO cashChargeDAO;
	
	@Autowired
	private MemberService memberService; // [ADD] MEMBER 캐시 증가 호출용

	//[ADD]
    @Autowired 
    private TossPaymentsClient tossPaymentsClient;
	
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

    // [ADD] 승인 트랜잭션 처리
    @Override
    @Transactional
    public boolean approveChargeTx(int memberId, String partnerOrderId, int approvedTotal, LocalDateTime approvedAt) {

        // 0) 파라미터 방어
        if (memberId <= 0 || partnerOrderId == null || partnerOrderId.isBlank()) return false;
        if (approvedTotal <= 0) return false;

        // 1) CASH_CHARGE 조회(READY row 확인)
        CashChargeDTO sel = new CashChargeDTO();
        sel.setCondition("CHARGE_SELECT_BY_ORDER_ID");
        sel.setPartnerOrderId(partnerOrderId);

        CashChargeDTO charge = cashChargeDAO.selectOne(sel);

        if (charge == null) return false;

        // 2) 상태/소유자/금액 검증 (위변조 & 중복승인 방지)
        if (!"READY".equalsIgnoreCase(charge.getStatus())) {
            // 이미 APPROVED/CANCEL/FAIL 이면 승인 처리하면 안 됨
            return false;
        }
        if (charge.getMemberId() != memberId) {
            // 다른 사람 주문번호로 승인 시도 방지
            return false;
        }
        if (charge.getCashAmount() != approvedTotal) {
            // 승인금액 위변조 방지(READY 때 저장된 cash_amount와 비교)
            return false;
        }

        // 3) CASH_CHARGE: READY -> APPROVED
        CashChargeDTO upd = new CashChargeDTO();
        upd.setCondition("CHARGE_APPROVE_READY_BY_ORDER");
        upd.setPartnerOrderId(partnerOrderId);
        upd.setMemberId(memberId);                 // 추가
        upd.setProvider(charge.getProvider());     //  추가(가장 안전)
        upd.setApprovedAt(approvedAt == null ? LocalDateTime.now() : approvedAt);

        boolean chargeOk = cashChargeDAO.update(upd);
        if (!chargeOk) {
            // READY가 아니거나(동시 처리), 주문번호가 없거나
            return false;
        }

        // 4) MEMBER 캐시 증가
        MemberDTO mUpd = new MemberDTO();
        mUpd.setCondition("MEMBER_CASH_PLUS");
        mUpd.setMemberId(memberId);
        mUpd.setMemberPayCash(approvedTotal);

        boolean memberOk = memberService.update(mUpd);
        if (!memberOk) {
            //  롤백을 위해 RuntimeException 발생
            throw new IllegalStateException("MEMBER 캐시 증가 실패");
        }

        return true;
    }

    // =========================================================
    // [ADD] 토스 승인 트랜잭션
    @Override
    @Transactional
    public boolean approveTossTx(int memberId, String orderId, String paymentKey, int amountFromQuery) {

        // 1) DB에서 orderId로 READY row 조회
        CashChargeDTO sel = new CashChargeDTO();
        sel.setCondition("CHARGE_SELECT_BY_ORDER_ID");
        sel.setPartnerOrderId(orderId);

        CashChargeDTO charge = cashChargeDAO.selectOne(sel);
        if (charge == null) return false;

        // 2) 기본 검증(회원/상태/금액)
        if (charge.getMemberId() != memberId) return false;
        if (!"READY".equalsIgnoreCase(charge.getStatus())) return false;

        int expected = charge.getCashAmount(); // 너 구조상 cash_amount 기준이 깔끔
        if (expected <= 0) return false;

        // (추가 안전) 쿼리로 온 amount와 DB가 다르면 중단
        if (amountFromQuery != expected) return false;

        // 3) TossPayments confirm 호출 (여기서 "진짜 승인"이 일어남) :contentReference[oaicite:4]{index=4}
        String json = tossPaymentsClient.confirm(paymentKey, orderId, expected);
        JsonObject pay = JsonParser.parseString(json).getAsJsonObject();

        // 4) 응답 검증(필수값/상태/금액/주문번호)
        String status = pay.has("status") && !pay.get("status").isJsonNull()
                ? pay.get("status").getAsString()
                : null;

        String respOrderId = pay.has("orderId") && !pay.get("orderId").isJsonNull()
                ? pay.get("orderId").getAsString()
                : null;

        int respAmount = pay.has("totalAmount") && !pay.get("totalAmount").isJsonNull()
                ? pay.get("totalAmount").getAsInt()
                : -1;

        if (status == null || !"DONE".equalsIgnoreCase(status)) {
            // 승인 완료가 아니면 FAIL 처리(선택)
            CashChargeDTO fail = new CashChargeDTO();
            fail.setCondition("CHARGE_FAIL_READY_BY_ORDER");
            fail.setPartnerOrderId(orderId);
            cashChargeDAO.update(fail);

            return false;
        }

        if (!orderId.equals(respOrderId)) return false;
        if (respAmount != expected) return false;

        // 5) approvedAt 파싱
        LocalDateTime approvedAt = LocalDateTime.now();
        if (pay.has("approvedAt") && !pay.get("approvedAt").isJsonNull()) {
            try {
                approvedAt = OffsetDateTime.parse(pay.get("approvedAt").getAsString()).toLocalDateTime();
            } catch (Exception ignore) {}
        }

        // 6) CASH_CHARGE: READY -> APPROVED (READY 조건 때문에 중복 처리 방지)
        CashChargeDTO updCharge = new CashChargeDTO();
        updCharge.setCondition("CHARGE_APPROVE_READY_BY_ORDER");
        updCharge.setPartnerOrderId(orderId);
        updCharge.setMemberId(memberId);               //  추가
        updCharge.setProvider(charge.getProvider());   //  "TOSSPAY" 직접 쓰지 말고 DB값 사용 추천
        updCharge.setApprovedAt(approvedAt);

        boolean chargeOk = cashChargeDAO.update(updCharge);
        if (!chargeOk) return false; // 이미 처리된 경우 등

        // 7) MEMBER 캐시 증가
        MemberDTO updMember = new MemberDTO();
        updMember.setCondition("MEMBER_CASH_PLUS");
        updMember.setMemberId(memberId);
        updMember.setMemberPayCash(expected);

        boolean memberOk = memberService.update(updMember);
        if (!memberOk) throw new IllegalStateException("MEMBER 캐시 증가 실패");

        return true;
    }
    
    @Override
    @Transactional
    public boolean cancelReadyTx(int memberId, String orderId, String provider) {
        if (memberId <= 0 || orderId == null || orderId.isBlank()) return false;

        CashChargeDTO sel = new CashChargeDTO();
        sel.setCondition("CHARGE_SELECT_BY_ORDER_ID");
        sel.setPartnerOrderId(orderId);

        CashChargeDTO charge = cashChargeDAO.selectOne(sel);
        if (charge == null) return false;

        if (charge.getMemberId() != memberId) return false;
        if (!"READY".equalsIgnoreCase(charge.getStatus())) return false;
        if (provider != null && !provider.equalsIgnoreCase(charge.getProvider())) return false;

        CashChargeDTO upd = new CashChargeDTO();
        upd.setCondition("CHARGE_CANCEL_READY_BY_ORDER");
        upd.setPartnerOrderId(orderId);

        return cashChargeDAO.update(upd);
    }

    @Override
    @Transactional
    public boolean failReadyTx(int memberId, String orderId, String provider) {
        if (memberId <= 0 || orderId == null || orderId.isBlank()) return false;

        CashChargeDTO sel = new CashChargeDTO();
        sel.setCondition("CHARGE_SELECT_BY_ORDER_ID");
        sel.setPartnerOrderId(orderId);

        CashChargeDTO charge = cashChargeDAO.selectOne(sel);
        if (charge == null) return false;

        if (charge.getMemberId() != memberId) return false;
        if (!"READY".equalsIgnoreCase(charge.getStatus())) return false;
        if (provider != null && !provider.equalsIgnoreCase(charge.getProvider())) return false;

        CashChargeDTO upd = new CashChargeDTO();
        upd.setCondition("CHARGE_FAIL_READY_BY_ORDER");
        upd.setPartnerOrderId(orderId);

        return cashChargeDAO.update(upd);
    }

}
