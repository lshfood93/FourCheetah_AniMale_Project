package fourcheetah.animale.web.dto.board;

public class ReplyDTO {
	private int replyId;
	private int boardId;
	private int memberId;
	private String replyContent;
	private String replyCreatedAt; // 작성일시
	private String replyUpdatedAt; // 수정일시

	// condition / join / view
	private String condition;
	private String writerNickname; // JOIN MEMBER + 탈퇴회원
	private String writerProfileImage; // JOIN MEMBER 프로필 이미지 추가!
	private int isEdited; // 댓글 수정 여부(0,1 IS_EDITED)

	private String writerProfileColor;
	private String writerNicknameColor;

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

	public int getIsEdited() {
		return isEdited;
	}

	public void setIsEdited(int isEdited) {
		this.isEdited = isEdited;

	}

	@Override
	public String toString() {
		return "ReplyDTO [replyId=" + replyId + ", boardId=" + boardId + ", memberId=" + memberId + ", replyContent="
				+ replyContent + ", replyCreatedAt=" + replyCreatedAt + ", replyUpdatedAt=" + replyUpdatedAt
				+ ", condition=" + condition + ", writerNickname=" + writerNickname + ", writerProfileImage="
				+ writerProfileImage + ", writerProfileColor=" + writerProfileColor + ", writerNicknameColor="
				+ writerNicknameColor + ", condition=" + condition + ", writerNickname=" + writerNickname
				+ ", writerProfileImage=" + writerProfileImage + ", isEdited=" + isEdited + "]";
	}
}