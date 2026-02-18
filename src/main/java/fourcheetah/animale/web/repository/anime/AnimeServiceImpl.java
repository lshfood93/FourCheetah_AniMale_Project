package fourcheetah.animale.web.repository.anime;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.service.anime.AnimeService;

@Service
public class AnimeServiceImpl implements AnimeService {

    @Autowired
<<<<<<< HEAD
    private AnimeDAO animeDAO;

    @Override
    public List<AnimeDTO> getAnimeList(AnimeDTO dto) {
=======
    private MybatisAnimeDAO animeDAO;

    @Override
    public List<AnimeDTO> selectAll(AnimeDTO dto) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
        return animeDAO.selectAll(dto);
    }

    @Override
<<<<<<< HEAD
    public AnimeDTO getAnime(AnimeDTO dto) {
=======
    public AnimeDTO selectOne(AnimeDTO dto) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
        return animeDAO.selectOne(dto);
    }

    @Override
<<<<<<< HEAD
    public boolean insertAnime(AnimeDTO dto) {
=======
    public boolean insert(AnimeDTO dto) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
        return animeDAO.insert(dto);
    }

    @Override
<<<<<<< HEAD
    public boolean updateAnime(AnimeDTO dto) {
=======
    public boolean update(AnimeDTO dto) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
        return animeDAO.update(dto);
    }

    @Override
<<<<<<< HEAD
    public boolean deleteAnime(AnimeDTO dto) {
=======
    public boolean delete(AnimeDTO dto) {
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
        return animeDAO.delete(dto);
    }
}