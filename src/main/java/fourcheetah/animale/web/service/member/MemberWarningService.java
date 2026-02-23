package fourcheetah.animale.web.service.member;

import fourcheetah.animale.web.dto.member.MemberWarningDTO;

/**
 * 회원 제재 관리 서비스
 */
public interface MemberWarningService {
    
    /**
     * 회원의 최신 제재 조회
     * 
     * @param memberId 회원 ID
     * @return 최신 제재 정보 (없으면 null)
     */
    MemberWarningDTO selectLatestWarning(int memberId);
    
    /**
     * 제재 이력 저장
     * 
     * @param dto 제재 정보
     * @return 성공 여부
     */
    boolean insertWarning(MemberWarningDTO dto);
    
    /**
     * 회원의 활성 제재 개수 조회
     * 
     * @param memberId 회원 ID
     * @return 활성 제재 개수
     */
    int selectActiveWarningCount(int memberId);
    
    /**
     * 제재 상태 확인 (AOP용)
     * 
     * @param memberId 회원 ID
     * @return "ACTIVE" (정상) / "WARNING" (경고) / "SUSPEND_7D" / "SUSPEND_30D" / "BAN"
     */
    String checkSanctionStatus(int memberId);
}