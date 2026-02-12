<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>신고 관리 - 백엔드 테스트</title>
<style>
* {
	margin: 0;
	padding: 0;
	box-sizing: border-box;
}

body {
	font-family: 'Malgun Gothic', sans-serif;
	background: #f5f5f5;
	padding: 20px;
}

.container {
	max-width: 1200px;
	margin: 0 auto;
	background: white;
	padding: 30px;
	border-radius: 10px;
	box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

h1 {
	color: #333;
	border-bottom: 3px solid #667eea;
	padding-bottom: 15px;
	margin-bottom: 30px;
}

.controls {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 20px;
	padding: 15px;
	background: #f8f9fa;
	border-radius: 8px;
}

.sort-control select {
	padding: 8px 15px;
	border: 1px solid #ddd;
	border-radius: 5px;
	font-size: 14px;
}

table {
	width: 100%;
	border-collapse: collapse;
	margin: 20px 0;
}

th, td {
	padding: 15px;
	text-align: left;
	border-bottom: 1px solid #eee;
}

th {
	background: #667eea;
	color: white;
	font-weight: bold;
}

.btn {
	padding: 8px 15px;
	border: none;
	border-radius: 5px;
	cursor: pointer;
	font-size: 14px;
	margin: 0 5px;
	transition: all 0.3s;
}

.btn-reject {
	background: #6c757d;
	color: white;
}

.btn-reject:hover {
	background: #5a6268;
}

.btn-approve {
	background: #dc3545;
	color: white;
}

.btn-approve:hover {
	background: #c82333;
}

.pagination {
	display: flex;
	justify-content: center;
	gap: 5px;
	margin-top: 30px;
}

.page-link {
	padding: 8px 12px;
	border: 1px solid #ddd;
	background: white;
	text-decoration: none;
	color: #333;
	border-radius: 5px;
	transition: all 0.3s;
}

.page-link:hover {
	background: #667eea;
	color: white;
	border-color: #667eea;
}

.page-link.active {
	background: #667eea;
	color: white;
	border-color: #667eea;
}

.empty-message {
	text-align: center;
	padding: 50px;
	color: #666;
	font-size: 16px;
}

.debug-info {
	margin-top: 30px;
	padding: 20px;
	background: #f8f9fa;
	border-left: 4px solid #667eea;
	border-radius: 5px;
}

.debug-info h3 {
	color: #667eea;
	margin-bottom: 10px;
}

.debug-info p {
	margin: 5px 0;
	color: #666;
}

.status-pending {
	color: #ffc107;
	font-weight: bold;
}

/* 클릭 가능한 행 스타일 */
tbody tr {
	cursor: pointer;
	transition: background 0.2s;
}

tbody tr:hover {
	background: #e8f4ff !important;
}

/* 버튼 영역은 클릭 방지 */
.action-buttons {
	cursor: default;
}

.action-buttons button {
	cursor: pointer;
}
</style>
</head>
<body>
	<div class="container">
		<h1>신고 관리 페이지 (백엔드 테스트)</h1>

		<!-- 정렬 컨트롤 -->
		<div class="controls">
			<div class="sort-control">
				<label>정렬:</label> <select
					onchange="location.href='/admin/reports?page=${currentPage}&sortOrder=' + this.value">
					<option value="desc" ${sortOrder == 'desc' ? 'selected' : ''}>최신순</option>
					<option value="asc" ${sortOrder == 'asc' ? 'selected' : ''}>오래된순</option>
				</select>
			</div>
			<div>
				<span>전체 신고: <strong>${totalCount}</strong>건
				</span>
			</div>
		</div>

		<!-- 신고 목록 테이블 -->
		<table>
			<thead>
    <tr>
        <th style="width: 60px;">번호</th>
        <th style="width: 100px;">작성자ID</th>
        <th style="width: 250px;">제목</th>
        <th>내용</th>
        <th style="width: 80px;">신고횟수</th>
        <th style="width: 180px;">관리</th>
    </tr>
</thead>
			<tbody>
    <c:forEach var="report" items="${reports}" varStatus="status">
        <tr onclick="viewDetail(${report.boardId})">
            <td>${status.count}</td>
            <td>${report.boardWriterId}</td>
            <td style="text-align: left; padding-left: 12px;">
                <div style="max-width: 250px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                    <c:out value="${report.boardTitle}" />
                </div>
            </td>
            <td style="text-align: left; padding-left: 12px;">
                <div style="max-width: 350px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: rgba(255,255,255,0.7);">
                    <c:out value="${report.boardContent}" />
                </div>
            </td>
            <td>${report.reportCount}회</td>
            <td class="action-buttons" onclick="event.stopPropagation()">
                <button class="btn btn-reject" onclick="rejectReport(${report.boardId})">반려</button>
                <button class="btn btn-approve" onclick="approveReport(${report.boardId})">승인</button>
            </td>
        </tr>
    </c:forEach>
</tbody>
		</table>

		<!-- 페이징 -->
		<div class="pagination">
			<c:if test="${currentPage > 1}">
				<a
					href="/admin/reports?page=${currentPage - 1}&sortOrder=${sortOrder}"
					class="page-link">이전</a>
			</c:if>

			<c:forEach var="i" begin="${startPage}" end="${endPage}">
				<a href="/admin/reports?page=${i}&sortOrder=${sortOrder}"
					class="page-link ${i == currentPage ? 'active' : ''}"> ${i} </a>
			</c:forEach>

			<c:if test="${currentPage < totalPages}">
				<a
					href="/admin/reports?page=${currentPage + 1}&sortOrder=${sortOrder}"
					class="page-link">다음</a>
			</c:if>
		</div>

		<!-- 디버그 정보 -->
		<div class="debug-info">
			<h3>백엔드 연결 확인</h3>
			<p>
				<strong>현재 페이지:</strong> ${currentPage}
			</p>
			<p>
				<strong>전체 페이지:</strong> ${totalPages}
			</p>
			<p>
				<strong>정렬 순서:</strong> ${sortOrder}
			</p>
			<p>
				<strong>데이터 개수:</strong> ${reports.size()}개
			</p>
			<p>
				<strong>Controller → JSP 연결:</strong> 성공
			</p>
		</div>
	</div>

	<!-- JavaScript -->
	<script>
 // 상세보기 (행 클릭)
    function viewDetail(boardId) {
        location.href = '/boardDetail?boardId=' + boardId;
    }
        
        // 신고 반려
        function rejectReport(boardId) {
            if (!confirm('이 신고를 반려하시겠습니까?')) {
                return;
            }
            
            console.log('[반려] 요청 시작 - boardId:', boardId);
            
            fetch('/admin/reports/reject', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'boardId=' + boardId
            })
            .then(response => {
                console.log('[반려] 응답 받음:', response);
                return response.json();
            })
            .then(data => {
                console.log('[반려] 데이터:', data);
                
                if (data.ok) {
                    alert(data.ok);
                    location.reload();
                } else if (data.fail) {
                    alert('오류: ' + data.fail);
                }
            })
            .catch(error => {
                console.error('[반려] 에러:', error);
                alert('신고 반려 처리 중 오류가 발생했습니다.');
            });
        }
        
     // 신고 승인
        function approveReport(boardId) {
            if (!confirm('이 신고를 승인하시겠습니까?\n\n게시글이 삭제되고 작성자에게 제재가 부과됩니다.')) {
                return;
            }
            
            console.log('[승인] 요청 시작 - boardId:', boardId);
            
            fetch('/admin/reports/approve', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'boardId=' + boardId
            })
            .then(response => {
                console.log('[승인] 응답 받음:', response);
                return response.json();
            })
            .then(data => {
                console.log('[승인] 데이터:', data);
                
                if (data.ok) {
                    alert(data.ok);  // "오류:" 제거!
                    location.reload();
                } else if (data.fail) {
                    alert('처리 실패: ' + data.fail);
                } else {
                    alert('알 수 없는 응답입니다.');
                }
            })
            .catch(error => {
                console.error('[승인] 에러:', error);
                alert('신고 승인 처리 중 오류가 발생했습니다.');
            });
        }
    </script>
</body>
</html>