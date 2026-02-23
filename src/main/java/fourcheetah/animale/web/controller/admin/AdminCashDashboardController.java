package fourcheetah.animale.web.controller.admin;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import jakarta.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.dto.admin.CashChargeDTO;
import fourcheetah.animale.web.service.admin.CashChargeService;

@RestController
public class AdminCashDashboardController {

    @Autowired
    private CashChargeService cashChargeService;

    // DAO에 쿼리 추가 안 하고 "승인 건수"만 뽑기 위해 사용
    @Autowired
    private JdbcTemplate jdbcTemplate;

 // [CHANGED] approved_at NULL 허용 → created_at로 fallback 해서 집계 안정화
    private static final String DASHBOARD_MONTH_APPROVED_COUNT =
        "SELECT COUNT(*) " +
        "FROM CASH_CHARGE " +
        "WHERE status='APPROVED' " +
        "  AND YEAR(COALESCE(approved_at, created_at))=? " +
        "  AND MONTH(COALESCE(approved_at, created_at))=?";

    @GetMapping("/api/admin/cash/admindashboard")
    public ResponseEntity<Map<String, Object>> dashboard(
            HttpSession session, CashChargeDTO cashChargeDTO
    ) {

        // =========================================================
        // 0) 권한 체크 (API도 방어)
        // =========================================================
        if (session == null || session.getAttribute("memberId") == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                "ok", false,
                "message", "로그인이 필요합니다."
            ));
        }

        String role = (String) session.getAttribute("memberRole");
        if (role == null || !role.equalsIgnoreCase("ADMIN")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                "ok", false,
                "message", "관리자만 접근할 수 있습니다."
            ));
        }

        // =========================================================
        // 1) year/month 기본값 (현재)
        // =========================================================
        LocalDate now = LocalDate.now();
    
        Integer year = cashChargeDTO.getYear();
        Integer month = cashChargeDTO.getMonth();

        int y = (year == null) ? now.getYear() : year;
        int m = (month == null) ? now.getMonthValue() : month;

        
        
        if (m < 1 || m > 12) {
            return ResponseEntity.badRequest().body(Map.of(
                "ok", false,
                "message", "month는 1~12만 가능합니다."
            ));
        }

        // =========================================================
        // 2) 서비스 집계 호출 (기존 로직 그대로 사용)
        // =========================================================
        Map<String, Object> summary = cashChargeService.getDashboardSummary(y, m);

        int thisMonthTotal = (int) summary.getOrDefault("thisMonthTotal", 0);
        int lastMonthTotal = (int) summary.getOrDefault("lastMonthTotal", 0);
        double momPercent = (double) summary.getOrDefault("momPercent", 0.0);

        @SuppressWarnings("unchecked")
        List<CashChargeDTO> providerList = (List<CashChargeDTO>) summary.get("providerList");

        @SuppressWarnings("unchecked")
        List<CashChargeDTO> yearMonthly = (List<CashChargeDTO>) summary.get("yearMonthly");


        // =========================================================
        // 3) [CHANGED] 승인 건수(이번달/전월) 둘 다 계산
        // =========================================================
        Integer cnt = jdbcTemplate.queryForObject(DASHBOARD_MONTH_APPROVED_COUNT, Integer.class, y, m);
        int approvedCount = (cnt == null) ? 0 : cnt;

        YearMonth prevYm = YearMonth.of(y, m).minusMonths(1);
        Integer prevCnt = jdbcTemplate.queryForObject(
            DASHBOARD_MONTH_APPROVED_COUNT,
            Integer.class,
            prevYm.getYear(),
            prevYm.getMonthValue()
        );
        int lastMonthApprovedCount = (prevCnt == null) ? 0 : prevCnt;

        int days;
        if (y == now.getYear() && m == now.getMonthValue()) {
            days = now.getDayOfMonth();
        } else {
            days = YearMonth.of(y, m).lengthOfMonth();
        }
        int dailyAvg = (days <= 0) ? 0 : (thisMonthTotal / days);

        // =========================================================
        // 4) 수단별 금액/비율 가공 (KAKAOPAY / TOSSPAY)
        // =========================================================
        int kakaoAmount = 0;
        int tossAmount = 0;

        if (providerList != null) {
            for (CashChargeDTO row : providerList) {
                String p = row.getProvider();
                int amt = row.getCashAmount(); // DAO에서 total을 cashAmount에 담아줌
                if (p == null) continue;

                if ("KAKAOPAY".equalsIgnoreCase(p)) kakaoAmount = amt;
                if ("TOSSPAY".equalsIgnoreCase(p)) tossAmount = amt;
            }
        }

        int totalForPct = thisMonthTotal; // 이번달 총액 기준
        int kakaoPct = (totalForPct == 0) ? 0 : (int) Math.round((kakaoAmount * 100.0) / totalForPct);
        int tossPct  = (totalForPct == 0) ? 0 : (int) Math.round((tossAmount  * 100.0) / totalForPct);

        // =========================================================
        // 5) 연간 월별 배열(1~12)로 변환 (차트 바로 사용)
        // =========================================================
        int[] monthlyAmounts = new int[12]; // 기본 0

        if (yearMonthly != null) {
            for (CashChargeDTO row : yearMonthly) {
                int mm = row.getMonth();      // 1~12
                int amt = row.getCashAmount();// DAO에서 total을 cashAmount에 담아줌
                if (mm >= 1 && mm <= 12) {
                    monthlyAmounts[mm - 1] = amt;
                }
            }
        }

        // =========================================================
        // 6) [CHANGED] 전월 데이터 유무 판정은 "전월 승인건수" 기반이 더 정확
        // =========================================================
        boolean hasPrev = lastMonthApprovedCount > 0;
        String direction = "NONE";
        int diffAmount = thisMonthTotal - lastMonthTotal;

        if (hasPrev && lastMonthTotal > 0) {
            direction = (diffAmount >= 0) ? "UP" : "DOWN";
        } else {
            // 전월이 없거나 전월 총액이 0이면 비교 퍼센트는 null로
            momPercent = 0.0; // 내부값은 의미 없지만 응답은 아래에서 null 처리
        }

        // =========================================================
        // 7) 최종 응답 구성
        // =========================================================
        Map<String, Object> res = new HashMap<>();
        res.put("ok", true);

        res.put("year", y);
        res.put("month", m);

        // 기존 키 유지
        res.put("thisMonthTotal", thisMonthTotal);
        res.put("lastMonthTotal", lastMonthTotal);
        res.put("momPercent", (hasPrev && lastMonthTotal > 0) ? momPercent : null);
        
        res.put("providerList", providerList);
        res.put("yearMonthly", yearMonthly);

        res.put("thisMonthCount", approvedCount);
        res.put("lastMonthCount", lastMonthApprovedCount);
        
        res.put("approvedCount", approvedCount);
        res.put("dailyAvg", dailyAvg);

        res.put("kakaoAmount", kakaoAmount);
        res.put("tossAmount", tossAmount);
        res.put("kakaoPct", kakaoPct);
        res.put("tossPct", tossPct);

        res.put("monthlyAmounts", monthlyAmounts);

        res.put("hasPrev", hasPrev);
        res.put("direction", direction);
        res.put("diffAmount", diffAmount);

        return ResponseEntity.ok(res);
    }
}
