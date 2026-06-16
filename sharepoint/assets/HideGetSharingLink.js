(function(window) {
    var STYLE_ID = 'HideGetSharingLink-StyleTag';

    function injectCSS(css) {
        if (document.getElementById(STYLE_ID)) {
            return;
        }
        const head = document.getElementsByTagName('head')[0];
        const style = document.createElement('style');
        style.id = STYLE_ID;
        style.innerHTML = css;
        head.appendChild(style);
    }

    window.addEventListener('DOMContentLoaded', () => {
        injectCSS(`
            li#lnkGetLnkItem {
                display: none !important;
            }
            li:has(a#ID_GetLink) {
                display: none !important;
            }
        `);
    });
})(window);