package;

import js.Browser;
import js.html.*;

// ゲーム状態の定義
enum GameState {
    MENU;
    DIFFICULTY_SELECT;
    TUTORIAL;
    PLAYING;
    PAUSED;
    GAME_OVER;
    RESULTS;
}

// 難易度の定義
enum Difficulty {
    EASY;
    NORMAL;
    HARD;
    EXTREME;
}

// ノーツの種類
typedef Note = {
    t:Float,
    l:Int,
    hit:Bool,
    len:Float,
    holding:Bool,
    tailHit:Bool,
    type:Int,
    ?hitTiming:String
};

// パーティクルエフェクト
typedef Particle = {
    x:Float,
    y:Float,
    vx:Float,
    vy:Float,
    life:Float,
    maxLife:Float,
    color:String,
    size:Float
};

// スコア記録
typedef ScoreRecord = {
    score:Int,
    combo:Int,
    rank:String,
    difficulty:String,
    timestamp:Float
};

class Main {
    static var ctx:CanvasRenderingContext2D;
    static var canvas:CanvasElement;

    // ゲーム状態
    static var gameState:GameState=GameState.MENU;
    static var currentDifficulty:Difficulty=Difficulty.NORMAL;
    static var charts:Map<String,Array<Note>>=new Map();
    static var currentChart:Array<Note>=[];
    
    // ゲーム時間
    static var startTime:Float=0;
    static var pausedTime:Float=0;
    static var totalPausedTime:Float=0;
    static var songDuration:Float=0;
    
    // 速度と入力
    static var speed:Float=0.7;
    static var keys=[false,false,false,false];
    
    // スコア関連
    static var score:Int=0;
    static var maxScore:Int=0;
    static var combo:Int=0;
    static var maxCombo:Int=0;
    static var life:Float=100;
    static var accuracy:Float=0;
    
    static var perfectCount:Int=0;
    static var greatCount:Int=0;
    static var goodCount:Int=0;
    static var badCount:Int=0;
    static var missCount:Int=0;
    
    // ボーナス倍率
    static var comboMultiplier:Float=1.0;
    static var baseScorePerNote:Int=100;
    
    // エフェクト
    static var particles:Array<Particle>=[];
    static var hitWave=[0.0,0.0,0.0,0.0];
    static var laneGlow=[0.0,0.0,0.0,0.0];
    static var ratingAlpha:Float=0;
    static var ratingScale:Float=0;
    static var ratingStr:String="";
    static var ratingColor:String="#FFF";
    
    // ゲームオプション
    static var botMode:Bool=false;
    static var upsideDown:Bool=false;
    
    // ランキング
    static var scoreRecords:Array<ScoreRecord>=[];
    static var tutorialStep:Int=0;
    
    // アニメーション
    static var difficultySelection:Int=0;
    static var bgScroll:Float=0;
    
    // ゲーム内設定
    static var skinColor:Int=0;  // 0=default, 1=neon, 2=dark
    static var soundEnabled:Bool=true;
    static var showParticles:Bool=true;
    static var judgeWindowSize:Float=1.0;  // 判定ウィンドウのサイズ（1.0=標準）
    static var noteSpeed:Float=1.0;  // ノーツ落下速度の倍率
    
    // ゲーム統計
    static var totalGamesPlayed:Int=0;
    static var totalPerfects:Int=0;
    static var bestScore:Int=0;
    static var totalPlayTime:Float=0;
    
    // ゲーム内イベント
    static var comboEvents:Array<Int>=[100,250,500,1000];  // コンボボーナスのタイミング
    static var comboEventTriggered:Array<Bool>=[false,false,false,false];
    static function main(){
        Browser.window.onload=function(_){
            canvas=cast(Browser.document.getElementById("gameCanvas"),CanvasElement);
            ctx=canvas.getContext2d();

            Browser.window.addEventListener("keydown",onKeyDown);
            Browser.window.addEventListener("keyup",onKeyUp);

            canvas.addEventListener("touchstart",onTouchStart);
            canvas.addEventListener("touchend",onTouchEnd);

            generateAllCharts();
            loadScoreRecords();  // 統計情報を読み込み
            
            loop();
        };
    }

