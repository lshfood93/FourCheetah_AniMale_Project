package fourcheetah.animale.web.repository.news;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.news.NewsDTO;
import fourcheetah.animale.web.service.news.NewsService;

@Service
public class NewsServiceImpl implements NewsService {

    @Autowired
    private MybatisNewsDAO newsDAO; // (수정) JdbcTemplate NewsDAO → MybatisNewsDAO

    @Override
    public NewsDTO selectOne(NewsDTO newsDTO) {
        return newsDAO.selectOne(newsDTO);
    }

    @Override
    public List<NewsDTO> selectAll(NewsDTO newsDTO) {
        return newsDAO.selectAll(newsDTO);
    }

    @Override
    public boolean insert(NewsDTO newsDTO) {
        return newsDAO.insert(newsDTO);
    }

    @Override
    public boolean update(NewsDTO newsDTO) {
        return newsDAO.update(newsDTO);
    }

    @Override
    public boolean delete(NewsDTO newsDTO) {
        return newsDAO.delete(newsDTO);
    }
}
