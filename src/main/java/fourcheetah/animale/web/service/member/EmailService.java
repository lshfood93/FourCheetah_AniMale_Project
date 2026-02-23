package fourcheetah.animale.web.service.member;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
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

    /**
     * 비밀번호 재설정 코드 발송
     */
    public void sendPasswordResetCode(String toEmail, String code) throws Exception {

        Properties props = buildProps();
        Session session = buildSession(props);

        MimeMessage message = new MimeMessage(session);
        message.setFrom(new InternetAddress(fromEmail, fromUsername, "UTF-8"));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail.trim(), false));
        message.setSubject("[AniMale] 애니메일 본인 인증 확인 코드", StandardCharsets.UTF_8.name());
        message.setText("인증 코드: " + code, StandardCharsets.UTF_8.name());

        Transport.send(message);
        System.out.println("[메일] 전송 성공 to=" + toEmail);
    }

    /**
     * 제재 알림 이메일 발송
     *
     * warningType:
     *   WARNING      - 1~2회 경고 (기능 제한 없음)
     *   SUSPEND_7D   - 3~4회 7일 정지
     *   SUSPEND_30D  - 5~6회 30일 정지
     *   BAN          - 7회 이상 영구 정지
     */
    public void sendSanctionNotice(String toEmail, String warningType, LocalDateTime endAt, String reason) {

        System.out.println("[이메일] 제재 알림 발송 시작 - " + toEmail);

        try {
            Properties props = buildProps();
            Session session = buildSession(props);

            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(fromEmail, fromUsername, "UTF-8"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail.trim(), false));

            String subject;
            String body;
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy년 MM월 dd일 HH시 mm분");

            if ("WARNING".equals(warningType)) {
                // 1~2회 경고
                subject = "[AniMale] 커뮤니티 이용 경고 안내";
                body = "안녕하세요, AniMale입니다.\n\n"
                     + "귀하의 게시글이 신고 처리되어 경고가 부여되었습니다.\n\n"
                     + "【경고 정보】\n"
                     + "제재 타입: 경고\n"
                     + "사유: " + reason + "\n\n"
                     + "현재 게시글 이용에 제한은 없으며 정상적으로 커뮤니티를 이용하실 수 있습니다.\n"
                     + "단, 경고가 누적될 경우 이용이 제한될 수 있으니 커뮤니티 이용 규칙을 준수해 주세요.\n\n"
                     + "【누적 경고 시 제재 기준】\n"
                     + "- 3~4회: 7일 이용 정지\n"
                     + "- 5~6회: 30일 이용 정지\n"
                     + "- 7회 이상: 영구 정지\n\n"
                     + "감사합니다.\n"
                     + "AniMale 운영팀";

            } else if ("SUSPEND_7D".equals(warningType)) {
                // 3~4회 7일 정지
                String endAtStr = (endAt != null) ? endAt.format(formatter) : "미정";
                subject = "[AniMale] 계정 7일 정지 안내";
                body = "안녕하세요, AniMale입니다.\n\n"
                     + "귀하의 계정이 7일 정지 처리되었습니다.\n\n"
                     + "【제재 정보】\n"
                     + "제재 타입: 7일 정지\n"
                     + "정지 종료: " + endAtStr + "\n"
                     + "사유: " + reason + "\n\n"
                     + "정지 기간 동안 다음 기능이 제한됩니다:\n"
                     + "- 게시글 작성, 수정, 삭제\n"
                     + "- 댓글 작성, 수정, 삭제\n"
                     + "- 신고 기능\n\n"
                     + "정지 종료 후 정상 이용 가능합니다.\n\n"
                     + "⚠️ 주의: 추가 제재 시 더 강한 제재가 부여될 수 있습니다.\n\n"
                     + "감사합니다.\n"
                     + "AniMale 운영팀";

            } else if ("SUSPEND_30D".equals(warningType)) {
                // 5~6회 30일 정지
                String endAtStr = (endAt != null) ? endAt.format(formatter) : "미정";
                subject = "[AniMale] 계정 30일 정지 안내";
                body = "안녕하세요, AniMale입니다.\n\n"
                     + "귀하의 계정이 30일 정지 처리되었습니다.\n\n"
                     + "【제재 정보】\n"
                     + "제재 타입: 30일 정지\n"
                     + "정지 종료: " + endAtStr + "\n"
                     + "사유: " + reason + "\n\n"
                     + "정지 기간 동안 다음 기능이 제한됩니다:\n"
                     + "- 게시글 작성, 수정, 삭제\n"
                     + "- 댓글 작성, 수정, 삭제\n"
                     + "- 신고 기능\n\n"
                     + "⚠️ 주의: 추가 제재 시 영구 정지될 수 있습니다.\n\n"
                     + "정지 종료 후 정상 이용 가능합니다.\n\n"
                     + "감사합니다.\n"
                     + "AniMale 운영팀";

            } else if ("BAN".equals(warningType)) {
                // 7회 이상 영구 정지
                subject = "[AniMale] 계정 영구 정지 안내";
                body = "안녕하세요, AniMale입니다.\n\n"
                     + "귀하의 계정이 영구 정지 처리되었습니다.\n\n"
                     + "【제재 정보】\n"
                     + "제재 타입: 영구 정지\n"
                     + "사유: " + reason + "\n\n"
                     + "영구 정지된 계정은 복구가 불가능하며 모든 서비스 이용이 제한됩니다.\n\n"
                     + "문의사항이 있으시면 고객센터로 연락해주세요.\n\n"
                     + "감사합니다.\n"
                     + "AniMale 운영팀";

            } else {
                System.out.println("[이메일] 알 수 없는 warningType: " + warningType + " - 발송 생략");
                return;
            }

            message.setSubject(subject, StandardCharsets.UTF_8.name());
            message.setText(body, StandardCharsets.UTF_8.name());

            Transport.send(message);
            System.out.println("[이메일] 제재 알림 발송 성공 - to=" + toEmail + ", type=" + warningType);

        } catch (Exception e) {
            System.out.println("[이메일] 제재 알림 발송 실패 - " + e.getMessage());
            e.printStackTrace();
        }
    }

    // =========================================================
    // 공통 유틸

    private Properties buildProps() {
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
        return props;
    }

    private Session buildSession(Properties props) {
        return Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(fromEmail, password);
            }
        });
    }
}