package fourcheetah.animale.web.controller.news;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import fourcheetah.animale.web.dto.news.NewsDTO;
import fourcheetah.animale.web.service.news.NewsService;

@Controller
@RequestMapping("")
public class NewsListController {

    @Autowired
    private NewsService newsService;

    @GetMapping("/newsList")
    public String execute(NewsDTO dto, Model model) {
        
        System.out.println("\n\n================================");
        System.out.println("✅ NewsListAction /newsList 실행됨!");
        System.out.println("✅ newsService = " + newsService);
        System.out.println("================================\n\n");
        
        model.addAttribute("activeMenu", "NEWS");

        int page = (dto.getPage() != 0) ? dto.getPage() : 1;
        if (page < 1) page = 1;
        
        String condition = dto.getCondition();
        String keyword = dto.getKeyword();
        
        int listSize = 12;
        int startNum = (page - 1) * listSize;

        boolean isSearch = "NEWS_SEARCH_TITLE".equals(condition) || 
                          "NEWS_SEARCH_CONTENT".equals(condition);

        if (keyword != null) {
            keyword = keyword.trim();
            if (keyword.isEmpty()) {
                keyword = null;
            }
        }

        if (isSearch && keyword == null) {
            model.addAttribute("msg", "검색어가 없습니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        NewsDTO countDTO = new NewsDTO();
        if (isSearch) {
            countDTO.setCondition(condition.replace("NEWS_SEARCH", "NEWS_COUNT"));
            countDTO.setKeyword(keyword);
        } else {
            countDTO.setCondition("NEWS_COUNT");
            condition = "NEWS_LIST_PAGE";
        }

        NewsDTO countResult = newsService.selectOne(countDTO);
        int totalCount = (countResult != null) ? countResult.getCnt() : 0;

        int totalPage = (int) Math.ceil((double) totalCount / listSize);
        if (totalPage == 0) totalPage = 1;
        if (page > totalPage) page = totalPage;

        int blockSize = 5;
        int currentBlock = (int) Math.ceil((double) page / blockSize);
        int startPage = (currentBlock - 1) * blockSize + 1;
        int endPage = Math.min(startPage + blockSize - 1, totalPage);

        boolean hasPrev = (currentBlock > 1);
        boolean hasNext = (endPage < totalPage);

        NewsDTO listDTO = new NewsDTO();
        if (isSearch) {
            listDTO.setCondition(condition.replace("NEWS_COUNT", "NEWS_SEARCH"));
            listDTO.setKeyword(keyword);
        } else {
            listDTO.setCondition("NEWS_LIST_PAGE");
        }
        listDTO.setStartNum(startNum);
        listDTO.setListSize(listSize);

        List<NewsDTO> newsList = newsService.selectAll(listDTO);

        model.addAttribute("newsList", newsList);
        model.addAttribute("page", page);
        model.addAttribute("totalPage", totalPage);
        model.addAttribute("startPage", startPage);
        model.addAttribute("endPage", endPage);
        model.addAttribute("hasPrev", hasPrev);
        model.addAttribute("hasNext", hasNext);
        model.addAttribute("condition", condition);
        model.addAttribute("keyword", keyword);

        System.out.println("news.jsp 렌더링 시작");
        
        return "news";
    }
}
