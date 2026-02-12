package fourcheetah.animale.web.dto.member;

import java.time.LocalDateTime;

public class MemberWarningDTO {
    
    private int warningId;
    private int memberId;
    private int issuedBy;
    private Integer sourceReportId;
    private String warningType;      // WARNING, SUSPEND_7D, SUSPEND_30D, BAN
    private String reason;
    private LocalDateTime startAt;
    private LocalDateTime endAt;
    private LocalDateTime createdAt;
    
    // Getter/Setter
    public int getWarningId() { return warningId; }
    public void setWarningId(int warningId) { this.warningId = warningId; }
    
    public int getMemberId() { return memberId; }
    public void setMemberId(int memberId) { this.memberId = memberId; }
    
    public int getIssuedBy() { return issuedBy; }
    public void setIssuedBy(int issuedBy) { this.issuedBy = issuedBy; }
    
    public Integer getSourceReportId() { return sourceReportId; }
    public void setSourceReportId(Integer sourceReportId) { this.sourceReportId = sourceReportId; }
    
    public String getWarningType() { return warningType; }
    public void setWarningType(String warningType) { this.warningType = warningType; }
    
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    
    public LocalDateTime getStartAt() { return startAt; }
    public void setStartAt(LocalDateTime startAt) { this.startAt = startAt; }
    
    public LocalDateTime getEndAt() { return endAt; }
    public void setEndAt(LocalDateTime endAt) { this.endAt = endAt; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}