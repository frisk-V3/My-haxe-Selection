import js.Browser;

class Content {
    static function main() {
        Browser.chrome.runtime.onMessage.addListener(function(msg, sender, sendResponse) {
            if (msg.type == "applyFont") {
                injectFont(msg.data);
            }
        });
    }

    static function injectFont(base64:String) {
        var css = "
        @font-face {
            font-family: 'DynamicFont';
            src: url('" + base64 + "') format('woff2');
        }
        * {
            font-family: 'DynamicFont' !important;
        }";

        var style = Browser.document.createStyleElement();
        style.innerHTML = css;
        Browser.document.head.appendChild(style);
    }
}
