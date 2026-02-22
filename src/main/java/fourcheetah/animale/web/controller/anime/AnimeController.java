package fourcheetah.animale.web.controller.anime;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import fourcheetah.animale.web.common.HtmlSanitizer; // ✅ [XSS] 추가
import fourcheetah.animale.web.dto.anime.AnimeDTO;
import fourcheetah.animale.web.service.anime.AnimeService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@Controller
public class AnimeController {

    @Autowired
    private AnimeService animeService;

    @Autowired
    private HtmlSanitizer htmlSanitizer; // ✅ [XSS] 추가: 일반 텍스트 필드 정리/태그 제거용

    // =========================================================
    // 1) 애니 리스트 (GET /animeList)
    @GetMapping("/animeList")
    public String animeList(AnimeDTO dto, BindingResult br, Model model) {

        model.addAttribute("activeMenu", "ANIME");

        // 1) 파라미터 기본값
        String pageStr = dto.getPage();
        String condition = dto.getCondition();
        String keyword = dto.getKeyword();
        String sort = dto.getSort();

        Integer year = dto.getYear();
        Integer quarter = dto.getQuarter();

        // ✅ [XSS] 검색어는 일반 텍스트 필드이므로 plain text sanitize
        // - reflected XSS 방어 (message.jsp / anime.jsp에서 다시 출력될 수 있음)
        // - 검색용 문자열로도 무리 없이 사용 가능
        if (keyword != null) {
            keyword = htmlSanitizer.sanitizePlainText(keyword);
            if (keyword.isEmpty()) {
                keyword = null;
            }
        }

        if (sort == null || sort.trim().isEmpty()) {
            sort = "LATEST";
        }

        // page 파싱
        int page = 1;
        try {
            if (pageStr != null && !pageStr.trim().isEmpty()) {
                page = Integer.parseInt(pageStr);
            }
        } catch (Exception e) {
            page = 1;
        }
        if (page < 1) page = 1;

        // 2) 검색 여부
        boolean isSearch = "ANIME_SEARCH".equals(condition);

        if (isSearch && (keyword == null || keyword.trim().isEmpty())) {
            model.addAttribute("msg", "검색어가 없습니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 3) 페이징 계산용 count 조회
        AnimeDTO countDTO = new AnimeDTO();
        countDTO.setCondition(isSearch ? "ANIME_COUNT_SEARCH" : "ANIME_COUNT");
        countDTO.setKeyword(keyword);
        countDTO.setYear(year);
        countDTO.setQuarter(quarter);

        AnimeDTO countData = animeService.selectOne(countDTO);
        int totalCount = (countData != null) ? countData.getAnimeCount() : 0;

        int rowCount = 12; // 페이지당 개수
        int totalPage = (int) Math.ceil((double) totalCount / rowCount);
        if (totalPage <= 0) totalPage = 1;
        if (page > totalPage) page = totalPage;

        int startRow = (page - 1) * rowCount + 1;
        int endRow = page * rowCount;

        // 페이지 블록 (1 2 3 4 5)
        int blockSize = 5;
        int startPage = ((page - 1) / blockSize) * blockSize + 1;
        int endPage = startPage + blockSize - 1;
        if (endPage > totalPage) endPage = totalPage;

        // 4) 리스트 조회
        AnimeDTO listDTO = new AnimeDTO();
        listDTO.setCondition(isSearch ? "ANIME_SEARCH" : "ANIME_LIST");
        listDTO.setKeyword(keyword);
        listDTO.setSort(sort);
        listDTO.setStartRow(startRow);
        listDTO.setEndRow(endRow);
        listDTO.setYear(year);
        listDTO.setQuarter(quarter);

        List<AnimeDTO> animeList = animeService.selectAll(listDTO);

        // ✅ [선택] 리스트 출력용 제목/원제/줄거리(미리보기)가 JSP에서 raw 출력될 가능성 대비
        // - 전체 항목 루프 sanitize는 비용이 크지 않음(페이지당 12개)
        // - genres/tags(JSON 문자열)는 구조 깨질 수 있어 건드리지 않음
        if (animeList != null) {
            for (AnimeDTO item : animeList) {
                if (item == null) continue;
                item.setAnimeTitle(htmlSanitizer.sanitizePlainText(item.getAnimeTitle()));
                item.setOriginalTitle(htmlSanitizer.sanitizePlainText(item.getOriginalTitle()));
                item.setAnimeStory(htmlSanitizer.sanitizePlainText(item.getAnimeStory()));
            }
        }

        // 5) 모델 바인딩
        model.addAttribute("animeList", animeList);

        model.addAttribute("page", page);
        model.addAttribute("totalPage", totalPage);
        model.addAttribute("startPage", startPage);
        model.addAttribute("endPage", endPage);

        model.addAttribute("condition", condition);
        model.addAttribute("keyword", keyword); // ✅ [XSS] sanitize 반영값
        model.addAttribute("sort", sort);

        model.addAttribute("year", year);
        model.addAttribute("quarter", quarter);

        return "anime";
    }

    // =========================================================
    // 2) 애니 상세 (GET /animeDetail)
    @GetMapping("/animeDetail")
    public String animeDetail(AnimeDTO dto, BindingResult br, Model model) {

        model.addAttribute("activeMenu", "ANIME");

        int animeId = dto.getAnimeId();

        // 1) 파라미터 검증
        if (animeId <= 0) {
            model.addAttribute("msg", "잘못된 애니 접근입니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 2) 상세 조회
        AnimeDTO searchDTO = new AnimeDTO();
        searchDTO.setAnimeId(animeId);
        searchDTO.setCondition("ANIME_DETAIL");

        AnimeDTO animeData = animeService.selectOne(searchDTO);

        if (animeData == null) {
            model.addAttribute("msg", "존재하지 않는 애니입니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // ✅ [XSS] 저장된 레거시 데이터/비정상 데이터 대비 표시 직전 방어
        // - 애니 제목/원제/줄거리는 HTML 허용 안 하는 일반 텍스트 필드라고 가정
        animeData.setAnimeTitle(htmlSanitizer.sanitizePlainText(animeData.getAnimeTitle()));
        animeData.setOriginalTitle(htmlSanitizer.sanitizePlainText(animeData.getOriginalTitle()));
        animeData.setAnimeStory(htmlSanitizer.sanitizePlainText(animeData.getAnimeStory()));

        model.addAttribute("animeData", animeData);
        return "animedetail";
    }

    // =========================================================
    // 3) 애니 작성 페이지 (GET /animeWrite)
    @GetMapping("/animeWrite")
    public String animeWritePage(HttpSession session, Model model) {

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
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 3) 작성 페이지 이동
        model.addAttribute("type", "ANIME");
        return "animewrite";
    }

    // =========================================================
    // 4) 애니 작성 처리 (POST /animeWrite)
    @PostMapping("/animeWrite")
    public String animeWrite(
            AnimeDTO dto,
            @RequestParam(value = "thumbFile", required = false) MultipartFile thumbFile,
            HttpSession session,
            HttpServletRequest request,
            Model model
    ) {

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
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 3) 입력값 검증
        // ✅ [XSS] 일반 텍스트 필드 정리/태그 제거 후 검증
        String animeTitle = htmlSanitizer.sanitizePlainText(dto.getAnimeTitle());
        String originalTitle = htmlSanitizer.sanitizePlainText(dto.getOriginalTitle());
        String animeStory = htmlSanitizer.sanitizePlainText(dto.getAnimeStory());

        Integer animeYear = dto.getAnimeYear();
        String animeQuarter = dto.getAnimeQuarter();
        String animeGenres = dto.getAnimeGenres(); // JSON 문자열 (구조 깨질 수 있어 XSS 패치에서 미변경)
        String animeTags = dto.getAnimeTags();     // JSON 문자열 (구조 깨질 수 있어 XSS 패치에서 미변경)

        // 제목
        if (animeTitle.isEmpty()) {
            model.addAttribute("msg", "애니 제목은 필수입니다.");
            model.addAttribute("location", "/animeWrite");
            return "message";
        }
        if (animeTitle.length() > 255) {
            model.addAttribute("msg", "애니 제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/animeWrite");
            return "message";
        }

        // 원제목 (선택값일 수 있으나 길이 제한은 적용)
        if (originalTitle != null && originalTitle.length() > 255) {
            model.addAttribute("msg", "원제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/animeWrite");
            return "message";
        }

        // 연도/분기
        if (animeYear == null) {
            model.addAttribute("msg", "연도는 필수입니다.");
            model.addAttribute("location", "/animeWrite");
            return "message";
        }

        if (animeQuarter == null || animeQuarter.trim().isEmpty()) {
            model.addAttribute("msg", "분기는 필수입니다.");
            model.addAttribute("location", "/animeWrite");
            return "message";
        }

        animeQuarter = animeQuarter.trim();

        // 줄거리 (일반 텍스트)
        if (animeStory.isEmpty()) {
            model.addAttribute("msg", "줄거리는 필수입니다.");
            model.addAttribute("location", "/animeWrite");
            return "message";
        }

        if (animeStory.length() > 5000) {
            model.addAttribute("msg", "줄거리는 5000자 이내로 작성해주세요.");
            model.addAttribute("location", "/animeWrite");
            return "message";
        }

        // 썸네일 파일 (선택/필수 여부는 기존 정책 유지)
        String thumbUrl = null;
        try {
            if (thumbFile != null && !thumbFile.isEmpty()) {
                thumbUrl = saveFile(thumbFile, "/upload/animeThumb/", request);
            }

            // 4) DTO 세팅 + INSERT
            AnimeDTO insertDTO = new AnimeDTO();
            insertDTO.setAnimeTitle(animeTitle);       // ✅ [XSS] sanitize된 값 저장
            insertDTO.setOriginalTitle(originalTitle); // ✅ [XSS] sanitize된 값 저장
            insertDTO.setAnimeYear(animeYear);
            insertDTO.setAnimeQuarter(animeQuarter);
            insertDTO.setAnimeStory(animeStory);       // ✅ [XSS] sanitize된 값 저장
            insertDTO.setAnimeThumbnailUrl(thumbUrl);

            // JSON 문자열은 구조 보존을 위해 그대로 유지 (XSS 패치 범위 밖)
            insertDTO.setAnimeGenres(animeGenres);
            insertDTO.setAnimeTags(animeTags);

            insertDTO.setCondition("ANIME_INSERT");

            boolean result = animeService.insert(insertDTO);

            if (!result) {
                model.addAttribute("msg", "애니 등록에 실패했습니다.");
                model.addAttribute("location", "/animeWrite");
                return "message";
            }

            model.addAttribute("msg", "애니 등록이 완료되었습니다.");
            model.addAttribute("location", "/animeList");
            return "message";

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("msg", "파일 업로드 중 오류가 발생했습니다.");
            model.addAttribute("location", "/animeWrite");
            return "message";
        }
    }

    // =========================================================
    // 5) 애니 수정 페이지 (GET /animeEdit)
    @GetMapping("/animeEdit")
    public String animeEditPage(AnimeDTO dto, HttpSession session, Model model) {

        int animeId = dto.getAnimeId();

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
            model.addAttribute("location", "/animeDetail?animeId=" + animeId);
            return "message";
        }

        // 3) 파라미터 검증
        if (animeId <= 0) {
            model.addAttribute("msg", "잘못된 애니 접근입니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 4) 기존 데이터 조회
        AnimeDTO searchDTO = new AnimeDTO();
        searchDTO.setAnimeId(animeId);
        searchDTO.setCondition("ANIME_DETAIL");

        AnimeDTO animeData = animeService.selectOne(searchDTO);

        if (animeData == null) {
            model.addAttribute("msg", "존재하지 않는 애니입니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // ✅ [XSS] 수정 폼 진입 시에도 레거시 데이터 방어
        animeData.setAnimeTitle(htmlSanitizer.sanitizePlainText(animeData.getAnimeTitle()));
        animeData.setOriginalTitle(htmlSanitizer.sanitizePlainText(animeData.getOriginalTitle()));
        animeData.setAnimeStory(htmlSanitizer.sanitizePlainText(animeData.getAnimeStory()));

        model.addAttribute("type", "ANIME");
        model.addAttribute("animeData", animeData);
        return "animeedit";
    }

    // =========================================================
    // 6) 애니 수정 처리 (POST /animeEdit)
    @PostMapping("/animeEdit")
    public String animeEdit(
            AnimeDTO dto,
            @RequestParam(value = "thumbFile", required = false) MultipartFile thumbFile,
            HttpSession session,
            HttpServletRequest request,
            Model model
    ) {

        int animeId = dto.getAnimeId();

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
            model.addAttribute("location", "/animeDetail?animeId=" + animeId);
            return "message";
        }

        // 3) 파라미터 검증
        if (animeId <= 0) {
            model.addAttribute("msg", "잘못된 애니 접근입니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 4) 입력값 검증
        // ✅ [XSS] 일반 텍스트 필드 정리/태그 제거 후 검증
        String animeTitle = htmlSanitizer.sanitizePlainText(dto.getAnimeTitle());
        String originalTitle = htmlSanitizer.sanitizePlainText(dto.getOriginalTitle());
        String animeStory = htmlSanitizer.sanitizePlainText(dto.getAnimeStory());

        Integer animeYear = dto.getAnimeYear();
        String animeQuarter = dto.getAnimeQuarter();
        String animeGenres = dto.getAnimeGenres(); // JSON 문자열은 그대로 유지
        String animeTags = dto.getAnimeTags();     // JSON 문자열은 그대로 유지

        if (animeTitle.isEmpty()) {
            model.addAttribute("msg", "애니 제목은 필수입니다.");
            model.addAttribute("location", "/animeEdit?animeId=" + animeId);
            return "message";
        }
        if (animeTitle.length() > 255) {
            model.addAttribute("msg", "애니 제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/animeEdit?animeId=" + animeId);
            return "message";
        }

        if (originalTitle != null && originalTitle.length() > 255) {
            model.addAttribute("msg", "원제목은 255자 이내로 작성해주세요.");
            model.addAttribute("location", "/animeEdit?animeId=" + animeId);
            return "message";
        }

        if (animeYear == null) {
            model.addAttribute("msg", "연도는 필수입니다.");
            model.addAttribute("location", "/animeEdit?animeId=" + animeId);
            return "message";
        }

        if (animeQuarter == null || animeQuarter.trim().isEmpty()) {
            model.addAttribute("msg", "분기는 필수입니다.");
            model.addAttribute("location", "/animeEdit?animeId=" + animeId);
            return "message";
        }

        animeQuarter = animeQuarter.trim();

        if (animeStory.isEmpty()) {
            model.addAttribute("msg", "줄거리는 필수입니다.");
            model.addAttribute("location", "/animeEdit?animeId=" + animeId);
            return "message";
        }

        if (animeStory.length() > 5000) {
            model.addAttribute("msg", "줄거리는 5000자 이내로 작성해주세요.");
            model.addAttribute("location", "/animeEdit?animeId=" + animeId);
            return "message";
        }

        // 5) 기존 데이터 조회 (존재 확인 + 썸네일 유지용)
        AnimeDTO originDTO = new AnimeDTO();
        originDTO.setAnimeId(animeId);
        originDTO.setCondition("ANIME_DETAIL");
        AnimeDTO origin = animeService.selectOne(originDTO);

        if (origin == null) {
            model.addAttribute("msg", "존재하지 않는 애니입니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        try {
            // 썸네일 처리: 새 파일 있으면 업로드, 없으면 기존 값 유지
            String thumbUrl = origin.getAnimeThumbnailUrl();
            if (thumbFile != null && !thumbFile.isEmpty()) {
                thumbUrl = saveFile(thumbFile, "/upload/animeThumb/", request);
            }

            // 6) UPDATE
            AnimeDTO updateDTO = new AnimeDTO();
            updateDTO.setAnimeId(animeId);
            updateDTO.setAnimeTitle(animeTitle);       // ✅ [XSS] sanitize된 값 저장
            updateDTO.setOriginalTitle(originalTitle); // ✅ [XSS] sanitize된 값 저장
            updateDTO.setAnimeYear(animeYear);
            updateDTO.setAnimeQuarter(animeQuarter);
            updateDTO.setAnimeStory(animeStory);       // ✅ [XSS] sanitize된 값 저장
            updateDTO.setAnimeThumbnailUrl(thumbUrl);

            // JSON 문자열은 구조 보존 위해 그대로 유지
            updateDTO.setAnimeGenres(animeGenres);
            updateDTO.setAnimeTags(animeTags);

            updateDTO.setCondition("ANIME_UPDATE");

            boolean result = animeService.update(updateDTO);

            if (!result) {
                model.addAttribute("msg", "애니 수정에 실패했습니다.");
                model.addAttribute("location", "/animeDetail?animeId=" + animeId);
                return "message";
            }

            model.addAttribute("msg", "애니 수정이 완료되었습니다.");
            model.addAttribute("location", "/animeDetail?animeId=" + animeId);
            return "message";

        } catch (Exception e) {
            e.printStackTrace();
            model.addAttribute("msg", "파일 업로드 중 오류가 발생했습니다.");
            model.addAttribute("location", "/animeEdit?animeId=" + animeId);
            return "message";
        }
    }

    // =========================================================
    // 7) 애니 삭제 (POST /animeDelete)
    @PostMapping("/animeDelete")
    public String animeDelete(AnimeDTO dto, HttpSession session, Model model) {

        int animeId = dto.getAnimeId();

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
            model.addAttribute("location", "/animeDetail?animeId=" + animeId);
            return "message";
        }

        // 3) 파라미터 검증
        if (animeId <= 0) {
            model.addAttribute("msg", "잘못된 애니 접근입니다.");
            model.addAttribute("location", "/animeList");
            return "message";
        }

        // 4) DELETE
        AnimeDTO deleteDTO = new AnimeDTO();
        deleteDTO.setAnimeId(animeId);
        deleteDTO.setCondition("ANIME_DELETE");

        boolean result = animeService.delete(deleteDTO);

        if (!result) {
            model.addAttribute("msg", "애니 삭제에 실패했습니다.");
            model.addAttribute("location", "/animeDetail?animeId=" + animeId);
            return "message";
        }

        model.addAttribute("msg", "애니가 삭제되었습니다.");
        model.addAttribute("location", "/animeList");
        return "message";
    }

    // =========================================================
    // 유틸리티: 파일 저장
    private String saveFile(MultipartFile file, String webDir, HttpServletRequest request) throws Exception {
        String originalFilename = file.getOriginalFilename();
        String extension = "";

        if (originalFilename != null && originalFilename.lastIndexOf(".") != -1) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }

        String savedName = UUID.randomUUID().toString() + extension;

        // 프로젝트 기준 저장 경로 (기존 구조 유지)
        String uploadDir = System.getProperty("user.dir") + "/src/main/webapp" + webDir;
        Path dirPath = Paths.get(uploadDir);

        if (!Files.exists(dirPath)) {
            Files.createDirectories(dirPath);
        }

        Path savePath = dirPath.resolve(savedName);

        try (InputStream is = file.getInputStream()) {
            Files.copy(is, savePath, StandardCopyOption.REPLACE_EXISTING);
        }

        // 웹 접근 경로 반환 (ctx 포함)
        return request.getContextPath() + webDir + savedName;
    }
}