    static function onTouchStart(e:TouchEvent){
        var rect=canvas.getBoundingClientRect();
        for(t in e.changedTouches){
            var l=Std.int((t.clientX-rect.left-200)/100);
            if(l>=0&&l<4){
                if(!keys[l]){
                    keys[l]=true;
                    if(gameState==GameState.PLAYING && !botMode) {
                        checkHit(l);
                    }
                }
            }
        }
    }

    static function onTouchEnd(_){
        for(i in 0...4) keys[i]=false;
    }

    static function onKeyDown(e:KeyboardEvent){
        // メニュー操作
        if(gameState==GameState.MENU){
            if(e.keyCode==13) startTutorial();
            if(e.keyCode==37) difficultySelection=(difficultySelection+3)%4;
            if(e.keyCode==39) difficultySelection=(difficultySelection+1)%4;
        }
        
        // 難易度選択画面
        if(gameState==GameState.DIFFICULTY_SELECT){
            if(e.keyCode==37) difficultySelection=(difficultySelection+3)%4;
            if(e.keyCode==39) difficultySelection=(difficultySelection+1)%4;
            if(e.keyCode==13){
                currentDifficulty=[Difficulty.EASY,Difficulty.NORMAL,Difficulty.HARD,Difficulty.EXTREME][difficultySelection];
                startGame();
            }
            if(e.keyCode==27) gameState=GameState.MENU;
        }
        
        // チュートリアル画面
        if(gameState==GameState.TUTORIAL){
            if(e.keyCode==32 || e.keyCode==13){
                tutorialStep++;
                if(tutorialStep>=5){
                    gameState=GameState.DIFFICULTY_SELECT;
                    tutorialStep=0;
                }
            }
            if(e.keyCode==27){
                gameState=GameState.MENU;
                tutorialStep=0;
            }
        }
        
        // ゲーム中
        if(gameState==GameState.PLAYING){
            if(e.keyCode==27){
                gameState=GameState.PAUSED;
                pausedTime=Browser.window.performance.now();
                return;
            }
            
            if(e.keyCode==32){
                botMode=!botMode;
                return;
            }
            if(e.keyCode==13){
                upsideDown=!upsideDown;
                return;
            }

            var l=getLane(e.keyCode);
            if(l!=-1&&!keys[l]&&!botMode){
                keys[l]=true;
                checkHit(l);
            }
        }
        
        // ポーズ中
        if(gameState==GameState.PAUSED){
            if(e.keyCode==27){
                totalPausedTime+=(Browser.window.performance.now()-pausedTime);
                gameState=GameState.PLAYING;
                return;
            }
            if(e.keyCode==82){
                resetGame();
                startGame();
            }
        }
        
        // リザルト画面
        if(gameState==GameState.RESULTS){
            if(e.keyCode==13) gameState=GameState.MENU;
            if(e.keyCode==82) startGame();
        }
    }

    static function onKeyUp(e:KeyboardEvent){
        var l=getLane(e.keyCode);
        if(l!=-1) keys[l]=false;
    }

    static function getLane(c:Int):Int {
        return switch(c){
            case 37: 0;
            case 40: 1;
            case 38: 2;
            case 39: 3;
            case 90: 0;
            case 88: 1;
            case 67: 2;
            case 86: 3;
            default: -1;
        };
    }

    static function generateAllCharts(){
        generateChartForDifficulty("easy", 60, 0.7, 0.3);
        generateChartForDifficulty("normal", 120, 0.8, 0.5);
        generateChartForDifficulty("hard", 180, 0.9, 0.7);
        generateChartForDifficulty("extreme", 250, 1.0, 0.9);
    }

