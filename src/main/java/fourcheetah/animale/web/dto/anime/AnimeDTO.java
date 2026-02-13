package fourcheetah.animale.web.dto.anime;

import org.apache.ibatis.type.Alias;
import org.springframework.web.multipart.MultipartFile;

@Alias("animeDTO")
public class AnimeDTO {

    private int animeId;
    private String animeTitle;
    private String originalTitle;
    private Integer animeYear;          // NULL 가능
    private String animeQuarter;
    private String animeStory;          // LONGTEXT
    private String animeThumbnailUrl;   // VARCHAR(2048)

    // 최프로 ERD 추가 컬럼 (MySQL JSON)
    private String animeGenres;         // JSON 문자열 (예: ["판타지","액션"])
    private String animeTags;           // JSON 문자열 (예: ["성장","힐링"])

    private String sort;                // 정렬 기준
    private int animeCount;             // COUNT 결과

    // 페이징 (MySQL LIMIT 계산에 사용)
    private int startRow;               // 1부터 시작한다고 가정
    private int endRow;

    // condition / keyword
    private String condition;           // TITLE / STORY 같은 구분값
    private String keyword;    
    private String page;

    // =========================
    // [필터 검색용 추가 필드]
    // =========================
    private Integer year;               // 년도 필터 (1980~2026)
    private Integer quarter;            // 분기 필터 (1~4, 프론트에서 숫자로 전송)

    // =========================
    // [요청 바인딩 전용] (DB 저장 X)
    // =========================
    // 수정 시 "기존 썸네일 유지" 용 hidden input 값
    private String existingThumbUrl;

    // 수정 시 업로드되는 새 썸네일 파일
    private MultipartFile thumbFile;

    public int getAnimeId() {
        return animeId;
    }
    public void setAnimeId(int animeId) {
        this.animeId = animeId;
    }

    public String getAnimeTitle() {
        return animeTitle;
    }
    public void setAnimeTitle(String animeTitle) {
        this.animeTitle = animeTitle;
    }

    public String getOriginalTitle() {
        return originalTitle;
    }
    public void setOriginalTitle(String originalTitle) {
        this.originalTitle = originalTitle;
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

    public String getAnimeStory() {
        return animeStory;
    }
    public void setAnimeStory(String animeStory) {
        this.animeStory = animeStory;
    }
    																																																																																																																												
    public String getAnimeThumbnailUrl() {
        return animeThumbnailUrl;
    }
    public void setAnimeThumbnailUrl(String animeThumbnailUrl) {
        this.animeThumbnailUrl = animeThumbnailUrl;
    }

    public String getAnimeGenres() {
        return animeGenres;
    }
    public void setAnimeGenres(String animeGenres) {
        this.animeGenres = animeGenres;
    }

    public String getAnimeTags() {
        return animeTags;
    }
    public void setAnimeTags(String animeTags) {
        this.animeTags = animeTags;
    }

    public String getSort() {
        return sort;
    }
    public void setSort(String sort) {
        this.sort = sort;
    }

    public int getAnimeCount() {
        return animeCount;
    }
    public void setAnimeCount(int animeCount) {
        this.animeCount = animeCount;
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
    
    public String getPage() {
        return page;
    }
    public void setPage(String page) {
        this.page = page;
    }

    // =========================
    // 필터 검색용 getter/setter
    // =========================
    public Integer getYear() {
        return year;
    }
    public void setYear(Integer year) {
        this.year = year;
    }

    public Integer getQuarter() {
        return quarter;
    }
    public void setQuarter(Integer quarter) {
        this.quarter = quarter;
    }

    // =========================
    // 요청 바인딩 전용 getter/setter
    // =========================
    public String getExistingThumbUrl() {
        return existingThumbUrl;
    }
    public void setExistingThumbUrl(String existingThumbUrl) {
        this.existingThumbUrl = existingThumbUrl;
    }

    public MultipartFile getThumbFile() {
        return thumbFile;
    }
    public void setThumbFile(MultipartFile thumbFile) {
        this.thumbFile = thumbFile;
    }

    @Override
    public String toString() {
        return "AnimeDTO [animeId=" + animeId
                + ", animeTitle=" + animeTitle
                + ", originalTitle=" + originalTitle
                + ", animeYear=" + animeYear
                + ", animeQuarter=" + animeQuarter
                + ", animeStory=" + animeStory
                + ", animeThumbnailUrl=" + animeThumbnailUrl
                + ", animeGenres=" + animeGenres
                + ", animeTags=" + animeTags
                + ", sort=" + sort
                + ", animeCount=" + animeCount
                + ", startRow=" + startRow
                + ", endRow=" + endRow
                + ", condition=" + condition
                + ", keyword=" + keyword
                + ", year=" + year
                + ", quarter=" + quarter
                + ", existingThumbUrl=" + existingThumbUrl
                + ", thumbFile=" + (thumbFile != null && !thumbFile.isEmpty())
                + "]";
    }
}