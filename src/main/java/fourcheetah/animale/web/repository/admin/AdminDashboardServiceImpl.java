package fourcheetah.animale.web.repository.admin;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.service.admin.AdminDashboardService;
import fourcheetah.animale.web.repository.admin.AdminCashDAO;
import fourcheetah.animale.web.dto.admin.CashStatsDTO;

import java.util.*;

@Service
public class AdminDashboardServiceImpl implements AdminDashboardService {

    @Autowired
    private AdminCashDAO adminCashDAO;

    @Override
    public Map<String, Object> getDashboardData(int year) {
        System.out.println("[Service] getDashboardData - year=" + year);
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            // =========================================================
            // 1. 월별 데이터 조회 (12개월) - DTO 사용!
            // =========================================================
            
            List<CashStatsDTO> monthlyDataList = new ArrayList<>();
            int yearlyTotalAmount = 0;
            
            for (int m = 1; m <= 12; m++) {
                CashStatsDTO monthStats = adminCashDAO.selectMonthlyStats(year, m);
                monthlyDataList.add(monthStats);
                
                // DTO에서 직접 가져오기 (타입 안전!)
                yearlyTotalAmount += monthStats.getTotalAmount();
            }
            
            result.put("monthlyData", monthlyDataList);
            result.put("yearlyTotalAmount", yearlyTotalAmount);
            
            // =========================================================
            // 2. 전년 대비 증감률 계산
            // =========================================================
            
            int lastYearAmount = 0;
            
            for (int m = 1; m <= 12; m++) {
                CashStatsDTO lastYearData = adminCashDAO.selectMonthlyStats(year - 1, m);
                lastYearAmount += lastYearData.getTotalAmount();
            }
            
            double yearGrowthRate = 0.0;
            if (lastYearAmount > 0) {
                yearGrowthRate = ((yearlyTotalAmount - lastYearAmount) * 100.0) / lastYearAmount;
                yearGrowthRate = Math.round(yearGrowthRate * 10.0) / 10.0;
            }
            
            result.put("lastYearAmount", lastYearAmount);
            result.put("yearGrowthRate", yearGrowthRate);
            
            // =========================================================
            // 3. 결제 수단 비율 계산
            // =========================================================
            
            int kakaopayAmount = 0;
            int tosspayAmount = 0;
            
            for (CashStatsDTO data : monthlyDataList) {
                kakaopayAmount += data.getKakaopayAmount();
                tosspayAmount += data.getTosspayAmount();
            }
            
            int totalPaymentAmount = kakaopayAmount + tosspayAmount;
            double kakaopayRate = 0.0;
            double tosspayRate = 0.0;
            
            if (totalPaymentAmount > 0) {
                kakaopayRate = Math.round((kakaopayAmount * 1000.0) / totalPaymentAmount) / 10.0;
                tosspayRate = Math.round((tosspayAmount * 1000.0) / totalPaymentAmount) / 10.0;
            }
            
            Map<String, Object> paymentStats = new HashMap<>();
            paymentStats.put("kakaopayAmount", kakaopayAmount);
            paymentStats.put("tosspayAmount", tosspayAmount);
            paymentStats.put("kakaopayRate", kakaopayRate);
            paymentStats.put("tosspayRate", tosspayRate);
            
            result.put("paymentStats", paymentStats);
            
            System.out.println("[Service] 데이터 조회 완료");
            
        } catch (Exception e) {
            System.out.println("[Service 에러] " + e.getMessage());
            e.printStackTrace();
            
            // 빈 데이터로 초기화
            result.put("monthlyData", new ArrayList<>());
            result.put("yearlyTotalAmount", 0);
            result.put("lastYearAmount", 0);
            result.put("yearGrowthRate", 0.0);
            result.put("paymentStats", Map.of(
                "kakaopayAmount", 0,
                "tosspayAmount", 0,
                "kakaopayRate", 0.0,
                "tosspayRate", 0.0
            ));
        }
        
        return result;
    }
}