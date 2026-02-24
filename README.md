# 🐾 ANIMale

애니메이션 정보와 커뮤니티 기능을 <br/>
중심으로 만든 웹 서비스 프로젝트입니다.<br/>
Spring Boot + JSP 기반으로 구현했으며,<br/>
회원/게시판/댓글/뉴스/애니리스트/결제/관리자 기능을 포함합니다.

기존 중간 프로젝트(Java Servlet/JSP + FrontController) 구조를 바탕으로, <br/>
최종 프로젝트에서 Spring Boot 구조로 확장/리팩토링했습니다.

---

## 📌 프로젝트 개요

ANIMale은 애니메이션 콘텐츠를 탐색하고, <br/>
커뮤니티에서 글/댓글/좋아요/신고 기능을 <br/>
사용할 수 있는 웹 커뮤니티 서비스입니다.

주요 목표
- 애니메이션 정보 탐색(리스트/상세)
- 커뮤니티 활동(게시글/댓글/좋아요/신고)
- 뉴스 운영(관리자 CRUD)
- 회원 관리(가입/로그인/비밀번호 재설정/마이페이지)
- 유료 커스터마이징(프로필/닉네임 꾸미기, 캐시 충전)
- 관리자 대시보드(캐시 운영 지표/신고 제재 처리)
- AI 기반 추천/채팅 기능

---

## 🧩 현재 프로젝트 기준 주요 변경점 (기존 README 대비)

- Java Servlet/JSP MVC → Spring Boot MVC
- FrontController `*.do` 구조 → `@Controller`, `@RestController` 기반 라우팅
- Oracle DB → MySQL
- Java 11 → Java 17
- 단순 MVC 구조 → Controller / Service / Repository + AOP + Config 분리
- 결제 기능 확장 (카카오페이 + 토스페이먼츠)
- AI 추천/채팅 API 추가
- XSS 방어용 HTML Sanitizer(JSoup) 적용
- 제재/삭제글 접근 차단 AOP 적용

---

## 🛠 기술 스택

### Backend
- Java 17
- Spring Boot (WAR 패키징)
- Spring MVC
- Spring JDBC (JdbcTemplate)
- MyBatis (XML Mapper 일부 기능)
- Spring AOP
- Spring Security Crypto (BCrypt 비밀번호 암호화)

### View / Frontend
- JSP / JSTL
- JavaScript / jQuery
- Bootstrap 기반 UI
- CKEditor (콘텐츠 편집)
- SweetAlert2 (알림 UI 일부)

### Database
- MySQL

### External / Integration
- KakaoPay
- Toss Payments
- SMTP 이메일 발송 (인증코드/제재 안내)
- Google GenAI SDK (AI 추천/채팅)

### Build / Deploy
- Maven
- WAR 배포 (외부 Tomcat 중심)

---

## 🧱 아키텍처 개요

이 프로젝트는 Spring Boot 기반의 레이어드 구조로 구성되어 있습니다.

- Controller
  - 페이지 요청 처리 (`@Controller`)
  - 비동기 API 요청 처리 (`@RestController`)
- Service
  - 비즈니스 로직 처리
- Repository
  - DB 접근 (JdbcTemplate / MyBatis Mapper 혼합)
- DTO
  - 화면/서비스/DB 데이터 전달 객체
- AOP
  - 제재 회원 기능 제한
  - 삭제된 게시글 접근 차단
- Common / Config
  - HTML Sanitizer (XSS 방어)
  - 업로드 리소스 매핑
  - BCrypt PasswordEncoder Bean
  - AI Client 설정

참고)
레거시 호환을 위해 일부 URL 네이밍(`/BoardLikeToggle`, `/ReplyListOrder` 등)은 
기존 스타일이 유지되어 있습니다.

---

## ✨ 주요 기능

### 1) 회원
- 회원가입 / 로그인 / 로그아웃
- 이메일 인증코드 발송 및 검증
- 비밀번호 찾기 / 비밀번호 변경
- 마이페이지
- 프로필 이미지 업로드
- 닉네임/프로필 꾸미기(캐시 사용)
- 회원 탈퇴
- 자동 로그인(쿠키 기반 처리)

### 2) 게시판 / 댓글
- 게시글 CRUD
- 댓글 CRUD
- 게시글 좋아요 (비동기)
- 좋아요 누른 회원 목록 조회 (비동기)
- 댓글 정렬/조회 (비동기)
- 게시글 신고 기능
- 삭제된 게시글 접근 차단(AOP)
- 제재 상태에 따른 기능 제한(AOP)

### 3) 뉴스
- 뉴스 목록 / 상세 조회
- 뉴스 CRUD (관리자)
- 뉴스 작성 시 애니 검색 API 연동
- CKEditor 콘텐츠 이미지 업로드

### 4) 애니메이션
- 애니 리스트 / 상세 조회
- 애니 CRUD (관리자)
- 장르/태그/방영정보 기반 데이터 관리
- API(`/api/anime`) 제공

### 5) 결제 / 캐시
- 카카오페이 결제 준비/승인/취소/실패 처리
- 토스페이먼츠 결제 준비/성공/실패 처리
- 캐시 충전 내역 관리
- 결제 승인 후 회원 캐시 반영

### 6) 관리자
- 관리자 페이지 / 대시보드
- 신고 게시글 처리(승인/반려)
- 제재 누적/경고/정지/영구정지 관리
- 캐시 대시보드 API

### 7) AI 기능
- AI 채팅 위젯
- 사용자 입력 기반 애니 추천 후보 추출/랭킹
- 세션별 대화 상태 관리
- Rate Limit 적용

---

## 🗂 프로젝트 구조 (실제 Spring Boot 구조 기준)
```text
animale/
├─ pom.xml
├─ src/
│  ├─ main/
│  │  ├─ java/fourcheetah/animale/web/
│  │  │  ├─ AnimaleApplication.java
│  │  │  ├─ ServletInitializer.java
│  │  │  ├─ aop/
│  │  │  ├─ common/
│  │  │  ├─ config/
│  │  │  ├─ controller/
│  │  │  │  ├─ admin/
│  │  │  │  ├─ ai/
│  │  │  │  ├─ anime/
│  │  │  │  ├─ board/
│  │  │  │  ├─ common/
│  │  │  │  ├─ member/
│  │  │  │  └─ news/
│  │  │  ├─ dto/
│  │  │  │  ├─ admin/
│  │  │  │  ├─ ai/
│  │  │  │  ├─ anime/
│  │  │  │  ├─ board/
│  │  │  │  ├─ member/
│  │  │  │  └─ news/
│  │  │  ├─ exception/
│  │  │  ├─ repository/
│  │  │  └─ service/
│  │  ├─ resources/
│  │  │  ├─ application.properties
│  │  │  ├─ mappers/
│  │  │  │  ├─ Anime.xml
│  │  │  │  └─ News.xml
│  │  │  └─ static/
│  │  │     ├─ css/
│  │  │     ├─ js/
│  │  │     ├─ images/
│  │  │     ├─ img/
│  │  │     └─ fonts/
│  │  └─ webapp/
│  │     ├─ WEB-INF/
│  │     │  ├─ common/ (header/footer/chatai)
│  │     │  └─ views/  (main, board, anime, news, member, admin JSP)
│  │     └─ error/
│  └─ test/
└─ uploads/ (로컬 개발 업로드 파일 저장용, 환경에 따라 외부 경로 사용)
