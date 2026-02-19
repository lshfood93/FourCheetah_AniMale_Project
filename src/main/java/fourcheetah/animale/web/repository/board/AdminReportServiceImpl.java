package fourcheetah.animale.web.dto.board;

import java.time.LocalDateTime;


/**
 * 게시글 신고 DTO
 */
public class BoardReportDTO {
    
    // 조회 조건
    private String condition;
    
    // 신고 정보
    private int boardReportId;          // 신고 ID
    private int boardId;                // 게시글 ID
    private int reporterId;             // 신고자 ID
    private String reasonCode;          // 신고 사유 코드
    private String reasonDetail;        // 신고 사유 상세
    private String status;              // 상태 (PENDING/APPROVED/REJECTED)
    private LocalDateTime createdAt;           // 신고 일시
    private String handledAt;           // 처리 일시
    private int handledBy;              // 처리자 ID
    
    // 게시글 정보 (조인)
    private String boardTitle;          // 게시글 제목
    private String boardContent;        // 게시글 내용
    private String boardCategory;       // 게시글 카테고리
    private int boardWriterId;          // 게시글 작성자 ID
    private String boardWriterNickname; // 게시글 작성자 닉네임
    
    // 집계용
    private int reportCount;            // 신고 횟수
    
    // 페이징
    private int page;
    private int pageSize;
    
    // 정렬
    private String sortBy;
    private String sortOrder;
    
    // =========================================================
    // 생성자
    // =========================================================
    
    public BoardReportDTO() {
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
    
    public int getBoardReportId() {
        return boardReportId;
    }
    
    public void setBoardReportId(int boardReportId) {
        this.boardReportId = boardReportId;
    }
    
    public int getBoardId() {
        return boardId;
    }
    
    public void setBoardId(int boardId) {
        this.boardId = boardId;
    }
    
    public int getReporterId() {
        return reporterId;
    }
    
    public void setReporterId(int reporterId) {
        this.reporterId = reporterId;
    }
    
    public String getReasonCode() {
        return reasonCode;
    }
    
    public void setReasonCode(String reasonCode) {
        this.reasonCode = reasonCode;
    }
    
    public String getReasonDetail() {
        return reasonDetail;
    }
    
    public void setReasonDetail(String reasonDetail) {
        this.reasonDetail = reasonDetail;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public String getHandledAt() {
        return handledAt;
    }
    
    public void setHandledAt(String handledAt) {
        this.handledAt = handledAt;
    }
    
    public int getHandledBy() {
        return handledBy;
    }
    
    public void setHandledBy(int handledBy) {
        this.handledBy = handledBy;
    }
    
    public String getBoardTitle() {
        return boardTitle;
    }
    
    public void setBoardTitle(String boardTitle) {
        this.boardTitle = boardTitle;
    }
    
    public String getBoardContent() {
        return boardContent;
    }
    
    public void setBoardContent(String boardContent) {
        this.boardContent = boardContent;
    }
    
    public String getBoardCategory() {
        return boardCategory;
    }
    
    public void setBoardCategory(String boardCategory) {
        this.boardCategory = boardCategory;
    }
    
    public int getBoardWriterId() {
        return boardWriterId;
    }
    
    public void setBoardWriterId(int boardWriterId) {
        this.boardWriterId = boardWriterId;
    }
    
    public String getBoardWriterNickname() {
        return boardWriterNickname;
    }
    
    public void setBoardWriterNickname(String boardWriterNickname) {
        this.boardWriterNickname = boardWriterNickname;
    }
    
    public int getReportCount() {
        return reportCount;
    }
    
    public void setReportCount(int reportCount) {
        this.reportCount = reportCount;
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
        return "BoardReportDTO{" +
                "boardId=" + boardId +
                ", boardTitle='" + boardTitle + '\'' +
                ", reportCount=" + reportCount +
                ", status='" + status + '\'' +
                '}';
    }
}