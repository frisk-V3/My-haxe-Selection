package;

import js.Browser;

class Main {
	private var secretNumber:Int;
	private var attempts:Int = 0;
	private var maxAttempts:Int = 10;
	private var isGameOver:Bool = false;

	public function new() {
		this.secretNumber = Std.random(50) + 1;

		trace("====== 数字当てゲーム ======");
		trace("1から50の間の数字を当ててください！");
		trace("試行回数制限: " + this.maxAttempts + "回");
		trace("----------------------------");

		// 最初の入力待ちを開始
		this.askForGuess();
	}

	private function askForGuess():Void {
		if (this.isGameOver)
			return;

		// ブラウザの入力ポップアップを表示（Node.jsでも動くよう、setTimeoutで非同期に実行）
		Browser.window.setTimeout(function() {
			var result = Browser.window.prompt("1〜50の数字を入力してください（残り " + (this.maxAttempts - this.attempts) + " 回）:");

			// キャンセルボタンが押された場合
			if (result == null) {
				trace("ゲームがキャンセルされました。");
				this.isGameOver = true;
				return;
			}

			var inputInt = Std.parseInt(result);
			if (inputInt == null) {
				trace("❌ エラー: 有効な数字を入力してください。");
				this.askForGuess(); // 再挑戦
				return;
			}

			this.guess(inputInt);
		}, 10);
	}

	public function guess(input:Int):Void {
		// 範囲チェック
		if (input < 1 || input > 50) {
			trace("❌ エラー: 1から50の間の数字を入力してください");
			this.askForGuess();
			return;
		}

		this.attempts++;

		// ゲームロジック
		if (input == this.secretNumber) {
			trace("🎉 正解です！ 数字は " + this.secretNumber + " でした");
			trace("試行回数: " + this.attempts + "回");
			this.isGameOver = true;
		} else if (input < this.secretNumber) {
			trace("🔼 " + input + " より【大きい】数字です");
			trace("残り試行回数: " + (this.maxAttempts - this.attempts) + "回");
		} else {
			trace("🔽 " + input + " より【小さい】数字です");
			trace("残り試行回数: " + (this.maxAttempts - this.attempts) + "回");
		}

		// 試行回数上限チェック
		if (this.attempts >= this.maxAttempts && !this.isGameOver) {
			trace("💥 ゲームオーバー。正解は " + this.secretNumber + " でした。");
			this.isGameOver = true;
		}

		// ゲームが続いていれば次の入力を促す
		if (!this.isGameOver) {
			this.askForGuess();
		}
	}

	static function main() {
		new Main();
	}
4
}
