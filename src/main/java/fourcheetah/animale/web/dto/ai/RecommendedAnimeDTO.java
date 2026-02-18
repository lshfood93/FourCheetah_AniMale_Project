package fourcheetah.animale.web.dto.ai;

import java.io.Serializable;
import java.util.List;

public class RecommendedAnimeDTO implements Serializable {
	private static final long serialVersionUID = 1L;

	private int animeId;
	private String title;
	private String thumbnailUrl;
	private List<String> genres; // JSON 컬럼 파싱 결과
	private String reason; // Ranker가 채움

	public int getAnimeId() {
		return animeId;
	}

	public void setAnimeId(int animeId) {
		this.animeId = animeId;
	}

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public String getThumbnailUrl() {
		return thumbnailUrl;
	}

	public void setThumbnailUrl(String thumbnailUrl) {
		this.thumbnailUrl = thumbnailUrl;
	}

	public List<String> getGenres() {
		return genres;
	}

	public void setGenres(List<String> genres) {
		this.genres = genres;
	}

	public String getReason() {
		return reason;
	}

	public void setReason(String reason) {
		this.reason = reason;
	}
}
