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
     * 비밀번호 재설정 코드 발송 (기존 메서드)
     */
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

    /**
     * ⭐ 제재 알림 이메일 발송
     *
     * @param toEmail       회원 이메일
     * @param warningType   WARNING / SUSPEND_7D / SUSPEND_30D / BAN
     * @param endAt         정지 종료일 (WARNING/BAN은 null)
     * @param reason        제재 사유 (DB reason 컬럼)
     * @param reportCount   현재 누적 신고 횟수
     * @param reportReason  신고 사유 코드 (SPAM/ABUSE/OBSCENE/ILLEGAL/ETC)
     */
    public void sendSanctionNotice(
            String toEmail,
            String warningType,
            LocalDateTime endAt,
            String reason,
            int reportCount,
            String reportReason
    ) {
        System.out.println("[이메일] 제재 알림 발송 시작 - " + toEmail);

        try {
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

            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy년 MM월 dd일 HH시 mm분");

            // ✅ 신고 사유 코드 → 한글 변환
            String reportReasonKo = convertReasonCode(reportReason);

            String subject = "";
            String body = "";

            // ==================== WARNING ====================
            if ("WARNING".equals(warningType)) {
                subject = "[AniMale] 신고 접수로 인한 게시물 삭제 및 경고 안내";
                body = "안녕하세요, AniMale입니다.\n\n"
                     + "귀하의 게시물이 다른 회원의 신고 접수로 검토 후 삭제 처리되었으며,\n"
                     + "경고 1회가 부과되었음을 안내드립니다.\n\n"
                     + "【제재 정보】\n"
                     + "신고 사유: " + reportReasonKo + "\n"
                     + "누적 경고 횟수: " + reportCount + "회\n\n"
                     + "【경고 누적 시 제재 기준】\n"
                     + "- 3회: 7일 이용 정지\n"
                     + "- 5회: 30일 이용 정지\n"
                     + "- 6회 이상: 영구 정지\n\n"
                     + "커뮤니티 이용 규칙을 준수하여 주시기 바랍니다.\n\n"
                     + "감사합니다.\n"
                     + "AniMale 운영팀";

            // ==================== SUSPEND_7D ====================
            } else if ("SUSPEND_7D".equals(warningType)) {
                String endAtStr = (endAt != null) ? endAt.format(formatter) : "미정";
                subject = "[AniMale] 계정 7일 이용 정지 안내";
                body = "안녕하세요, AniMale입니다.\n\n"
                     + "귀하의 계정이 누적 경고 횟수 초과로 7일 이용 정지 처리되었습니다.\n\n"
                     + "【제재 정보】\n"
                     + "신고 사유: " + reportReasonKo + "\n"
                     + "누적 경고 횟수: " + reportCount + "회\n"
                     + "정지 해제일: " + endAtStr + "\n\n"
                     + "【정지 기간 중 제한 기능】\n"
                     + "- 게시글 작성, 수정, 삭제\n"
                     + "- 댓글 작성, 수정, 삭제\n"
                     + "- 신고 기능\n\n"
                     + "【이용 가능 기능】\n"
                     + "- 게시글/댓글 조회\n"
                     + "- 좋아요 기능\n"
                     + "- 캐시 충전/사용\n\n"
                     + "⚠️ 주의: 추가 신고 누적 시 30일 정지 또는 영구 정지될 수 있습니다.\n\n"
                     + "감사합니다.\n"
                     + "AniMale 운영팀";

            // ==================== SUSPEND_30D ====================
            } else if ("SUSPEND_30D".equals(warningType)) {
                String endAtStr = (endAt != null) ? endAt.format(formatter) : "미정";
                subject = "[AniMale] 계정 30일 이용 정지 안내";
                body = "안녕하세요, AniMale입니다.\n\n"
                     + "귀하의 계정이 누적 경고 횟수 초과로 30일 이용 정지 처리되었습니다.\n\n"
                     + "【제재 정보】\n"
                     + "신고 사유: " + reportReasonKo + "\n"
                     + "누적 경고 횟수: " + reportCount + "회\n"
                     + "정지 해제일: " + endAtStr + "\n\n"
                     + "【정지 기간 중 제한 기능】\n"
                     + "- 게시글 작성, 수정, 삭제\n"
                     + "- 댓글 작성, 수정, 삭제\n"
                     + "- 신고 기능\n\n"
                     + "【이용 가능 기능】\n"
                     + "- 게시글/댓글 조회\n"
                     + "- 좋아요 기능\n"
                     + "- 캐시 충전/사용\n\n"
                     + "⚠️ 경고: 추가 신고 1회 누적 시 영구 정지 처리됩니다.\n\n"
                     + "감사합니다.\n"
                     + "AniMale 운영팀";

            // ==================== BAN ====================
            } else if ("BAN".equals(warningType)) {
                subject = "[AniMale] 계정 영구 정지 안내";
                body = "안녕하세요, AniMale입니다.\n\n"
                     + "귀하의 계정이 누적 경고 횟수 초과로 영구 정지 처리되었습니다.\n\n"
                     + "【제재 정보】\n"
                     + "신고 사유: " + reportReasonKo + "\n"
                     + "누적 경고 횟수: " + reportCount + "회\n"
                     + "정지 해제일: 해당 없음 (영구 정지)\n\n"
                     + "영구 정지된 계정은 로그인이 불가하며 모든 서비스 이용이 제한됩니다.\n"
                     + "이의가 있으시면 고객센터로 문의해주세요.\n\n"
                     + "감사합니다.\n"
                     + "AniMale 운영팀";
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

    /**
     * 신고 사유 코드 → 한글 변환
     */
    private String convertReasonCode(String code) {
        if (code == null) return "기타";
        switch (code) {
            case "SPAM":    return "스팸/광고";
            case "ABUSE":   return "욕설/비하";
            case "OBSCENE": return "음란성 게시물";
            case "ILLEGAL": return "불법 정보";
            case "ETC":     return "기타";
            default:        return code;
        }
    }
}