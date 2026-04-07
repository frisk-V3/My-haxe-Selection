class Main {
    static function main() {
        var c = new Counter(10);
        trace("初期値: " + c.value);

        c.add(5);
        trace("5 加算後: " + c.value);

        c.reset();
        trace("リセット後: " + c.value);
    }
}
