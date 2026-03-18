(function(window) {
    function injectCSS(css) {
        const head = document.getElementsByTagName('head')[0];
        const style = document.createElement('style');
        style.innerHTML = css;
        head.appendChild(style);
    }

    window.addEventListener('DOMContentLoaded', () => {
        injectCSS(`
            li#lnkGetLnkItem {
                display: none!important;
            }
        `);
    });
})(window);