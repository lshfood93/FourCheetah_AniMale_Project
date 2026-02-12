package fourcheetah.animale.web.dto.admin;

import java.time.LocalDateTime;

public class CashChargeDTO {

    // =========================
    // 기본 컬럼 (CASH_CHARGE)
    // =========================
    private int chargeId;        // PK, AI
    private int memberId;        // FK
    private String provider;         // ENUM('KAKAOPAY','TOSSPAY')
    private int amount;          // 결제 금액
    private int cashAmount;      // 충전 캐시(비율 적용 결과)

    private String status;           // ENUM('READY','APPROVED','CANCEL','FAIL')
    private String partnerOrderId;   // UNIQUE

    private LocalDateTime approvedAt; // 승인시간(결제기준)
    private LocalDateTime createdAt;  // 생성일

    // =========================
    // condition 기반 DAO 스타일용
    // =========================
    private String condition;  // "CHARGE_INSERT", "DASHBOARD_THIS_MONTH" ... 등
    private int year;      // 대시보드 조회용
    private int month;     // 대시보드 조회용
	public int getChargeId() {
		return chargeId;
	}
	public void setChargeId(int chargeId) {
		this.chargeId = chargeId;
	}
	public int getMemberId() {
		return memberId;
	}
	public void setMemberId(int memberId) {
		this.memberId = memberId;
	}
	public String getProvider() {
		return provider;
	}
	public void setProvider(String provider) {
		this.provider = provider;
	}
	public int getAmount() {
		return amount;
	}
	public void setAmount(int amount) {
		this.amount = amount;
	}
	public int getCashAmount() {
		return cashAmount;
	}
	public void setCashAmount(int cashAmount) {
		this.cashAmount = cashAmount;
	}
	public String getStatus() {
		return status;
	}
	public void setStatus(String status) {
		this.status = status;
	}
	public String getPartnerOrderId() {
		return partnerOrderId;
	}
	public void setPartnerOrderId(String partnerOrderId) {
		this.partnerOrderId = partnerOrderId;
	}
	public LocalDateTime getApprovedAt() {
		return approvedAt;
	}
	public void setApprovedAt(LocalDateTime approvedAt) {
		this.approvedAt = approvedAt;
	}
	public LocalDateTime getCreatedAt() {
		return createdAt;
	}
	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}
	public String getCondition() {
		return condition;
	}
	public void setCondition(String condition) {
		this.condition = condition;
	}
	public int getYear() {
		return year;
	}
	public void setYear(int year) {
		this.year = year;
	}
	public int getMonth() {
		return month;
	}
	public void setMonth(int month) {
		this.month = month;
	}
	@Override
	public String toString() {
		return "CashChargeDTO [chargeId=" + chargeId + ", memberId=" + memberId + ", provider=" + provider + ", amount="
				+ amount + ", cashAmount=" + cashAmount + ", status=" + status + ", partnerOrderId=" + partnerOrderId
				+ ", approvedAt=" + approvedAt + ", createdAt=" + createdAt + ", condition=" + condition + ", year="
				+ year + ", month=" + month + "]";
	}
}