    // 難易度別チャート生成関数
    // 難易度が上がるにつれてノーツの密度が上がり、ロングノーツ比率が高くなる
    static function generateChartForDifficulty(name:String, noteCount:Int, density:Float, longNoteRatio:Float){
        var chart:Array<Note>=[];
        var t=3000.0;
        
        for(i in 0...noteCount){
            // レーン選択: sin関数を使って流れるようなパターンを生成
            var lane=Math.floor(Math.abs(Math.sin(i*1.27)*4))%4;
            
            // ノーツ間隔: 基本間隔にcos関数で変動を加える
            var baseInterval=260+Math.cos(i*0.75)*100;
            if(i%6==0) baseInterval+=120;  // 6ノーツごとに長めの空白を作る
            
            // 難易度に応じた間隔調整
            var interval=baseInterval/density;
            
            // ロングノーツの生成判定
            var len:Float=0;
            var type:Int=0;
            
            if(Math.random()<longNoteRatio){
                len=320+Math.random()*380;  // 320~700msの長さ
                type=1;  // ロングノーツ
            }
            
            chart.push({
                t: t,
                l: lane,
                hit: false,
                len: len,
                holding: false,
                tailHit: false,
                type: type,
                hitTiming: null
            });
            t+=interval;
        }
        
        songDuration=t+2000;
        charts.set(name, chart);
    }

    static function startGame(){
        resetGame();
        currentChart=charts.get(switch(currentDifficulty){
            case Difficulty.EASY: "easy";
            case Difficulty.NORMAL: "normal";
            case Difficulty.HARD: "hard";
            case Difficulty.EXTREME: "extreme";
        });
        
        for(note in currentChart){
            maxScore+=baseScorePerNote;
        }
        
        startTime=Browser.window.performance.now();
        totalPausedTime=0;
        gameState=GameState.PLAYING;
    }

    static function startTutorial(){
        gameState=GameState.TUTORIAL;
        tutorialStep=0;
    }

    static function resetGame(){
        score=0;
        combo=0;
        maxCombo=0;
        life=100;
        perfectCount=0;
        greatCount=0;
        goodCount=0;
        badCount=0;
        missCount=0;
        maxScore=0;
        particles=[];
        hitWave=[0,0,0,0];
        laneGlow=[0,0,0,0];
        ratingAlpha=0;
        totalPausedTime=0;
        comboMultiplier=1.0;
        bgScroll=0;
        
        for(note in currentChart){
            note.hit=false;
            note.holding=false;
            note.tailHit=false;
            note.hitTiming=null;
        }
    }

    // ノーツのヒット判定処理
    // レーンに対応するキーが押されたときに呼び出される
    // タイミング精度に応じてスコアと判定を決定する
    static function checkHit(l:Int){
        var now=Browser.window.performance.now()-startTime-totalPausedTime;
        var best:Note=null;
        var bestDiff:Float=9999.0;

        // 該当レーンでまだヒットしていないノーツを検索
        for(n in currentChart){
            if(n.hit && n.len<=0) continue;  // すでにヒット済みのノーツはスキップ
            if(n.l!=l) continue;  // 異なるレーンのノーツはスキップ
            var diff=Math.abs(n.t-now);
            if(diff<bestDiff && diff<200){  // 200ms以内が判定対象
                bestDiff=diff;
                best=n;
            }
        }

        if(best!=null){
            // タイミング精度に基づいた判定
            // スコア計算: 基本スコア * タイミング倍率 * コンボボーナス倍率
            var timing:String;
            var addScore:Int=baseScorePerNote;  // 基本スコア: 100点
            var lifeGain:Float=0;
            
            if(bestDiff<50){
                // PERFECT: ±50ms以内 -> 1.5倍スコア
                timing="PERFECT";
                addScore=Std.int(addScore*1.5);
                lifeGain=8;
                perfectCount++;
            } else if(bestDiff<100){
                // GREAT: ±100ms以内 -> 1.2倍スコア
                timing="GREAT";
                addScore=Std.int(addScore*1.2);
                lifeGain=5;
                greatCount++;
            } else if(bestDiff<150){
                // GOOD: ±150ms以内 -> 0.8倍スコア
                timing="GOOD";
                addScore=Std.int(addScore*0.8);
                lifeGain=2;
                goodCount++;
            } else {
                // BAD: 150ms以上 -> 0.4倍スコア
                timing="BAD";
                addScore=Std.int(addScore*0.4);
                lifeGain=0;
                badCount++;
            }
            
            best.hit=true;
            best.hitTiming=timing;
            
            combo++;
            if(combo>maxCombo) maxCombo=combo;
            
            // コンボボーナス倍率計算: コンボ数に応じて最大2.5倍
            comboMultiplier=1.0+(combo*0.005);
            if(comboMultiplier>2.5) comboMultiplier=2.5;
            
            // 最終スコア = 基本スコア * コンボ倍率
            score+=Std.int(addScore*comboMultiplier);
            life=Math.min(100, life+lifeGain);
            
            // ビジュアルエフェクト
            hitWave[l]=1.0;
            laneGlow[l]=1.0;
            ratingStr=timing;
            ratingAlpha=1.0;
            ratingScale=0.5;
            
            createHitParticles(l, timing);
        } else {
            // ミス: ノーツの判定枠から外れた場合
            missCount++;
            combo=0;
            comboMultiplier=1.0;
            life-=15;  // ライフを15減少
            createMissParticles(l);
        }
        
        // ライフがなくなったらゲームオーバー
        if(life<=0){
            gameState=GameState.GAME_OVER;
            finalizeResults();
        }
    }

