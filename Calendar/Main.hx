import Date;

class Main {
    static function main() {
        var now = Date.now();
        var year = now.getFullYear();
        var month = now.getMonth(); 

        var monthNames = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"];
        
        Sys.println('--- ${year}年 ${monthNames[month]} ---');
        Sys.println("日 月 火 水 木 金 土");

        // 月の初日の曜日 (0:日曜)
        var firstDay = new Date(year, month, 1, 0, 0, 0).getDay();
        
        // その月の末日（次の月の0日目を指定するテクニック）
        var daysInMonth = getDaysInMonth(year, month);

        var line = "";
        // 最初の週の空白（1日目の曜日までスペースを埋める）
        for (i in 0...firstDay) {
            line += "   "; 
        }

        for (day in 1...daysInMonth + 1) {
            line += StringTools.lpad(Std.string(day), " ", 2) + " ";
            
            // 土曜日で改行、または月末
            if ((day + firstDay) % 7 == 0 || day == daysInMonth) {
                Sys.println(line);
                line = "";
            }
        }
    }

    // 月の日数を計算する補助関数
    static function getDaysInMonth(year:Int, month:Int):Int {
        // 1月(0)〜11月(10)なら次の月の0日＝今月末
        // 12月(11)なら翌年1月の0日
        var d = new Date(year, month + 1, 0, 0, 0, 0);
        return d.getDate();
    }
}
