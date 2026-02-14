package fourcheetah.animale.web.service.news;

import java.util.List;

import fourcheetah.animale.web.dto.news.NewsDTO;

public interface NewsService {
    NewsDTO selectOne(NewsDTO newsDTO);
    List<NewsDTO> selectAll(NewsDTO newsDTO);
    
    boolean insert(NewsDTO newsDTO); 
    
    boolean update(NewsDTO newsDTO);
    boolean delete(NewsDTO newsDTO);
}