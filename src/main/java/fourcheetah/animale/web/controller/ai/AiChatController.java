package fourcheetah.animale.web.controller.ai;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import fourcheetah.animale.web.dto.ai.AiChatMessageRequest;
import fourcheetah.animale.web.dto.ai.AiChatMessageResponse;
import fourcheetah.animale.web.dto.ai.AiChatOpenResponse;
import fourcheetah.animale.web.exception.ApiException;
import fourcheetah.animale.web.service.ai.AiChatService;
import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/api/ai-chat")
public class AiChatController {

	@Autowired
    private AiChatService aiChatService;

   

    // 1) 챗봇 화면 진입(페이지)
    @GetMapping("/chat")
    public String chatPage(HttpSession session) {
        // 여기서 로그인 체크 원하면 session.getAttribute("memberId")로 처리
        return "chatAi"; // thymeleaf/jsp 경로
    }

    
    
    // 2) 열기(초기 메시지 + 세션 초기화)
    @ResponseBody
    @GetMapping("/open")
    public AiChatOpenResponse open(HttpSession session) {
    	 if (session == null) throw new ApiException(HttpStatus.UNAUTHORIZED, "NO_SESSION", "세션이 없습니다.");
        return aiChatService.open(session);
    }

    // 3) 조건 입력 → 추천 반환
    @ResponseBody
    @PostMapping("/message")
    public AiChatMessageResponse message(@RequestBody AiChatMessageRequest req, HttpSession session) {
        return aiChatService.chat(session, req.getUserMessage());
    }

    // 4) 더 추천 받기
    @ResponseBody
    @PostMapping("/more")
    public AiChatMessageResponse more(HttpSession session) {
        return aiChatService.more(session);
    }

    // 5) 조건 바꾸기
    @ResponseBody
    @PostMapping("/change")
    public AiChatMessageResponse change(@RequestBody AiChatMessageRequest req, HttpSession session) {
        return aiChatService.changeCondition(session, req.getUserMessage());
    }

    // 6) 새 대화하기(강제 리셋)
    @ResponseBody
    @PostMapping("/reset")
    public AiChatOpenResponse reset(HttpSession session) {
        return aiChatService.reset(session);
    }
}
