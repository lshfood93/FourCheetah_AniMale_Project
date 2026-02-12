package fourcheetah.animale.web.service.admin;

import java.util.Map;

public interface AdminDashboardService {
    
    /**
     * 대시보드 전체 데이터 조회
     * @param year 조회 연도
     * @return 대시보드 데이터
     */
    Map<String, Object> getDashboardData(int year);
}