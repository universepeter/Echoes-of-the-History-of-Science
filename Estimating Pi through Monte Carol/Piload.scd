
//数据加载
(
~currentFilePath = thisProcess.nowExecutingPath;
~currentDir = PathName(~currentFilePath).pathOnly;
~datax=List.readArchive(~currentDir++"datax.scd");
~datay=List.readArchive(~currentDir++"datay.scd");
~datapi=List.readArchive(~currentDir++"datapi.scd");
~datadur=List.readArchive(~currentDir++"datadur.scd");
~datacorr=List.readArchive(~currentDir++"datacorr.scd");
);
(

~index=0;
~targetAddr = NetAddr("127.0.0.1", 12345);
Pbind(\sendi,Pfunc({~datax[~index].postln;
	~datay[~index].postln;
	~datacorr[~index].postln;

	~targetAddr.sendMsg("/datax",~datax[~index]);
	~targetAddr.sendMsg("/datay",~datay[~index]);
	~targetAddr.sendMsg("/datapi",~datapi[~index]);
	~index=~index+1;
}),
\dur,Pfunc({~datadur[~index]}),

).play;
)