package fourcheetah.animale.web.dto.news;

import org.apache.ibatis.type.Alias;

/**
 * 뉴스 DTO (Spring Boot + MySQL 버전)
 * - 중프 Oracle 코드를 최프 MySQL 스키마에 맞춰 변환
 * - CLOB → LONGTEXT 변환
 * - 필드명은 중프와 동일하게 유지 (호환성)
 */

@Alias("newsDTO")
public class NewsDTO {

    // ========== 기본 필드 (DB 컬럼) ==========
    private int newsId;                    // NEWS_ID (PK, AUTO_INCREMENT)
    private Integer animeId;               // ANIME_ID (FK, NULL 가능)
    private String newsTitle;              // NEWS_TITLE
    private String newsContent;            // NEWS_CONTENT (LONGTEXT)
    private String newsImageUrl;           // NEWS_IMAGE_URL (VARCHAR(2048))
    private String newsThumbnailUrl;       // NEWS_THUMBNAIL_URL (VARCHAR(2048))

    // ========== 페이징 관련 ==========
    private int newsCount;                 // COUNT(*) 결과 담기용
    private int startRow;                  // 페이징 시작 행
    private int endRow;                    // 페이징 끝 행
    private int page;                      // 현재 페이지

    // ========== 검색/정렬 관련 ==========
    private String condition;              // DAO 분기용 컨디션
    private String keyword;                // 검색어 (제목/내용)

    // ========== JOIN 결과 담기용 (ANIME 테이블) ==========
    private String animeTitle;             // 애니 제목
    private Integer animeYear;             // 방영 연도 (NULL 가능)
    private String animeQuarter;           // 방영 분기
    private String animeThumbnailUrl;      // 애니 썸네일
    
    // ========== MyBatis/LIMIT-OFFSET 용 ==========
    private int startNum;                  // OFFSET
    private int listSize;                  // LIMIT

    // ========== Getter/Setter ==========
    
    public int getNewsId() {
        return newsId;
    }

    public void setNewsId(int newsId) {
        this.newsId = newsId;
    }

    public Integer getAnimeId() {
        return animeId;
    }

    public void setAnimeId(Integer animeId) {
        this.animeId = animeId;
    }

    public String getNewsTitle() {
        return newsTitle;
    }

    public void setNewsTitle(String newsTitle) {
        this.newsTitle = newsTitle;
    }

    public String getNewsContent() {
        return newsContent;
    }

    public void setNewsContent(String newsContent) {
        this.newsContent = newsContent;
    }

    public String getNewsImageUrl() {
        return newsImageUrl;
    }

    public void setNewsImageUrl(String newsImageUrl) {
        this.newsImageUrl = newsImageUrl;
    }

    public String getNewsThumbnailUrl() {
        return newsThumbnailUrl;
    }

    public void setNewsThumbnailUrl(String newsThumbnailUrl) {
        this.newsThumbnailUrl = newsThumbnailUrl;
    }

    public int getNewsCount() {
        return newsCount;
    }

    public void setNewsCount(int newsCount) {
        this.newsCount = newsCount;
    }

    public int getStartRow() {
        return startRow;
    }

    public void setStartRow(int startRow) {
        this.startRow = startRow;
    }

    public int getEndRow() {
        return endRow;
    }

    public void setEndRow(int endRow) {
        this.endRow = endRow;
    }

    public int getPage() {
        return page;
    }

    public void setPage(int page) {
        this.page = page;
    }

    public String getCondition() {
        return condition;
    }

    public void setCondition(String condition) {
        this.condition = condition;
    }

    public String getKeyword() {
        return keyword;
    }

    public void setKeyword(String keyword) {
        this.keyword = keyword;
    }

    public String getAnimeTitle() {
        return animeTitle;
    }

    public void setAnimeTitle(String animeTitle) {
        this.animeTitle = animeTitle;
    }

    public Integer getAnimeYear() {
        return animeYear;
    }

    public void setAnimeYear(Integer animeYear) {
        this.animeYear = animeYear;
    }

    public String getAnimeQuarter() {
        return animeQuarter;
    }

    public void setAnimeQuarter(String animeQuarter) {
        this.animeQuarter = animeQuarter;
    }

    public String getAnimeThumbnailUrl() {
        return animeThumbnailUrl;
    }

    public void setAnimeThumbnailUrl(String animeThumbnailUrl) {
        this.animeThumbnailUrl = animeThumbnailUrl;
    }

    public int getStartNum() {
        return startNum;
    }

    public void setStartNum(int startNum) {
        this.startNum = startNum;
    }

    public int getListSize() {
        return listSize;
    }

    public void setListSize(int listSize) {
        this.listSize = listSize;
    }

    @Override
    public String toString() {
        return "NewsDTO [newsId=" + newsId + ", animeId=" + animeId + ", newsTitle=" + newsTitle + ", newsContent="
                + newsContent + ", newsImageUrl=" + newsImageUrl + ", newsThumbnailUrl=" + newsThumbnailUrl
                + ", newsCount=" + newsCount + ", startRow=" + startRow + ", endRow=" + endRow + ", page=" + page
                + ", condition=" + condition + ", keyword=" + keyword + ", animeTitle=" + animeTitle + ", animeYear="
                + animeYear + ", animeQuarter=" + animeQuarter + ", animeThumbnailUrl=" + animeThumbnailUrl
                + ", startNum=" + startNum + ", listSize=" + listSize + "]";
    }
}