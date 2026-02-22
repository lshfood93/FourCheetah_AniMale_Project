package fourcheetah.animale.web.controller.news;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import fourcheetah.animale.web.common.HtmlSanitizer;
import fourcheetah.animale.web.dto.news.NewsDTO;
import fourcheetah.animale.web.service.news.NewsService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

/**
 * 뉴스 통합 컨트롤러
 * 
 * 기능:
 * - 목록: GET /newsList
 * - 상세: GET /newsDetail
 * - 작성: GET/POST /newsWrite
 * - 수정: GET/POST /newsEdit
 * - 삭제: POST /newsDelete
 * 
 * 통합 이전:
 * - NewsListController
 * - NewsDetailController
 * - NewsWriteController
 * - NewsEditController
 * - NewsDeleteController
 */
@Controller
public class NewsController {

    @Autowired
    private NewsService newsService;
    
    @Autowired
    private HtmlSanitizer htmlSanitizer;

    // ==================== 목록 ====================
    
    /**
     * 뉴스 목록 (페이징 + 검색)
     * 
     * GET /newsList
     * - 페이징 처리
     * - 제목/내용 검색 지원
     * - 페이지당 12개 표시
     */
    @GetMapping("/newsList")
    public String newsList(NewsDTO dto, Model model) {
        
        System.out.println("\n\n================================");
        System.out.println("NewsListAction /newsList 실행됨");
        System.out.println("newsService = " + newsService);
        System.out.println("================================\n\n");
        
        model.addAttribute("activeMenu", "NEWS");

        // 1) 페이지 번호 처리
        int page = (dto.getPage() != 0) ? dto.getPage() : 1;
        if (page < 1) page = 1;
        
        String condition = dto.getCondition();
        String keyword = dto.getKeyword();
        
        int listSize = 12;
        int startNum = (page - 1) * listSize;

        // 2) 검색 여부 확인
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

        // 3) 전체 개수 조회
        NewsDTO countDTO = new NewsDTO();
        if (isSearch) {
            countDTO.setCondition(condition.replace("NEWS_SEARCH", "NEWS_COUNT"));
            countDTO.setKeyword(keyword);
        } else {
            countDTO.setCondition("NEWS_COUNT");
            condition = "NEWS_LIST_PAGE";
        }

        NewsDTO countResult = newsService.selectOne(countDTO);
        int totalCount = (countResult != null) ? countResult.getNewsCount() : 0; 

        // 4) 페이징 계산
        int totalPage = (int) Math.ceil((double) totalCount / listSize);
        if (totalPage == 0) totalPage = 1;
        if (page > totalPage) page = totalPage;

        int blockSize = 5;
        int currentBlock = (int) Math.ceil((double) page / blockSize);
        int startPage = (currentBlock - 1) * blockSize + 1;
        int endPage = Math.min(startPage + blockSize - 1, totalPage);

        boolean hasPrev = (currentBlock > 1);
        boolean hasNext = (endPage < totalPage);

        // 5) 목록 조회
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

        // 6) Model에 데이터 추가
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

    // ==================== 상세 ====================
    
    /**
     * 뉴스 상세
     * 
     * GET /newsDetail?newsId=X
     * - 뉴스 상세 정보 조회
     * - 애니메이션 정보 포함 (JOIN)
     */
    @GetMapping("/newsDetail")
    public String newsDetail(NewsDTO dto, Model model) {
        
        System.out.println("\n\n================================");
        System.out.println(" NewsDetailAction /newsDetail 실행됨");
        System.out.println(" newsId = " + dto.getNewsId());
        System.out.println("================================\n\n");
        
        model.addAttribute("activeMenu", "NEWS");

        int newsId = dto.getNewsId();
        int page = (dto.getPage() != 0) ? dto.getPage() : 1;
        String condition = dto.getCondition();
        String keyword = dto.getKeyword();

        // 1) newsId 유효성 검증
        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 2) 뉴스 상세 조회
        NewsDTO newsDTO = new NewsDTO();
        newsDTO.setNewsId(newsId);
        newsDTO.setCondition("NEWS_DETAIL");

        NewsDTO newsData = newsService.selectOne(newsDTO);

        if (newsData == null) {
            model.addAttribute("msg", "존재하지 않는 뉴스입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }
        
     //  추가
        newsData.setNewsContent(htmlSanitizer.sanitizeNewsHtml(newsData.getNewsContent()));

        // 3) Model에 데이터 추가
        model.addAttribute("newsData", newsData);
        model.addAttribute("page", page);
        model.addAttribute("condition", condition);
        model.addAttribute("keyword", keyword);

        return "newsdetail";
    }

    // ==================== 작성 ====================
    
    /**
     * 뉴스 작성 페이지
     * 
     * GET /newsWrite
     * - 관리자 전용
     */
    @GetMapping("/newsWrite")
    public String newsWritePage(HttpSession session, Model model) {
        
        System.out.println("[뉴스 작성 페이지] GET /newsWrite 시작");

        // 1) 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        // 2) 관리자 권한 체크
        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 작성할 수 있습니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 3) 작성 페이지 이동
        model.addAttribute("type", "NEWS");
        System.out.println("[뉴스 작성 페이지] write.jsp 렌더링");
        return "write";
    }

    /**
     * 뉴스 작성 처리
     * 
     * POST /newsWrite
     * - 제목, 내용, 썸네일 필수
     * - XSS 방지 검증
     * - 파일 업로드 처리
     */
    @PostMapping("/newsWrite")
    public String newsWrite(
            NewsDTO dto,
            @RequestParam("thumbFile") MultipartFile thumbFile,
            HttpSession session,
            HttpServletRequest request,
            Model model,
            RedirectAttributes ra
    ) {
        System.out.println("[뉴스 작성] POST /newsWrite 시작");

        // 1) 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        // 2) 관리자 권한 체크
        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 작성할 수 있습니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 3) 입력값 검증
        Integer animeId = dto.getAnimeId();

        // ✅ [변경] 제목은 일반 텍스트 normalize 적용 (제어문자 제거 + trim)
        String newsTitle = htmlSanitizer.normalizePlainText(dto.getNewsTitle());

        // ✅ [유지] 본문은 리치텍스트이므로 trim만 적용 후 sanitize
        String newsContent = (dto.getNewsContent() == null) ? "" : dto.getNewsContent().trim();

        // 제목 검증
        if (newsTitle.isEmpty()) {
            model.addAttribute("msg", "제목은 필수입니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }
        if (newsTitle.length() > 255) {
            model.addAttribute("msg", "제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        // 내용 검증 (원본 기준)
        if (newsContent.isEmpty()) {
            model.addAttribute("msg", "내용은 필수입니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }
        if (newsContent.length() > 100000) {
            model.addAttribute("msg", "내용이 너무 깁니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        // ✅ [핵심] 서버측 HTML Sanitizing
        String safeNewsContent = htmlSanitizer.sanitizeNewsHtml(newsContent);
        if (safeNewsContent == null || safeNewsContent.trim().isEmpty()) {
            model.addAttribute("msg", "내용이 올바르지 않습니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        // (보조) 문자열 기반 차단 - sanitize가 핵심 방어, 이건 보조 유지
        String lowerContent = newsContent.toLowerCase();
        if (lowerContent.contains("<script") || lowerContent.contains("javascript:")) {
            model.addAttribute("msg", "허용되지 않는 내용이 포함되어 있습니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        // 썸네일 파일 검증
        if (thumbFile == null || thumbFile.isEmpty()) {
            model.addAttribute("msg", "썸네일은 필수입니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }

        // 4) 파일 업로드 + DB 저장
        try {
            String thumbnailUrl = saveFile(thumbFile, "/upload/newsThumb/", request);

            // ✅ [유지] sanitize된 HTML 기준으로 첫 이미지 추출 (더 안전/일관적)
            String newsImageUrl = extractFirstImgSrc(safeNewsContent);

            NewsDTO insertDTO = new NewsDTO();
            insertDTO.setAnimeId(animeId);
            insertDTO.setNewsTitle(newsTitle);             // ✅ normalize된 제목 저장
            insertDTO.setNewsContent(safeNewsContent);     // ✅ sanitize된 본문 저장
            insertDTO.setNewsThumbnailUrl(thumbnailUrl);
            insertDTO.setNewsImageUrl(newsImageUrl);
            insertDTO.setCondition("NEWS_INSERT");

            boolean result = newsService.insert(insertDTO);

            if (!result) {
                model.addAttribute("msg", "뉴스 작성에 실패했습니다.");
                model.addAttribute("location", "/newsWrite");
                return "message";
            }

            int newsId = insertDTO.getNewsId();
            if (newsId <= 0) {
                model.addAttribute("msg", "뉴스 ID 생성에 실패했습니다.");
                model.addAttribute("location", "/newsList");
                return "message";
            }

            System.out.println("[뉴스 작성] 완료 - newsId=" + newsId);
            ra.addFlashAttribute("msg", "뉴스 작성 완료!");
            return "redirect:/newsDetail?newsId=" + newsId;

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("msg", "파일 업로드 중 오류가 발생했습니다.");
            model.addAttribute("location", "/newsWrite");
            return "message";
        }
    }

    // ==================== 수정 ====================
    
    /**
     * 뉴스 수정 페이지
     * 
     * GET /newsEdit?newsId=X
     * - 관리자 전용
     * - 기존 데이터 로드
     */
    @GetMapping("/newsEdit")
    public String newsEditPage(
            NewsDTO dto,
            HttpSession session,
            Model model
    ) {
        System.out.println("[뉴스 수정 페이지] GET /newsEdit?newsId=" + dto.getNewsId());

        // 1) 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        // 2) 관리자 권한 체크
        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 수정할 수 있습니다.");
            model.addAttribute("location", "/newsDetail?newsId=" + dto.getNewsId());
            return "message";
        }

        // 3) newsId 유효성 검증
        int newsId = dto.getNewsId();
        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 4) 뉴스 데이터 조회
        NewsDTO searchDTO = new NewsDTO();
        searchDTO.setNewsId(newsId);
        searchDTO.setCondition("NEWS_DETAIL");

        NewsDTO newsData = newsService.selectOne(searchDTO);

        if (newsData == null) {
            model.addAttribute("msg", "존재하지 않는 뉴스입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // ✅ [추가] 수정 화면 진입 시에도 본문 sanitize
        // - 레거시 데이터/이상 HTML이 textarea로 그대로 내려가는 것 방지
        // - boardEditPage에서 한 방식과 동일한 방어
        newsData.setNewsContent(
                htmlSanitizer.sanitizeNewsHtml(newsData.getNewsContent())
        );

        // 5) 수정 페이지 이동
        model.addAttribute("type", "NEWS");
        model.addAttribute("newsData", newsData);
        System.out.println("[뉴스 수정 페이지] edit.jsp 렌더링 - newsId=" + newsId);
        return "edit";
    }

    /**
     * 뉴스 수정 처리
     * 
     * POST /newsEdit
     * - 제목, 내용 필수
     * - 파일 업로드 선택사항
     * - 기존 파일 유지 가능
     */
    @PostMapping("/newsEdit")
    public String newsEdit(
            NewsDTO dto,
            @RequestParam(required = false) String existingThumbUrl,
            @RequestParam(required = false) String existingImageUrl,
            @RequestParam(value = "thumbFile", required = false) MultipartFile thumbFile,
            @RequestParam(value = "newsImageFile", required = false) MultipartFile newsImageFile,
            HttpSession session,
            HttpServletRequest request,
            Model model,
            RedirectAttributes ra
    ) {
        System.out.println("[뉴스 수정] POST /newsEdit 시작 - newsId=" + dto.getNewsId());

        // 1) 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        // 2) 관리자 권한 체크
        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 수정할 수 있습니다.");
            model.addAttribute("location", "/newsDetail?newsId=" + dto.getNewsId());
            return "message";
        }

        // 3) newsId 유효성 검증
        int newsId = dto.getNewsId();
        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 4) 입력값 검증
        // ✅ [변경] 제목은 일반 텍스트 normalize 적용
        String newsTitle = htmlSanitizer.normalizePlainText(dto.getNewsTitle());

        // ✅ [유지] 본문은 리치텍스트이므로 trim 후 sanitize
        String newsContent = (dto.getNewsContent() == null) ? "" : dto.getNewsContent().trim();

        // 제목 검증
        if (newsTitle.isEmpty()) {
            model.addAttribute("msg", "제목은 필수입니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }
        if (newsTitle.length() > 255) {
            model.addAttribute("msg", "제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }

        // 내용 검증
        if (newsContent.isEmpty()) {
            model.addAttribute("msg", "내용은 필수입니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }
        if (newsContent.length() > 100000) {
            model.addAttribute("msg", "내용이 너무 깁니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }

        // ✅ [핵심] 서버측 HTML Sanitizing
        String safeNewsContent = htmlSanitizer.sanitizeNewsHtml(newsContent);
        if (safeNewsContent == null || safeNewsContent.trim().isEmpty()) {
            model.addAttribute("msg", "내용이 올바르지 않습니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }

        // (보조) 문자열 기반 차단
        String lowerContent = newsContent.toLowerCase();
        if (lowerContent.contains("<script") || lowerContent.contains("javascript:")) {
            model.addAttribute("msg", "허용되지 않는 내용이 포함되어 있습니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }

        // 5) 파일 업로드 + DB 업데이트
        try {
            // 썸네일: 새 파일이 있으면 업로드, 없으면 기존 URL 유지
            String thumbnailUrl = existingThumbUrl;
            if (thumbFile != null && !thumbFile.isEmpty()) {
                thumbnailUrl = saveFile(thumbFile, "/upload/newsThumb/", request);
            }

            // 이미지: 새 파일이 있으면 업로드, 없으면 기존 URL 유지
            String newsImageUrl = existingImageUrl;
            if (newsImageFile != null && !newsImageFile.isEmpty()) {
                newsImageUrl = saveFile(newsImageFile, "/upload/newsImage/", request);
            }

            // 이미지 URL이 없으면 content에서 추출 (sanitize 결과 기준)
            if (newsImageUrl == null || newsImageUrl.isEmpty()) {
                newsImageUrl = extractFirstImgSrc(safeNewsContent);
            }

            // DB 업데이트
            NewsDTO updateDTO = new NewsDTO();
            updateDTO.setNewsId(newsId);
            updateDTO.setAnimeId(dto.getAnimeId());
            updateDTO.setNewsTitle(newsTitle);             // ✅ normalize된 제목 저장
            updateDTO.setNewsContent(safeNewsContent);     // ✅ sanitize된 본문 저장
            updateDTO.setNewsThumbnailUrl(thumbnailUrl);
            updateDTO.setNewsImageUrl(newsImageUrl);
            updateDTO.setCondition("NEWS_UPDATE");

            boolean result = newsService.update(updateDTO);

            if (!result) {
                model.addAttribute("msg", "뉴스 수정에 실패했습니다.");
                model.addAttribute("location", "/newsDetail?newsId=" + newsId);
                return "message";
            }

            System.out.println("[뉴스 수정] 완료 - newsId=" + newsId);
            ra.addFlashAttribute("msg", "뉴스 수정 완료!");
            return "redirect:/newsDetail?newsId=" + newsId;

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("msg", "파일 업로드 중 오류가 발생했습니다.");
            model.addAttribute("location", "/newsEdit?newsId=" + newsId);
            return "message";
        }
    }
    
    // ==================== 삭제 ====================
    
    /**
     * 뉴스 삭제
     * 
     * POST /newsDelete
     * - 관리자 전용
     * - 물리적 삭제
     */
    @PostMapping("/newsDelete")
    public String newsDelete(NewsDTO dto, HttpSession session, Model model) {
        
        int newsId = dto.getNewsId();

        // 1) 로그인 체크
        if (session == null || session.getAttribute("memberId") == null) {
            model.addAttribute("msg", "로그인이 필요한 기능입니다.");
            model.addAttribute("location", "/login");
            return "message";
        }

        // 2) 관리자 권한 체크
        String memberRole = (String) session.getAttribute("memberRole");
        if (!"ADMIN".equals(memberRole)) {
            model.addAttribute("msg", "관리자만 삭제할 수 있습니다.");
            model.addAttribute("location", "/newsDetail?newsId=" + newsId);
            return "message";
        }

        // 3) newsId 유효성 검증
        if (newsId <= 0) {
            model.addAttribute("msg", "잘못된 뉴스 접근입니다.");
            model.addAttribute("location", "/newsList");
            return "message";
        }

        // 4) 삭제 처리
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

    // ==================== 유틸리티 메서드 ====================
    
    /**
     * 파일 저장
     * 
     * @param file 업로드할 파일
     * @param webDir 웹 경로 (예: /upload/newsThumb/)
     * @return 저장된 파일의 웹 경로
     */
    private String saveFile(MultipartFile file, String webDir, HttpServletRequest request) throws Exception {
        // 확장자 추출
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }

        // UUID 기반 파일명 생성
        String savedName = UUID.randomUUID().toString() + extension;
        String uploadPath = System.getProperty("user.dir") + "/src/main/webapp" + webDir;
        Path dirPath = Paths.get(uploadPath);

        // 디렉토리 생성 (없으면)
        if (!Files.exists(dirPath)) {
            Files.createDirectories(dirPath);
        }

        // 파일 저장
        Path savedPath = dirPath.resolve(savedName);
        try (InputStream inputStream = file.getInputStream()) {
            Files.copy(inputStream, savedPath, StandardCopyOption.REPLACE_EXISTING);
        }

        return request.getContextPath() + webDir + savedName;
    }

    /**
     * HTML 내용에서 첫 번째 이미지 src 추출
     * 
     * @param content HTML 내용
     * @return 첫 번째 이미지 URL (없으면 null)
     */
    private String extractFirstImgSrc(String content) {
        Pattern pattern = Pattern.compile("<img[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"]", Pattern.CASE_INSENSITIVE);
        Matcher matcher = pattern.matcher(content);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }
}