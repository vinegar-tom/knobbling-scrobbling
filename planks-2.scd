(
ServerMeter(s, 1, 2).window.bounds_(Rect(1400, 60, 115.0, 230.0));
MIDIClient.init;
~mio = MIDIOut.newByName("mio", "mio").latency_(0.4);
)
(
//// Setup and SynthDefs
~percDict = Dictionary.new;
~thisDir = thisProcess.nowExecutingPath.dirname;
~percDict.add(\maraca ->
	PathName(~thisDir +/+ "dry-perc/maracas").entries.collect({
		arg file;
		Buffer.read(s, file.fullPath);
	})
);
~percDict.add(\plank ->
	PathName(~thisDir +/+ "dry-perc/planks").entries.collect({
		arg file;
		Buffer.read(s, file.fullPath);
	})
);
~percDict.add(\brkDrum ->
	PathName(~thisDir +/+ "dry-perc/brk-drum").entries.collect({
		arg file;
		Buffer.read(s, file.fullPath);
	})
);

~percEnsemble = Dictionary.new;
~percEnsemble.add(\plank -> List.new);
~percEnsemble.add(\maraca -> List.new);
~percEnsemble.add(\brkDrum -> List.new);

SynthDef(\bufPlay, {
	arg buf, rate=1, pan=0, amp=1, out=0;
	var sig;
	sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf) * rate, doneAction:2);
	sig = Balance2.ar(sig[0], sig[1], pan, amp);
	Out.ar(out, sig);
}).add;

SynthDef(\reverb, {
	arg in, out=0;
	var sig;
	sig = In.ar(in, 2);
	sig = FreeVerb.ar(sig, 0.1, 0.2);
	Out.ar(out, sig);
}).add;

~effectBus = Bus.audio(s, 2);
~sampleGroup = Group.new(s);
~effectGroup = Group.after(~sampleGroup);
~maxLag = 0.14;
~tempo = 60 / 66;

//// Patterns
~plankP = Pbind(
	\instrument, \bufPlay,
	\group, Pfunc({ ~sampleGroup }),
	\out, Pfunc({ ~effectBus }),
	\buf, Prand(~percDict[\plank], inf),
	\dur, Pwrand(
		[1, 1.5, Pseq([Pn(0.125, 2), Rest(0.25)]), Pn(0.5, 2), Rest(0.5)],
		[4, 4, 1, 0.5, 7].normalizeSum,
		inf),
	\stretch, Pfunc{~tempo},
	\lag, Pwhite(0.1, Pfunc{~maxLag}, inf),
	\rate, Pwhite(-3.midiratio, 3.midiratio, inf),
	\pan, Pwhite(-0.5, 0.5, inf),
	\amp, Pwhite(0.2, 0.5, inf),
);

~maracaP = Pbind(
	\instrument, \bufPlay,
	\group, Pfunc({ ~sampleGroup }),
	\out, Pfunc({ ~effectBus }),
	\buf, Prand(~percDict[\maraca], inf),
	\dur, Pwrand([1, 1.5, Rest(1)], [1, 1, 4].normalizeSum, inf),
	\stretch, Pfunc{~tempo},
	\lag, Pwhite(0.0, 0.1, inf),
	\rate, Pwhite(-4.midiratio, 1.midiratio, inf),
	\pan, Pwhite(-0.25, 0.25, inf),
	\amp, Pwhite(0.3, 0.5, inf),
);

~brkDrumP = Pbind(
	\instrument, \bufPlay,
	\group, Pfunc({ ~sampleGroup }),
	\out, Pfunc({ ~effectBus }),
	\buf, Prand(~percDict[\brkDrum], inf),
	\dur, Pwrand(
		[
			1,
			Rest(1),
			Pseq([Rest(3/4), Pn(1/12, 3), 1], 1),
			Pseq([Pn(1/8, 2), Rest(1/4), Pn(1/8, 3), Rest(1/8)], 1)
		],
		[3, 6, 1, 1].normalizeSum,
		inf
	),
	\stretch, Pfunc{~tempo},
	\lag, Pwhite(0.1, 0.12, inf),
	\rate, Pwhite(-0.05.midiratio, 0.05.midiratio, inf),
	\amp, Pseq((0.2, 0.22..0.4), inf),
);

//// GUI
w = Window("Percussion ensemble", Rect(1060, 700, 440, 112))
.front
.alwaysOnTop_(true);

// Planks
StaticText(w, Rect(10, 10, 80, 24))
.string_("planks")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(100, 10, 24, 24))
.states_([["-"]])
.font_(Font("IBM Plex Mono", 16))
.action_({
	if( ~percEnsemble[\plank].size > 0,
		{ ~percEnsemble[\plank].pop.stop },
		{ "No more planks".postln }
	);
	~plankCount.doAction;
});

