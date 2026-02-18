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
        // ✅ 여기 컬럼/값은 너희 DB에 맞게 수정
        int updated = jdbcTemplate.update(
                "UPDATE MEMBER SET MEMBER_STATUS = 'WITHDRAWN' WHERE MEMBER_ID = ?",
                memberId
        );
        return updated == 1;
    }
}
