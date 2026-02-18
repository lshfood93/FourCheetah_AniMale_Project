package fourcheetah.animale.web.dto.member;

import java.time.LocalDateTime;

public class MemberDTO {
    // =========================
    // DB Columns (MEMBER table)
    // =========================
    private int memberId;                 // member_id (PK)
    private String memberName;            // member_name
    private String memberPassword;        // member_password
    private String memberNickname;        // member_nickname
    private int memberCash;               // member_cash
    private String memberRole;            // member_role : ACTIVE / WITHDRAWN / ADMIN
    private String memberProfileImage;    // member_profile_image (LONGTEXT) - URL or Base64 etc.
    private String memberEmail;           // member_email

    private int validReportCount;         // valid_report_count
    private LocalDateTime lastWarningAt;  // last_warning_at
    private String noticePending;         // notice_pending : 'Y'/'N'
    private String noticeMessage;         // notice_message

    private String memberProfileColor;    // member_profile_color
    private String memberNicknameColor;   // member_nickname_color

    // =========================
    // Non-DB fields (for logic)
    // =========================
    private int memberPayCash;            // 결제/차감 요청 금액 등 (DB 컬럼 아님)
    private String condition;             // 쿼리 분기/검색 조건 등 (DB 컬럼 아님)

    // ===== getters / setters =====
    public int getMemberId() { return memberId; }
    public void setMemberId(int memberId) { this.memberId = memberId; }

    public String getMemberName() { return memberName; }
    public void setMemberName(String memberName) { this.memberName = memberName; }

    public String getMemberPassword() { return memberPassword; }
    public void setMemberPassword(String memberPassword) { this.memberPassword = memberPassword; }

    public String getMemberNickname() { return memberNickname; }
    public void setMemberNickname(String memberNickname) { this.memberNickname = memberNickname; }

    public int getMemberCash() { return memberCash; }
    public void setMemberCash(int memberCash) { this.memberCash = memberCash; }

    public int getMemberPayCash() { return memberPayCash; }
    public void setMemberPayCash(int memberPayCash) { this.memberPayCash = memberPayCash; }

    public String getMemberRole() { return memberRole; }
    public void setMemberRole(String memberRole) { this.memberRole = memberRole; }

    public String getMemberProfileImage() { return memberProfileImage; }
    public void setMemberProfileImage(String memberProfileImage) { this.memberProfileImage = memberProfileImage; }

    public String getMemberEmail() { return memberEmail; }
    public void setMemberEmail(String memberEmail) { this.memberEmail = memberEmail; }

    public int getValidReportCount() { return validReportCount; }
    public void setValidReportCount(int validReportCount) { this.validReportCount = validReportCount; }

    public LocalDateTime getLastWarningAt() { return lastWarningAt; }
    public void setLastWarningAt(LocalDateTime lastWarningAt) { this.lastWarningAt = lastWarningAt; }

    public String getNoticePending() { return noticePending; }
    public void setNoticePending(String noticePending) { this.noticePending = noticePending; }

    public String getNoticeMessage() { return noticeMessage; }
    public void setNoticeMessage(String noticeMessage) { this.noticeMessage = noticeMessage; }

    public String getMemberProfileColor() { return memberProfileColor; }
    public void setMemberProfileColor(String memberProfileColor) { this.memberProfileColor = memberProfileColor; }

    public String getMemberNicknameColor() { return memberNicknameColor; }
    public void setMemberNicknameColor(String memberNicknameColor) { this.memberNicknameColor = memberNicknameColor; }

    public String getCondition() { return condition; }
    public void setCondition(String condition) { this.condition = condition; }

    @Override
    public String toString() {
        return "MemberDTO [memberId=" + memberId
                + ", memberName=" + memberName
                + ", memberPassword=" + memberPassword
                + ", memberNickname=" + memberNickname
                + ", memberCash=" + memberCash
                + ", memberPayCash=" + memberPayCash
                + ", memberRole=" + memberRole
                + ", memberProfileImage=" + memberProfileImage
                + ", memberEmail=" + memberEmail
                + ", validReportCount=" + validReportCount
                + ", lastWarningAt=" + lastWarningAt
                + ", noticePending=" + noticePending
                + ", noticeMessage=" + noticeMessage
                + ", memberProfileColor=" + memberProfileColor
                + ", memberNicknameColor=" + memberNicknameColor
                + ", condition=" + condition
                + "]";
    }
<<<<<<< HEAD
=======
	public Object getSanctionReason() {
		// TODO Auto-generated method stub
		return null;
	}
	public Object getSanctionEndAt() {
		// TODO Auto-generated method stub
		return null;
	}
	public String getMemberStatus() {
		// TODO Auto-generated method stub
		return null;
	}
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
}