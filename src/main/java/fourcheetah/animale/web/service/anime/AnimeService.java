package fourcheetah.animale.web.service.anime;

import java.util.List;

import fourcheetah.animale.web.dto.anime.AnimeDTO;

public interface AnimeService {
<<<<<<< HEAD
    List<AnimeDTO> getAnimeList(AnimeDTO dto); // selectAll
    AnimeDTO getAnime(AnimeDTO dto);           // selectOne (detail/count)
    boolean insertAnime(AnimeDTO dto);
    boolean updateAnime(AnimeDTO dto);
    boolean deleteAnime(AnimeDTO dto);
=======
    List<AnimeDTO> selectAll(AnimeDTO dto); 
    AnimeDTO selectOne(AnimeDTO dto);         
    boolean insert(AnimeDTO dto);
    boolean update(AnimeDTO dto);
    boolean delete(AnimeDTO dto);
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
}
