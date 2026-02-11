package fourcheetah.animale.web.controller.admin;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import fourcheetah.animale.web.service.admin.CashChargeService;

@RestController
@RequestMapping("/api/admin/cash")
public class CashChargeApiController {

	@Autowired
    private CashChargeService cashChargeService;

    // 대시보드 데이터 조회
    @GetMapping("/dashboard")
    public Map<String, Object> dashboard(
            @RequestParam int year,
            @RequestParam int month
    ) {
        return cashChargeService.getDashboardSummary(year, month);
    }
}
