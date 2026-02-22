package fourcheetah.animale.web.common;

import java.net.URI;
import java.nio.file.Path;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.safety.Safelist;
import org.springframework.stereotype.Component;

@Component
public class HtmlSanitizer {

    // ✅ [CHANGED] baseUri를 빈 문자열("") 대신 사용할 기본 기준 URI
    // - Jsoup가 상대경로(/upload/..., /animale/upload/...)의 프로토콜 검사를 할 때 필요
    // - preserveRelativeLinks(true)와 함께 쓰면 최종 결과는 상대경로를 유지함
    private static final String DEFAULT_BASE_URI = "https://animale.local";

    private final Safelist richTextSafelist;
    private final Document.OutputSettings outputSettings;

    // ===========================
    // 입력 형식 정책 (프로젝트 정책에 맞게 조정 가능)
    // ===========================
    // 로그인 ID: 영문/숫자/._- , 4~30자
    private static final Pattern LOGIN_ID_PATTERN =
            Pattern.compile("^[a-zA-Z0-9._-]{4,30}$");

    // 닉네임: 한글/영문/숫자/공백/._- , 2~20자
    private static final Pattern NICKNAME_PATTERN =
            Pattern.compile("^[가-힣a-zA-Z0-9._ -]{2,20}$");

    // 프로필 임시 토큰: m{memberId}_{32hex}.{ext}
    // 예: m12_a1b2c3...d4.jpg
    private static final Pattern PROFILE_TEMP_TOKEN_PATTERN =
            Pattern.compile("^m\\d+_[a-fA-F0-9]{32}\\.(jpg|jpeg|png|webp)$");

    public HtmlSanitizer() {
        this.outputSettings = new Document.OutputSettings().prettyPrint(false);

        // ✅ [유지 + 보강] CKEditor 리치 텍스트용 화이트리스트
        // - figure / figcaption / table 등 CKEditor가 자주 만드는 태그 허용
        // - img의 src/alt/width/height 허용
        // - class 허용(figure.image 등 유지)
        this.richTextSafelist = Safelist.relaxed()
                .addTags("figure", "figcaption", "span", "div", "hr",
                        "table", "thead", "tbody", "tr", "th", "td")
                .addAttributes(":all", "class")
                .addAttributes("a", "target", "rel")
                .addAttributes("img", "src", "alt", "width", "height")
                .addProtocols("a", "href", "http", "https", "mailto")
                .addProtocols("img", "src", "http", "https");

        // ✅ [중요] /upload/... 같은 상대경로를 최종 결과에서 유지
        this.richTextSafelist.preserveRelativeLinks(true);

        // ✅ 링크 보안 속성 강제
        this.richTextSafelist.addEnforcedAttribute("a", "rel", "noopener noreferrer nofollow");
    }

    // ===========================
    // Rich HTML (게시글/뉴스 본문)
    // ===========================

    /**
     * ✅ [CHANGED] 리치 HTML 공통 정제
     * - 핵심: baseUri를 빈 문자열("")로 주지 않음
     * - 이유: 상대경로 img src(/upload/...)가 프로토콜 검사 단계에서 탈락하지 않도록 하기 위함
     */
    private String cleanRichHtmlInternal(String html) {
        if (html == null) return "";

        // 1) 기본 sanitize (화이트리스트 기반)
        String cleaned = Jsoup.clean(html, DEFAULT_BASE_URI, richTextSafelist, outputSettings);

        // 2) ✅ [보강] 아주 드물게 남을 수 있는 빈 src img 정리 (선택적 방어)
        //    - "<img>" 또는 src="" 만 남아 레이아웃만 깨지는 경우 예방
        //    - 필요 없으면 이 줄은 제거해도 됨
        cleaned = cleaned.replaceAll("(?i)<img(?=\\s|>)(?![^>]*\\bsrc\\s*=)[^>]*>", "");

        return cleaned;
    }

    public String sanitizeBoardHtml(String html) {
        return cleanRichHtmlInternal(html);
    }

    public String sanitizeNewsHtml(String html) {
        return cleanRichHtmlInternal(html);
    }

    // (선택) 공통 리치HTML 메서드
    public String sanitizeRichHtml(String html) {
        return cleanRichHtmlInternal(html);
    }

    // ===========================
    // Plain Text (제목/댓글/닉네임 등)
    // ===========================

    // 일반 텍스트용 최소 정리 (제어문자 제거 + trim)
    public String normalizePlainText(String text) {
        if (text == null) return "";
        return text.replaceAll("[\\p{Cntrl}&&[^\\r\\n\\t]]", "").trim();
    }

    // 일반 텍스트용 XSS 방어 (태그 제거 + 제어문자 정리)
    // - 제목/원제목/줄거리(HTML 미허용)/댓글/닉네임 등에 사용
    public String sanitizePlainText(String text) {
        if (text == null) return "";

        // 1) 기본 정리 (제어문자 제거 + trim)
        String normalized = normalizePlainText(text);
        if (normalized.isEmpty()) return "";

        // 2) HTML 태그 제거 (허용 태그 없음)
        // 예: "<script>alert(1)</script>안녕" -> "alert(1)안녕"
        String stripped = Jsoup.clean(normalized, Safelist.none());

        // 3) 한 번 더 정리
        return normalizePlainText(stripped);
    }

    // ===========================
    // URL / 이미지 URL 검증
    // ===========================

    /**
     * http/https 또는 내부 상대경로(/...)만 허용
     * - javascript:, data:, vbscript: 차단
     */
    public String sanitizeSafeUrl(String url) {
        if (url == null) return null;

        String v = url.trim();
        if (v.isEmpty()) return null;

        // 내부 상대경로 허용 (/upload/..., /newsList 등)
        if (v.startsWith("/")) {
            return v;
        }

        try {
            URI uri = URI.create(v);
            String scheme = uri.getScheme();
            if (scheme == null) return null;

            String s = scheme.toLowerCase(Locale.ROOT);
            if (Set.of("http", "https").contains(s)) {
                return v;
            }
            return null;
        } catch (Exception e) {
            return null;
        }
    }

    // 이미지 URL도 동일 정책 사용
    public String sanitizeImageUrl(String url) {
        return sanitizeSafeUrl(url);
    }

    // ===========================
    // 로그인 ID / 닉네임 형식 검증
    // ===========================

    public boolean isSafeLoginId(String loginId) {
        if (loginId == null) return false;
        String v = sanitizePlainText(loginId);
        return LOGIN_ID_PATTERN.matcher(v).matches();
    }

    public boolean isSafeNickname(String nickname) {
        if (nickname == null) return false;
        String v = sanitizePlainText(nickname);
        return NICKNAME_PATTERN.matcher(v).matches();
    }

    // ===========================
    // 프로필 임시 토큰 / 경로 검증
    // ===========================

    public boolean isValidProfileTempToken(String token) {
        if (token == null) return false;
        return PROFILE_TEMP_TOKEN_PATTERN.matcher(token.trim()).matches();
    }

    /**
     * baseDir 하위 경로인지 확인 (path traversal 방지)
     */
    public boolean isUnderBaseDir(Path baseDir, Path target) {
        if (baseDir == null || target == null) return false;

        Path base = baseDir.toAbsolutePath().normalize();
        Path t = target.toAbsolutePath().normalize();

        return t.startsWith(base);
    }
}