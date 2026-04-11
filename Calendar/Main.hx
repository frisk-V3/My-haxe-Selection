class Main {
    static function main() {
        var now = Date.now();
        var year = now.getFullYear();
        var month = now.getMonth(); // 0-11
        
        // 月の名前
        var monthNames = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"];
        
        Sys.println('--- ${year}年 ${monthNames[month]} ---');
        Sys.println("日 月 火 水 木 金 土");

        // 月の初日の曜日を取得 (0:日曜)
        var firstDay = new Date(year, month, 1, 0, 0, 0).getDay();
        
        // その月の末日（日数）を取得
        var daysInMonth = DateTools.getMonthDays(now);

        // 最初の週の空白
        var line = "";
        for (i in 0...firstDay) {
            line += "   ";
        }

        // 日付の描画
        for (day in 1...daysInMonth + 1) {
            line += StringTools.lpad(Std.string(day), " ", 2) + " ";
            
            // 土曜日（または末日）で改行
            if ((day + firstDay) % 7 == 0 || day == daysInMonth) {
                Sys.println(line);
                line = "";
            }
        }
    }
}
