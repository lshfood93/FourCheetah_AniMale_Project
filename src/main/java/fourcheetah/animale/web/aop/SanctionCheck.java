package fourcheetah.animale.web.aop;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 제재 회원 기능 제한 어노테이션
 * 
 * 사용 예시:
 * @SanctionCheck - 모든 제재 회원 차단
 * @SanctionCheck(allowTypes = {"WARNING"}) - WARNING 회원은 허용
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface SanctionCheck {
    
    /**
     * 허용할 제재 타입 목록
     * 
     * 기본값: 빈 배열 (모든 제재 회원 차단)
     * 
     * 예시:
     * - allowTypes = {"WARNING"} → 경고 회원만 허용
     * - allowTypes = {"WARNING", "SUSPEND_7D"} → 경고+7일정지 허용
     */
    String[] allowTypes() default {};
}