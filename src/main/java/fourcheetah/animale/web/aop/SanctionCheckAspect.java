package fourcheetah.animale.web.aop;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import fourcheetah.animale.web.dto.member.MemberWarningDTO;
import fourcheetah.animale.web.service.member.MemberWarningService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

/**
 * 제재 회원 기능 제한 AOP
 * 
 * @SanctionCheck 어노테이션이 붙은 메서드 실행 전에
 * DB에서 최신 제재 정보를 조회하여 제재 회원의 기능을 제한
 * 
 * 제재 타입:
 * - WARNING: 경고 (기본적으로 모든 기능 사용 가능, allowTypes로 제어)
 * - SUSPEND_7D: 7일 정지 (게시글/댓글 작성 차단)
 * - SUSPEND_30D: 30일 정지 (게시글/댓글 작성 차단)
 * - BAN: 영구 정지 (강제 로그아웃)
 */
@Aspect
@Component
public class SanctionCheckAspect {

    @Autowired
    private MemberWarningService memberWarningService;
    
    /**
     * @SanctionCheck 어노테이션이 붙은 메서드 실행 전 제재 상태 체크
     */
    @Around("@annotation(sanctionCheck)")
    public Object checkSanction(ProceedingJoinPoint joinPoint, SanctionCheck sanctionCheck) throws Throwable {
        
        System.out.println("========================================");
        System.out.println("[AOP] SanctionCheck 실행 - " + joinPoint.getSignature().getName());
        
        // 1. HttpServletRequest 가져오기
        ServletRequestAttributes attributes = 
            (ServletRequestAttributes) RequestContextHolder.currentRequestAttributes();
        HttpServletRequest request = attributes.getRequest();
        HttpSession session = request.getSession(false);
        
        // 2. 로그인 체크 (비로그인은 통과)
        if (session == null || session.getAttribute("memberId") == null) {
            System.out.println("[AOP] 비로그인 - 통과");
            System.out.println("========================================");
            return joinPoint.proceed();
        }
        
        Integer memberId = (Integer) session.getAttribute("memberId");
        System.out.println("[AOP] 로그인 회원 - memberId=" + memberId);
        
        // 3. DB에서 최신 제재 정보 조회
        System.out.println("[AOP] DB 조회 시작");
        MemberWarningDTO latestWarning = memberWarningService.selectLatestWarning(memberId);
        
        // 4. 제재 없음 → 통과
        if (latestWarning == null) {
            System.out.println("[AOP] 제재 없음 - 통과");
            System.out.println("========================================");
            return joinPoint.proceed();
        }
        
        String warningType = latestWarning.getWarningType();
        System.out.println("[AOP] 제재 정보 조회 완료");
        System.out.println("  - warningType=" + warningType);
        System.out.println("  - endAt=" + latestWarning.getEndAt());
        
        // 5. 영구 정지 (BAN) → 강제 로그아웃
        if ("BAN".equals(warningType)) {
            System.out.println("[AOP] 영구 정지 - 강제 로그아웃");
            System.out.println("========================================");
            return handleBan(joinPoint, request, session);
        }
        
        // 6. 기간 정지 (SUSPEND_7D / SUSPEND_30D) → 종료일 체크
        if ("SUSPEND_7D".equals(warningType) || "SUSPEND_30D".equals(warningType)) {
            LocalDateTime endAt = latestWarning.getEndAt();
            
            if (endAt != null && LocalDateTime.now().isBefore(endAt)) {
                // 아직 정지 기간 중 → 차단
                System.out.println("[AOP] 정지 기간 중 - 차단");
                System.out.println("  - 종료일=" + endAt);
                System.out.println("========================================");
                return handleSuspend(joinPoint, request, endAt, latestWarning.getReason());
            }
            
            // 정지 종료 → 통과
            System.out.println("[AOP] 정지 종료 - 통과");
            System.out.println("========================================");
            return joinPoint.proceed();
        }
        
        // 7. WARNING (경고) → allowTypes 체크
        if ("WARNING".equals(warningType)) {
            String[] allowTypes = sanctionCheck.allowTypes();
            
            // allowTypes에 WARNING 포함 → 통과
            for (String allowType : allowTypes) {
                if ("WARNING".equals(allowType)) {
                    System.out.println("[AOP] WARNING 허용 - 통과");
                    System.out.println("========================================");
                    return joinPoint.proceed();
                }
            }
            
            // allowTypes에 WARNING 없음 → 차단
            System.out.println("[AOP] WARNING 차단");
            System.out.println("========================================");
            return handleWarning(joinPoint, request);
        }
        
        // 8. 기타 (정상 처리)
        System.out.println("[AOP] 기타 제재 타입 - 통과");
        System.out.println("========================================");
        return joinPoint.proceed();
    }
    
