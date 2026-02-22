package fourcheetah.animale.web.common;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.safety.Safelist;
import org.springframework.stereotype.Component;

@Component
public class HtmlSanitizer {

    private final Safelist richTextSafelist;
    private final Document.OutputSettings outputSettings;

    public HtmlSanitizer() {
        this.outputSettings = new Document.OutputSettings().prettyPrint(false);

        // CKEditor 리치 텍스트용 화이트리스트
        this.richTextSafelist = Safelist.relaxed()
                .addTags("figure", "figcaption", "span", "div", "hr",
                         "table", "thead", "tbody", "tr", "th", "td")
                .addAttributes(":all", "class")
                .addAttributes("a", "target", "rel")
                .addAttributes("img", "src", "alt", "width", "height")
                .addProtocols("a", "href", "http", "https", "mailto")
                .addProtocols("img", "src", "http", "https");

        // /upload/... 같은 상대경로 이미지 유지
        this.richTextSafelist.preserveRelativeLinks(true);

        // 링크 보안 속성 강제
        this.richTextSafelist.addEnforcedAttribute("a", "rel", "noopener noreferrer nofollow");
    }

    public String sanitizeBoardHtml(String html) {
        if (html == null) return "";
        return Jsoup.clean(html, "", richTextSafelist, outputSettings);
    }

    public String sanitizeNewsHtml(String html) {
        if (html == null) return "";
        return Jsoup.clean(html, "", richTextSafelist, outputSettings);
    }

    // 일반 텍스트용 최소 정리 (제어문자 제거 + trim)
    public String normalizePlainText(String text) {
        if (text == null) return "";
        return text.replaceAll("[\\p{Cntrl}&&[^\\r\\n\\t]]", "").trim();
    }
}