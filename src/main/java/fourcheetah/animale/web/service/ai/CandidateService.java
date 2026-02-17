package fourcheetah.animale.web.service.ai;

import java.util.List;
import java.util.Set;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import fourcheetah.animale.web.dto.ai.QuerySpec;
import fourcheetah.animale.web.dto.ai.RecommendedAnimeDTO;
import fourcheetah.animale.web.repository.ai.AnimeRepository;

@Service
public class CandidateService {

    private final AnimeRepository animeRepository;

    @Value("${ai.chat.candidate.limit:20}")
    private int candidateLimit;

    public CandidateService(AnimeRepository animeRepository) {
        this.animeRepository = animeRepository;
    }

    public List<RecommendedAnimeDTO> getCandidates(QuerySpec spec, Set<Integer> excludeIds) {
        List<String> genres = (spec != null) ? spec.getGenres() : List.of();
        List<RecommendedAnimeDTO> result = animeRepository.findCandidates(genres, excludeIds, candidateLimit);

        // 부족하면(예: 장르 너무 빡셈) 장르조건 없이 한번 더
        if (result.size() < candidateLimit / 2) {
            result = animeRepository.findCandidates(List.of(), excludeIds, candidateLimit);
        }
        return result;
    }
}
