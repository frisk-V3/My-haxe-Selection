class Main {
    static function main() {
        new Main();
    }

    function new() {
        trace("(ﾟ∀ﾟ)ｱﾋｬ");
        
        var x:Int = 342;
        var y:Int = 123;
        
        trace("x: " + x + ", y: " + y);
        
        switch (x) {
            case 342:
                trace("x is 342");
            default:
                trace("x is something else");
        }
        
        if (y > 100) {
            trace("y is greater than 100");
        } else {
            trace("y is 100 or less");
        }
    }
}
