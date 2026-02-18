package fourcheetah.animale.web.controller.board;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;                         // ✅ CHANGED
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import fourcheetah.animale.web.dto.board.BoardDTO;
import fourcheetah.animale.web.service.board.BoardService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@Controller
public class BoardWriteController {

	@Autowired
	private BoardService boardService;


	/*
    역할 분리
    1) /boardWritePage : 로그인/type/category 검증 후 redirect만 담당
    2) /write          : 실제 write.jsp 렌더링 담당 (model 세팅)
	 */

	// =========================================================
	// 1) 검증 + redirect 담당
	@GetMapping("/boardWritePage")
	public String boardWritePage(
			BoardDTO boardDTO,        // 커맨드 객체 바인딩(type/boardCategory)
			BindingResult br,         // (선택) 바인딩 오류 확인
			HttpServletRequest request,
			Model model               // ✅ CHANGED: RedirectAttributes 제거 → Model로 message 렌더링
			) {

		HttpSession session = request.getSession(false);

		// ✅ CHANGED: 로그인 체크 실패 시 message.jsp 뷰 렌더링
		if (session == null || session.getAttribute("memberId") == null) {
			System.out.println("[글쓰기 이동 로그] 실패: 로그인 세션 없음");
			return message(model, "로그인이 필요한 기능입니다.", "/login");
		}

		// 1) type 수신 + 기본값 처리
		String type = boardDTO.getType();
		if (type == null || type.trim().isEmpty()) {
			type = "BOARD";
		}
		type = type.trim().toUpperCase();
		System.out.println("[글쓰기 이동 로그] type=[" + type + "]");

		boolean isBoard = "BOARD".equals(type);
		boolean isNews  = "NEWS".equals(type);

		// 2) type 화이트리스트 검증
		if (!isBoard && !isNews) {
			System.out.println("[글쓰기 이동 로그] type 검증 실패 → message.jsp");
			return message(model, "잘못된 글쓰기 접근입니다.", "/mainPage");
		}

		// 3) type별 redirect 구성
		if (isBoard) {
			String category = boardDTO.getBoardCategory(); // ✅ boardCategory로 받는 전제
			if (category == null || category.trim().isEmpty()) {
				category = "ANIME";
				System.out.println("[글쓰기 이동 로그] boardCategory 없음 → 기본값 적용 [" + category + "]");
			}
			category = category.trim().toUpperCase();

			// ✅ CHANGED: redirect 파라미터를 boardCategory로 통일
			return "redirect:/write?type=BOARD&boardCategory=" + category;
		}

		// NEWS
		return "redirect:/write?type=NEWS";
	}

	// =========================================================
	// 2) 실제 write.jsp 렌더링 담당
	@GetMapping("/write")
	public String writePage(
			BoardDTO boardDTO,       // 커맨드 객체 바인딩(type/boardCategory)
			HttpServletRequest request,
			Model model
			) {

		HttpSession session = request.getSession(false);

		// ✅ CHANGED: 로그인 체크 실패 시 message.jsp 뷰 렌더링
		if (session == null || session.getAttribute("memberId") == null) {
			System.out.println("[글쓰기 화면 로그] 실패: 로그인 세션 없음");
			return message(model, "로그인이 필요한 기능입니다.", "/login");
		}

		model.addAttribute("activeMenu", "COMMUNITY");

		String type = boardDTO.getType();
		type = (type == null || type.trim().isEmpty()) ? "BOARD" : type.trim().toUpperCase();

		boolean isBoard = "BOARD".equals(type);
		boolean isNews  = "NEWS".equals(type);

		if (!isBoard && !isNews) {
			return message(model, "잘못된 글쓰기 접근입니다.", "/mainPage");
		}

		model.addAttribute("type", type);

		if (isBoard) {
			String category = boardDTO.getBoardCategory();
			if (category == null || category.trim().isEmpty()) {
				category = "ANIME";
			}
			model.addAttribute("boardCategory", category.trim().toUpperCase());
		}

		return "write";
	}



