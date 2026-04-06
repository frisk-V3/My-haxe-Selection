class Main {
    static function main() {
        var canvas = js.Browser.document.createCanvasElement();
        canvas.width = 400;
        canvas.height = 300;
        js.Browser.document.body.appendChild(canvas);

        var ctx = canvas.getContext2d();
        var x = 0;

        function loop(_) {
            ctx.clearRect(0, 0, 400, 300);
            ctx.fillStyle = "red";
            ctx.fillRect(x, 120, 40, 40);
            x = (x + 2) % 400;
            js.Browser.window.requestAnimationFrame(loop);
        }

        loop(null);
    }
}
