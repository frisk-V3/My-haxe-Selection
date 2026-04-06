import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.Window;

class Main {
    static var canvas:CanvasElement;
    static var ctx:CanvasRenderingContext2D;

    // 画面サイズ
    static var WIDTH:Int = 800;
    static var HEIGHT:Int = 600;

    // ボール
    static var ballX:Float;
    static var ballY:Float;
    static var ballVX:Float;
    static var ballVY:Float;
    static var ballRadius:Float = 8;

    // パドル
    static var paddleX:Float;
    static var paddleY:Float;
    static var paddleWidth:Float = 100;
    static var paddleHeight:Float = 16;
    static var paddleSpeed:Float = 8;
    static var moveLeft:Bool = false;
    static var moveRight:Bool = false;

    // ブロック
    static var cols:Int = 10;
    static var rows:Int = 6;
    static var brickWidth:Float;
    static var brickHeight:Float = 24;
    static var brickPadding:Float = 4;
    static var brickOffsetTop:Float = 60;
    static var brickOffsetLeft:Float = 40;
    static var bricks:Array<Array<Bool>>;

    // ゲーム状態
    static var score:Int = 0;
    static var lives:Int = 3;
    static var isGameOver:Bool = false;
    static var isClear:Bool = false;
    static var isPaused:Bool = false;

    public static function main() {
        canvas = cast Browser.document.getElementById("game");
        if (canvas == null) {
            canvas = Browser.document.createCanvasElement();
            canvas.id = "game";
            canvas.width = WIDTH;
            canvas.height = HEIGHT;
            Browser.document.body.appendChild(canvas);
        } else {
            canvas.width = WIDTH;
            canvas.height = HEIGHT;
        }

        ctx = canvas.getContext2d();

        initGame();
        setupInput();

        // メインループ
        Browser.window.requestAnimationFrame(loop);
    }

    static function initGame() {
        // ボール初期位置
        ballX = WIDTH / 2;
        ballY = HEIGHT / 2;
        ballVX = 4;
        ballVY = -4;

        // パドル初期位置
        paddleX = WIDTH / 2 - paddleWidth / 2;
        paddleY = HEIGHT - 40;

        // ブロック初期化
        brickWidth = (WIDTH - brickOffsetLeft * 2 - brickPadding * (cols - 1)) / cols;
        bricks = [];
        for (r in 0...rows) {
            var row = new Array<Bool>();
            for (c in 0...cols) {
                row.push(true);
            }
            bricks.push(row);
        }

        score = 0;
        lives = 3;
        isGameOver = false;
        isClear = false;
        isPaused = false;
    }

    static function resetBallAndPaddle() {
        ballX = WIDTH / 2;
        ballY = HEIGHT / 2;
        ballVX = 4;
        ballVY = -4;
        paddleX = WIDTH / 2 - paddleWidth / 2;
        paddleY = HEIGHT - 40;
    }

    static function setupInput() {
        Browser.window.addEventListener("keydown", function(e:KeyboardEvent) {
            switch (e.key) {
                case "ArrowLeft":
                    moveLeft = true;
                case "ArrowRight":
                    moveRight = true;
                case " ":
                    // スペースでポーズ
                    isPaused = !isPaused;
                case "r", "R":
                    // Rでリスタート
                    if (isGameOver || isClear) {
                        initGame();
                    }
                default:
            }
        });

        Browser.window.addEventListener("keyup", function(e:KeyboardEvent) {
            switch (e.key) {
                case "ArrowLeft":
                    moveLeft = false;
                case "ArrowRight":
                    moveRight = false;
                default:
            }
        });

        canvas.addEventListener("mousemove", function(e:MouseEvent) {
            var rect = canvas.getBoundingClientRect();
            var mouseX = e.clientX - rect.left;
            paddleX = mouseX - paddleWidth / 2;
            if (paddleX < 0) paddleX = 0;
            if (paddleX + paddleWidth > WIDTH) paddleX = WIDTH - paddleWidth;
        });
    }

    static function loop(_time:Float) {
        update();
        draw();
        Browser.window.requestAnimationFrame(loop);
    }