	@PostMapping("/boardWrite")
	public String boardWrite(
			BoardDTO boardDTO,        // 커맨드 객체 바인딩
			BindingResult br,         // (선택) 바인딩 오류 받기
			HttpSession session,
			Model model               // ✅ CHANGED: RedirectAttributes -> Model
			) {

		// =========================================================
		// 1) 로그인 체크
		Object memberIdObj = (session != null) ? session.getAttribute("memberId") : null;
		if (session == null || memberIdObj == null) {
			System.out.println("[게시글 작성 로그] 실패: 로그인 세션 없음");
			return message(model, "로그인이 필요한 기능입니다.", "/mainPage"); // ✅ CHANGED
		}

		int memberId;
		try {
			if (memberIdObj instanceof Integer) {
				memberId = (Integer) memberIdObj;
			} else {
				memberId = Integer.parseInt(String.valueOf(memberIdObj));
			}
		} catch (Exception e) {
			System.out.println("[게시글 작성 로그] 실패: 세션 memberId 형변환 오류 memberIdObj=" + memberIdObj);
			return message(model, "로그인 정보가 올바르지 않습니다.", "/mainPage"); // ✅ CHANGED
		}

		String memberRole = (String) session.getAttribute("memberRole"); // null 가능
		System.out.println("[게시글 작성 로그] 로그인 memberId=" + memberId + ", role=" + memberRole);

		// =========================================================
		// 2) 파라미터 유효성 검사 (커맨드 객체에서 꺼내서 검증)
		String category = boardDTO.getBoardCategory();
		String title = boardDTO.getBoardTitle();
		String content = boardDTO.getBoardContent();

		if (category == null || category.trim().isEmpty()) {
			System.out.println("[게시글 작성 로그] 실패: boardCategory 없음");
			return message(model, "게시판 카테고리가 올바르지 않습니다.", "/mainPage"); // ✅ CHANGED
		}
		category = category.trim();
		boardDTO.setBoardCategory(category);

		if (title == null || title.trim().isEmpty()) {
			System.out.println("[게시글 작성 로그] 실패: 제목 없음");
			return message(model, "제목은 필수입니다.", "/boardWritePage?boardCategory=" + category); // ✅ CHANGED
		}
		title = title.trim();
		boardDTO.setBoardTitle(title);

		if (title.length() > 255) {
			System.out.println("[게시글 작성 로그] 실패: 제목 길이 초과 len=" + title.length());
			return message(model, "제목은 255자 이내로 작성해주세요.", "/boardWritePage?boardCategory=" + category); // ✅ CHANGED
		}

		if (content == null || content.trim().isEmpty()) {
			System.out.println("[게시글 작성 로그] 실패: 내용 없음");
			return message(model, "내용은 필수입니다.", "/boardWritePage?boardCategory=" + category); // ✅ CHANGED
		}
		content = content.trim();
		boardDTO.setBoardContent(content);

		// =========================================================
		// 3) 최소 XSS 방어 (기존 로직 유지)
		String lowerContent = content.toLowerCase();
		if (lowerContent.contains("<script") || lowerContent.contains("javascript:")) {
			System.out.println("[게시글 작성 로그] 실패: XSS 의심 태그 포함");
			return message(model, "허용되지 않는 내용이 포함되어 있습니다.", "/boardWritePage?boardCategory=" + category); // ✅ CHANGED
		}

		// =========================================================
		// 4) DTO 세팅 + INSERT 호출
		boardDTO.setMemberId(memberId);
		boardDTO.setCondition("BOARD_INSERT");

		Integer newBoardId = boardService.insertReturnId(boardDTO);

		// =========================================================
		// 5) INSERT 실패 처리
		if (newBoardId == null || newBoardId <= 0) {
			System.out.println("[게시글 작성 로그] 실패: INSERT 실패");
			return message(model, "게시글 작성에 실패했습니다.", "/boardList?boardCategory=" + category); // ✅ CHANGED
		}

		System.out.println("[게시글 작성 로그] 성공: newBoardId=" + newBoardId);

		// =========================================================
		// 6) 성공 시 상세로 redirect (중복 제출 방지)
		return "redirect:/boardDetail?boardId=" + newBoardId;
	}

	// NEW: message.jsp 뷰 렌더링 공통 처리
	private String message(Model model, String msg, String location) {
		model.addAttribute("msg", msg);
		model.addAttribute("location", location);
		return "message";
	}
}
