package fourcheetah.animale.web.dto.board;

public class BoardLikeDTO {
	
	private int boardLikeId;
	private int boardId;
	private int memberId;
<<<<<<< HEAD
=======
	private String createdAt;  // 작성일시
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
	
	// condition / view
	private String condition;
	private int likeCnt; // 좋아요 개수(LIKE_CNT)
	private int isLiked; // 내가 눌렀는지(0/1, IS_LIKED)
<<<<<<< HEAD
=======
	
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
	public int getBoardLikeId() {
		return boardLikeId;
	}
	public void setBoardLikeId(int boardLikeId) {
		this.boardLikeId = boardLikeId;
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
<<<<<<< HEAD
=======
	public String getCreatedAt() {
		return createdAt;
	}
	public void setCreatedAt(String createdAt) {
		this.createdAt = createdAt;
	}
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
	public String getCondition() {
		return condition;
	}
	public void setCondition(String condition) {
		this.condition = condition;
	}
	public int getLikeCnt() {
		return likeCnt;
	}
	public void setLikeCnt(int likeCnt) {
		this.likeCnt = likeCnt;
	}
	public int getIsLiked() {
		return isLiked;
	}
	public void setIsLiked(int isLiked) {
		this.isLiked = isLiked;
	}
	@Override
	public String toString() {
		return "BoardLikeDTO [boardLikeId=" + boardLikeId + ", boardId=" + boardId + ", memberId=" + memberId
<<<<<<< HEAD
				+ ", condition=" + condition + ", likeCnt=" + likeCnt + ", isLiked=" + isLiked + "]";
	}
}
=======
				+ ", createdAt=" + createdAt + ", condition=" + condition + ", likeCnt=" + likeCnt + ", isLiked=" + isLiked + "]";
	}
}
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
