package fourcheetah.animale.web.dto.ai;

import java.io.Serializable;
import java.util.List;

public class AiChatOpenResponse implements Serializable {
	private static final long serialVersionUID = 1L;

	private String welcomeMessage;
	private String initialPrompt;
	
    private boolean resumed;              // 기존 대화 복원 여부
    private List<ChatMessage> chatHistory; // 서버 세션 히스토리
    private int moreCount;
    
    //  추가: 마지막 추천 리스트 복원용
    private List<RecommendedAnimeDTO> lastRecommendedAnimes;

	public String getWelcomeMessage() {
		return welcomeMessage;
	}

	public void setWelcomeMessage(String welcomeMessage) {
		this.welcomeMessage = welcomeMessage;
	}

	public String getInitialPrompt() {
		return initialPrompt;
	}

	public void setInitialPrompt(String initialPrompt) {
		this.initialPrompt = initialPrompt;
	}

	public boolean isResumed() {
		return resumed;
	}

	public void setResumed(boolean resumed) {
		this.resumed = resumed;
	}

	public List<ChatMessage> getChatHistory() {
		return chatHistory;
	}

	public void setChatHistory(List<ChatMessage> chatHistory) {
		this.chatHistory = chatHistory;
	}

	public int getMoreCount() {
		return moreCount;
	}

	public void setMoreCount(int moreCount) {
		this.moreCount = moreCount;
	}

	public List<RecommendedAnimeDTO> getLastRecommendedAnimes() {
		return lastRecommendedAnimes;
	}

	public void setLastRecommendedAnimes(List<RecommendedAnimeDTO> lastRecommendedAnimes) {
		this.lastRecommendedAnimes = lastRecommendedAnimes;
	}
	
	
	
	
}
