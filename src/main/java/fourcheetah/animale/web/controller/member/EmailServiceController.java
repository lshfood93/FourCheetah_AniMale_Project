package fourcheetah.animale.web.controller.member;

import java.nio.charset.StandardCharsets;
import java.util.Properties;

import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import org.springframework.stereotype.Service;

@Service
public class EmailServiceController {

    private static final String FROM_EMAIL = "lhbworld123@gmail.com";
    private static final String PASSWORD   = "ncob esmo ucst jaos"; // 앱 비밀번호(16자리)

    public void sendPasswordResetCode(String toEmail, String code) throws Exception {

        String fromUsername = "AniMale";

        Properties props = new Properties(
        		
        		);
        props.put("mail.transport.protocol", "smtp");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.starttls.required", "true");
        props.put("mail.smtp.ssl.protocols", "TLSv1.2");
        props.put("mail.smtp.ssl.trust", "smtp.gmail.com");
        props.put("mail.debug", "false");

        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(FROM_EMAIL, PASSWORD);
            }
        });


        MimeMessage message = new MimeMessage(session);
        message.setFrom(new InternetAddress(FROM_EMAIL, fromUsername, "UTF-8"));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail, false));
        message.setSubject("[AniMale] 애니메일 본인 인증 확인 코드", StandardCharsets.UTF_8.name());
        message.setText("인증 코드: " + code, StandardCharsets.UTF_8.name());

        Transport.send(message);
        System.out.println("[메일] 전송 성공 to=" + toEmail);
    }
}
