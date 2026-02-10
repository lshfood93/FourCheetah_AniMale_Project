package fourcheetah.animale.web.service.anime;

import java.util.List;

import fourcheetah.animale.web.dto.anime.AnimeDTO;

public interface AnimeService {
    List<AnimeDTO> selectAll(AnimeDTO dto); 
    AnimeDTO selectOne(AnimeDTO dto);         
    boolean insertAnime(AnimeDTO dto);
    boolean updateAnime(AnimeDTO dto);
    boolean deleteAnime(AnimeDTO dto);
}
