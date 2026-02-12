package fourcheetah.animale.web.config;

import java.nio.file.Path;
import java.nio.file.Paths;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfigController implements WebMvcConfigurer {

    @Value("${app.upload.root-dir}")
    private String uploadRootDir;
    
    @Autowired
    private SanctionCheckInterceptor sanctionCheckInterceptor;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        Path uploadRoot = Paths.get(uploadRootDir).toAbsolutePath().normalize();
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(uploadRoot.toUri().toString());
    }
    
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(sanctionCheckInterceptor)
                .addPathPatterns(
                    "/boardWrite",           // 게시글 작성
                    "/boardEdit",            // 게시글 수정
                    "/boardDelete",          // 게시글 삭제
                    "/replyWrite",           // 댓글 작성
                    "/replyEdit",            // 댓글 수정
                    "/replyDelete",          // 댓글 삭제
                    "/report/**"             // 신고 기능
                )
                .excludePathPatterns(
                    "/boardList",            // 목록 조회 허용
                    "/boardDetail",          // 상세 조회 허용
                    "/BoardLikeToggle",      // 좋아요 허용
                    "/cash/**"               // 캐시 관련 허용
                );
    }
}