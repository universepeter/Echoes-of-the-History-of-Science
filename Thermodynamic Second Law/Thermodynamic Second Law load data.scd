///////////////////////////////////////////首先运行的代码段——————相关函数///////////////////////////////
(
~currentFilePath = thisProcess.nowExecutingPath;
~currentDir = PathName(~currentFilePath).pathOnly;
~datavector= List.readArchive(~currentDir++"datavectors.scd");
~newfader=List.new;
);
///////fader
(
~fader=1;
OSCdef(\fader, {|msg, time, addr, recvPort|
	var array;

    array = msg[1..]; // 从消息中提取数组，假设数组是消息的第一个参数之后的所有内容
	//array[0].postln;
	~fader=array[0];

}, '/fader2', recvPort: 57120);

)




(
// 移动点的函数
~movePoint = { |point|
    var directions, move, potentialNewX, potentialNewY;

    // 定义八个方向的移动
    directions = [
        [0, 1],   // 上
        [0, -1],  // 下
        [-1, 0],  // 左
        [1, 0],   // 右
        [-1, 1],  // 左上
        [1, 1],   // 右上
        [-1, -1], // 左下
        [1, -1],   // 右下
		[0, 0]//不动
    ];

    // 随机选择一个方向
    move = directions.choose;

    // 计算潜在的新坐标
    potentialNewX = point[0] + move[0];
    potentialNewY = point[1] + move[1];

    // 检查是否触碰边界
    // 如果新坐标超出边界，保持原坐标不变
    potentialNewX = if(potentialNewX >= 0 and: { potentialNewX <= 100 }, { potentialNewX }, { point[0] });
    potentialNewY = if(potentialNewY >= 0 and: { potentialNewY <= 100 }, { potentialNewY }, { point[1] });

    // 返回新的或未变的坐标
    [potentialNewX, potentialNewY];
};


/*~newVectors = ~vectors.collect(~movePoint);

// 打印新的向量数组
~newVectors.postln;*/



///将坐标映射为所在的区域我需要写一个函数，输入的数组这样定义：vectors是含有N个二维向量的数组。第一个维度的范围是从（a,b[都是整数]），第二个维度的范围是（c,d[都是整数]），现在需要将此区域（a,b,c,d）内平均划分为M个区域，此M个区域的任何区域可以表示成新的命名空间的区域，如“01”，代表横坐标为0，纵坐标为1的区域。 此函数的输入值是vectors,a,b,c,d,M,  返回值是每个向量所处于的区域并存储于返回值的数组中。


~fregion= { |vectors, a, b, c, d, m|
    var xDivs, yDivs, xSize, ySize, regions;

    // 确定每个维度的分割数
    xDivs = yDivs = (m.sqrt).floor;

    // 计算每个区域的尺寸
    xSize = (b - a) / xDivs;
    ySize = (d - c) / yDivs;

    // 为每个向量分配区域
    regions = vectors.collect { |vec|
        var xIndex, yIndex, region;

        // 计算向量在分割区域内的索引
        xIndex = ((vec[0] - a) / xSize).floor.asInteger;
        yIndex = ((vec[1] - c) / ySize).floor.asInteger;

        // 构造区域标识符
        region = xIndex.asString ++ yIndex.asString;
        region;
    };

    // 返回区域标识符数组
    regions;
};


/*~vectors1 = [[1, 2], [5, 0], [80, 6]];

~result = ~fregion.value(~vectors1, 0, 100, 0, 100, 12);
~result.postln;*/
)
 //////////////////////////////////////运行第二段代码////////////////////////////////////////////////
(
// 定义统计函数
~fregioncount = { |a, b, c, d, m, results|
    var xDivs, yDivs, regionCounts,region;

    xDivs = yDivs = m.sqrt.floor.asInteger;
    regionCounts = Dictionary.new;

    // 初始化所有可能区域的计数为0
    xDivs.do { |x|
        yDivs.do { |y|
            region = x.floor.asInteger.asString ++ y.floor.asInteger.asString;
			regionCounts[region]=0;
        };
    };

	//regionCounts.postln;

    // 遍历results来统计每个区域的向量数量
    results.do { |region|
        regionCounts[region]=regionCounts[region] + 1;};
	regionCounts.postln;

    regionCounts;

};
/*~results1 = ["00", "01", "00", "01", "01", "00"];
// 确保调用时使用英文逗号分隔参数
// 假设~results1已经定义并包含了你的数据
~regionCounts = f.value(0, 10, 0, 10, 4, ~results1);
~regionCounts.postln;*/
)

