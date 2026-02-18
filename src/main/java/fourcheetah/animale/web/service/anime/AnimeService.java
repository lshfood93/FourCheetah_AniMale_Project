package fourcheetah.animale.web.service.anime;

import java.util.List;

import fourcheetah.animale.web.dto.anime.AnimeDTO;

public interface AnimeService {
    List<AnimeDTO> getAnimeList(AnimeDTO dto); // selectAll
    AnimeDTO getAnime(AnimeDTO dto);           // selectOne (detail/count)
    boolean insertAnime(AnimeDTO dto);
    boolean updateAnime(AnimeDTO dto);
    boolean deleteAnime(AnimeDTO dto);
}
