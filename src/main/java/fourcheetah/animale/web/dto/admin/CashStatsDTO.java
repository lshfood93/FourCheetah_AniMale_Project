package fourcheetah.animale.web.dto.admin;

/**
 * 캐시 충전 통계 DTO
 */
public class CashStatsDTO {
    
    // 조회 조건
    private String condition;
    
    // 조회 파라미터
    private int year;
    private int month;
    
    // 월별 통계
    private int totalAmount;        // 총 충전액
    private int chargeCount;        // 충전 건수
    private int avgAmount;          // 평균 충전액
    private int uniqueUsers;        // 충전 회원 수
    
    // 증감률 계산용
    private int lastMonthAmount;    // 전월 충전액
    private double growthRate;      // 증감률 (%)
    
    // 결제 수단별
    private int kakaopayAmount;     // 카카오페이 충전액
    private int tosspayAmount;      // 토스페이 충전액
    private double kakaopayRate;    // 카카오페이 비율 (%)
    private double tosspayRate;     // 토스페이 비율 (%)
    
    // 페이징
    private int page;
    private int pageSize;
    
    // 정렬
    private String sortBy;
    private String sortOrder;
    
    // =========================================================
    // 생성자
    // =========================================================
    
    public CashStatsDTO() {
    }
    
    // =========================================================
    // Getter & Setter
    // =========================================================
    
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
    
    public int getAvgAmount() {
        return avgAmount;
    }
    
    public void setAvgAmount(int avgAmount) {
        this.avgAmount = avgAmount;
    }
    
    public int getUniqueUsers() {
        return uniqueUsers;
    }
    
    public void setUniqueUsers(int uniqueUsers) {
        this.uniqueUsers = uniqueUsers;
    }
    
    public int getLastMonthAmount() {
        return lastMonthAmount;
    }
    
    public void setLastMonthAmount(int lastMonthAmount) {
        this.lastMonthAmount = lastMonthAmount;
    }
    
    public double getGrowthRate() {
        return growthRate;
    }
    
    public void setGrowthRate(double growthRate) {
        this.growthRate = growthRate;
    }
    
    public int getKakaopayAmount() {
        return kakaopayAmount;
    }
    
    public void setKakaopayAmount(int kakaopayAmount) {
        this.kakaopayAmount = kakaopayAmount;
    }
    
    public int getTosspayAmount() {
        return tosspayAmount;
    }
    
    public void setTosspayAmount(int tosspayAmount) {
        this.tosspayAmount = tosspayAmount;
    }
    
    public double getKakaopayRate() {
        return kakaopayRate;
    }
    
    public void setKakaopayRate(double kakaopayRate) {
        this.kakaopayRate = kakaopayRate;
    }
    
    public double getTosspayRate() {
        return tosspayRate;
    }
    
    public void setTosspayRate(double tosspayRate) {
        this.tosspayRate = tosspayRate;
    }
    
    public int getPage() {
        return page;
    }
    
    public void setPage(int page) {
        this.page = page;
    }
    
    public int getPageSize() {
        return pageSize;
    }
    
    public void setPageSize(int pageSize) {
        this.pageSize = pageSize;
    }
    
    public String getSortBy() {
        return sortBy;
    }
    
    public void setSortBy(String sortBy) {
        this.sortBy = sortBy;
    }
    
    public String getSortOrder() {
        return sortOrder;
    }
    
    public void setSortOrder(String sortOrder) {
        this.sortOrder = sortOrder;
    }
    
    @Override
    public String toString() {
        return "CashStatsDTO{" +
                "year=" + year +
                ", month=" + month +
                ", totalAmount=" + totalAmount +
                ", chargeCount=" + chargeCount +
                ", uniqueUsers=" + uniqueUsers +
                '}';
    }
}