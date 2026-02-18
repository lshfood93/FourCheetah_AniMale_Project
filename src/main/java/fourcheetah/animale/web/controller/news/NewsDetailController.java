package fourcheetah.animale.web.controller.news;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import fourcheetah.animale.web.dto.news.NewsDTO;
import fourcheetah.animale.web.service.news.NewsService;

@Controller
@RequestMapping("")
public class NewsDetailController {

    @Autowired
    private NewsService newsService;

    @GetMapping("/newsDetail")
    public String execute(NewsDTO dto, Model model) {
        
        System.out.println("\n\n================================");
        System.out.println(" NewsDetailAction /newsDetail 실행됨!");
        System.out.println(" newsId = " + dto.getNewsId());
        System.out.println("================================\n\n");
        
        model.addAttribute("activeMenu", "NEWS");

        int newsId = dto.getNewsId();
        int page = (dto.getPage() != 0) ? dto.getPage() : 1;
        String condition = dto.getCondition();
        String keyword = dto.getKeyword();

        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        NewsDTO newsDTO = new NewsDTO();
        newsDTO.setNewsId(newsId);
        newsDTO.setCondition("NEWS_DETAIL");

        NewsDTO newsData = newsService.selectOne(newsDTO);

        if (newsData == null) {
            model.addAttribute("msg", "존재하지 않는 뉴스입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        model.addAttribute("newsData", newsData);
        model.addAttribute("page", page);
        model.addAttribute("condition", condition);
        model.addAttribute("keyword", keyword);

        return "newsdetail";  
    }
}