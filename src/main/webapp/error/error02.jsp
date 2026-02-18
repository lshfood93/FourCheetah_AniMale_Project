<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" isELIgnored="false" %>
<<<<<<< HEAD
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
=======
>>>>>>> 7ed5837effdde5111f23de87ce812c016b022871
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>에러페이지02</title>
</head>
<body>

<h1>404 에러</h1>
<hr>
요청실패한 URI : ${pageContext.errorData.requestURI} <br>
상태코드 : ${pageContext.errorData.statusCode} <br>
예외유형 : ${pageContext.errorData.throwable}

</body>
</html>