package fourcheetah.animale.web.repository.board;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.board.BoardDTO;

@Repository
public class BoardDAO {

   @Autowired
   private JdbcTemplate jdbcTemplate; // (유지) DI 받은 JdbcTemplate

   // =========================================================
   // [공통] 좋아요 집계 서브쿼리
   private static final String LIKE_COUNT_SUBQUERY = "SELECT board_id, COUNT(*) AS like_cnt " + "FROM board_like "
         + "GROUP BY board_id";

   // =========================================================
   // SELECT ALL
   private static final String SELECT_CATEGORY_LIST = "SELECT " + "  b.board_id, b.member_id, "
         + "  m.member_role AS writer_role, "
         + "  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' ELSE m.member_nickname END AS writer_nickname, "
         + "  b.board_title, b.board_views, b.board_category, " + "  IFNULL(l.like_cnt, 0) AS like_cnt "
         + "FROM board b " + "JOIN member m ON m.member_id = b.member_id " + "LEFT JOIN (" + LIKE_COUNT_SUBQUERY
         + ") l ON l.board_id = b.board_id " + "WHERE b.board_category = ? AND m.member_role <> 'ADMIN' "
         + "ORDER BY b.board_id DESC";

   private static final String SELECT_BOARD_NOTICE_LIST = "SELECT " + "  b.board_id, b.member_id, "
         + "  m.member_role AS writer_role, " + "  m.member_nickname AS writer_nickname, "
         + "  b.board_title, b.board_views, b.board_category, " + "  IFNULL(l.like_cnt, 0) AS like_cnt "
         + "FROM board b " + "JOIN member m ON m.member_id = b.member_id " + "LEFT JOIN (" + LIKE_COUNT_SUBQUERY
         + ") l ON l.board_id = b.board_id " + "WHERE b.board_category = ? AND m.member_role = 'ADMIN' "
         + "ORDER BY b.board_id DESC";

   private static final String SELECT_MY_BOARD_WRITE_LIST = "SELECT "
	        + "  b.board_id, b.member_id, "
	        + "  m.member_role AS writer_role, "
	        + "  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' ELSE m.member_nickname END AS writer_nickname, "
	        + "  b.board_title, b.board_views, b.board_category, b.board_status, "  // board_status 추가
	        + "  IFNULL(l.like_cnt, 0) AS like_cnt "
	        + "FROM board b "
	        + "JOIN member m ON m.member_id = b.member_id "
	        + "LEFT JOIN (" + LIKE_COUNT_SUBQUERY + ") l ON l.board_id = b.board_id "
	        + "WHERE b.member_id = ? "
	        + "ORDER BY b.board_id DESC";

   private static final String SELECT_MY_BOARD_LIKE_LIST = "SELECT "
	        + "  b.board_id, b.member_id, "
	        + "  m.member_role AS writer_role, "
	        + "  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' ELSE m.member_nickname END AS writer_nickname, "
	        + "  b.board_title, b.board_views, b.board_category, b.board_status, "  // board_status 추가
	        + "  IFNULL(l.like_cnt, 0) AS like_cnt "
	        + "FROM board_like bl "
	        + "JOIN board b ON b.board_id = bl.board_id "
	        + "JOIN member m ON m.member_id = b.member_id "
	        + "LEFT JOIN (" + LIKE_COUNT_SUBQUERY + ") l ON l.board_id = b.board_id "
	        + "WHERE bl.member_id = ? "
	        + "ORDER BY bl.board_like_id DESC";

   private static final String SELECT_BOARD_LIKE_MEMBER_LIST = "SELECT " + "  bl.member_id, "
         + "  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' ELSE m.member_nickname END AS like_member_nickname "
         + "FROM board_like bl " + "JOIN member m ON m.member_id = bl.member_id " + "WHERE bl.board_id = ? "
         + "ORDER BY bl.board_like_id DESC";

   private static final String SELECT_BOARD_BEST_LIKE_LIST = "SELECT " + "  b.board_id, b.member_id, "
         + "  m.member_role AS writer_role, "
         + "  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' ELSE m.member_nickname END AS writer_nickname, "
         + "  b.board_title, b.board_views, b.board_category, " + "  COUNT(bl.member_id) AS like_cnt "
         + "FROM board b " + "JOIN member m ON m.member_id = b.member_id "
         + "JOIN board_like bl ON bl.board_id = b.board_id "
         + "WHERE b.board_category = ? AND m.member_role <> 'ADMIN' "
         + "GROUP BY b.board_id, b.member_id, m.member_role, m.member_nickname, b.board_title, b.board_views, b.board_category "
         + "HAVING COUNT(bl.member_id) >= 10 " + "ORDER BY like_cnt DESC, b.board_id DESC";

