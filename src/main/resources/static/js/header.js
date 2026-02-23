/**
 * header.js
 *
 * 목적
 * - 모든 페이지에서 공통으로 쓰는 헤더 UI만 담당한다.
 * - 스크롤 위치에 따라 헤더에 클래스를 붙였다/뗐다 해서 스타일을 바꾼다.
 *
 * 범위(주의)
 * - 검색, 페이지별 분기 같은 “페이지 의존 로직”은 넣지 않는다.
 * - 여기서는 헤더 상태(class)만 관리하고, 실제 모양(색/높이/그림자 등)은 CSS에서 처리한다.
 */

document.addEventListener("DOMContentLoaded", function () {

    /*
     * DOM이 완전히 만들어진 다음에 실행한다.
     * (헤더 요소가 아직 없는 시점에 querySelector를 하면 null이 나올 수 있음)
     */
    var header = document.querySelector(".header");

    /*
     * 공용 스크립트라서, 어떤 페이지에는 .header가 없을 수도 있다.
     * 그런 경우 에러 안 나게 바로 종료한다.
     */
    if (!header) return;

    /*
     * 스크롤 이벤트로 현재 스크롤 위치(window.scrollY)를 확인한다.
     * 일정 기준(여기서는 50px)을 넘으면 '스크롤된 상태' 클래스를 붙여서
     * CSS가 해당 상태에 맞는 스타일을 적용하게 만든다.
     */
    window.addEventListener("scroll", function () {

        /*
         * window.scrollY : 문서 최상단에서 얼마나 아래로 스크롤했는지(px)
         * 기준값 50px을 넘으면 header--scrolled 클래스를 추가
         * 아니면 header--scrolled 클래스를 제거
         */
        if (window.scrollY > 50) {
            header.classList.add("header--scrolled");
        } else {
            header.classList.remove("header--scrolled");
        }
    });

});