    static function createHitParticles(l:Int, timing:String){
        var colors=[["#FF6B6B","#FF8E8E"],["#4ECDC4","#7CFFDB"],["#FFE66D","#FFF9A6"],["#95E1D3","#C7F0D8"]];
        var colorPair=colors[l];
        
        var count=switch(timing){
            case "PERFECT": 12;
            case "GREAT": 8;
            case "GOOD": 5;
            default: 3;
        };
        
        for(i in 0...count){
            var angle=Math.random()*Math.PI*2;
            var speed=3+Math.random()*7;
            particles.push({
                x: 250+l*100,
                y: 500,
                vx: Math.cos(angle)*speed,
                vy: Math.sin(angle)*speed-2,
                life: 1.0,
                maxLife: 1.0,
                color: colorPair[i%2],
                size: 3+Math.random()*4
            });
        }
    }

    static function createMissParticles(l:Int){
        for(i in 0...6){
            var angle=Math.random()*Math.PI*2;
            particles.push({
                x: 250+l*100,
                y: 500,
                vx: Math.cos(angle)*2,
                vy: Math.sin(angle)*2-1,
                life: 0.7,
                maxLife: 0.7,
                color: "#FF3333",
                size: 2+Math.random()*3
            });
        }
    }

    static function finalizeResults(){
        var totalNotes=perfectCount+greatCount+goodCount+badCount+missCount;
        if(totalNotes>0){
            accuracy=((perfectCount*1.0+greatCount*0.8+goodCount*0.5)/(totalNotes))*100;
        }
        if(Math.isNaN(accuracy)) accuracy=0;
        
        var record:ScoreRecord={
            score: score,
            combo: maxCombo,
            rank: getRank(),
            difficulty: getDifficultyStr(),
            timestamp: Date.now().getTime()
        };
        scoreRecords.push(record);
        scoreRecords.sort((a,b)->b.score-a.score);
        if(scoreRecords.length>10) scoreRecords.pop();
        saveScoreRecords();
        
        // ゲーム統計を更新
        totalGamesPlayed++;
        if(perfectCount>0) totalPerfects+=perfectCount;
        if(score>bestScore) bestScore=score;
        totalPlayTime+=(Browser.window.performance.now()-startTime)/1000;  // 秒単位で記録
        saveGameStats();
        
        gameState=GameState.RESULTS;
    }

    static function getRank():String {
        if(accuracy>=99) return "S+";
        if(accuracy>=95) return "S";
        if(accuracy>=90) return "A+";
        if(accuracy>=85) return "A";
        if(accuracy>=80) return "B";
        if(accuracy>=70) return "C";
        return "D";
    }

    static function getDifficultyStr():String {
        return switch(currentDifficulty){
            case Difficulty.EASY: "EASY";
            case Difficulty.NORMAL: "NORMAL";
            case Difficulty.HARD: "HARD";
            case Difficulty.EXTREME: "EXTREME";
        };
    }

    static function saveScoreRecords(){
        if(Browser.window.localStorage!=null){
            var json=haxe.Json.stringify(scoreRecords);
            Browser.window.localStorage.setItem("rhythm_scores", json);
        }
    }

