package fourcheetah.animale.web.dto.ai;

import java.io.Serializable;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashSet;
import java.util.Set;

public class AiChatSessionState implements Serializable {

	private Integer memberId;

	// 최근 N턴 유지 (턴=유저+어시스턴트 한 쌍이므로 메시지는 2*N개로 관리하는게 편함)
	private Deque<ChatMessage> chatHistory = new ArrayDeque<>();

	private Set<Integer> excludeAnimeIds = new HashSet<>();
	private int moreRecommendCount = 0;

	// rate limit
	private long minuteWindowStartEpochMs = 0L;
	private int minuteCount = 0;
	private int sessionTotalCount = 0;

	public AiChatSessionState() {
	}

	public Integer getMemberId() {
		return memberId;
	}

	public void setMemberId(Integer memberId) {
		this.memberId = memberId;
	}

	public Deque<ChatMessage> getChatHistory() {
		return chatHistory;
	}

	public void setChatHistory(Deque<ChatMessage> chatHistory) {
		this.chatHistory = chatHistory;
	}

	public Set<Integer> getExcludeAnimeIds() {
		return excludeAnimeIds;
	}

	public void setExcludeAnimeIds(Set<Integer> excludeAnimeIds) {
		this.excludeAnimeIds = excludeAnimeIds;
	}

	public int getMoreRecommendCount() {
		return moreRecommendCount;
	}

	public void setMoreRecommendCount(int moreRecommendCount) {
		this.moreRecommendCount = moreRecommendCount;
	}

	public long getMinuteWindowStartEpochMs() {
		return minuteWindowStartEpochMs;
	}

	public void setMinuteWindowStartEpochMs(long v) {
		this.minuteWindowStartEpochMs = v;
	}

	public int getMinuteCount() {
		return minuteCount;
	}

	public void setMinuteCount(int v) {
		this.minuteCount = v;
	}

	public int getSessionTotalCount() {
		return sessionTotalCount;
	}

	public void setSessionTotalCount(int v) {
		this.sessionTotalCount = v;
	}
}
