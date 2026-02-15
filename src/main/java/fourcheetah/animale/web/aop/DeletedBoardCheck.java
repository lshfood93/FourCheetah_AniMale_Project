package fourcheetah.animale.web.aop;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 삭제된 게시글 접근 차단 어노테이션
 * 
 * 사용 예시:
 * @DeletedBoardCheck - 삭제된 게시글 접근 차단
 * @DeletedBoardCheck(allowAdmin = true) - 관리자는 허용
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface DeletedBoardCheck {
    
    /**
     * 관리자 접근 허용 여부
     * 
     * 기본값: false (관리자도 차단)
     * true로 설정 시 관리자는 삭제된 게시글에 접근 가능
     */
    boolean allowAdmin() default false;
}