    static function loadScoreRecords(){
        if(Browser.window.localStorage!=null){
            var json=Browser.window.localStorage.getItem("rhythm_scores");
            if(json!=null){
                try{
                    scoreRecords=haxe.Json.parse(json);
                }catch(e:Dynamic){
                    scoreRecords=[];
                }
            }
            
            // ゲーム統計を読み込み
            var statsJson=Browser.window.localStorage.getItem("rhythm_stats");
            if(statsJson!=null){
                try{
                    var stats:Dynamic=haxe.Json.parse(statsJson);
                    totalGamesPlayed=stats.totalGamesPlayed;
                    totalPerfects=stats.totalPerfects;
                    bestScore=stats.bestScore;
                    totalPlayTime=stats.totalPlayTime;
                    skinColor=stats.skinColor;
                    soundEnabled=stats.soundEnabled;
                }catch(e:Dynamic){
                    resetStats();
                }
            }
        }
    }
    
    static function saveGameStats(){
        if(Browser.window.localStorage!=null){
            var stats={
                totalGamesPlayed: totalGamesPlayed,
                totalPerfects: totalPerfects,
                bestScore: bestScore,
                totalPlayTime: totalPlayTime,
                skinColor: skinColor,
                soundEnabled: soundEnabled
            };
            var json=haxe.Json.stringify(stats);
            Browser.window.localStorage.setItem("rhythm_stats", json);
        }
    }
    
    static function resetStats(){
        totalGamesPlayed=0;
        totalPerfects=0;
        bestScore=0;
        totalPlayTime=0;
    }
    static function loop(){
        Browser.window.requestAnimationFrame(function(t){
            update(t);
            loop();
        });
    }

    static function update(t:Float){
        var now=t-startTime-totalPausedTime;

        ctx.setTransform(1,0,0,1,0,0);
        ctx.fillStyle="#0a0a0a";
        ctx.fillRect(0,0,800,600);
        
        drawBackground();
        
        if(gameState==GameState.MENU){
            drawMenu();
        } else if(gameState==GameState.DIFFICULTY_SELECT){
            drawDifficultySelect();
        } else if(gameState==GameState.TUTORIAL){
            drawTutorial();
        } else if(gameState==GameState.PLAYING){
            drawGame(now);
        } else if(gameState==GameState.PAUSED){
            drawGame(now);
            drawPauseScreen();
        } else if(gameState==GameState.GAME_OVER){
            drawGameOver();
        } else if(gameState==GameState.RESULTS){
            drawResults();
        }
    }

    static function drawBackground(){
        var grad=ctx.createLinearGradient(0,0,0,600);
        grad.addColorStop(0,"#1a0033");
        grad.addColorStop(1,"#330055");
        ctx.fillStyle=grad;
        ctx.fillRect(0,0,800,600);
        
        ctx.fillStyle="rgba(100,50,200,0.1)";
        for(i in 0...4){
            var y=(bgScroll+i*100)%600;
            ctx.fillRect(0,y,800,50);
        }
        bgScroll+=0.5;
    }

    static function drawMenu(){
        ctx.fillStyle="rgba(0,0,0,0.5)";
        ctx.fillRect(0,0,800,600);
        
        ctx.fillStyle="#FF1493";
        ctx.font="bold 70px Arial";
        ctx.textAlign="center";
        ctx.fillText("RHYTHM LEGEND",400,150);
        
        ctx.fillStyle="#FFF";
        ctx.font="30px Arial";
        ctx.fillText("PRESS ENTER TO START",400,250);
        
        ctx.fillStyle="#888";
        ctx.font="24px Arial";
        ctx.fillText("← → to select difficulty",400,350);
        
        var difficulties=["EASY","NORMAL","HARD","EXTREME"];
        var colors=["#00FF00","#00FFFF","#FF8800","#FF0000"];
        var x=200;
        for(i in 0...4){
            ctx.fillStyle=colors[i];
            ctx.fillRect(x,400,80,40);
            ctx.fillStyle="#000";
            ctx.font="bold 16px Arial";
            ctx.textAlign="center";
            ctx.fillText(difficulties[i],x+40,425);
            x+=150;
        }
        
        drawRanking();
        
        // ゲーム統計表示
        drawGameStatistics();
    }
    
    static function drawGameStatistics(){
        ctx.fillStyle="#888";
        ctx.font="bold 16px Arial";
        ctx.textAlign="left";
        ctx.fillText("TOTAL GAMES: "+totalGamesPlayed,20,450);
        ctx.fillText("BEST SCORE: "+bestScore,20,475);
        ctx.fillText("TOTAL PERFECTS: "+totalPerfects,20,500);
        ctx.fillText("TOTAL PLAY TIME: "+Std.int(totalPlayTime)+"s",20,525);
    }

