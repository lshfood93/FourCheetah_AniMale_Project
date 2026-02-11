package fourcheetah.animale.web.dto.admin;

import java.time.LocalDateTime;

/**
 * 캐시 충전 기록 DTO
 */
public class CashChargeDTO {


	private String condition;
	// 기본 정보
	private int chargeId;           	// 충전 ID
	private int memberId;               // 회원 ID
	private int amount;					// 결제 금액
	private int cashAmount;             // 충전 금액
	private String provider;       		// 결제 수단 (KAKAOPAY/TOSSPAY)
	private String partnerOrderId;      // 주문 번호(UNIQUE)
	private String status;              // 상태 (SUCCESS/FAILED/CANCELLED)
	private LocalDateTime approvedAt; // 승인 시각(집계 기준)
	private LocalDateTime createdAt;  // 생성일

	// 조인 데이터 (회원 정보)
	private String memberName;          // 회원 이름
	private String memberNickname;      // 회원 닉네임
	private String memberEmail;         // 회원 이메일

	// 집계용
	private int totalAmount;            // 총 충전액
	private int chargeCount;            // 충전 건수
	private int ranking;                // 순위



	// =========================
	// [추가] 관리자 캐시 대시보드 집계용 필드
	// =========================

	// 요청 파라미터(조회 조건)
	private int year;             // 드롭다운 연도
	private int month;            // 현재월(혹은 선택월)

	// 결과(월별 집계)
	private int monthNum;         // 1~12
	private Long sumAmount;           // 합계(결제 금액 기준)  ※ amount SUM 결과

	// 결과(수단 비율)
	private Double ratio;             // provider 비율(%)

	// 결과(증감 카드)
	private Long thisMonthTotal;      // 이번달 총액
	private Long lastMonthTotal;      // 전월 총액
	private Long deltaAmount;         // 증감 금액
	private Double deltaPercent;      // 증감률(전월 0이면 null)
	private String deltaLabel;        // "OK" / "NEW" / "SAME"

	// =========================================================
	// 생성자
	// =========================================================


	// =========================================================
	// Getter & Setter
	// =========================================================


	

	public int getChargeId() {
		return chargeId;
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

	public int getMonthNum() {
		return monthNum;
	}

	public void setMonthNum(int monthNum) {
		this.monthNum = monthNum;
	}

	public Long getSumAmount() {
		return sumAmount;
	}

	public void setSumAmount(Long sumAmount) {
		this.sumAmount = sumAmount;
	}

	public Double getRatio() {
		return ratio;
	}

	public void setRatio(Double ratio) {
		this.ratio = ratio;
	}

	public Long getThisMonthTotal() {
		return thisMonthTotal;
	}

	public void setThisMonthTotal(Long thisMonthTotal) {
		this.thisMonthTotal = thisMonthTotal;
	}

	public Long getLastMonthTotal() {
		return lastMonthTotal;
	}

	public void setLastMonthTotal(Long lastMonthTotal) {
		this.lastMonthTotal = lastMonthTotal;
	}

	public Long getDeltaAmount() {
		return deltaAmount;
	}

	public void setDeltaAmount(Long deltaAmount) {
		this.deltaAmount = deltaAmount;
	}

	public Double getDeltaPercent() {
		return deltaPercent;
	}

	public void setDeltaPercent(Double deltaPercent) {
		this.deltaPercent = deltaPercent;
	}

	public String getDeltaLabel() {
		return deltaLabel;
	}

	public void setDeltaLabel(String deltaLabel) {
		this.deltaLabel = deltaLabel;
	}

	public int getAmount() {
		return amount;
	}

	public void setAmount(int amount) {
		this.amount = amount;
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

	public void setChargeId(int chargeId) {
		this.chargeId = chargeId;
	}

	public int getMemberId() {
		return memberId;
	}

	public void setMemberId(int memberId) {
		this.memberId = memberId;
	}

	public int getCashAmount() {
		return cashAmount;
	}

	public void setCashAmount(int cashAmount) {
		this.cashAmount = cashAmount;
	}

	public String getProvider() {
		return provider;
	}

	public void setProvider(String provider) {
		this.provider = provider;
	}



	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public String getMemberName() {
		return memberName;
	}

	public void setMemberName(String memberName) {
		this.memberName = memberName;
	}

	public String getMemberNickname() {
		return memberNickname;
	}

	public void setMemberNickname(String memberNickname) {
		this.memberNickname = memberNickname;
	}

	public String getMemberEmail() {
		return memberEmail;
	}

	public void setMemberEmail(String memberEmail) {
		this.memberEmail = memberEmail;
	}

	public int getTotalAmount() {
		return totalAmount;
	}

	public void setTotalAmount(int totalAmount) {
		this.totalAmount = totalAmount;
	}

	public int getChargeCount() {
		return chargeCount;
	}

	public void setChargeCount(int chargeCount) {
		this.chargeCount = chargeCount;
	}

	public int getRanking() {
		return ranking;
	}

	public void setRanking(int ranking) {
		this.ranking = ranking;
	}

	@Override
	public String toString() {
		return "CashChargeDTO [chargeId=" + chargeId + ", memberId=" + memberId + ", amount=" + amount + ", cashAmount="
				+ cashAmount + ", provider=" + provider + ", partnerOrderId=" + partnerOrderId + ", status=" + status
				+ ", approvedAt=" + approvedAt + ", createdAt=" + createdAt + ", memberName=" + memberName
				+ ", memberNickname=" + memberNickname + ", memberEmail=" + memberEmail + ", totalAmount=" + totalAmount
				+ ", chargeCount=" + chargeCount + ", ranking=" + ranking + ", year=" + year + ", month=" + month
				+ ", monthNum=" + monthNum + ", sumAmount=" + sumAmount + ", ratio=" + ratio + ", thisMonthTotal="
				+ thisMonthTotal + ", lastMonthTotal=" + lastMonthTotal + ", deltaAmount=" + deltaAmount
				+ ", deltaPercent=" + deltaPercent + ", deltaLabel=" + deltaLabel + "]";
	}
}