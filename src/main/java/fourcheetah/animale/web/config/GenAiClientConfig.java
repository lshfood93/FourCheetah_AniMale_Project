package fourcheetah.animale.web.config;

import com.google.genai.Client;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GenAiClientConfig {

    @Value("${google.genai.api-key:}")
    private String apiKey;

    @Bean
    public Client genAiClient() {
        if (apiKey != null && !apiKey.isBlank()) {
            return Client.builder().apiKey(apiKey).build();
        }
        return new Client(); // 환경변수(GOOGLE_API_KEY / GEMINI_API_KEY) 기반
    }
}