    static function drawRanking(){
        ctx.fillStyle="#FFF";
        ctx.font="bold 20px Arial";
        ctx.textAlign="left";
        ctx.fillText("TOP SCORES:",20,520);
        
        var y=545;
        for(i in 0...Math.min(3,scoreRecords.length)){
            var record=scoreRecords[i];
            ctx.font="16px Arial";
            ctx.fillStyle="#CCC";
            ctx.fillText((i+1)+". "+record.score+" ["+record.rank+"]",20,y);
            y+=25;
        }
    }

    static function drawDifficultySelect(){
        ctx.fillStyle="rgba(0,0,0,0.7)";
        ctx.fillRect(0,0,800,600);
        
        ctx.fillStyle="#00FF00";
        ctx.font="bold 50px Arial";
        ctx.textAlign="center";
        ctx.fillText("SELECT DIFFICULTY",400,100);
        
        var difficulties=["EASY","NORMAL","HARD","EXTREME"];
        var colors=["#00FF00","#00FFFF","#FF8800","#FF0000"];
        var descriptions=["For beginners","Recommended","Very challenging","EXTREME MODE"];
        
        var x=50;
        for(i in 0...4){
            var w=170;
            var h=120;
            if(i==difficultySelection){
                ctx.fillStyle=colors[i];
                ctx.shadowColor=colors[i];
                ctx.shadowBlur=20;
                ctx.shadowOffsetX=0;
                ctx.shadowOffsetY=0;
                ctx.fillRect(x-10,200-10,w+20,h+20);
            }
            
            ctx.fillStyle=colors[i];
            ctx.fillRect(x,200,w,h);
            
            ctx.fillStyle="#000";
            ctx.font="bold 24px Arial";
            ctx.textAlign="center";
            ctx.fillText(difficulties[i],x+w/2,240);
            
            ctx.fillStyle="#CCC";
            ctx.font="14px Arial";
            ctx.fillText(descriptions[i],x+w/2,275);
            
            x+=200;
        }
        
        ctx.shadowColor="transparent";
        ctx.fillStyle="#888";
        ctx.font="18px Arial";
        ctx.textAlign="center";
        ctx.fillText("← → Select | ENTER Start | ESC Menu",400,500);
    }

    static function drawTutorial(){
        ctx.fillStyle="rgba(0,0,0,0.8)";
        ctx.fillRect(0,0,800,600);
        
        ctx.fillStyle="#00FF00";
        ctx.font="bold 40px Arial";
        ctx.textAlign="center";
        ctx.fillText("HOW TO PLAY",400,50);
        
        ctx.fillStyle="#FFF";
        ctx.font="24px Arial";
        var texts=[
            "矢印キー (↑↓←→) またはZXCVで4つのレーンを操作",
            "画面上から落ちてくるノーツを正確にタイミングよくヒット",
            "PERFECT: ±50ms, GREAT: ±100ms, GOOD: ±150ms",
            "コンボを繋ぐとスコアボーナス倍率が上昇! 最大2.5倍",
            "ライフがなくなるとゲームオーバー。生き残ってクリアしよう!"
        ];
        
        var y=150;
        for(i in 0...texts.length){
            if(i==tutorialStep){
                ctx.fillStyle="#FF1493";
                ctx.font="bold 24px Arial";
            } else {
                ctx.fillStyle="#888";
                ctx.font="24px Arial";
            }
            ctx.fillText(texts[i],400,y);
            y+=70;
        }
        
        ctx.fillStyle="#FFF";
        ctx.font="18px Arial";
        ctx.fillText("SPACE/ENTER 次へ | ESC 戻る",400,550);
    }

