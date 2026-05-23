import js.Browser;
import js.html.CanvasRenderingContext2D;
import js.html.CanvasElement;
import Math;

class Main {
    static function main() {
        Browser.window.onload = function() {
            var canvas:CanvasElement = cast Browser.document.getElementById("clockCanvas");
            var ctx = canvas.getContext2d();

            function update(t:Float) {
                drawClock(ctx, canvas.width, canvas.height);
                Browser.window.requestAnimationFrame(update);
            }
            Browser.window.requestAnimationFrame(update);
        };
    }

    static function drawClock(ctx:CanvasRenderingContext2D, w:Float, h:Float) {
        var date = Date.now();
        var radius = Math.min(w, h) / 2 * 0.9;
        var cx = w / 2;
        var cy = h / 2;

        ctx.clearRect(0, 0, w, h);

        // 外枠
        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
        ctx.strokeStyle = "#333";
        ctx.lineWidth = 5;
        ctx.stroke();

        // -------------------------
        // ① 点の文字盤（60個）
        // -------------------------
        for (i in 0...60) {
            var angle = (i / 60) * 2 * Math.PI - Math.PI / 2;
            var outer = radius * 0.95;
            var inner = (i % 5 == 0) ? radius * 0.85 : radius * 0.90;

            ctx.beginPath();
            ctx.lineWidth = (i % 5 == 0) ? 4 : 2;
            ctx.strokeStyle = "#000";
            ctx.moveTo(
                cx + Math.cos(angle) * inner,
                cy + Math.sin(angle) * inner
            );
            ctx.lineTo(
                cx + Math.cos(angle) * outer,
                cy + Math.sin(angle) * outer
            );
            ctx.stroke();
        }

        // 針描画
        function hand(value:Float, max:Float, len:Float, width:Float, color:String) {
            var angle = (value / max) * 2 * Math.PI - Math.PI / 2;
            ctx.beginPath();
            ctx.lineWidth = width;
            ctx.lineCap = "round";
            ctx.strokeStyle = color;
            ctx.moveTo(cx, cy);
            ctx.lineTo(cx + Math.cos(angle) * len, cy + Math.sin(angle) * len);
            ctx.stroke();
        }

        // -------------------------
        // ② カチカチ式（秒は整数）
        // -------------------------
        var sec = date.getSeconds();                 
        var min = date.getMinutes() + sec / 60;     
        var hour = (date.getHours() % 12) + min / 60;

        // 針
        hand(hour, 12, radius * 0.5, 6, "#000");
        hand(min, 60, radius * 0.75, 4, "#444");
        hand(sec, 60, radius * 0.85, 2, "#d00");

        // 中心キャップ
        ctx.beginPath();
        ctx.arc(cx, cy, 6, 0, 2 * Math.PI);
        ctx.fillStyle = "#000";
        ctx.fill();
    }
}
