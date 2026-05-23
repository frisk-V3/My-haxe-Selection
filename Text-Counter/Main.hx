import js.Browser;
import js.html.InputElement;
import js.html.TextAreaElement; 

class Main {
    static function main() {

        var input = cast(Browser.document.getElementById("user-input"), TextAreaElement);
        var countDisplay = Browser.document.getElementById("count");
        
        if (input != null && countDisplay != null) {
            input.oninput = function(e) {
                var text = input.value;
                var len = text.length; 
                
                countDisplay.innerHTML = "現在の文字数: " + len;
            };
        }
    }
}
