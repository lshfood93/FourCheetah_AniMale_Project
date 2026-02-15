package fourcheetah.animale.web.dto.ai;

import java.io.Serializable;

public class AiChatMessageRequest implements Serializable {
	private static final long serialVersionUID = 1L;

	private String userMessage;

	public String getUserMessage() {
		return userMessage;
	}

	public void setUserMessage(String userMessage) {
		this.userMessage = userMessage;
	}
}
