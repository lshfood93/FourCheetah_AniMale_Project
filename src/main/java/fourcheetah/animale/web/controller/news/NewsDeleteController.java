package fourcheetah.animale.web.controller.news;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import fourcheetah.animale.web.dto.news.NewsDTO;
import fourcheetah.animale.web.service.news.NewsService;
import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("")
public class NewsDeleteController {
	
    @Autowired
    private NewsService newsService;

    @PostMapping("/newsDelete")
    public String execute(NewsDTO dto, HttpSession session, Model model) {
        
        int newsId = dto.getNewsId();

        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 삭제할 수 있습니다.");
            model.addAttribute("location", "/newsDetail?newsId=" + newsId);
            return "message";
        }

        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        NewsDTO deleteDTO = new NewsDTO();
        deleteDTO.setNewsId(newsId);
        deleteDTO.setCondition("NEWS_DELETE");

        boolean result = newsService.delete(deleteDTO);

        if (!result) {
            model.addAttribute("msg", "뉴스 삭제에 실패했습니다.");
            model.addAttribute("location", "/newsDetail?newsId=" + newsId);
            return "message";
        }

        model.addAttribute("msg", "뉴스가 삭제되었습니다.");
        model.addAttribute("location", "/newsList");
        return "message";
    }
}