Button(w, Rect(134, 10, 24, 24))
.states_([["+"]])
.font_(Font("IBM Plex Mono", 16))
.action_({
	~percEnsemble[\plank].addFirst(~plankP.play(quant: ~tempo));
	~plankCount.doAction;
});

~plankCount = StaticText(w, Rect(168, 10, 32, 24))
.string_(~percEnsemble[\plank].size)
.font_(Font("IBM Plex Mono", 16))
.align_(\left)
.action_({ |obj|
	obj.string_(~percEnsemble[\plank].size);
});

// Maracas
StaticText(w, Rect(10, 44, 80, 24))
.string_("maracas")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(100, 44, 24, 24))
.states_([["-"]])
.font_(Font("IBM Plex Mono", 16))
.action_({
	if( ~percEnsemble[\maraca].size > 0,
		{ ~percEnsemble[\maraca].pop.stop },
		{ "No more maracas".postln }
	);
	~maracaCount.doAction;
});

Button(w, Rect(134, 44, 24, 24))
.states_([["+"]])
.font_(Font("IBM Plex Mono", 16))
.action_({
	~percEnsemble[\maraca].addFirst(~maracaP.play(quant: ~tempo));
	~maracaCount.doAction;
});

~maracaCount = StaticText(w, Rect(168, 44, 32, 24))
.string_(~percEnsemble[\maraca].size)
.font_(Font("IBM Plex Mono", 16))
.align_(\left)
.action_({ |obj|
	obj.string_(~percEnsemble[\maraca].size);
});

// Brake drums
StaticText(w, Rect(10, 78, 80, 24))
.string_("brkDrums")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(100, 78, 24, 24))
.states_([["-"]])
.font_(Font("IBM Plex Mono", 16))
.action_({
	if( ~percEnsemble[\brkDrum].size > 0,
		{ ~percEnsemble[\brkDrum].pop.stop },
		{ "No more brake drums".postln }
	);
	~brkDrumCount.doAction;
});

Button(w, Rect(134, 78, 24, 24))
.states_([["+"]])
.font_(Font("IBM Plex Mono", 16))
.action_({
	~percEnsemble[\brkDrum].addFirst(~brkDrumP.play(quant: ~tempo));
	~brkDrumCount.doAction;
});

~brkDrumCount = StaticText(w, Rect(168, 78, 32, 24))
.string_(~percEnsemble[\brkDrum].size)
.font_(Font("IBM Plex Mono", 16))
.align_(\left)
.action_({ |obj|
	obj.string_(~percEnsemble[\brkDrum].size);
});

// Clear all
StaticText(w, Rect(220, 10, 94, 24))
.string_("clear all")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(324, 10, 24, 24))
.states_([["*"]])
.font_(Font("IBM Plex Mono", 16))
.action_({
	~percEnsemble.keys.do({ |key|
		~percEnsemble[key].size.do{ ~percEnsemble[key].pop.stop };
	});
	~plankCount.doAction;
	~maracaCount.doAction;
	~brkDrumCount.doAction;
});

// Max lag
StaticText(w, Rect(220, 44, 94, 24))
.string_("max lag:")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

TextField(w, Rect(324, 44, 80, 24))
.font_(Font("IBM Plex Mono", 16))
.value_(~maxLag)
.action_({ |obj|
	~maxLag = obj.value.asFloat.clip(0.1, 0.3);
	obj.value = ~maxLag;
});

// Reverb (output) On/Off
StaticText(w, Rect(210, 78, 104, 24))
.string_("audio out:")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(324, 78, 40, 24))
.states_([["OFF"], ["ON", Color.white, Color.green]])
.font_(Font("IBM Plex Mono", 16))
.action_({ |obj|
	if( obj.value == 0,
		{ ~revSynth.free },
		{ ~revSynth = Synth(\reverb, [\in, ~effectBus], target:~effectGroup) }
	);
});
)



//// Reference controls

(// Start sound
Synth(\reverb, [\in, ~effectBus], target:~effectGroup);
)


8.do{ ~percEnsemble[\plank].addFirst(~plankP.play(quant: ~tempo)) };
4.do{ ~percEnsemble[\maraca].addFirst(~maracaP.play(quant: ~tempo)) };
1.do{ ~percEnsemble[\brkDrum].addFirst(~brkDrumP.play(quant: ~tempo)) };

// One off
~percEnsemble[\maraca].pop.stop;
(// Family off
var family = \brkDrum;
~percEnsemble[family].size.do{ ~percEnsemble[family].pop.stop };
)
(// All off
~percEnsemble.keys.do({ |key|
	~percEnsemble[key].size.do{ ~percEnsemble[key].pop.stop };
});
)
