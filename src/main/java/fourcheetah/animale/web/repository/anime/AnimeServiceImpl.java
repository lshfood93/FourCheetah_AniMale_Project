package fourcheetah.animale.web.repository.anime;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.service.anime.AnimeService;

@Service
public class AnimeServiceImpl implements AnimeService {

    @Autowired
    private MybatisAnimeDAO animeDAO;

    @Override
    public List<AnimeDTO> selectAll(AnimeDTO dto) {
        return animeDAO.selectAll(dto);
    }

    @Override
    public AnimeDTO selectOne(AnimeDTO dto) {
        return animeDAO.selectOne(dto);
    }

    @Override
    public boolean insert(AnimeDTO dto) {
        return animeDAO.insert(dto);
    }

    @Override
    public boolean update(AnimeDTO dto) {
        return animeDAO.update(dto);
    }

    @Override
    public boolean delete(AnimeDTO dto) {
        return animeDAO.delete(dto);
    }
}