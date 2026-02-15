package fourcheetah.animale.web.dto.ai;

import java.io.Serializable;

public class AiChatOpenResponse implements Serializable {
	private static final long serialVersionUID = 1L;

	private String welcomeMessage;
	private String initialPrompt;

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
}
