package boot.mini.jenkins;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan("data.*")
public class GitJenkinsProjectApplication {

	public static void main(String[] args) {
		SpringApplication.run(GitJenkinsProjectApplication.class, args);
	}

}