   private static final String SELECT_BOARD_SEARCH_TITLE = "SELECT " + "  b.board_id, b.member_id, "
         + "  m.member_role AS writer_role, "
         + "  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' ELSE m.member_nickname END AS writer_nickname, "
         + "  b.board_title, b.board_views, b.board_category, " + "  IFNULL(l.like_cnt, 0) AS like_cnt "
         + "FROM board b " + "JOIN member m ON m.member_id = b.member_id " + "LEFT JOIN (" + LIKE_COUNT_SUBQUERY
         + ") l ON l.board_id = b.board_id " + "WHERE b.board_category = ? AND m.member_role <> 'ADMIN' "
         + "  AND b.board_title LIKE CONCAT('%', ?, '%') " + "ORDER BY b.board_id DESC";

   private static final String SELECT_BOARD_SEARCH_WRITER = "SELECT " + "  b.board_id, b.member_id, "
         + "  m.member_role AS writer_role, " + "  m.member_nickname AS writer_nickname, "
         + "  b.board_title, b.board_views, b.board_category, " + "  IFNULL(l.like_cnt, 0) AS like_cnt "
         + "FROM board b " + "JOIN member m ON m.member_id = b.member_id " + "LEFT JOIN (" + LIKE_COUNT_SUBQUERY
         + ") l ON l.board_id = b.board_id " + "WHERE b.board_category = ? " + "  AND m.member_role = 'ACTIVE' "
         + "  AND m.member_nickname LIKE CONCAT('%', ?, '%') " + "ORDER BY b.board_id DESC";

   private static final String SELECT_BOARD_SEARCH_CONTENT = "SELECT " + "  b.board_id, b.member_id, "
         + "  m.member_role AS writer_role, "
         + "  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' ELSE m.member_nickname END AS writer_nickname, "
         + "  b.board_title, b.board_views, b.board_category, " + "  IFNULL(l.like_cnt, 0) AS like_cnt "
         + "FROM board b " + "JOIN member m ON m.member_id = b.member_id " + "LEFT JOIN (" + LIKE_COUNT_SUBQUERY
         + ") l ON l.board_id = b.board_id " + "WHERE b.board_category = ? AND m.member_role <> 'ADMIN' "
         + "  AND b.board_content LIKE CONCAT('%', ?, '%') " + "ORDER BY b.board_id DESC";

   private static final String SELECT_ADMIN_BOARD_CATEGORY = "SELECT DISTINCT board_category FROM board ORDER BY board_category ASC";

   // =========================================================
   // SELECT ONE
   // board_status, board_created_at, board_updated_at 추가
   private static final String SELECT_BOARD_DETAIL = 
		    "SELECT " +
		    "  b.board_id, b.member_id, " +
		    "  m.member_role AS writer_role, " +
		    "  CASE WHEN m.member_role = 'WITHDRAWN' THEN '탈퇴한 회원' ELSE m.member_nickname END AS writer_nickname, " +
		    "  b.board_title, b.board_content, b.board_views, b.board_category, " +
		    "  b.board_status, " +
		    "  b.board_created_at, " +
		    "  b.board_updated_at, " +
		    "  IFNULL(l.like_cnt, 0) AS like_cnt, " +
		    
		    // isLiked 계산 (좋아요 눌렀는지)
		    "  CASE " +
		    "    WHEN ? IS NULL THEN 0 " +
		    "    ELSE (SELECT COUNT(*) FROM board_like " +
		    "          WHERE board_id = b.board_id AND member_id = ?) " +
		    "  END AS is_liked, " +
		    
		    // isReported 계산 (신고했는지)
		    "  CASE " +
		    "    WHEN ? IS NULL THEN 0 " +
		    "    ELSE (SELECT COUNT(*) FROM board_report " +
		    "          WHERE board_id = b.board_id " +
		    "          AND reporter_member_id = ? " +
		    "          AND status = 'PENDING') " +
		    "  END AS is_reported, " +
		    
		    // isEdited 계산 (수정되었는지)
		    "  CASE " +
		    "    WHEN b.board_updated_at IS NULL THEN 0 " +
		    "    WHEN b.board_created_at = b.board_updated_at THEN 0 " +
		    "    ELSE 1 " +
		    "  END AS is_edited " +
		    
		    
		    "FROM board b " +
		    "JOIN member m ON m.member_id = b.member_id " +
		    "LEFT JOIN (" + LIKE_COUNT_SUBQUERY + ") l ON l.board_id = b.board_id " +
		    "WHERE b.board_id = ?";
   
   private static final String SELECT_BOARD_EXISTS = "SELECT board_id FROM board WHERE board_id = ?";

   // =========================================================
   // INSERT / UPDATE / DELETE
   private static final String INSERT_BOARD = "INSERT INTO board (member_id, board_title, board_content, board_category) VALUES (?, ?, ?, ?)";

