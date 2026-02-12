package fourcheetah.animale.web.dto.ai;

import java.io.Serializable;
import java.util.List;

public class AiChatMessageResponse implements Serializable {
	private static final long serialVersionUID = 1L;

	private List<RecommendedAnimeDTO> recommendedAnimes;
	private String errorMessage; // 실패/타임아웃 시

	public List<RecommendedAnimeDTO> getRecommendedAnimes() {
		return recommendedAnimes;
	}

	public void setRecommendedAnimes(List<RecommendedAnimeDTO> recommendedAnimes) {
		this.recommendedAnimes = recommendedAnimes;
	}

	public String getErrorMessage() {
		return errorMessage;
	}

	public void setErrorMessage(String errorMessage) {
		this.errorMessage = errorMessage;
	}
}
