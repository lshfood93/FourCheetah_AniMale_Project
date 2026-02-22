package fourcheetah.animale.web.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * PasswordConfig
 *
 * 역할:
 * - 비밀번호 해시/검증에 사용할 PasswordEncoder Bean 등록
 *
 * 왜 필요한가?
 * - 회원가입/비밀번호변경 때: encode(rawPassword)
 * - 로그인/현재비밀번호확인 때: matches(rawPassword, encodedPassword)
 *
 * 참고:
 * - BCryptPasswordEncoder는 솔트를 내부적으로 자동 처리함
 * - 서비스에서는 BCryptPasswordEncoder 구체타입보다
 *   PasswordEncoder 인터페이스로 주입받는 것을 권장
 */
@Configuration // ✅ 스프링 설정 클래스임을 표시 (Bean 등록용)
public class PasswordConfig {

    /**
     * PasswordEncoder Bean 등록
     *
     * 반환 타입은 인터페이스(PasswordEncoder)로 두고,
     * 실제 구현체는 BCryptPasswordEncoder를 사용한다.
     *
     * 장점:
     * - 나중에 Argon2 등으로 바꾸더라도 서비스 코드는 덜 바뀜
     * - 테스트/유지보수에 유리함
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        // BCrypt 사용 (솔트 자동 포함)
        // 기본 strength(로그라운드)는 10
        // 나중에 성능/보안 정책에 따라 new BCryptPasswordEncoder(12) 같이 조정 가능
        return new BCryptPasswordEncoder();
    }
}