    static function update() {
        if (isGameOver || isClear || isPaused) return;

        // パドル移動（キーボード）
        if (moveLeft) {
            paddleX -= paddleSpeed;
        }
        if (moveRight) {
            paddleX += paddleSpeed;
        }
        if (paddleX < 0) paddleX = 0;
        if (paddleX + paddleWidth > WIDTH) paddleX = WIDTH - paddleWidth;

        // ボール移動
        ballX += ballVX;
        ballY += ballVY;

        // 壁との当たり判定
        if (ballX - ballRadius < 0) {
            ballX = ballRadius;
            ballVX *= -1;
        } else if (ballX + ballRadius > WIDTH) {
            ballX = WIDTH - ballRadius;
            ballVX *= -1;
        }

        if (ballY - ballRadius < 0) {
            ballY = ballRadius;
            ballVY *= -1;
        }

        // パドルとの当たり判定
        if (ballY + ballRadius >= paddleY
            && ballY + ballRadius <= paddleY + paddleHeight
            && ballX >= paddleX
            && ballX <= paddleX + paddleWidth) {

            ballY = paddleY - ballRadius;
            ballVY *= -1;

            // 当たった位置で角度を変える
            var hitPos = (ballX - (paddleX + paddleWidth / 2)) / (paddleWidth / 2);
            ballVX = hitPos * 6;
        }

        // 下に落ちた
        if (ballY - ballRadius > HEIGHT) {
            lives--;
            if (lives <= 0) {
                isGameOver = true;
            } else {
                resetBallAndPaddle();
            }
        }

        // ブロックとの当たり判定
        checkBrickCollision();

        // クリア判定
        if (isAllBricksCleared()) {
            isClear = true;
        }
    }

    static function checkBrickCollision() {
        // ボールの位置から、どのブロック行・列にいるかをざっくり計算
        for (r in 0...rows) {
            for (c in 0...cols) {
                if (!bricks[r][c]) continue;

                var bx = brickOffsetLeft + c * (brickWidth + brickPadding);
                var by = brickOffsetTop + r * (brickHeight + brickPadding);
                var bw = brickWidth;
                var bh = brickHeight;

                if (circleRectCollision(ballX, ballY, ballRadius, bx, by, bw, bh)) {
                    bricks[r][c] = false;
                    score += 10;

                    // 反射方向をざっくり決める
                    // 上下どちらから当たったかを判定
                    var ballCenterY = ballY;
                    if (ballCenterY < by || ballCenterY > by + bh) {
                        ballVY *= -1;
                    } else {
                        ballVX *= -1;
                    }
                    return;
                }
            }
        }
    }

    static function circleRectCollision(cx:Float, cy:Float, cr:Float,
        rx:Float, ry:Float, rw:Float, rh:Float):Bool {

        var closestX = clamp(cx, rx, rx + rw);
        var closestY = clamp(cy, ry, ry + rh);

        var dx = cx - closestX;
        var dy = cy - closestY;
        return dx * dx + dy * dy <= cr * cr;
    }

    static inline function clamp(v:Float, min:Float, max:Float):Float {
        return if (v < min) min else if (v > max) max else v;
    }

    static function isAllBricksCleared():Bool {
        for (r in 0...rows) {
            for (c in 0...cols) {
                if (bricks[r][c]) return false;
            }
        }
        return true;
    }

    static function draw() {
        // 背景
        ctx.fillStyle = "#111";
        ctx.fillRect(0, 0, WIDTH, HEIGHT);

        // ブロック
        for (r in 0...rows) {
            for (c in 0...cols) {
                if (!bricks[r][c]) continue;
                var x = brickOffsetLeft + c * (brickWidth + brickPadding);
                var y = brickOffsetTop + r * (brickHeight + brickPadding);
                ctx.fillStyle = getBrickColor(r);
                ctx.fillRect(x, y, brickWidth, brickHeight);
            }
        }

        // パドル
        ctx.fillStyle = "#eee";
        ctx.fillRect(paddleX, paddleY, paddleWidth, paddleHeight);

        // ボール
        ctx.beginPath();
        ctx.arc(ballX, ballY, ballRadius, 0, Math.PI * 2);
        ctx.fillStyle = "#ffcc00";
        ctx.fill();
        ctx.closePath();

        // スコア・ライフ
        ctx.fillStyle = "#fff";
        ctx.font = "20px sans-serif";
        ctx.fillText("Score: " + score, 20, 30);
        ctx.fillText("Lives: " + lives, WIDTH - 120, 30);

        // ポーズ表示
        if (isPaused) {
            drawCenterText("PAUSED (Space)", "#ffff88");
        }

        // ゲームオーバー / クリア表示
        if (isGameOver) {
            drawCenterText("GAME OVER - Press R", "#ff6666");
        } else if (isClear) {
            drawCenterText("CLEAR!! - Press R", "#66ff99");
        }
    }

    static function drawCenterText(text:String, color:String) {
        ctx.fillStyle = color;
        ctx.font = "32px sans-serif";
        var metrics = ctx.measureText(text);
        var textWidth = metrics.width;
        ctx.fillText(text, (WIDTH - textWidth) / 2, HEIGHT / 2);
    }

    static function getBrickColor(row:Int):String {
        return switch (row) {
            case 0: "#ff6666";
            case 1: "#ff9966";
            case 2: "#ffcc66";
            case 3: "#99ff66";
            case 4: "#66ccff";
            case 5: "#cc66ff";
            default: "#ffffff";
        }
    }
}
