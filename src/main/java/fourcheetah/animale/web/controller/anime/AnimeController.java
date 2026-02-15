package fourcheetah.animale.web.controller.anime;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.service.anime.AnimeService;
import jakarta.servlet.http.HttpSession;

@Controller
public class AnimeController {
	
	@Autowired
    private AnimeService animeService;
	
	@Value("${app.upload.anime-dir:${app.upload.root-dir}/anime}")
	private String animeUploadDir;

	@Value("${app.upload.anime-url-prefix:/uploads/anime}")
	private String animeUrlPrefix;
    
    /*
     * [역할]
     * 1) 로그인 체크
     * 2) 관리자 권한 체크
     * 3) 통과하면 animewrite.jsp(뷰)로 이동
     * 4) 실패하면 message.jsp(alert + location.href)로 이동
     *
     * ※ 부트에서는 "뷰 이름 리턴" = forward(포워드)와 동일한 효과
     *    - return "animewrite";  => /WEB-INF/views/animewrite.jsp 렌더링
     *    - return "redirect:/..."; => 리다이렉트
     */
    @GetMapping("/animeWritePage")
    public String animeWritePage(HttpSession session, Model model) {

        // 1) 로그인 체크
        Object memberId = (session == null) ? null : session.getAttribute("memberId");
        // (혹시 로그인 컨트롤러에서 userId로 넣는 경우도 있어서 안전빵)
        if (memberId == null && session != null) {
            memberId = session.getAttribute("userId");
        }

        if (memberId == null) {
            System.out.println("[애니 추가 이동 로그] 세션 없음 : 로그인 필요");
            model.addAttribute("msg", "로그인 정보가 없습니다.");
            model.addAttribute("location", "/loginPage");
            return "message";
        }

        // 2) 관리자 권한 체크
        Object roleObj = session.getAttribute("memberRole");
        if (roleObj == null) roleObj = session.getAttribute("userRole"); // 안전빵

        String memberRole = (roleObj == null) ? "" : roleObj.toString();
        System.out.println("[애니 추가 이동 로그] 세션 : memberId=[" + memberId + "]");
        System.out.println("[애니 추가 이동 로그] 세션 : memberRole=[" + memberRole + "]");

        if (!"ADMIN".equalsIgnoreCase(memberRole)) {
            model.addAttribute("msg", "관리자만 접근할 수 있습니다.");
            model.addAttribute("location", "/main");   // 너희 메인 매핑에 맞게 바꿔도 됨 (/main, /index 등)
            return "message";
        }

        // 3) 통과 → 작성 페이지로 forward
        return "animewrite"; // /WEB-INF/views/animewrite.jsp
    }

    @PostMapping("/animeWrite")
    public String writeAnime(
            AnimeDTO dto,                 // 커맨드객체 바인딩
            BindingResult br,             // 타입 변환 실패(예: year) 감지용
            HttpSession session,
            Model model,
            RedirectAttributes ra
    ) {
        System.out.println("[애니 추가 액션] start");

        // 0) 로그인/관리자 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인 정보가 없습니다.");
            model.addAttribute("location", "/loginPage");
            return "message";
        }

