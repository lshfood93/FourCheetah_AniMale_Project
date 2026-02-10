package fourcheetah.animale.web.controller.common;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.dto.member.MemberDTO;
import fourcheetah.animale.web.dto.news.NewsDTO;
import fourcheetah.animale.web.service.anime.AnimeService;
import fourcheetah.animale.web.service.member.MemberService;
import fourcheetah.animale.web.service.news.NewsService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@Controller
public class MainPageController {

    @Autowired
    private MemberService memberService;

    @Autowired
    private NewsService newsService;   // 너가 가진 서비스/DAO 구조에 맞게 연결
    @Autowired
    private AnimeService animeService; // 너가 가진 서비스/DAO 구조에 맞게 연결

    @GetMapping({"/", "/mainPage"})
    public String mainPage(
            @CookieValue(value = "autoLogin", required = false) String autoLoginMemberName,
            HttpSession session,
            HttpServletResponse response,
            Model model
    ) {
        model.addAttribute("activeMenu", "HOME"); // 메뉴 활성화용

        // 0) 자동 로그인: 세션이 없을 때만 쿠키로 시도
        if (session.getAttribute("memberName") == null
                && autoLoginMemberName != null
                && !autoLoginMemberName.trim().isEmpty()) {

            MemberDTO memberDTO = new MemberDTO();
            memberDTO.setCondition("MEMBER_AUTOLOGIN"); // 아래 2)에서 DAO에 추가할 컨디션
            memberDTO.setMemberName(autoLoginMemberName);

            MemberDTO memberData = memberService.selectOne(memberDTO);

            if (memberData != null) {
                // 자동 로그인 성공 → 세션 저장
                session.setAttribute("memberId", memberData.getMemberId());
                session.setAttribute("memberName", memberData.getMemberName());
                session.setAttribute("memberNickName", memberData.getMemberNickname());
                session.setAttribute("memberRole", memberData.getMemberRole());
                session.setAttribute("memberProfileImage", memberData.getMemberProfileImage());
                session.setAttribute("memberEmail", memberData.getMemberEmail());

                // 기존 코드에 있던 memberPhoneNumber는 현재 DTO에 없으니 세션 저장에서 제거함
            } else {
                // DB에 없는 값이면 쿠키 삭제
                Cookie cookieToDelete = new Cookie("autoLogin", "");
                cookieToDelete.setMaxAge(0);
                cookieToDelete.setPath("/");
                cookieToDelete.setHttpOnly(true);
                response.addCookie(cookieToDelete);
            }
        }

        // 1) 메인 배너 뉴스 최신 3개
        NewsDTO newsDTO = new NewsDTO();
        newsDTO.setCondition("MAIN_BANNER_NEWSLIST");
        List<NewsDTO> mainBannerNewsList = newsService.selectAll(newsDTO);

        // 2) 메인 애니 최신 12개
        AnimeDTO animeDTO = new AnimeDTO();
        animeDTO.setCondition("MAIN_ANIMELIST");
        List<AnimeDTO> mainAnimeList = animeService.selectAll(animeDTO);

        model.addAttribute("mainBannerNewsList", mainBannerNewsList);
        model.addAttribute("mainAnimeList", mainAnimeList);

        return "mainpage"; // /WEB-INF/views/mainpage.jsp
    }
}