   private static final String UPDATE_BOARD = "UPDATE board SET board_title = ?, board_content = ? WHERE board_id = ? AND member_id = ?";

   private static final String UPDATE_BOARD_VIEWS = "UPDATE board SET board_views = board_views + 1 WHERE board_id = ?";

   private static final String DELETE_BOARD = "DELETE FROM board WHERE board_id = ? AND member_id = ?";

   // RowMapper 분리: 목록용(내용 X) / 상세용(내용 O)

   
   // =========================================================
   // RowMapper 대체: JdbcTemplate 람다 매핑 (공통)
   // =========================================================
   // selectAll
   public ArrayList<BoardDTO> selectAll(BoardDTO boardDTO) {

       String condition = boardDTO.getCondition();

       // 람다(mapBoardRowList) 제거 → RowMapper 클래스로 통일
       final BoardListRowMapper listMapper = new BoardListRowMapper();

       
      if ("ADMIN_BOARD_CATEGORY".equals(condition)) {
         List<BoardDTO> list = jdbcTemplate.query(SELECT_ADMIN_BOARD_CATEGORY, (rs, rowNum) -> {
            BoardDTO d = new BoardDTO();
            d.setBoardCategory(rs.getString("board_category"));
            return d;
         });
         return new ArrayList<>(list);
      }

      if ("BOARD_LIKE_MEMBER_LIST".equals(condition)) {
         List<BoardDTO> list = jdbcTemplate.query(SELECT_BOARD_LIKE_MEMBER_LIST, (rs, rowNum) -> {
            BoardDTO d = new BoardDTO();
            d.setMemberId(rs.getInt("member_id"));
            d.setLikeMemberNickname(rs.getString("like_member_nickname"));
            return d;
         }, boardDTO.getBoardId());
         return new ArrayList<>(list);
      }   
   
       List<BoardDTO> list;

       // selectAll은 전부 listMapper 사용 (board_content 읽지 않음)
       if ("CATEGORY_LIST".equals(condition)) {
           list = jdbcTemplate.query(SELECT_CATEGORY_LIST, listMapper, boardDTO.getBoardCategory());

       } else if ("BOARD_NOTICE_LIST".equals(condition)) {
           list = jdbcTemplate.query(SELECT_BOARD_NOTICE_LIST, listMapper, boardDTO.getBoardCategory());

       } else if ("MY_BOARD_WRITE_LIST".equals(condition)) {
           list = jdbcTemplate.query(SELECT_MY_BOARD_WRITE_LIST, listMapper, boardDTO.getMemberId());

       } else if ("MY_BOARD_LIKE_LIST".equals(condition)) {
           list = jdbcTemplate.query(SELECT_MY_BOARD_LIKE_LIST, listMapper, boardDTO.getMemberId());

       } else if ("BOARD_BEST_LIKE_LIST".equals(condition)) {
           list = jdbcTemplate.query(SELECT_BOARD_BEST_LIKE_LIST, listMapper, boardDTO.getBoardCategory());

       } else if ("BOARD_SEARCH_TITLE".equals(condition)) {
           list = jdbcTemplate.query(SELECT_BOARD_SEARCH_TITLE, listMapper,
                   boardDTO.getBoardCategory(), boardDTO.getKeyword());

       } else if ("BOARD_SEARCH_WRITER".equals(condition)) {
           list = jdbcTemplate.query(SELECT_BOARD_SEARCH_WRITER, listMapper,
                   boardDTO.getBoardCategory(), boardDTO.getKeyword());

       } else if ("BOARD_SEARCH_CONTENT".equals(condition)) {
           list = jdbcTemplate.query(SELECT_BOARD_SEARCH_CONTENT, listMapper,
                   boardDTO.getBoardCategory(), boardDTO.getKeyword());

       } else {
           return new ArrayList<>();
       }

       return new ArrayList<>(list);
   }

   // =========================================================
   // selectOne
   public BoardDTO selectOne(BoardDTO boardDTO) {

       String condition = boardDTO.getCondition();

       try {
           if ("BOARD_DETAIL".equals(condition)) {

               // 파라미터 순서 중요
               Integer currentMemberId = boardDTO.getMemberId();  // DTO에서 가져옴
               
               return jdbcTemplate.queryForObject(
                       SELECT_BOARD_DETAIL,
                       new BoardDetailRowMapper(),
                       currentMemberId,           // isLiked 계산용 (? IS NULL)
                       currentMemberId,           // isLiked 계산용 (member_id = ?)
                       currentMemberId,           // isReported 계산용 (? IS NULL)
                       currentMemberId,           // isReported 계산용 (reporter_member_id = ?)
                       boardDTO.getBoardId()      // WHERE b.board_id = ?
               );
           }

           if ("BOARD_EXISTS".equals(condition)) {
               Integer id = jdbcTemplate.queryForObject(
                       SELECT_BOARD_EXISTS,
                       (rs, rowNum) -> rs.getInt("board_id"),
                       boardDTO.getBoardId()
               );

               if (id == null) return null;

               BoardDTO data = new BoardDTO();
               data.setBoardId(id);
               return data;
           }

           return null;

       } catch (org.springframework.dao.EmptyResultDataAccessException e) {
           return null;
       }
   }
   // update / delete 는 그대로