    static function drawGame(now:Float){
        var colors=["#FF6B6B","#4ECDC4","#FFE66D","#95E1D3"];
        
        ctx.fillStyle="rgba(0,0,0,0.3)";
        ctx.fillRect(200,0,400,600);
        
        for(i in 0...4){
            ctx.fillStyle="rgba(255,255,255,"+0.1*laneGlow[i]+")";
            ctx.fillRect(200+i*100,0,100,600);
            laneGlow[i]*=0.95;
            
            ctx.strokeStyle="rgba(255,255,255,0.2)";
            ctx.lineWidth=2;
            ctx.beginPath();
            ctx.moveTo(200+(i+1)*100,0);
            ctx.lineTo(200+(i+1)*100,600);
            ctx.stroke();
        }
        
        var judgeY=upsideDown?100:500;
        ctx.fillStyle="rgba(255,255,255,0.5)";
        ctx.fillRect(200,judgeY-5,400,10);
        ctx.strokeStyle="#FFF";
        ctx.lineWidth=2;
        ctx.beginPath();
        ctx.moveTo(150,judgeY);
        ctx.lineTo(650,judgeY);
        ctx.stroke();
        
        for(n in currentChart){
            var noteY=judgeY+(upsideDown?-1:1)*(n.t-now)*0.2;
            
            if(noteY>-50 && noteY<700){
                ctx.fillStyle=colors[n.l];
                
                if(n.len>0){
                    var tailY=judgeY+(upsideDown?-1:1)*(n.t+n.len-now)*0.2;
                    ctx.globalAlpha=0.6;
                    ctx.fillRect(200+n.l*100+5,Math.min(noteY,tailY),90,Math.abs(tailY-noteY));
                    ctx.globalAlpha=1.0;
                    
                    ctx.fillStyle=colors[n.l];
                    ctx.fillRect(200+n.l*100+10,tailY-5,80,10);
                } else {
                    if(n.hit && n.hitTiming!=null){
                        ctx.fillStyle="rgba(255,255,255,0.8)";
                        ctx.fillRect(200+n.l*100+10,noteY-10,80,20);
                    } else {
                        ctx.fillRect(200+n.l*100+10,noteY-10,80,20);
                    }
                }
                
                ctx.strokeStyle="rgba(255,255,255,0.8)";
                ctx.lineWidth=2;
                ctx.strokeRect(200+n.l*100+10,noteY-10,80,20);
            }
        }
        
        for(i in 0...particles.length){
            var p=particles[i];
            ctx.fillStyle=p.color;
            ctx.globalAlpha=p.life/p.maxLife;
            ctx.beginPath();
            ctx.arc(p.x,p.y,p.size,0,Math.PI*2);
            ctx.fill();
            
            p.x+=p.vx;
            p.y+=p.vy;
            p.vy+=0.2;
            p.life-=1/60;
        }
        ctx.globalAlpha=1.0;
        
        particles=particles.filter(p->p.life>0);
        
        ctx.fillStyle="#FFF";
        ctx.font="bold 28px Arial";
        ctx.textAlign="left";
        ctx.fillText("SCORE: "+score,20,40);
        ctx.fillText("COMBO: "+combo,20,70);
        ctx.fillText("LIFE: "+Std.int(life)+"%",20,100);
        
        ctx.globalAlpha=ratingAlpha;
        ctx.fillStyle=ratingColor;
        ctx.font="bold 60px Arial";
        ctx.textAlign="center";
        ctx.save();
        ctx.translate(400,250);
        ctx.scale(ratingScale,ratingScale);
        ctx.fillText(ratingStr,0,0);
        ctx.restore();
        ctx.globalAlpha=1.0;
        ratingAlpha*=0.95;
        ratingScale+=0.03;
        
        ctx.font="18px Arial";
        ctx.textAlign="right";
        ctx.fillText(getDifficultyStr(),780,30);
        
        if(botMode){
            ctx.fillStyle="#FF0000";
            ctx.font="bold 20px Arial";
            ctx.textAlign="right";
            ctx.fillText("BOT MODE",780,60);
        }
        
        if(now>songDuration){
            gameState=GameState.GAME_OVER;
            finalizeResults();
        }
    }

    static function drawPauseScreen(){
        ctx.fillStyle="rgba(0,0,0,0.7)";
        ctx.fillRect(0,0,800,600);
        
        ctx.fillStyle="#FFF";
        ctx.font="bold 60px Arial";
        ctx.textAlign="center";
        ctx.fillText("PAUSED",400,200);
        
        ctx.font="28px Arial";
        ctx.fillStyle="#FFD700";
        ctx.fillText("ESC: Resume",400,300);
        ctx.fillStyle="#FF6B6B";
        ctx.fillText("R: Restart",400,360);
        ctx.fillStyle="#888";
        ctx.fillText("M: Menu",400,420);
    }

