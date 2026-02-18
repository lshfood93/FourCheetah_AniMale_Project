package fourcheetah.animale.web.controller.member;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.repository.member.MemberDAO;
import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/payment/kakaopay")
public class KakaoPayApproveController {

    private static final String READY_URL   = "https://open-api.kakaopay.com/online/v1/payment/ready";
    private static final String APPROVE_URL = "https://open-api.kakaopay.com/online/v1/payment/approve";

    @Value("${kakaopay.cid}")
    private String cid;

    @Value("${kakaopay.secret}")
    private String secretKey;

    private final MemberDAO memberDAO;

    public KakaoPayApproveController(MemberDAO memberDAO) {
        this.memberDAO = memberDAO;
    }

    @PostMapping("/ready")
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

        // baseUrl 자동 (http://localhost:8088 같은 거)
        String baseUrl = ServletUriComponentsBuilder.fromCurrentContextPath().build().toUriString();

        String partnerOrderId = "CASH_" + UUID.randomUUID();
        String partnerUserId  = String.valueOf(memberId);

        String approvalUrl = baseUrl + "/payment/kakaopay/approve";
        String cancelUrl   = baseUrl + "/payment/kakaopay/cancel";
        String failUrl     = baseUrl + "/payment/kakaopay/fail";

        try {
            // 설정값 체크 로그(앞부분만)
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

            session.setAttribute("kakaopay_tid", tid);
            session.setAttribute("kakaopay_partner_order_id", partnerOrderId);
            session.setAttribute("kakaopay_partner_user_id", partnerUserId);
            session.setAttribute("kakaopay_total_amount", cashCharge);

            return "redirect:" + nextRedirectPcUrl;

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("payResult", "FAIL");
            model.addAttribute("message", e.getMessage() == null ? "결제 준비(READY) 실패" : e.getMessage());
            return "cashresult";
        }
    }

    @GetMapping("/approve")
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
        String partnerUserId  = (String) session.getAttribute("kakaopay_partner_user_id");
        Integer cashCharge    = (Integer) session.getAttribute("kakaopay_total_amount");

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

            MemberDTO upd = new MemberDTO();
            upd.setCondition("MEMBER_CASH_PLUS");
            upd.setMemberId(memberId);
            upd.setMemberPayCash(approvedTotal);

            boolean ok = memberDAO.update(upd);
            if (!ok) {
                model.addAttribute("payResult", "FAIL");
                model.addAttribute("message", "캐시 충전 DB 반영 실패");
                return "cashresult";
            }

            MemberDTO sel = new MemberDTO();
            sel.setCondition("MEMBER_MYPAGE");
            sel.setMemberId(memberId);
            MemberDTO memberData = memberDAO.selectOne(sel);
            int totalCash = (memberData == null) ? 0 : memberData.getMemberCash();

            session.setAttribute("kakaopay_processed_order_id", partnerOrderId);

            model.addAttribute("payResult", "SUCCESS");
            model.addAttribute("totalAmount", String.format("%,d", approvedTotal));
            model.addAttribute("totalCash", String.format("%,d", totalCash));
            if (resObj.has("approved_at") && !resObj.get("approved_at").isJsonNull()) {
                model.addAttribute("approvedAt", resObj.get("approved_at").getAsString());
            }
            return "cashresult";

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

    @GetMapping("/cancel")
    public String cancel(Model model) {
        model.addAttribute("payResult", "FAIL");
        model.addAttribute("message", "결제가 취소되었습니다.");
        return "cashresult";
    }

    @GetMapping("/fail")
    public String fail(Model model) {
        model.addAttribute("payResult", "FAIL");
        model.addAttribute("message", "결제에 실패했습니다.");
        return "cashresult";
    }

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
}
