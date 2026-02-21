package fourcheetah.animale.web.controller.member;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import fourcheetah.animale.web.dto.admin.CashChargeDTO;
import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.service.admin.CashChargeService;
import fourcheetah.animale.web.service.member.MemberService;
import jakarta.servlet.http.HttpSession;

/**
 * 결제 컨트롤러 (카카오페이)
 * 
 * 통합 이전:
 * - KakaoPayApproveController
 * - KakaoPayCancelController
 * - KakaoPayFailController
 */
@Controller
public class PaymentController {

    private static final String READY_URL = "https://open-api.kakaopay.com/online/v1/payment/ready";
    private static final String APPROVE_URL = "https://open-api.kakaopay.com/online/v1/payment/approve";

    @Value("${kakaopay.cid}")
    private String cid;

    @Value("${kakaopay.secret}")
    private String secretKey;
    
    @Value("${toss.clientKey}")
    private String tossclientKey;
    
 //  [ADD]
    @Autowired
    private org.springframework.core.env.Environment env;

    private final MemberService memberService;
    
    @Autowired
    private CashChargeService cashChargeService;

    public PaymentController(MemberService memberService) {
        this.memberService = memberService;
    }

    // ==================== 결제 준비 ====================

    @PostMapping("/payment/kakaopay/ready")
    public String ready(@RequestParam("selectCash") int cashCharge,
                        HttpSession session,
                        Model model) {

        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId == null) return "redirect:/login";

        if (!(cashCharge == 1000 || cashCharge == 5000 || cashCharge == 10000 || cashCharge == 50000)) {
            model.addAttribute("payResult", "FAIL");
            model.addAttribute("message", "허용되지 않은 충전 금액입니다.");
            return "cashresult";
        }

        String baseUrl = ServletUriComponentsBuilder.fromCurrentContextPath().build().toUriString();

        String partnerOrderId = "CASH_" + UUID.randomUUID();
        String partnerUserId = String.valueOf(memberId);

        String approvalUrl = baseUrl + "/payment/kakaopay/approve";
        String cancelUrl = baseUrl + "/payment/kakaopay/cancel";
        String failUrl = baseUrl + "/payment/kakaopay/fail";

