package fourcheetah.animale.web.service.anime;

import java.util.List;

import fourcheetah.animale.web.dto.anime.AnimeDTO;

public interface AnimeService {
    List<AnimeDTO> selectAll(AnimeDTO dto); 
    AnimeDTO selectOne(AnimeDTO dto);         
    boolean insert(AnimeDTO dto);
    boolean update(AnimeDTO dto);
    boolean delete(AnimeDTO dto);
}
