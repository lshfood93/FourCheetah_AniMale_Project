package fourcheetah.animale.web.dto.board;

public class ReplyDTO {
	private int replyId;
	private int boardId;
	private int memberId;
	private String replyContent;
<<<<<<< HEAD
=======
	private String replyCreatedAt;  // 작성일시
	private String replyUpdatedAt;  // 수정일시
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
	
	// condition / join / view
	private String condition;
	private String writerNickname; // JOIN MEMBER + 탈퇴회원 
<<<<<<< HEAD
=======
	private String writerProfileImage; // 작성자 표시용 (JOIN으로 채움)
	private String writerProfileColor;
	private String writerNicknameColor;
	
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
	public int getReplyId() {
		return replyId;
	}
	public void setReplyId(int replyId) {
		this.replyId = replyId;
	}
	public int getBoardId() {
		return boardId;
	}
	public void setBoardId(int boardId) {
		this.boardId = boardId;
	}
	public int getMemberId() {		
		return memberId;
	}
	public void setMemberId(int memberId) {
		this.memberId = memberId;
	}
	public String getReplyContent() {
		return replyContent;
	}
	public void setReplyContent(String replyContent) {
		this.replyContent = replyContent;
	}
<<<<<<< HEAD
=======
	public String getReplyCreatedAt() {
		return replyCreatedAt;
	}
	public void setReplyCreatedAt(String replyCreatedAt) {
		this.replyCreatedAt = replyCreatedAt;
	}
	public String getReplyUpdatedAt() {
		return replyUpdatedAt;
	}
	public void setReplyUpdatedAt(String replyUpdatedAt) {
		this.replyUpdatedAt = replyUpdatedAt;
	}
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
	public String getCondition() {
		return condition;
	}
	public void setCondition(String condition) {
		this.condition = condition;
	}
	public String getWriterNickname() {
		return writerNickname;
	}
	public void setWriterNickname(String writerNickname) {
		this.writerNickname = writerNickname;
	}
<<<<<<< HEAD
	@Override
	public String toString() {
		return "ReplyDTO [replyId=" + replyId + ", boardId=" + boardId + ", memberId=" + memberId + ", replyContent="
				+ replyContent + ", condition=" + condition + ", writerNickname=" + writerNickname + "]";
	}
}
=======
	
	public String getWriterProfileImage() {
		return writerProfileImage;
	}
	public void setWriterProfileImage(String writerProfileImage) {
		this.writerProfileImage = writerProfileImage;
	}
	public String getWriterProfileColor() {
		return writerProfileColor;
	}
	public void setWriterProfileColor(String writerProfileColor) {
		this.writerProfileColor = writerProfileColor;
	}
	public String getWriterNicknameColor() {
		return writerNicknameColor;
	}
	public void setWriterNicknameColor(String writerNicknameColor) {
		this.writerNicknameColor = writerNicknameColor;
	}
	@Override
	public String toString() {
		return "ReplyDTO [replyId=" + replyId + ", boardId=" + boardId + ", memberId=" + memberId + ", replyContent="
				+ replyContent + ", replyCreatedAt=" + replyCreatedAt + ", replyUpdatedAt=" + replyUpdatedAt
				+ ", condition=" + condition + ", writerNickname=" + writerNickname + ", writerProfileImage="
				+ writerProfileImage + ", writerProfileColor=" + writerProfileColor + ", writerNicknameColor="
				+ writerNicknameColor + "]";
	}
}
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
