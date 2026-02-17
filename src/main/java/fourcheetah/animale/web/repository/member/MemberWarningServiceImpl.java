package fourcheetah.animale.web.repository.member;

import java.time.LocalDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.member.MemberWarningDTO;
import fourcheetah.animale.web.service.member.MemberWarningService;

/**
 * 회원 제재 관리 서비스 구현체
 */
@Service
public class MemberWarningServiceImpl implements MemberWarningService {

    @Autowired
    private MemberWarningDAO memberWarningDAO;
    
    /**
     * 회원의 최신 제재 조회
     */
    @Override
    public MemberWarningDTO selectLatestWarning(int memberId) {
        System.out.println("[MemberWarningService] selectLatestWarning 호출 - memberId=" + memberId);
        
        MemberWarningDTO warning = memberWarningDAO.selectLatestWarning(memberId);
        
        if (warning == null) {
            System.out.println("[MemberWarningService] 제재 없음 (정상 회원)");
            return null;
        }
        
        System.out.println("[MemberWarningService] 제재 조회 완료");
        System.out.println("  - warningType=" + warning.getWarningType());
        System.out.println("  - endAt=" + warning.getEndAt());
        
        return warning;
    }
    
    /**
     * 제재 이력 저장
     */
    @Override
    public boolean insertWarning(MemberWarningDTO dto) {
        System.out.println("[MemberWarningService] insertWarning 호출");
        
        if (dto.getMemberId() <= 0 || dto.getIssuedBy() <= 0) {
            System.out.println("[MemberWarningService] 필수 파라미터 누락");
            return false;
        }
        
        if (dto.getWarningType() == null || dto.getWarningType().trim().isEmpty()) {
            System.out.println("[MemberWarningService] warningType 누락");
            return false;
        }
        
        int result = memberWarningDAO.insertWarning(dto);
        
        return result > 0;
    }
    
    /**
     * 회원의 활성 제재 개수 조회
     */
    @Override
    public int selectActiveWarningCount(int memberId) {
        System.out.println("[MemberWarningService] selectActiveWarningCount 호출 - memberId=" + memberId);
        
        return memberWarningDAO.selectActiveWarningCount(memberId);
    }
    
    /**
     * 제재 상태 확인 (AOP용)
     * 
     * @return "ACTIVE" (정상) / "WARNING" / "SUSPEND_7D" / "SUSPEND_30D" / "BAN"
     */
    @Override
    public String checkSanctionStatus(int memberId) {
        System.out.println("[MemberWarningService] checkSanctionStatus 호출 - memberId=" + memberId);
        
        MemberWarningDTO warning = memberWarningDAO.selectLatestWarning(memberId);
        
        // 제재 없음
        if (warning == null) {
            System.out.println("[MemberWarningService] 제재 없음 → ACTIVE");
            return "ACTIVE";
        }
        
        String warningType = warning.getWarningType();
        System.out.println("[MemberWarningService] 제재 타입=" + warningType);
        
        // 영구 정지
        if ("BAN".equals(warningType)) {
            System.out.println("[MemberWarningService] 영구 정지 → BAN");
            return "BAN";
        }
        
        // 기간 정지 (7일/30일)
        if ("SUSPEND_7D".equals(warningType) || "SUSPEND_30D".equals(warningType)) {
            LocalDateTime endAt = warning.getEndAt();
            
            if (endAt == null) {
                // 종료일 없음 (데이터 오류)
                System.out.println("[MemberWarningService] 종료일 없음 (데이터 오류) → WARNING");
                return "WARNING";
            }
            
            // 현재 시간이 종료일 이전 → 정지 중
            if (LocalDateTime.now().isBefore(endAt)) {
                System.out.println("[MemberWarningService] 정지 기간 중 → " + warningType);
                return warningType;
            }
            
            // 정지 종료 → 정상
            System.out.println("[MemberWarningService] 정지 종료 → ACTIVE");
            return "ACTIVE";
        }
        
        // WARNING (경고)
        if ("WARNING".equals(warningType)) {
            System.out.println("[MemberWarningService] 경고 상태 → WARNING");
            return "WARNING";
        }
        
        // 기타 (정상 처리)
        System.out.println("[MemberWarningService] 기타 → ACTIVE");
        return "ACTIVE";
    }
}