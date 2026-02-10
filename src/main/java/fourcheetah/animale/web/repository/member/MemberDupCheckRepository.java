package fourcheetah.animale.web.repository.member;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class MemberDupCheckRepository {

    private final JdbcTemplate jdbcTemplate;

    public MemberDupCheckRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public boolean existsByName(String memberName) {
        Integer cnt = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM MEMBER WHERE MEMBER_NAME = ?",
                Integer.class,
                memberName
        );
        return cnt != null && cnt > 0;
    }

    public boolean existsByNickname(String memberNickname) {
        Integer cnt = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM MEMBER WHERE MEMBER_NICKNAME = ?",
                Integer.class,
                memberNickname
        );
        return cnt != null && cnt > 0;
    }

    public boolean existsByEmail(String memberEmail) {
        Integer cnt = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM MEMBER WHERE MEMBER_EMAIL = ?",
                Integer.class,
                memberEmail
        );
        return cnt != null && cnt > 0;
    }
}
