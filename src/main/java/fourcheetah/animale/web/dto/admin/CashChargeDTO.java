package fourcheetah.animale.web.dto.admin;

/**
 * 캐시 충전 기록 DTO
 */
public class CashChargeDTO {
    
    // 기본 정보
    private int cashChargeId;           // 충전 ID
    private int memberId;               // 회원 ID
    private int chargeAmount;           // 충전 금액
    private String paymentMethod;       // 결제 수단 (KAKAOPAY/TOSSPAY)
    private String transactionId;       // 거래 ID
    private String status;              // 상태 (SUCCESS/FAILED/CANCELLED)
    private String chargedAt;           // 충전 일시
    
    // 조인 데이터 (회원 정보)
    private String memberName;          // 회원 이름
    private String memberNickname;      // 회원 닉네임
    private String memberEmail;         // 회원 이메일
    
    // 집계용
    private int totalAmount;            // 총 충전액
    private int chargeCount;            // 충전 건수
    private int ranking;                // 순위
    
    // =========================================================
    // 생성자
    // =========================================================
    
    public CashChargeDTO() {
    }
    
    // =========================================================
    // Getter & Setter
    // =========================================================
    
    public int getCashChargeId() {
        return cashChargeId;
    }
    
    public void setCashChargeId(int cashChargeId) {
        this.cashChargeId = cashChargeId;
    }
    
    public int getMemberId() {
        return memberId;
    }
    
    public void setMemberId(int memberId) {
        this.memberId = memberId;
    }
    
    public int getChargeAmount() {
        return chargeAmount;
    }
    
    public void setChargeAmount(int chargeAmount) {
        this.chargeAmount = chargeAmount;
    }
    
    public String getPaymentMethod() {
        return paymentMethod;
    }
    
    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }
    
    public String getTransactionId() {
        return transactionId;
    }
    
    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getChargedAt() {
        return chargedAt;
    }
    
    public void setChargedAt(String chargedAt) {
        this.chargedAt = chargedAt;
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
        return "CashChargeDTO{" +
                "cashChargeId=" + cashChargeId +
                ", memberId=" + memberId +
                ", chargeAmount=" + chargeAmount +
                ", paymentMethod='" + paymentMethod + '\'' +
                ", status='" + status + '\'' +
                '}';
    }
}