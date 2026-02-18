package fourcheetah.animale.web.config;

import java.nio.file.Path;
import java.nio.file.Paths;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.upload.anime-dir:uploads/anime}")
    private String animeUploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {

        Path uploadDir = Paths.get(animeUploadDir).toAbsolutePath().normalize();

        registry.addResourceHandler("/upload/anime/**")
                .addResourceLocations(uploadDir.toUri().toString());
    }
}