        Object roleObj = session.getAttribute("memberRole");
        String role = (roleObj == null) ? "" : roleObj.toString();
        if (!"ADMIN".equalsIgnoreCase(role)) {
            model.addAttribute("msg", "관리자만 접근할 수 있습니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 1) 바인딩 타입 오류(예: animeYear에 문자가 들어온 경우)
        if (br != null && br.hasErrors()) {
            model.addAttribute("errorMsg", "입력 값 형식이 올바르지 않습니다.");
            return "animewrite";
        }

        // 2) 필수값 검증
        String animeTitle = (dto.getAnimeTitle() == null) ? "" : dto.getAnimeTitle().trim();
        if (animeTitle.isEmpty()) {
            model.addAttribute("errorMsg", "애니 제목은 필수입니다.");
            return "animewrite";
        }

        Integer animeYear = dto.getAnimeYear();
        if (animeYear == null) {
            model.addAttribute("errorMsg", "연도 값이 올바르지 않습니다.");
            return "animewrite";
        }

        String animeQuarter = (dto.getAnimeQuarter() == null) ? "" : dto.getAnimeQuarter().trim();
        if (animeQuarter.isEmpty()) {
            model.addAttribute("errorMsg", "분기 값이 올바르지 않습니다.");
            return "animewrite";
        }

        // 3) 파일 필수 + 확장자 검증
        MultipartFile thumbFile = dto.getThumbFile();
        if (thumbFile == null || thumbFile.isEmpty()) {
            model.addAttribute("errorMsg", "썸네일 이미지를 선택해주세요.");
            return "animewrite";
        }

        String originalName = thumbFile.getOriginalFilename();
        String ext = extractExtLower(originalName);
        if (!(ext.equals(".jpg") || ext.equals(".jpeg") || ext.equals(".png") || ext.equals(".webp"))) {
            model.addAttribute("errorMsg", "이미지 파일(jpg, jpeg, png, webp)만 업로드 가능합니다.");
            return "animewrite";
        }

        // 4) 저장 + DB URL 세팅
        try {
            String savedName = UUID.randomUUID().toString().replace("-", "") + ext;

            Path dir = Paths.get(animeUploadDir).toAbsolutePath().normalize();
            Files.createDirectories(dir);

            Path target = dir.resolve(savedName);
            thumbFile.transferTo(target.toFile());

            String thumbnailUrl = animeUrlPrefix + "/" + savedName;

            // 5) 서버에서 값 정리/세팅 (클라 입력값 그대로 신뢰 X)
            dto.setAnimeTitle(animeTitle);
            if (dto.getOriginalTitle() != null) dto.setOriginalTitle(dto.getOriginalTitle().trim());
            if (dto.getAnimeStory() != null) dto.setAnimeStory(dto.getAnimeStory().trim());

            dto.setAnimeThumbnailUrl(thumbnailUrl);
            dto.setCondition("ANIME_INSERT");

            // 6) INSERT
            boolean ok = animeService.insert(dto);
            if (!ok) {
                model.addAttribute("errorMsg", "애니 등록에 실패했습니다.");
                return "animewrite";
            }

            ra.addFlashAttribute("msg", "애니 등록 완료!");
            return "redirect:/animeList";

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("errorMsg", "처리 중 오류가 발생했습니다: " + e.getMessage());
            return "animewrite";
        }
    }
    
    @GetMapping("/animeList")
    public String animeList(AnimeDTO dto, Model model) {

        model.addAttribute("activeMenu", "ANILIST");

        String condition = dto.getCondition();
        String keyword = dto.getKeyword();

        // 1) 검색 분기값
        System.out.println("[애니리스트 이동 로그] condition : [" + condition + "]");
        System.out.println("[애니리스트 이동 로그] keyword : [" + keyword + "]");

        // 보정: 검색 조건 외 값은 기본 목록
        if (!"ANIME_SEARCH_TITLE".equals(condition) && !"ANIME_SEARCH_STORY".equals(condition)) {
            condition = "ANIME_LIST_RECENT";
        }

        // 2) 검색 여부
        boolean isSearch = "ANIME_SEARCH_TITLE".equals(condition) || "ANIME_SEARCH_STORY".equals(condition);
        System.out.println("[애니리스트 이동 로그] isSearch : [" + isSearch + "]");

        // 3) keyword 정리
        if (keyword != null) {
            keyword = keyword.trim();
        }

        // 4) 검색인데 keyword가 없으면 차단
        if (isSearch && (keyword == null || keyword.isEmpty())) {
            model.addAttribute("msg", "검색어가 없습니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 5) 검색 아닌 경우 빈 문자열이면 null로 정리
        if (!isSearch && keyword != null && keyword.isEmpty()) {
            keyword = null;
        }

        // 6) JSP에 전달 (폼 상태 유지 + JS 비동기 호출 파라미터로 재사용)
        System.out.println("[애니리스트 이동 로그] 최종 condition : [" + condition + "]");
        System.out.println("[애니리스트 이동 로그] 최종 keyword : [" + keyword + "]");

        model.addAttribute("condition", condition);
        model.addAttribute("keyword", keyword);

        return "anime";
    }
    
    /*
     * 변경 포인트
     * - 요청: /animeDetail?animeId=1
     * - 수신: 커맨드객체(AnimeDTO) 바인딩으로 animeId 자동 세팅
     */
    @GetMapping("/animeDetail")
    public String animeDetail(AnimeDTO dto, Model model) {

        model.addAttribute("activeMenu", "ANILIST");

        // 1) animeId 검증 (커맨드객체로 받은 값)
        int animeId = dto.getAnimeId();

        if (animeId <= 0) {
            System.out.println("[애니 상세보기 로그] 조회 실패 : animeId 유효하지 않음");
            model.addAttribute("msg", "잘못된 애니 선택입니다...");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 2) selectOne
        dto.setCondition("ANIME_DETAIL");
        System.out.println("[애니 상세 로그] param animeId = [" + animeId + "]");

        AnimeDTO animeData = animeService.selectOne(dto);

        System.out.println("[애니 상세 로그] selectOne result = " + animeData);

        // 3) 존재여부 검사
        if (animeData == null) {
            System.out.println("[애니 상세보기 로그] 조회 실패 : 해당 애니는 없는 애니");
            model.addAttribute("msg", "잘못된 애니 선택입니다...");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 4) 썸네일 경로 보정
        String thumb = animeData.getAnimeThumbnailUrl();
        if (thumb != null && !thumb.startsWith("/")) {
            animeData.setAnimeThumbnailUrl("/" + thumb);
        }

        System.out.println("[애니 상세보기 로그] 조회 완료 : animeData = [" + animeData + "]");

        // 5) 결과 담아서 페이지 전달
        model.addAttribute("animeData", animeData);
        return "animedetail";
    }  
    
    @GetMapping("/animeEditPage")
    public String animeEditPage(
            AnimeDTO dto,          // 커맨드객체 바인딩 (animeId 자동 세팅)
            HttpSession session,
            Model model
    ) {

        // 1) 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            System.out.println("[애니 수정 이동 로그] 세션 없음 또는 memberId 유효하지 않음");
            model.addAttribute("msg", "잘못된 접근입니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 2) 관리자 권한 체크
        Object roleObj = session.getAttribute("memberRole");
        String memberRole = (roleObj == null) ? "" : roleObj.toString();
        System.out.println("[애니 수정 이동 로그] 로그인 유저 ROLE : memberRole [" + memberRole + "]");

        if (!"ADMIN".equalsIgnoreCase(memberRole)) {
            System.out.println("[애니 수정 이동 로그] 관리자 권한 없음 : [" + memberRole + "]");
            model.addAttribute("msg", "관리자만 접근할 수 있습니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 3) animeId 검증 (DTO에서 꺼내기)
        int animeId = dto.getAnimeId();
        System.out.println("[애니 수정 이동 로그] 애니 PK 검사 : animeId [" + animeId + "]");

        if (animeId <= 0) {
            model.addAttribute("msg", "잘못된 애니 접근입니다.");
            model.addAttribute("location", "/mainPage");
            return "message";
        }

        // 4) 조회 (DTO 재활용)
        dto.setCondition("ANIME_DETAIL");
        AnimeDTO animeData = animeService.selectOne(dto);
        System.out.println("[애니 수정 이동 로그] 애니 조회 완료 : animeData = [" + animeData + "]");

        // 5) 존재여부 검사
        if (animeData == null) {
            model.addAttribute("msg", "존재하지 않는 애니입니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 6) 수정 페이지 forward
        model.addAttribute("animeData", animeData);
        return "animeedit";
    }

    // 커맨드객체(AnimeDTO)로 통일: /animeEdit?animeId=...
    @PostMapping("/animeEdit")
    public String editAnime(
            AnimeDTO dto,                 // 커맨드객체 바인딩
            BindingResult br,              // 타입 변환 오류 등 받기용(선택)
            HttpSession session,
            RedirectAttributes ra
    ) {
        // 0) 로그인 체크
        Object memberId = (session == null) ? null : session.getAttribute("memberId");
        if (memberId == null) {
            return "redirect:/loginPage";
        }

        int animeId = dto.getAnimeId();

        // 0-1) 관리자 체크
        Object roleObj = session.getAttribute("memberRole");
        String role = (roleObj == null) ? "" : roleObj.toString();
        if (!"ADMIN".equalsIgnoreCase(role)) {
            ra.addAttribute("animeId", animeId);
            ra.addFlashAttribute("msg", "권한이 없습니다.");
            return "redirect:/animeDetail";
        }

        // 0-2) 바인딩/타입변환 오류(예: animeYear에 문자가 들어온 경우)
        if (br.hasErrors()) {
            ra.addAttribute("animeId", animeId);
            ra.addFlashAttribute("msg", "입력값 형식이 올바르지 않습니다.");
            return "redirect:/animeEditPage";
        }

        // 1) PK 검증
        if (animeId <= 0) {
            ra.addFlashAttribute("msg", "잘못된 요청입니다.");
            return "redirect:/animeList";
        }

        // 2) 필수값 체크(최소)
        if (dto.getAnimeTitle() == null || dto.getAnimeTitle().trim().isEmpty()) {
            ra.addAttribute("animeId", animeId);
            ra.addFlashAttribute("msg", "제목은 필수입니다.");
            return "redirect:/animeEditPage";
        }

        // 3) 썸네일 기본은 기존값 유지 (hidden 값)
        // 폼에서 existingThumbUrl 이라는 name으로 넘어온다고 가정
        String thumbnailUrl = (dto.getExistingThumbUrl() == null) ? null : dto.getExistingThumbUrl().trim();

        // 4) 새 파일이 들어오면 저장하고 URL 갱신
        MultipartFile thumbFile = dto.getThumbFile();
        if (thumbFile != null && !thumbFile.isEmpty()) {
            try {
                String originalName = thumbFile.getOriginalFilename();
                String ext = extractExtLower(originalName);

                if (!(ext.equals(".jpg") || ext.equals(".jpeg") || ext.equals(".png") || ext.equals(".webp"))) {
                    ra.addAttribute("animeId", animeId);
                    ra.addFlashAttribute("msg", "이미지 파일(jpg, jpeg, png, webp)만 업로드 가능합니다.");
                    return "redirect:/animeEditPage";
                }

                String savedName = UUID.randomUUID().toString().replace("-", "") + ext;

                Path dir = Paths.get(animeUploadDir).toAbsolutePath().normalize();
                Files.createDirectories(dir);

                Path target = dir.resolve(savedName);
                thumbFile.transferTo(target.toFile());

                thumbnailUrl = animeUrlPrefix + "/" + savedName;

            } catch (Exception e) {
                e.printStackTrace();
                ra.addAttribute("animeId", animeId);
                ra.addFlashAttribute("msg", "썸네일 업로드 중 오류가 발생했습니다.");
                return "redirect:/animeEditPage";
            }
        }

        // 5) 업데이트 (컨디션은 서버에서 세팅)
        dto.setAnimeId(animeId);
        dto.setAnimeTitle(dto.getAnimeTitle().trim());
        dto.setAnimeThumbnailUrl(thumbnailUrl);
        dto.setCondition("ANIME_UPDATE");

        boolean ok = animeService.update(dto);

        ra.addAttribute("animeId", animeId);
        if (!ok) {
            ra.addFlashAttribute("msg", "수정에 실패했습니다. (대상 없음 또는 처리 실패)");
            return "redirect:/animeDetail";
        }

        return "redirect:/animeDetail";
    }
    
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
       if (animeService.delete(dto)) {
           System.out.println("[로그] 애니 삭제 성공");
           ra.addFlashAttribute("msg", "삭제되었습니다.");
           return "redirect:/animeList";
           
       } else {
       	ra.addAttribute("animeId", animeId);
           ra.addFlashAttribute("errorMsg", "삭제에 실패했습니다. (대상 없음/이미 삭제됨)");            
           return "redirect:/animeDetail"; // 쿼리 파라미터 스타일
       }
   }
   
   private String extractExtLower(String filename) {
       if (filename == null) return "";
       int dot = filename.lastIndexOf('.');
       if (dot == -1) return "";
       return filename.substring(dot).toLowerCase();
   }

}
