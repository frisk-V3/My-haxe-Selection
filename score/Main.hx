class Main {
    static function main() {
        var name = "frisk";
        var score = add(40, 2);
        trace(name + "のスコアは" + score);
    }

    static function add(a:Int, b:Int):Int {
        return a + b;
    }
}
