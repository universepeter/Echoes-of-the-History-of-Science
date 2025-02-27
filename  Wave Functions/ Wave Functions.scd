(
// 定义合成器
SynthDef(\granular_sine, { arg out=0, freq=440, dur=0.1, amp=0.4, x=0.5, a=1, n=1,attack=0.03, decay=4, sustain=0.7, release=5, gate=1;
    var env, source, psi;
	var envelope = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction:2);

    // 定义波函数
    psi = (2/a).sqrt * SinOsc.kr(n * pi * x / a, 0, 0.5);

    // 创建颗粒合成器源
    source = GrainSin.ar(
        numChannels: 2,
        trigger: Impulse.kr(10),
        dur: dur,
        freq: freq + (psi * 100),
        pan: LFNoise1.kr(0.5).range(-1, 1),
        envbufnum: -1,
        maxGrains: 100
	) * amp * (psi.abs)*envelope ;  // 通过乘以振幅因子来调整振幅

    // 输出源
    Out.ar(out, source);
}).add;
)

// 创建音乐片段
(
Pbind(
    \instrument, \granular_sine,
    \dur, Pwhite(0.1, 0.3, inf),
    \x, Pwhite(0, 1, inf),  // x 在[0, 1]范围内随机变化
    \a, 0.8,  // 势井的宽度
    \n, 1,  // 量子数
    \freq, 2000,
    \amp, 0.3
).play;
)



