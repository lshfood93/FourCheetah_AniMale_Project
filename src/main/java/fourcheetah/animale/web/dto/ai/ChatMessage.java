package fourcheetah.animale.web.dto.ai;

import java.io.Serializable;

public class ChatMessage implements Serializable {
    private static final long serialVersionUID = 1L;

    private String role; // "user" | "assistant"
    private String content;

    public ChatMessage() {}

    public ChatMessage(String role, String content) {
        this.role = role;
        this.content = content;
    }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
