package fourcheetah.animale.web.controller.member;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class TossPaymentsClient {

    private final RestClient restClient;

    // secretKey는 서버 properties에만 두기
    public TossPaymentsClient(@Value("${toss.secretKey}") String secretKey) {
        String token = Base64.getEncoder()
                .encodeToString((secretKey + ":").getBytes(StandardCharsets.UTF_8));

        this.restClient = RestClient.builder()
                .baseUrl("https://api.tosspayments.com")
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Basic " + token)
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    //  결제 승인(confirm) 호출
    public String confirm(String paymentKey, String orderId, int amount) {
        Map<String, Object> body = Map.of(
                "paymentKey", paymentKey,
                "orderId", orderId,
                "amount", amount
        );

        // 토스 문서 기준: paymentKey/orderId/amount로 승인 API 호출 :contentReference[oaicite:2]{index=2}
        return restClient.post()
                .uri("/v1/payments/confirm")
                .accept(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(String.class);
    }
}