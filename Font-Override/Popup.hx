import js.Browser;
import js.html.FileReader;
import js.html.InputElement;

class Popup {
    static function main() {
        var input:InputElement = cast Browser.document.getElementById("fontFile");
        input.onchange = function(_) {
            var file = input.files[0];
            var reader = new FileReader();

            reader.onload = function(_) {
                var base64 = reader.result;
                // content script に送信
                Browser.chrome.tabs.query({active:true, currentWindow:true}, function(tabs) {
                    Browser.chrome.tabs.sendMessage(tabs[0].id, {
                        type: "applyFont",
                        data: base64
                    });
                });
            };

            reader.readAsDataURL(file); // Base64 化
        };
    }
}
