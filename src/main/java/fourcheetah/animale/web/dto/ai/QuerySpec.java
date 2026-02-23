package fourcheetah.animale.web.dto.ai;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class QuerySpec implements Serializable {
    private static final long serialVersionUID = 1L;

    private List<String> genres = new ArrayList<>();   // 예: ["판타지","액션"]
    private List<String> keywords = new ArrayList<>(); // 예: ["마법","성장"]
    private String rawUserMessage;

    public QuerySpec() {}

    public List<String> getGenres() { return genres; }
    public void setGenres(List<String> genres) { this.genres = genres; }

    public List<String> getKeywords() { return keywords; }
    public void setKeywords(List<String> keywords) { this.keywords = keywords; }

    public String getRawUserMessage() { return rawUserMessage; }
    public void setRawUserMessage(String rawUserMessage) { this.rawUserMessage = rawUserMessage; }
}