   // =========================================================
   // insert (getGeneratedKeys -> KeyHolder)
   public boolean insert(BoardDTO boardDTO) {

       if (!"BOARD_INSERT".equals(boardDTO.getCondition())) {
           return false;
       }

       KeyHolder keyHolder = new GeneratedKeyHolder();

       int result = jdbcTemplate.update(con -> {
           PreparedStatement ps = con.prepareStatement(INSERT_BOARD, Statement.RETURN_GENERATED_KEYS);
           ps.setInt(1, boardDTO.getMemberId());
           ps.setString(2, boardDTO.getBoardTitle());
           ps.setString(3, boardDTO.getBoardContent());
           ps.setString(4, boardDTO.getBoardCategory());
           return ps;
       }, keyHolder);

       if (result <= 0) return false;

       Number key = keyHolder.getKey();
       if (key == null) return false;

       boardDTO.setBoardId(key.intValue());  // 핵심
       return true;
   }


   // =========================================================
   // update (jdbcTemplate.update)
   public boolean update(BoardDTO boardDTO) {

      String condition = boardDTO.getCondition();

      int result;

      if ("BOARD_UPDATE".equals(condition)) {
         result = jdbcTemplate.update(UPDATE_BOARD, boardDTO.getBoardTitle(), boardDTO.getBoardContent(),
               boardDTO.getBoardId(), boardDTO.getMemberId());
      } else if ("UPDATE_BOARD_VIEWS".equals(condition)) {
         result = jdbcTemplate.update(UPDATE_BOARD_VIEWS, boardDTO.getBoardId());
      } else {
         return false;
      }

      return result > 0;
   }

   // =========================================================
   // delete (jdbcTemplate.update)
   public boolean delete(BoardDTO boardDTO) {

      if (!"BOARD_DELETE".equals(boardDTO.getCondition())) {
         return false;
      }

      int result = jdbcTemplate.update(DELETE_BOARD, boardDTO.getBoardId(), boardDTO.getMemberId());
      return result > 0;
   }
   
   
   
   // =========================================================
      // 리스트용 RowMapper (board_content 읽지 않음)
      // =========================================================
   class BoardListRowMapper implements RowMapper<BoardDTO> {

	    @Override
	    public BoardDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
	        BoardDTO data = new BoardDTO();

	        data.setBoardId(rs.getInt("board_id"));
	        data.setMemberId(rs.getInt("member_id"));
	        data.setWriterRole(rs.getString("writer_role"));
	        data.setWriterNickname(rs.getString("writer_nickname"));
	        data.setBoardTitle(rs.getString("board_title"));
	        data.setBoardViews(getIntOrZero(rs, "board_views"));
	        data.setBoardCategory(rs.getString("board_category"));
	        data.setLikeCnt(getIntOrZero(rs, "like_cnt"));

	        // board_status: MY 쿼리에만 있으므로 없는 경우 무시
	        try { data.setBoardStatus(rs.getString("board_status")); }
	        catch (SQLException ignored) {}

	        return data;
	    }

	    private int getIntOrZero(ResultSet rs, String colName) throws SQLException {
	        Object obj = rs.getObject(colName);
	        if (obj == null) return 0;
	        return ((Number) obj).intValue();
	    }
	}

      // =========================================================
      // 상세용 RowMapper (board_content + board_status + created_at + updated_at 포함)
      // =========================================================
      class BoardDetailRowMapper implements RowMapper<BoardDTO> {
          private final BoardListRowMapper base = new BoardListRowMapper();

          @Override
          public BoardDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
              BoardDTO data = base.mapRow(rs, rowNum);
              data.setBoardContent(rs.getString("board_content"));
              data.setBoardStatus(rs.getString("board_status"));
              data.setBoardCreatedAt(rs.getString("board_created_at"));
              data.setBoardUpdatedAt(rs.getString("board_updated_at"));
              
              data.setIsLiked(getIntOrZero(rs, "is_liked"));
              data.setIsReported(getIntOrZero(rs, "is_reported"));
              data.setIsEdited(getIntOrZero(rs, "is_edited"));
              
              return data;
          }
          
          private int getIntOrZero(ResultSet rs, String colName) throws SQLException {
              Object obj = rs.getObject(colName);
              if (obj == null) return 0;
              return ((Number) obj).intValue();
          }
      }
}