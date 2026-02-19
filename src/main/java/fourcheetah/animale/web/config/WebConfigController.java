package fourcheetah.animale.web.config;

import java.nio.file.Path;
import java.nio.file.Paths;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfigController implements WebMvcConfigurer {

    @Value("${app.upload.root-dir}")
    private String uploadRootDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 1. 절대경로 업로드 파일 (기존)
        Path uploadRoot = Paths.get(uploadRootDir).toAbsolutePath().normalize();
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(uploadRoot.toUri().toString());
        
        // 2. static 리소스 (추가!) - Spring Boot 기본 동작이지만 명시적으로 추가
        registry.addResourceHandler("/css/**")
                .addResourceLocations("classpath:/static/css/");
        
        registry.addResourceHandler("/js/**")
                .addResourceLocations("classpath:/static/js/");
        
        registry.addResourceHandler("/fonts/**")
                .addResourceLocations("classpath:/static/fonts/");
        
        registry.addResourceHandler("/img/**")
                .addResourceLocations("classpath:/static/img/");
        
        registry.addResourceHandler("/images/**")
                .addResourceLocations("classpath:/static/images/");
    }
}