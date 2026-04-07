// ファイル名: Counter.hx

class Counter {
    public var value:Int;

    public function new(start:Int = 0) {
        value = start;
    }

    public function add(n:Int):Void {
        value += n;
    }

    public function reset():Void {
        value = 0;
    }
}
