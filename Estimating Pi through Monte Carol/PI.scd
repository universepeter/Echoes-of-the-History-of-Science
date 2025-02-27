(
MIDIClient.init;  // 初始化MIDI客户端
MIDIIn.connectAll;

//MIDIdef.noteOn(\noteOnText,{"key down".psotln});

MIDIClient.destinations;
~midiOut = MIDIOut.new(0);  // 创建一个新的MIDIOut对象，0是你的MIDI设备的端口号

~x=0;~y=0;
~countin=0;~countout=0;
~pii=0;
~count=0;
~corr=0;
~distance={|x,y|
	var distance;
	distance=((x-0.5)**2)+((y-0.5)**2);
	distance;
};

~startDur=2.0;
~factor=0.9;
~factor2=0.5;
~startspeed=2.0;
~speed=~startspeed;
~durre=~startDur;
///////保存数据//////////
~datadur=List.new;
~datax=List.new;
~datay=List.new;
~datacorr=List.new;
~datapi=List.new;


~updateDur = { arg currentDur;
    var newDur;
    newDur = currentDur * ~factor;
    newDur = newDur.max(0.01); // 确保dur不会小于0.01秒，这里假设0.01是最短的值
    newDur;
};
~updatean={arg currentDur;
    var newDur;
    newDur = currentDur * ~factor2;
    newDur = newDur.max(0.01); // 确保dur不会小于0.01秒，这里假设0.01是最短的值
    newDur;
};


~writeListToFile = { |list, filename|
    var file = File(filename, "w");
    list.do { |item|
        file.write(item.asString ++ "\n");
    };
    file.close;
    "List written to file: %".format(filename).postln;
};




~readListFromFile = { |filename|
    var file = File(filename, "r");
    var list = [];
    var line;
    while { (line = file.getLine).notNil } {
        list = list.add(line.interpret);
    };
    file.close;
    "List read from file: %".format(filename).postln;
    list;
};


Pbind(\dur,Pfunc({
	var datadur;
	~durre=~updateDur.value(~durre);
	~speed=~updatean.value(~speed);
	~datadur.add(~durre);
	~durre;}),
	\prg,Pfunc({
	~x=rrand(0.0,1.0);
	~y=rrand(0.0,1.0);
	~datax.add(~x);

	~datax.postln;
	~datay.add(~y);
	~midiOut.control(0,7,~x.linlin(0.0,1.0,0,127));
	~midiOut.noteOn(0,~x.linlin(0.0,1.0,(64-(1/~speed).linlin(0.5,200,6,63).round),(64+(1/~speed).linlin(0.5,200,6,53).round)),~x.linlin(0.0,1.0,0,127));
	/*		"start".postln;
	(64-(1/~speed).linlin(0.5,200,6,63)).round.postln;
	(64+(1/~speed).linlin(0.5,200,6,53)).round.postln;
	"end".postln;*/
	~midiOut.control(1,7,~y.linlin(0.0,1.0,0,127));
	if(~distance.value(~x,~y)<0.25,{~countin=~countin+1},{~countout=~countout+1});
	~pii=4*(~countin/(~countin+~countout));
	~corr=(~pii-pi).abs;
	~datacorr.add(~corr);
	~datapi.add(~pii);
	~midiOut.control(2,7,~corr.linlin(0,1,0,127));
	~midiOut.control(3,7,~corr.linlin(0,1,127,0));
	~pii.postln;
	~count=~count+1;
	~count.postln;
	}),
).play;
)

////存储数据
(
~currentFilePath = thisProcess.nowExecutingPath;
~currentDir = PathName(~currentFilePath).pathOnly;
~datax.postln;
~datax.writeArchive(~currentDir++"datax.scd");
~datay.writeArchive(~currentDir++"datay.scd");
~datadur.writeArchive(~currentDir++"datadur.scd");
~datacorr.writeArchive(~currentDir++"datacorr.scd");
~datapi.writeArchive(~currentDir++"datapi.scd");
)



///加载数据
~loadedData = List.readArchive(~currentDir++"datax.scd");