    /**
     * 영구 정지 처리 (BAN)
     */
    private Object handleBan(ProceedingJoinPoint joinPoint, HttpServletRequest request, HttpSession session) {
        // 강제 로그아웃
        session.invalidate();
        
        String methodName = joinPoint.getSignature().getName();
        
        // RestController 메서드인 경우 ResponseEntity 반환
        if (isRestControllerMethod(methodName)) {
            Map<String, Object> body = new HashMap<>();
            body.put("fail", "영구 정지된 계정입니다. 관리자에게 문의하세요.");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(body);
        }
        
        // 일반 Controller 메서드인 경우 message 반환
        request.setAttribute("msg", "영구 정지된 계정입니다.\n관리자에게 문의하세요.");
        request.setAttribute("location", "/login");
        return "message";
    }
    
    /**
     * 기간 정지 처리 (SUSPEND_7D / SUSPEND_30D)
     */
    private Object handleSuspend(ProceedingJoinPoint joinPoint, HttpServletRequest request, 
                                  LocalDateTime endAt, String reason) {
        
        // 종료일 포맷팅
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy년 MM월 dd일 HH시 mm분");
        String endAtStr = (endAt != null) ? endAt.format(formatter) : "미정";
        
        String reasonStr = (reason != null && !reason.trim().isEmpty()) ? reason : "관리자 제재";
        
        String methodName = joinPoint.getSignature().getName();
        
        // RestController 메서드인 경우 ResponseEntity 반환
        if (isRestControllerMethod(methodName)) {
            Map<String, Object> body = new HashMap<>();
            body.put("fail", "계정이 정지되어 이 기능을 사용할 수 없습니다.");
            body.put("endAt", endAtStr);
            body.put("reason", reasonStr);
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(body);
        }
        
        // 일반 Controller 메서드인 경우 message 반환
        String msg = "계정이 정지되어 이 기능을 사용할 수 없습니다.\n\n" +
                     "정지 종료: " + endAtStr + "\n" +
                     "사유: " + reasonStr;
        
        request.setAttribute("msg", msg);
        request.setAttribute("location", "/mainPage");
        return "message";
    }
    
    /**
     * 경고 처리 (WARNING)
     */
    private Object handleWarning(ProceedingJoinPoint joinPoint, HttpServletRequest request) {
        String methodName = joinPoint.getSignature().getName();
        
        // RestController 메서드인 경우 ResponseEntity 반환
        if (isRestControllerMethod(methodName)) {
            Map<String, Object> body = new HashMap<>();
            body.put("fail", "경고를 받은 상태로 이 기능을 사용할 수 없습니다.");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(body);
        }
        
        // 일반 Controller 메서드인 경우 message 반환
        request.setAttribute("msg", "경고를 받은 상태로 이 기능을 사용할 수 없습니다.");
        request.setAttribute("location", "/mainPage");
        return "message";
    }
    
    /**
     * RestController 메서드 판별
     */
    private boolean isRestControllerMethod(String methodName) {
        // BoardApiController, UserReportController의 메서드들
        return "toggleLike".equals(methodName)
            || "reportBoard".equals(methodName)
            || "replyListOrder".equals(methodName)
            || "likeMemberList".equals(methodName);
    }
}