package fourcheetah.animale.web.controller.admin;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import fourcheetah.animale.web.service.admin.CashChargeService;
import fourcheetah.animale.web.service.admin.CashChargeServiceImpl;
import jakarta.servlet.http.HttpSession;

@Controller
public class CashChargeController {

	@Autowired
    private CashChargeServiceImpl cashChargeService;

   

    // =========================================================
    // (V) 캐시 대시보드 페이지 이동
    // - 프론트 메뉴 클릭 시 이동용
    // =========================================================
	@GetMapping("/admindashboard")
	public String cashDashboardMain(HttpSession session) {
	    if (!isAdmin(session)) return "redirect:/mainPage";
	    return "/admin/admindashboardmain"; // viewName은 그대로(네 JSP 경로)
	}

    // =========================================================
    // (API1) 월별 캐시 충전량(년 기준) - cash_amount SUM
    // GET /admin/api/cash/monthly?year=2026
    //
    // Response:
    //  totalChargeByMonth: [{month:1, amount:...}, ...]
    //  yearTotalChargeAmount: ...
    // =========================================================
    @GetMapping(value = "/admin/api/cash/monthly", produces = "application/json; charset=UTF-8")
    public ResponseEntity<?> monthly(
            @RequestParam(name = "year", required = false) Integer year,
            HttpSession session
    ) {
        if (!isAdmin(session)) {
            return ResponseEntity.status(403).body(Map.of("result", "FORBIDDEN"));
        }

        int y = (year == null) ? cashChargeService.getCurrentYear() : year;

        // ✅ 핵심: Service가 cash_amount 기준 월별/연합계를 만들어줌
        Map<String, Object> res = cashChargeService.getMonthlyCashChart(y);
        return ResponseEntity.ok(res);
    }

    // =========================================================
    // (API2) 결제수단 비율(월 기준) - cash_amount SUM 비율
    // GET /admin/api/cash/providerRatio?year=2026&month=2
    // - month 생략 시 현재월 자동
    //
    // Response:
    //  providerRatioList: [{provider, amount, ratio}, ...]
    //  thisMonthTotal, lastMonthTotal, deltaPercent, deltaLabel
    // =========================================================
    @GetMapping(value = "/admin/api/cash/providerRatio", produces = "application/json; charset=UTF-8")
    public ResponseEntity<?> providerRatio(
            @RequestParam(name = "year", required = false) Integer year,
            @RequestParam(name = "month", required = false) Integer month,
            HttpSession session
    ) {
        if (!isAdmin(session)) {
            return ResponseEntity.status(403).body(Map.of("result", "FORBIDDEN"));
        }

        int y = (year == null) ? cashChargeService.getCurrentYear() : year;
        int m = (month == null) ? cashChargeService.getCurrentMonth() : month;

        // ✅ 핵심 방어: month 범위 체크
        if (m < 1 || m > 12) {
            return ResponseEntity.badRequest().body(Map.of("result", "INVALID_MONTH"));
        }

        Map<String, Object> res = cashChargeService.getProviderRatio(y, m);
        return ResponseEntity.ok(res);
    }

    // =========================================================
    // (API3) 월 충전 증감(현재월 vs 전월) - cash_amount SUM
    // GET /admin/api/cash/monthDelta?year=2026&month=2
    // - month 생략 시 현재월 자동
    //
    // Response:
    //  thisMonthCharge, lastMonthCharge, deltaAmount, deltaPercent, deltaLabel
    // =========================================================
    @GetMapping(value = "/admin/api/cash/monthDelta", produces = "application/json; charset=UTF-8")
    public ResponseEntity<?> monthDelta(
            @RequestParam(name = "year", required = false) Integer year,
            @RequestParam(name = "month", required = false) Integer month,
            HttpSession session
    ) {
        if (!isAdmin(session)) {
            return ResponseEntity.status(403).body(Map.of("result", "FORBIDDEN"));
        }

        int y = (year == null) ? cashChargeService.getCurrentYear() : year;
        int m = (month == null) ? cashChargeService.getCurrentMonth() : month;

        if (m < 1 || m > 12) {
            return ResponseEntity.badRequest().body(Map.of("result", "INVALID_MONTH"));
        }

        Map<String, Object> res = cashChargeService.getMonthDelta(y, m);
        return ResponseEntity.ok(res);
    }

    // =========================================================
    // 공통: 관리자 권한 체크 (세션 기반)
    // =========================================================
    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        Object roleObj = session.getAttribute("memberRole");
        return roleObj != null && "ADMIN".equals(String.valueOf(roleObj));
    }
}