////////////////////////////////////////运行第三段代码///////////////////////////////////////
//用区域统计结果映射到midiout上，从而发声
(
MIDIClient.init;  // 初始化MIDI客户端
MIDIIn.connectAll;
//MIDIdef.noteOn(\noteOnText,{"key down".psotln});
MIDIClient.destinations;
~midiOut = MIDIOut.new(0);  // 创建一个新的MIDIOut对象，0是你的MIDI设备的端口号
~transformidiout=
{
arg regionCounts,m;

regionCounts.keysValuesDo { |key, value|
		if (key== "00", {~midiOut.control(0, 7,(value/m).linlin(0,1,0,127));});
		if (key== "10", {~midiOut.control(1, 7,(value/m).linlin(0,1,0,127));});
		if (key== "20", {~midiOut.control(2, 7,(value/m).linlin(0,1,0,127));});
		if (key== "30", {~midiOut.control(3, 7,(value/m).linlin(0,1,0,127));});
		if (key== "40", {~midiOut.control(4, 7,(value/m).linlin(0,1,0,127));});
		if (key== "01", {~midiOut.control(0, 8,(value/m).linlin(0,1,0,127));});
		if (key== "11", {~midiOut.control(1, 8,(value/m).linlin(0,1,0,127));});
		if (key== "21", {~midiOut.control(2, 8,(value/m).linlin(0,1,0,127));});
		if (key== "31", {~midiOut.control(3, 8,(value/m).linlin(0,1,0,127));});
		if (key== "41", {~midiOut.control(4, 8,(value/m).linlin(0,1,0,127));});
		if (key== "02", {~midiOut.control(0, 9,(value/m).linlin(0,1,0,127));});
		if (key== "12", {~midiOut.control(1, 9,(value/m).linlin(0,1,0,127));});
		if (key== "22", {~midiOut.control(2, 9,(value/m).linlin(0,1,0,127));});
		if (key== "32", {~midiOut.control(3, 9,(value/m).linlin(0,1,0,127));});
		if (key== "42", {~midiOut.control(4, 9,(value/m).linlin(0,1,0,127));});
		if (key== "03", {~midiOut.control(0, 10,(value/m).linlin(0,1,0,127));});
		if (key== "13", {~midiOut.control(1, 10,(value/m).linlin(0,1,0,127));});
		if (key== "23", {~midiOut.control(2, 10,(value/m).linlin(0,1,0,127));});
		if (key== "33", {~midiOut.control(3, 10,(value/m).linlin(0,1,0,127));});
		if (key== "43", {~midiOut.control(4, 10,(value/m).linlin(0,1,0,127));});
		if (key== "04", {~midiOut.control(0, 11,(value/m).linlin(0,1,0,127));});
		if (key== "14", {~midiOut.control(1, 11,(value/m).linlin(0,1,0,127));});
		if (key== "24", {~midiOut.control(2, 11,(value/m).linlin(0,1,0,127));});
		if (key== "34", {~midiOut.control(3, 11,(value/m).linlin(0,1,0,127));});
		if (key== "44", {~midiOut.control(4, 11,(value/m).linlin(0,1,0,127));});
};

}
)

//////////////////////////////////运行第四段代码初始化粒子/////////////////////////////
// 可调整的参数如下：~number代表粒子的数量，~minValue1 ~maxValue1 代表横坐标范围，~minValue2 ~minValue2 代表纵坐标范围
(
// 定义向量的数量,   定义粒子的数量
~number=20;

// 定义粒子初始状态所在范围
~minValue1 = 0;
~maxValue1 = 24;
~minValue2 = 0;
~maxValue2 = 24;

// 创建并初始化向量数组
~vectors = Array.fill(~number, {
    // 为每个向量生成随机的二维值
    [
        ~minValue1 + (~maxValue1 - ~minValue1).rand, // 第一维的值
        ~minValue2 + (~maxValue2 - ~minValue2).rand  // 第二维的值
    ]
});

// 打印向量数组以验证
~vectors.postln;
)

////////////////////////////////运行第五段代码运行Pbind////////////////////////////////
(
~targetAddr = NetAddr("127.0.0.1", 7001); // 假设接收端在本机，使用57120端口
~targetAddr1 = NetAddr("127.0.0.1", 7234); // 假设接收端在本机，使用57120端口
~indexindex=0;
~result;
~regionCounts;
Pbind(
	\dur,Pfunc({~newfader.add(~fader);~fader.linlin(0,1,0.1,1)}),
      //0.1 0.3
	\processing,Pfunc({
		var step=20;
		~vectors=~datavector[~indexindex];
		~indexindex=~indexindex+step;//所有粒子的点 扩散一步的结果
		if((~indexindex>(~datavector.size-1)),{~indexindex=~indexindex-step});

		~dataflaten=~vectors.flatten;
		"flaten:".postln;
		~dataflaten.postln;
		//~targetAddr.sendMsg("/myosc",[ [1, 2], [3, 4], [9, 11] ]);
		~targetAddr.sendMsg("/myc", *~dataflaten);
		"完成1".postln;
		~result=~fregion.value(~vectors, 0, 101, 0, 101, 25);//将这些点变换成所在区域，边界值范围增加1
		~result.postln;
		"完成2".postln;
		~regionCounts=~fregioncount.value(0, 100, 0, 100, 25,~result);//获得统计数据
		~entropy=0;
		~regionCounts.do{|value| if(value.log>0,{ ~entropy=~entropy+((value.log)*value*(-1))})};
		~entropy.postln;//此处可以
		~targetAddr1.sendMsg("entropy",~entropy);
		"完成3".postln;
		~transformidiout.value(~regionCounts,~number);
		"完成4".postln;
	}),
).play;
)


//对所在区域的点进行统计。


////存储数据
(
~currentFilePath = thisProcess.nowExecutingPath;
~currentDir = PathName(~currentFilePath).pathOnly;
//~datavector.writeArchive(~currentDir++"datavectors.scd");
~newfader.writeArchive(~currentDir++"newfader.scd");

)


//////////////////以下不用运行
(
~entropy=0;
~regionCounts.do{|value| if(value.log>0,{ ~entropy=~entropy+((value.log)*value*(-1))});
	value.log;
};
~entropy.postln;
)
///// 测试osc通信
(
~targetAddr3 = NetAddr("192.168.225.207", 57120);
~targetAddr3.sendMsg("/red",12345)
)