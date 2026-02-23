package fourcheetah.animale.web.exception;

public class ErrorResponse {

    private boolean success;
    private String errorMessage;

    public ErrorResponse() {}

    public ErrorResponse(boolean success, String errorMessage) {
        this.success = success;
        this.errorMessage = errorMessage;
    }

    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }
}
