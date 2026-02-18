package fourcheetah.animale.web.repository.member;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class WithdrawRepository {

    private final JdbcTemplate jdbcTemplate;

    public WithdrawRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public boolean withdraw(int memberId) {
        String sql = "UPDATE MEMBER SET MEMBER_ROLE = ? WHERE MEMBER_ID = ?";
        return jdbcTemplate.update(sql, "WITHDRAWN", memberId) > 0;
    }
}