    static function drawGameOver(){
        ctx.fillStyle="rgba(0,0,0,0.8)";
        ctx.fillRect(0,0,800,600);
        
        ctx.fillStyle="#FF1493";
        ctx.font="bold 80px Arial";
        ctx.textAlign="center";
        ctx.fillText("GAME OVER",400,150);
        
        ctx.fillStyle="#FFF";
        ctx.font="28px Arial";
        var stats=[
            "SCORE: "+score+" / "+maxScore,
            "ACCURACY: "+accuracy.toFixed(2)+"%",
            "RANK: "+getRank(),
            "MAX COMBO: "+maxCombo,
            "PERFECT: "+perfectCount+" GREAT: "+greatCount+" GOOD: "+goodCount+" BAD: "+badCount+" MISS: "+missCount
        ];
        
        var y=250;
        for(stat in stats){
            ctx.fillText(stat,400,y);
            y+=50;
        }
        
        // 判定基準の表示
        ctx.font="16px Arial";
        ctx.fillStyle="#FFD700";
        ctx.fillText("JUDGMENT WINDOW:",150,450);
        ctx.fillStyle="#00FF00";
        ctx.fillText("PERFECT: ±50ms",150,475);
        ctx.fillStyle="#00FFFF";
        ctx.fillText("GREAT: ±100ms",150,500);
        ctx.fillStyle="#FFD700";
        ctx.fillText("GOOD: ±150ms",150,525);
    }

    static function drawResults(){
        ctx.fillStyle="rgba(0,0,0,0.8)";
        ctx.fillRect(0,0,800,600);
        
        var rankColor=switch(getRank()){
            case "S+": "#FFD700";
            case "S": "#C0C0C0";
            case "A+": "#FF6B6B";
            case "A": "#FFB6C1";
            default: "#888";
        };
        
        ctx.fillStyle=rankColor;
        ctx.font="bold 100px Arial";
        ctx.textAlign="center";
        ctx.fillText(getRank(),400,150);
        
        ctx.fillStyle="#FFF";
        ctx.font="28px Arial";
        var stats=[
            "SCORE: "+score+" / "+maxScore,
            "ACCURACY: "+accuracy.toFixed(2)+"%",
            "MAX COMBO: "+maxCombo,
            "DIFFICULTY: "+getDifficultyStr()
        ];
        
        var y=250;
        for(stat in stats){
            ctx.fillText(stat,400,y);
            y+=60;
        }
        
        // 判定詳細表示
        ctx.font="18px Arial";
        ctx.fillStyle="#00FF00";
        ctx.fillText("PERFECT: "+perfectCount,150,450);
        ctx.fillStyle="#00FFFF";
        ctx.fillText("GREAT: "+greatCount,150,475);
        ctx.fillStyle="#FFD700";
        ctx.fillText("GOOD: "+goodCount,150,500);
        ctx.fillStyle="#FF8800";
        ctx.fillText("BAD: "+badCount,150,525);
        ctx.fillStyle="#FF3333";
        ctx.fillText("MISS: "+missCount,150,550);
        
        // ボーナス情報
        ctx.fillStyle="#FFF";
        ctx.font="18px Arial";
        ctx.fillText("MAX MULTIPLIER: "+(comboMultiplier.toFixed(2))+"x",500,450);
        
        ctx.font="20px Arial";
        ctx.fillStyle="#FFD700";
        ctx.fillText("ENTER: Menu | R: Retry",400,580);
        
        if(scoreRecords.length>0){
            ctx.fillStyle="#FFF";
            ctx.font="bold 18px Arial";
            ctx.textAlign="left";
            ctx.fillText("YOUR RANKING:",20,450);
            
            for(i in 0...Math.min(2,scoreRecords.length)){
                var record=scoreRecords[i];
                ctx.font="14px Arial";
                ctx.fillStyle="#CCC";
                ctx.fillText((i+1)+". "+record.score,20,475+i*20);
            }
        }
    }
}
