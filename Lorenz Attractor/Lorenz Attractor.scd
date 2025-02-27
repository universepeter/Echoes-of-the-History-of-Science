ServerOptions.devices;
Server.default.options.device_("Loopback Audio");
s.options.inDevice = "";
s.options.outDevice = "Loopback Audio";
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;
s.options.sampleRate = 44100;
rand;
thisProcess.openUDPPort(22244);
thisProcess.openUDPPort(57120);





(
MIDIClient.init;  // 初始化MIDI客户端
MIDIIn.connectAll;

//MIDIdef.noteOn(\noteOnText,{"key down".psotln});

MIDIClient.destinations;
~midiOut = MIDIOut.new(0);  // 创建一个新的MIDIOut对象，0是你的MIDI设备的端口号
)
~midiOut.control(2, 7,10);
~midiOut.noteOn(1, 60, 64);
~midiOut.noteOff(1,60,64);

(
~lorenz = { |x, y, z, a = 10, b = 28, c = (8/3), dt = 0.01|
    var dx = (a * (y - x)) * dt;
    var dy = (x * (b - z) - y) * dt;
	var dz = ((x * y) - (c * z) )* dt;
    [x + dx, y + dy, z + dz]
};

// 使用洛伦兹和 Supercollider 生成音乐
SynthDef.new(\simpleFM, {
    arg freq=440, amp=0.1, modIndex=2, modFreqRatio=1, pan=0, attack=0.01, decay=0.1, sustain=0.5, release=1, gate=1;

    var modulator = SinOsc.ar(freq * modFreqRatio) * modIndex;
    var carrier = SinOsc.ar(freq + modulator);
    var envelope = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction:2);

    Out.ar(0, Pan2.ar(carrier * envelope * amp, pan));
}).add;

~oscValue=0.0;
// 初始化洛伦兹参数
~x = 0.1;
~y = 0;
~z = 0;
)
// 生成音乐
(
~targetIP = "127.0.0.1"; // 目标 IP 地址，这里设置为本地回环地址
~targetPort=12345;
~oscSender = NetAddr(~targetIP, ~targetPort);

Pdef(\lorenz_music, Pbind(
    \instrument, \simpleFM,
	\dur, Pfunc({~oscValue.linlin(0.0,1.0,0.01,0.1)}),
	// 将音符持续时间增加到 0.5 秒
    \freq, Pfunc({ |evt|
        var xyz = ~lorenz.value(~x, ~y, ~z);
        ~x = xyz[0];
        ~y = xyz[1];
        ~z = xyz[2];
		[~x,~y,~z].postln;
		~oscSender.sendMsg("/xyz", ~x,~y,~z);
		~midiOut.control(0, 7,~x.linlin(-50,50,0,127));
		~midiOut.control(2, 7,~y.linlin(-50,50,0,127));
		~midiOut.control(1, 7,~z.linlin(-50,50,0,127));
		(~x).linlin(-25,15,0,1)*3000
    }),
    \amp, 0.1,
    //\pan, Pfunc({ |evt| (~z).linlin(-50, 50, -1, 1) }),
	\modFreqRatio,Pfunc({ |evt| (~y).linlin(-50, 50, 0, 0.2) }),
    \legato, 1.0, // 增加音符重叠，产生更连续的音效
)).play;


(
thisProcess.openUDPPort(57120);
~oscValue = 1.0;
OSCdef(\oscReceiver, { |msg|
	~oscValue = msg[1].asFloat; // 将接收到的 OSC 数据转换为浮点数
   "ReceivedOSC: %".format(~oscValue).postln;
}, "/fader1");
)
)




// 停止音乐
Pdef(\lorenz_music).stop;
