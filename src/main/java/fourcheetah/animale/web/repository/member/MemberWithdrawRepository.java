package fourcheetah.animale.web.repository.member;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class MemberWithdrawRepository {

    private final JdbcTemplate jdbcTemplate;

    public MemberWithdrawRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public boolean withdraw(int memberId) {
        int updated = jdbcTemplate.update(
                "UPDATE MEMBER SET MEMBER_STATUS = 'WITHDRAWN' WHERE MEMBER_ID = ?",
                memberId
        );
        return updated == 1;
    }
}