        try {
            System.out.println("[KAKAO READY] cid=" + cid
                    + ", secret=" + (secretKey == null ? "null" : secretKey.substring(0, Math.min(4, secretKey.length())) + "****")
                    + ", approvalUrl=" + approvalUrl);

            JsonObject body = new JsonObject();
            body.addProperty("cid", cid);
            body.addProperty("partner_order_id", partnerOrderId);
            body.addProperty("partner_user_id", partnerUserId);
            body.addProperty("item_name", "캐시 충전 " + cashCharge + "원");
            body.addProperty("quantity", 1);
            body.addProperty("total_amount", cashCharge);
            body.addProperty("vat_amount", calcVat(cashCharge));
            body.addProperty("tax_free_amount", 0);
            body.addProperty("approval_url", approvalUrl);
            body.addProperty("cancel_url", cancelUrl);
            body.addProperty("fail_url", failUrl);

            String responseJson = postJson(READY_URL, body.toString());
            JsonObject resObj = JsonParser.parseString(responseJson).getAsJsonObject();

            String tid = resObj.get("tid").getAsString();
            String nextRedirectPcUrl = resObj.get("next_redirect_pc_url").getAsString();
            
         // [ADD] CASH_CHARGE에 READY INSERT (대시보드/승인 업데이트의 기반 row)
            CashChargeDTO charge = new CashChargeDTO();
            charge.setMemberId(memberId);
            charge.setProvider("KAKAOPAY");
            charge.setAmount(cashCharge);
            charge.setCashAmount(cashCharge);
            charge.setStatus("READY");
            charge.setPartnerOrderId(partnerOrderId);
            charge.setApprovedAt(null);
            
            charge.setCondition("CHARGE_INSERT");	

         boolean insOk = cashChargeService.insert(charge);
         if (!insOk) {
             model.addAttribute("payResult", "FAIL");
             model.addAttribute("message", "결제 준비 내역 저장 실패(CASH_CHARGE)");
             return "cashresult";
         }
         
      // [ADD] 카카오 READY 중복 호출 방지 락
         if (session.getAttribute("KAKAO_READY_LOCK") != null) {
             model.addAttribute("payResult", "FAIL");
             model.addAttribute("message", "결제가 이미 진행 중입니다. 잠시 후 다시 시도해주세요.");
             return "cashresult";
         }
         session.setAttribute("KAKAO_READY_LOCK", true);

            
            
            session.setAttribute("kakaopay_tid", tid);
            session.setAttribute("kakaopay_partner_order_id", partnerOrderId);
            session.setAttribute("kakaopay_partner_user_id", partnerUserId);
            session.setAttribute("kakaopay_total_amount", cashCharge);
            session.removeAttribute("KAKAO_READY_LOCK");

            return "redirect:" + nextRedirectPcUrl;

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("payResult", "FAIL");
            model.addAttribute("message", e.getMessage() == null ? "결제 준비(READY) 실패" : e.getMessage());
            return "cashresult";
        }
    }

    // ==================== 결제 승인 ====================
    @GetMapping("/payment/kakaopay/approve")
    public String approve(@RequestParam("pg_token") String pgToken,
                          HttpSession session,
                          Model model) {

        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId == null) {
            model.addAttribute("payResult", "FAIL");
            model.addAttribute("message", "로그인이 필요합니다.");
            return "cashresult";
        }

        String tid = (String) session.getAttribute("kakaopay_tid");
        String partnerOrderId = (String) session.getAttribute("kakaopay_partner_order_id");
        String partnerUserId = (String) session.getAttribute("kakaopay_partner_user_id");
        Integer cashCharge = (Integer) session.getAttribute("kakaopay_total_amount");

        if (tid == null || partnerOrderId == null || partnerUserId == null || cashCharge == null) {
            model.addAttribute("payResult", "FAIL");
            model.addAttribute("message", "세션 결제정보가 없습니다. 다시 시도해주세요.");
            return "cashresult";
        }

        String processedOrderId = (String) session.getAttribute("kakaopay_processed_order_id");
        if (partnerOrderId.equals(processedOrderId)) {
            return "redirect:/member/mypage";
        }

        try {
            JsonObject body = new JsonObject();
            body.addProperty("cid", cid);
            body.addProperty("tid", tid);
            body.addProperty("partner_order_id", partnerOrderId);
            body.addProperty("partner_user_id", partnerUserId);
            body.addProperty("pg_token", pgToken);

            String responseJson = postJson(APPROVE_URL, body.toString());
            JsonObject resObj = JsonParser.parseString(responseJson).getAsJsonObject();

            Integer approvedTotal = null;
            if (resObj.has("amount") && resObj.get("amount").isJsonObject()) {
                JsonObject amountObj = resObj.getAsJsonObject("amount");
                if (amountObj.has("total")) approvedTotal = amountObj.get("total").getAsInt();
            }

            if (approvedTotal == null || !approvedTotal.equals(cashCharge)) {
                model.addAttribute("payResult", "FAIL");
                model.addAttribute("message", "승인 금액 검증 실패");
                return "cashresult";
            }

       
            // =========================================================
            // 2) approved_at 파싱 (LocalDateTime)
            // =========================================================
            java.time.LocalDateTime approvedAt = java.time.LocalDateTime.now();

            if (resObj.has("approved_at") && !resObj.get("approved_at").isJsonNull()) {
                String s = resObj.get("approved_at").getAsString();
                try {
                    approvedAt = java.time.OffsetDateTime.parse(s).toLocalDateTime();
                } catch (Exception ignore) {
                    try {
                        approvedAt = java.time.LocalDateTime.parse(s.replace("Z","")); // ✅ [FIX] 풀네임
                    } catch (Exception ignore2) {
                        // 파싱 실패하면 now() 유지
                    }
                }
            }

            // =========================================================
            // 3) CASH_CHARGE: READY -> APPROVED (partner_order_id 기준)
            // =========================================================
            CashChargeDTO chargeUpd = new CashChargeDTO();
            chargeUpd.setCondition("CHARGE_APPROVE_READY_BY_ORDER");
            chargeUpd.setPartnerOrderId(partnerOrderId);
            chargeUpd.setApprovedAt(approvedAt);

         // approvedAt 파싱 로직은 그대로 두고
            boolean txOk = cashChargeService.approveChargeTx(
                memberId,
                partnerOrderId,
                approvedTotal,
                approvedAt
            );

            if (!txOk) {
                model.addAttribute("payResult", "FAIL");
                model.addAttribute("message", "결제 승인 내역 반영 실패(트랜잭션)");
                return "cashresult";
            }

            //  [CHANGED] 트랜잭션 성공 후에만 중복 처리 세션 세팅
            session.setAttribute("kakaopay_processed_order_id", partnerOrderId);
            // =========================================================
            // 4) 화면 출력용 데이터 세팅 + 성공 리턴
            // =========================================================
            MemberDTO sel = new MemberDTO();
            sel.setCondition("MEMBER_MYPAGE");
            sel.setMemberId(memberId);
            MemberDTO memberData = memberService.selectOne(sel);
            int totalCash = (memberData == null) ? 0 : memberData.getMemberCash();

            model.addAttribute("payResult", "SUCCESS");
            model.addAttribute("payMethod", "카카오페이");
            model.addAttribute("totalAmount", String.format("%,d", approvedTotal));
            model.addAttribute("totalCash", String.format("%,d", totalCash));
            model.addAttribute("approvedAt", approvedAt.toString()); // 필요하면 포맷 적용

            return "cashresult"; // [FIX] 성공 시 리턴 추가

        } catch (DataAccessException dae) {
            dae.printStackTrace();
            model.addAttribute("payResult", "FAIL");
            model.addAttribute("message", dae.getMessage());
            return "cashresult";
        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("payResult", "FAIL");
            model.addAttribute("message", e.getMessage() == null ? "결제 승인(APPROVE) 실패" : e.getMessage());
            return "cashresult";
        }
    }

    // ==================== 카카오페이 콜백 ====================

    @GetMapping("/payment/kakaopay/cancel")
    public String cancel(Model model,  HttpSession session) {
        model.addAttribute("payResult", "FAIL");
        model.addAttribute("payMethod", "카카오페이");
        model.addAttribute("message", "결제가 취소되었습니다.");
        session.removeAttribute("KAKAO_READY_LOCK");
        return "cashresult";
    }

    @GetMapping("/payment/kakaopay/fail")
    public String fail(Model model,  HttpSession session) {
        model.addAttribute("payResult", "FAIL");
        model.addAttribute("payMethod", "카카오페이");
        model.addAttribute("message", "결제에 실패했습니다.");
        session.removeAttribute("KAKAO_READY_LOCK");
        return "cashresult";
    }


    // ==================== 기존 경로 (KakaoPayCancelController, KakaoPayFailController) ====================

    @GetMapping("/KakaoPayCancel")
    public String kakaoPayCancel(Model model) {
        System.out.println("[카카오페이 CANCEL 로그] 결제 취소 : 마이페이지 이동");
        model.addAttribute("msg", "결제가 취소되었습니다.");
        model.addAttribute("location", "/myPage");
        return "message";
    }

    @GetMapping("/KakaoPayFail")
    public String kakaoPayFail(Model model) {
        System.out.println("[카카오페이 FAIL 로그] 결제 실패 : 완료페이지 이동");
        model.addAttribute("payResult", "FAIL");
        return "cashresult";
    }

    // ==================== 헬퍼 메서드 ====================

    private String postJson(String url, String jsonBody) throws IOException {
        if (secretKey == null || secretKey.trim().isEmpty()) {
            throw new IllegalStateException("kakaopay.secret 값을 설정하세요.");
        }

        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);
        conn.setRequestProperty("Authorization", "SECRET_KEY " + secretKey.trim());
        conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
        conn.setRequestProperty("Accept", "application/json");

        try (OutputStream os = conn.getOutputStream()) {
            os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
        }

        int code = conn.getResponseCode();
        InputStream is = (code >= 200 && code < 300) ? conn.getInputStream() : conn.getErrorStream();

        StringBuilder sb = new StringBuilder();
        if (is != null) {
            try (BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
                String line;
                while ((line = br.readLine()) != null) sb.append(line);
            }
        }

        if (code < 200 || code >= 300) {
            throw new IOException("KakaoPay API 실패: HTTP[" + code + "] body[" + sb + "]");
        }

        return sb.toString();
    }

    private int calcVat(int amount) {
        return (int) Math.round(amount / 11.0);
    }
    
    
    
 // [ADD] Toss 결제 시작(READY) 엔드포인트
    @PostMapping("/payment/toss/prepare")
    public ResponseEntity<Map<String, Object>> tossReady(
    		 @RequestParam(value = "selectCash", required = false) Integer selectCash,
    	        @RequestParam(value = "amount", required = false) Integer amount, CashChargeDTO dto,
            HttpSession session
    ) {
        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                "ok", false,
                "message", "로그인이 필요합니다."
            ));
        }

        // [FIX] 어떤 이름으로 오든 금액 확정
        Integer cashCharge = (selectCash != null) ? selectCash : amount;

        // [FIX] 누락 방어 (여기서 예외 대신 400으로 처리)
        if (cashCharge == null) {
            return ResponseEntity.badRequest().body(Map.of(
                    "ok", false,
                    "message", "selectCash(또는 amount) 파라미터가 필요합니다."
            ));
        }
        // 금액 화이트리스트
        if (!(cashCharge == 1000 || cashCharge == 5000 || cashCharge == 10000 || cashCharge == 50000)) {
            return ResponseEntity.badRequest().body(Map.of(
                "ok", false,
                "message", "허용되지 않은 충전 금액입니다."
            ));
        }

        // 서버에서 orderId 생성(클라 생성 금지)
        String orderId = "CASH_" + java.util.UUID.randomUUID();
        String partnerUserId = String.valueOf(memberId);

        // 콜백 URL 생성
        String baseUrl = org.springframework.web.servlet.support.ServletUriComponentsBuilder
                .fromCurrentContextPath()
                .build()
                .toUriString();

        String successUrl = baseUrl + "/payment/toss/success";
        String failUrl    = baseUrl + "/payment/toss/fail";

        // DB: CASH_CHARGE INSERT (READY)
       
        // 서비스/DAO가 condition 체크하면 아래 라인 사용
        // dto.setCondition("CHARGE_INSERT");

        dto.setMemberId(memberId);
        dto.setProvider("TOSSPAY");     // provider 통일
        dto.setAmount(cashCharge);
        dto.setCashAmount(cashCharge);  // 너 DB는 cash_amount 기준 집계라 이게 중요
        dto.setStatus("READY");
        dto.setPartnerOrderId(orderId);
        dto.setApprovedAt(null);

        
        
        
        boolean insOk = cashChargeService.insert(dto);
        if (!insOk) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "ok", false,
                "message", "결제 준비 내역 저장 실패(CASH_CHARGE)"
            ));
        }

        //  (선택) 세션에도 저장해두면 디버깅/추적 편함
        session.setAttribute("toss_partner_order_id", orderId);
        session.setAttribute("toss_partner_user_id", partnerUserId);
        session.setAttribute("toss_total_amount", cashCharge);

        // clientKey는 공개키라 내려줘도 됨(프론트에서 requestPayment에 필요)
        // - application.properties: toss.clientKey=...
        String clientKey = env.getProperty("toss.clientKey"); // ✅ env 주입 필요(아래 참고)

        return ResponseEntity.ok(Map.of(
            "ok", true,
            "orderId", orderId,
            "amount", cashCharge,
            "orderName", "캐시 충전 " + String.format("%,d", cashCharge) + "원",
            "successUrl", successUrl,
            "failUrl", failUrl,
            "clientKey", (clientKey == null ? "" : clientKey)
        ));
    }
    
    
    
 // ==================== TossPayments 콜백 (임시) ====================

    /**
     * 토스 결제 성공 콜백
     * TossPayments는 successUrl로 paymentKey, orderId, amount 를 쿼리스트링으로 전달합니다.
     */
    @GetMapping("/payment/toss/success")
    public String tossSuccess(@RequestParam("paymentKey") String paymentKey,
                              @RequestParam("orderId") String orderId,
                              @RequestParam("amount") int amount,
                              HttpSession session,
                              Model model) {

        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId == null) return "redirect:/login";

        // (안전장치) 허용된 충전 금액만 처리
        if (!(amount == 1000 || amount == 5000 || amount == 10000 || amount == 50000)) {
            model.addAttribute("payResult", "FAIL");
            model.addAttribute("payMethod", "토스페이");
            model.addAttribute("message", "허용되지 않은 충전 금액입니다.");
            return "cashresult";
        }

        // 중복 처리 방지(새로고침/뒤로가기)
        String processedOrderId = (String) session.getAttribute("toss_processed_order_id");
        if (orderId != null && orderId.equals(processedOrderId)) {
            return "redirect:/member/mypage";
        }

        try {
            //  [CHANGED] 여기서 바로 memberService.update 하면 안 됨
            boolean txOk = cashChargeService.approveTossTx(memberId, orderId, paymentKey, amount);

            if (!txOk) {
                model.addAttribute("payResult", "FAIL");
                model.addAttribute("payMethod", "토스페이");
                model.addAttribute("message", "결제 승인 확인 실패(토스 confirm)");
                return "cashresult";
            }

            // [CHANGED] 트랜잭션 성공 후에만 중복처리 방지 세션값 저장
            session.setAttribute("toss_processed_order_id", orderId);

            // 화면 출력용
            MemberDTO sel = new MemberDTO();
            sel.setCondition("MEMBER_MYPAGE");
            sel.setMemberId(memberId);
            MemberDTO memberData = memberService.selectOne(sel);
            int totalCash = (memberData == null) ? 0 : memberData.getMemberCash();

            model.addAttribute("payResult", "SUCCESS");
            model.addAttribute("payMethod", "토스페이");
            model.addAttribute("totalAmount", String.format("%,d", amount));
            model.addAttribute("totalCash", String.format("%,d", totalCash));
            model.addAttribute("approvedAt", java.time.LocalDateTime.now()
                    .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));

            return "cashresult";

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("payResult", "FAIL");
            model.addAttribute("payMethod", "토스페이");
            model.addAttribute("message", e.getMessage() == null ? "토스 결제 성공 처리 실패" : e.getMessage());
            return "cashresult";
        }
    }

    /**
     * 토스 결제 실패 콜백
     * TossPayments는 failUrl로 code, message(및 orderId) 등을 전달합니다.
     */
    @GetMapping("/payment/toss/fail")
    public String tossFail(@RequestParam(value = "code", required = false) String code,
                           @RequestParam(value = "message", required = false) String message,
                           @RequestParam(value = "orderId", required = false) String orderId,
                           HttpSession session,
                           Model model) {

        model.addAttribute("payResult", "FAIL");
        model.addAttribute("payMethod", "토스페이");

        String msg = "결제에 실패했습니다.";
        if (message != null && !message.isBlank()) msg = message;
        if (code != null && !code.isBlank()) msg = msg + " (" + code + ")";
        model.addAttribute("message", msg);


        // ================================
        // [ADD] READY -> CANCEL/FAIL 상태 반영
        // ================================
        Integer memberId = (Integer) session.getAttribute("memberId");
        if (memberId != null && orderId != null && !orderId.isBlank()) {

            boolean isCancel = "PAY_PROCESS_CANCELED".equalsIgnoreCase(code)
                            || "USER_CANCEL".equalsIgnoreCase(code); // 환경에 따라 다를 수 있어 대비

            if (isCancel) {
                cashChargeService.cancelReadyTx(memberId, orderId, "TOSSPAY"); // 아래 서비스 메서드 추가
            } else {
                cashChargeService.failReadyTx(memberId, orderId, "TOSSPAY");   // 아래 서비스 메서드 추가
            }

            // 세션 잔재 제거 (중복/교차 결제 방지)
            session.removeAttribute("toss_pending_order_id");
            session.removeAttribute("toss_processed_order_id");
        }

        return "cashresult";
    }
}