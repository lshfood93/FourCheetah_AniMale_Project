package fourcheetah.animale.web.config;

import com.google.genai.Client;
import com.google.genai.types.HttpOptions;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GenAiClientConfig {

	@Value("${google.genai.apikey:}")
    private String apiKey;

    @Value("${ai.chat.timeoutMs:20000}")
    private int timeoutMs;

    @Bean(destroyMethod = "close") // [ADDED] Client는 close 가능(리소스 정리) :contentReference[oaicite:2]{index=2}
    public Client genAiClient() {
        return Client.builder()
                .apiKey(apiKey)
                .httpOptions(HttpOptions.builder()
                        .timeout(timeoutMs) // [ADDED] SDK 기본 timeout (ms) :contentReference[oaicite:3]{index=3}
                        .build())
                .build();
    }
}