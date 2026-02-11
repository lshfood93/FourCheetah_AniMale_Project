<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>캐시 대시보드 (백엔드 테스트)</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        
        h1 {
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 15px;
            margin-bottom: 30px;
            font-size: 32px;
        }
        
        .year-selector {
            margin: 20px 0;
            padding: 15px;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .year-selector select {
            padding: 10px 15px;
            font-size: 16px;
            border-radius: 8px;
            border: 2px solid #4CAF50;
            background: white;
            cursor: pointer;
            font-weight: bold;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 8px 20px rgba(0,0,0,0.15);
            transition: transform 0.3s;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
        }
        
        .stat-label {
            font-size: 14px;
            opacity: 0.9;
            margin-bottom: 8px;
            font-weight: 500;
        }
        
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            margin-top: 5px;
        }
        
        .card-yellow {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }
        
        .card-blue {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }
        
        .card-green {
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
        }
        
        h2 {
            color: #333;
            margin: 40px 0 20px 0;
            font-size: 24px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 4px 10px rgba(0,0,0,0.1);
        }
        
        th, td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #f0f0f0;
        }
        
        th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-weight: bold;
            text-transform: uppercase;
            font-size: 13px;
            letter-spacing: 0.5px;
        }
        
        tr:hover {
            background-color: #f8f9fa;
        }
        
        tbody tr:last-child td {
            border-bottom: none;
        }
        
        tfoot tr {
            background-color: #f5f7fa;
            font-weight: bold;
            font-size: 16px;
        }
        
        .success {
            color: #4CAF50;
            font-weight: bold;
        }
        
        .info {
            color: #2196F3;
            font-weight: 600;
        }
        
        .debug-box {
            margin-top: 40px;
            padding: 20px;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            border-left: 5px solid #4CAF50;
            border-radius: 10px;
        }
        
        .debug-box h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 20px;
        }
        
        .debug-box p {
            margin: 8px 0;
            font-size: 15px;
            color: #555;
        }
        
        .success-badge {
            display: inline-block;
            padding: 8px 15px;
            background: #4CAF50;
            color: white;
            border-radius: 20px;
            font-size: 14px;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>💰 캐시 대시보드 (백엔드 테스트)</h1>
        
        <!-- 연도 선택 -->
        <div class="year-selector">
            <label style="font-weight: bold; color: #333;">📅 조회 연도: </label>
            <select onchange="location.href='/admin/dashboard?year=' + this.value">
                <option value="2024" ${year == 2024 ? 'selected' : ''}>2024년</option>
                <option value="2025" ${year == 2025 ? 'selected' : ''}>2025년</option>
                <option value="2026" ${year == 2026 ? 'selected' : ''}>2026년</option>
            </select>
        </div>

        <!-- 통계 카드 -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">년간 총 충전액</div>
                <div class="stat-value">
                    <fmt:formatNumber value="${yearlyTotalAmount}" pattern="#,###"/>원
                </div>
            </div>
            
            <div class="stat-card card-yellow">
                <div class="stat-label">전년 대비</div>
                <div class="stat-value">
                    <c:choose>
                        <c:when test="${yearGrowthRate >= 0}">
                            ▲ <fmt:formatNumber value="${yearGrowthRate}" pattern="#,##0.0"/>%
                        </c:when>
                        <c:otherwise>
                            ▼ <fmt:formatNumber value="${yearGrowthRate * -1}" pattern="#,##0.0"/>%
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>

            <div class="stat-card card-blue">
                <div class="stat-label">카카오페이</div>
                <div class="stat-value">
                    <fmt:formatNumber value="${paymentStats.kakaopayRate}" pattern="#,##0.0"/>%
                </div>
            </div>

            <div class="stat-card card-green">
                <div class="stat-label">토스페이</div>
                <div class="stat-value">
                    <fmt:formatNumber value="${paymentStats.tosspayRate}" pattern="#,##0.0"/>%
                </div>
            </div>
        </div>

        <!-- 월별 데이터 테이블 -->
        <h2>📊 월별 충전 통계 (${year}년)</h2>
        <table>
            <thead>
                <tr>
                    <th>월</th>
                    <th>충전 금액</th>
                    <th>충전 건수</th>
                    <th>평균 금액</th>
                    <th>카카오페이</th>
                    <th>토스페이</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="data" items="${monthlyData}">
                    <tr>
                        <td><strong>${data.month}월</strong></td>
                        <td class="success">
                            <fmt:formatNumber value="${data.total_amount}" pattern="#,###"/>원
                        </td>
                        <td class="info">${data.charge_count}건</td>
                        <td>
                            <fmt:formatNumber value="${data.avg_amount}" pattern="#,###"/>원
                        </td>
                        <td>
                            <fmt:formatNumber value="${data.kakaopay_amount}" pattern="#,###"/>원
                        </td>
                        <td>
                            <fmt:formatNumber value="${data.tosspay_amount}" pattern="#,###"/>원
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
            <tfoot>
                <tr>
                    <td>합계</td>
                    <td class="success">
                        <fmt:formatNumber value="${yearlyTotalAmount}" pattern="#,###"/>원
                    </td>
                    <td colspan="4"></td>
                </tr>
            </tfoot>
        </table>

        <!-- 결제 수단 상세 -->
        <h2>💳 결제 수단 비율</h2>
        <table>
            <thead>
                <tr>
                    <th>결제 수단</th>
                    <th>충전액</th>
                    <th>비율</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><strong>카카오페이</strong></td>
                    <td class="success">
                        <fmt:formatNumber value="${paymentStats.kakaopayAmount}" pattern="#,###"/>원
                    </td>
                    <td class="info">
                        <fmt:formatNumber value="${paymentStats.kakaopayRate}" pattern="#,##0.0"/>%
                    </td>
                </tr>
                <tr>
                    <td><strong>토스페이</strong></td>
                    <td class="success">
                        <fmt:formatNumber value="${paymentStats.tosspayAmount}" pattern="#,###"/>원
                    </td>
                    <td class="info">
                        <fmt:formatNumber value="${paymentStats.tosspayRate}" pattern="#,##0.0"/>%
                    </td>
                </tr>
            </tbody>
        </table>

        <!-- 디버그 정보 -->
        <div class="debug-box">
            <h3> 백엔드 작동 확인</h3>
            <p><strong>조회 연도:</strong> ${year}년</p>
            <p><strong>현재 월:</strong> ${currentMonth}월</p>
            <p><strong>전년도 총액:</strong> <fmt:formatNumber value="${lastYearAmount}" pattern="#,###"/>원</p>
            <p><strong>데이터 개수:</strong> ${monthlyData.size()}개월</p>
            <span class="success-badge">✨ Controller → Service → DAO → DB 연결 성공!</span>
        </div>
    </div>
</body>
</html>