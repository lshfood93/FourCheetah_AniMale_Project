package fourcheetah.animale.web.controller.anime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.service.anime.AnimeService;
import jakarta.servlet.http.HttpSession;

@Controller
public class AnimeDeleteController {

    @Autowired
    private AnimeService animeService;

    /*
     1) 로그인 체크 (세션)
     2) 관리자 권한 체크
     3) animeId 검증
     4) deleteAnime 호출
     5) 성공 -> 목록 redirect / 실패 -> 상세 redirect + 메시지
    */
    @PostMapping("/animeDelete")
    public String deleteAnime(
            AnimeDTO dto,              // 커맨드객체 바인딩
            HttpSession session,
            RedirectAttributes ra
    ) {
        // 0) 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            System.out.println("[로그] AnimeDeleteController : session null or memberId null");
            return "redirect:/loginPage";
        }
        
        int animeId = dto.getAnimeId();
        
        // 1) 관리자 체크
        Object roleObj = session.getAttribute("memberRole");
        String role = (roleObj == null) ? null : roleObj.toString();        

        if (!"ADMIN".equalsIgnoreCase(role)) {
        	ra.addAttribute("animeId", animeId);
        	ra.addFlashAttribute("errorMsg", "삭제 권한이 없습니다.");
        	return "redirect:/animeDetail"; // 쿼리 파라미터 스타일            
        }

        // 2) animeId 검증
        
        if (animeId <= 0) {
            ra.addFlashAttribute("errorMsg", "잘못된 요청입니다. (anime_id 오류)");
            return "redirect:/animeList";
        }

        // 3) 서버에서 컨디션 세팅(클라 입력값 신뢰 X)
        dto.setCondition("ANIME_DELETE");

        // 4) 삭제 호출
        if (animeService.deleteAnime(dto)) {
            System.out.println("[로그] 애니 삭제 성공");
            ra.addFlashAttribute("msg", "삭제되었습니다.");
            return "redirect:/animeList";
            
        } else {
        	ra.addAttribute("animeId", animeId);
            ra.addFlashAttribute("errorMsg", "삭제에 실패했습니다. (대상 없음/이미 삭제됨)");            
            return "redirect:/animeDetail"; // 쿼리 파라미터 스타일
        }
    }
}
