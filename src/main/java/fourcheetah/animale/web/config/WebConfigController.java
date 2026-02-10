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

        Path uploadRoot = Paths.get(uploadRootDir).toAbsolutePath().normalize();

        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(uploadRoot.toUri().toString()); // file:/D:/... 로 자동 변환
    }
}
