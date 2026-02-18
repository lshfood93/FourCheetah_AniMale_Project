package fourcheetah.animale.web.service.member;

import java.nio.charset.StandardCharsets;
import java.util.Properties;

import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    // application.properties에서 주입
    @Value("${mail.smtp.host}")
    private String smtpHost;

    @Value("${mail.smtp.port}")
    private int smtpPort;

    @Value("${mail.smtp.username}")
    private String fromEmail;

    @Value("${mail.smtp.password}")
    private String password;

    @Value("${mail.smtp.from-name}")
    private String fromUsername;

    @Value("${mail.smtp.auth}")
    private boolean smtpAuth;

    @Value("${mail.smtp.starttls.enable}")
    private boolean starttlsEnable;

    @Value("${mail.smtp.starttls.required}")
    private boolean starttlsRequired;

    @Value("${mail.smtp.ssl.protocols}")
    private String sslProtocols;

    @Value("${mail.smtp.debug}")
    private boolean debug;

    public void sendPasswordResetCode(String toEmail, String code) throws Exception {

        Properties props = new Properties();
        props.put("mail.transport.protocol", "smtp");
        props.put("mail.smtp.host", smtpHost);
        props.put("mail.smtp.port", String.valueOf(smtpPort));
        props.put("mail.smtp.auth", String.valueOf(smtpAuth));
        props.put("mail.smtp.starttls.enable", String.valueOf(starttlsEnable));
        props.put("mail.smtp.starttls.required", String.valueOf(starttlsRequired));
        props.put("mail.smtp.ssl.protocols", sslProtocols);
        props.put("mail.smtp.ssl.trust", smtpHost);
        props.put("mail.debug", String.valueOf(debug));

        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(fromEmail, password);
            }
        });

        MimeMessage message = new MimeMessage(session);
        message.setFrom(new InternetAddress(fromEmail, fromUsername, "UTF-8"));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail, false));
        message.setSubject("[AniMale] 애니메일 본인 인증 확인 코드", StandardCharsets.UTF_8.name());
        message.setText("인증 코드: " + code, StandardCharsets.UTF_8.name());

        Transport.send(message);
        System.out.println("[메일] 전송 성공 to=" + toEmail);
    }
}