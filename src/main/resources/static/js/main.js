'use strict';

(function ($) {

    /* ==================================================
       Preloader
       - 페이지의 모든 리소스(이미지/CSS/JS 등) 로딩이 끝난 뒤 실행
       - 로딩 화면(스피너/프리로더)을 자연스럽게 사라지게 처리
       ================================================== */
    $(window).on('load', function () {
        // 로딩 아이콘(스피너) 먼저 페이드아웃
        $(".loader").fadeOut();

        // 프리로더 전체 레이어를 0.2초 대기 후 천천히 숨김
        $("#preloder").delay(200).fadeOut("slow");
    });

    /* ==================================================
       Background Image (data-setbg 처리)
       - HTML 요소에 data-setbg="이미지경로"가 있으면
         해당 경로를 background-image로 세팅
       - CSS 배경 이미지로 깔아야 하는 섹션(배너/카드)에 주로 사용
       ================================================== */
	$('.set-bg').each(function () {
        // data-setbg 속성에 들어있는 이미지 경로 읽기
	    var bg = $(this).data('setbg');

        // background-image: url(...) 형태로 적용
	    $(this).css('background-image', 'url(' + bg + ')');
	});

})(jQuery);

/* ==================================================
   DOM Ready 영역
   - 문서 구조(DOM)가 준비되면 실행되는 초기화 구간
   ================================================== */
$(function () {

	/* ==================================================
	   정렬 기준 UI (드롭다운 형태)
	   - 지금은 코드가 주석 처리되어 있어서 동작하지 않음
	   - 필요할 때 다시 켜면, 버튼 클릭으로 목록 토글되고
	     항목 선택 시 텍스트 바뀌는 구조
	   ================================================== */

	/* $(function () {

	    // 페이지 시작 시 정렬 리스트는 닫힌 상태로 강제
	    $(".sort-list").hide();

        // 정렬 버튼 클릭 시 목록 토글(열기/닫기)
	    $("#sortToggle").on("click", function (e) {
	        e.stopPropagation(); // 문서 클릭 이벤트로 닫히는 걸 막기
	        $(".sort-list").toggle();
	    });

        // 목록 영역 클릭은 바깥 클릭으로 취급되지 않게 막기
	    $(".sort-list").on("click", function (e) {
	        e.stopPropagation();
	    });

        // 목록 항목 클릭 시 선택 텍스트 변경 + 목록 닫기
	    $(".sort-list li").on("click", function () {
	        $("#sortText").text($(this).text());
	        $(".sort-list").hide();
	    });

	}); */


    /* ==================================================
       바깥 클릭 시 닫기
       - 정렬 드롭다운 같은 UI는
         영역 밖을 클릭하면 자동으로 닫히게 만드는 패턴
       ================================================== */
	$(document).on("click", function (e) {

	    // 클릭한 위치가 .board-sort-box 내부가 아니면 정렬 리스트 닫기
	    if (!$(e.target).closest(".board-sort-box").length) {
	        $(".sort-list").hide();
	    }

	});

});

/* ==================================================
   Scroll To Top (맨 위로)
   - 스크롤이 어느 정도 내려가면 버튼을 보여주고
   - 버튼 누르면 부드럽게 최상단으로 이동
   ================================================== */
$(window).on("scroll", function () {
    // 스크롤 위치가 300px 넘어가면 버튼 표시
    if ($(this).scrollTop() > 300) {
        $("#scrollTopBtn").fadeIn();
    } else {
        // 다시 위로 올라오면 버튼 숨김
        $("#scrollTopBtn").fadeOut();
    }
});

$("#scrollTopBtn").on("click", function () {
    // html, body 둘 다 잡는 이유: 브라우저별 스크롤 타겟 차이 대응
    $("html, body").animate({ scrollTop: 0 }, 600);
});


/* ==================================================
   Profile Image Preview (프로필 이미지 미리보기)
   - 파일 input에서 이미지를 선택하면 FileReader로 읽어서
     img 태그(src)에 넣어 미리보기 표시
   ================================================== */
$(function () {
    // 파일 선택 input
    const input = document.getElementById("profileInput");
    // 미리보기 이미지(img)
    const preview = document.getElementById("profilePreview");

    // 해당 요소가 없는 페이지에서도 JS 에러 안 나게 방어
    if (!input || !preview) return;

    // 파일 선택이 바뀔 때 실행
    input.addEventListener("change", function () {
        // 첫 번째 파일만 사용(단일 업로드 기준)
        const file = this.files[0];
        if (!file) return;

        // 이미지 파일이 아니면 막기 (확장자 말고 MIME 타입 기준)
        if (!file.type.startsWith("image/")) {
            alert("이미지 파일만 선택할 수 있습니다.");
            input.value = ""; // 선택값 초기화
            return;
        }

        // 브라우저에서 파일 내용을 읽어서 base64 데이터 URL로 변환
        const reader = new FileReader();
        reader.onload = function (e) {
            // 변환된 dataURL을 img src에 넣어서 즉시 미리보기
            preview.src = e.target.result;
        };
        reader.readAsDataURL(file);
    });
});