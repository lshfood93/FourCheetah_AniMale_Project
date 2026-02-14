package fourcheetah.animale.web.repository.news;

import java.util.Collections;
import java.util.List;

import org.apache.ibatis.session.SqlSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import fourcheetah.animale.web.dto.news.NewsDTO;

@Repository
public class MybatisNewsDAO {

    @Autowired
    private SqlSession sqlSession;

    private static final String NAMESPACE = "News.";

    public List<NewsDTO> selectAll(NewsDTO dto) {
        if (dto == null) return Collections.emptyList();

        String condition = dto.getCondition();

        if ("MAIN_BANNER_NEWSLIST".equals(condition)) {
            return sqlSession.selectList(NAMESPACE + "mainBannerNewsList");
        }

        if ("NEWS_LIST".equals(condition)) {
            return sqlSession.selectList(NAMESPACE + "newsList");
        }

        if ("NEWS_SEARCH_TITLE".equals(condition)) {
            dto.setKeyword("%" + safeKeyword(dto.getKeyword()) + "%");
            return sqlSession.selectList(NAMESPACE + "searchTitle", dto);
        }

        if ("NEWS_SEARCH_CONTENT".equals(condition)) {
            dto.setKeyword("%" + safeKeyword(dto.getKeyword()) + "%");
            return sqlSession.selectList(NAMESPACE + "searchContent", dto);
        }

        if ("NEWS_LIST_PAGE".equals(condition)) {
            // dto.listSize, dto.startNum 사용
            return sqlSession.selectList(NAMESPACE + "newsListPage", dto);
        }

        if ("NEWS_LIST_PAGE_TITLE".equals(condition)) {
            dto.setKeyword("%" + safeKeyword(dto.getKeyword()) + "%");
            return sqlSession.selectList(NAMESPACE + "newsListPageTitle", dto);
        }

        if ("NEWS_LIST_PAGE_CONTENT".equals(condition)) {
            dto.setKeyword("%" + safeKeyword(dto.getKeyword()) + "%");
            return sqlSession.selectList(NAMESPACE + "newsListPageContent", dto);
        }

        return Collections.emptyList();
    }

    public NewsDTO selectOne(NewsDTO dto) {
        if (dto == null) return null;

        String condition = dto.getCondition();

        if ("NEWS_DETAIL".equals(condition)) {
            return sqlSession.selectOne(NAMESPACE + "newsDetail", dto);
        }

        if ("NEWS_COUNT".equals(condition)) {
            Integer count = sqlSession.selectOne(NAMESPACE + "newsCount");
            NewsDTO data = new NewsDTO();
            data.setNewsCount(count == null ? 0 : count);
            return data;
        }

        if ("NEWS_COUNT_TITLE".equals(condition)) {
            dto.setKeyword("%" + safeKeyword(dto.getKeyword()) + "%");
            Integer count = sqlSession.selectOne(NAMESPACE + "newsCountTitle", dto);
            NewsDTO data = new NewsDTO();
            data.setNewsCount(count == null ? 0 : count);
            return data;
        }

        if ("NEWS_COUNT_CONTENT".equals(condition)) {
            dto.setKeyword("%" + safeKeyword(dto.getKeyword()) + "%");
            Integer count = sqlSession.selectOne(NAMESPACE + "newsCountContent", dto);
            NewsDTO data = new NewsDTO();
            data.setNewsCount(count == null ? 0 : count);
            return data;
        }

        return null;
    }

    public boolean insert(NewsDTO dto) {
        if (dto == null) return false;
        if (!"NEWS_INSERT".equals(dto.getCondition())) return false;

        // XML insert에 useGeneratedKeys 적용하면 dto.newsId 자동 세팅됨
        return sqlSession.insert(NAMESPACE + "insertNews", dto) > 0;
    }

    public boolean update(NewsDTO dto) {
        if (dto == null) return false;
        if (!"NEWS_UPDATE".equals(dto.getCondition())) return false;

        return sqlSession.update(NAMESPACE + "updateNews", dto) > 0;
    }

    public boolean delete(NewsDTO dto) {
        if (dto == null) return false;
        if (!"NEWS_DELETE".equals(dto.getCondition())) return false;

        return sqlSession.delete(NAMESPACE + "deleteNews", dto) > 0;
    }

    private String safeKeyword(String keyword) {
        return (keyword == null) ? "" : keyword.trim();
    }
}
