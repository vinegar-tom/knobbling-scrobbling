(
//// Setup and SynthDefs
~carolPitch = #[
	61, 66, 71, 76, 70, 75, 73, // 0-6
	59, 66, 70, 75, 68, 73, 71, // 7-13
	58, 64, 68, 73, 67, 71, 70, // 14-20
	56, 63, 68, 71, 54, 69, // 21-26
	52, 59, 71, 80, 58, 73, 78, 76, // 27-34
	51, 59, 66, 71, 78, 75, // 35-40
	44, 59, 68, 71, 73, 75, 49, 61, 65, 71, 77, // 41-51
	54, 61, 66, 70, 78, // 52-56
	54, 66, 69, 74, // 57-60
	54, 62, 66, 71, // 61-64
	54, 60, 63, 68, // 65-68
	44, 48, 51, 56, 58, 60, 63, 66, 68 //69-77
];
~carolers = List.new;
~min = 0;
~max = 6;
~carolMinMIDI = 5.0;
~carolMaxMIDI = 8.0;

SynthDef(\warbleTri, {
	arg freq=200, modHz=1, mod=0.2, att=1, rel=2,
	pan=0, width=0.5, gate=1, amp=0.7, out=0;
	var sig, env, fm;

	fm = SinOsc.ar(modHz, pi/1.3, 3, -2).clip * (mod.midiratio - 1) + 1;
	sig = VarSaw.ar(
		{freq * Rand(-0.1.midiratio, 0.1.midiratio)}!2 * fm,
		width: width
	);
	sig = LPF.ar(sig,
		freq/2 + LFNoise2.kr(LFNoise1.kr(2).range(0.5, 1.2)).range(1500, 4000)
	);

	env = EnvGen.kr(Env.asr(att, 1, rel), gate, doneAction:2);
	sig = sig * env * AmpCompA.kr(freq, 50, 0.5);

	sig = Balance2.ar(sig[0], sig[1], pan, amp);
	Out.ar(out, sig);
}).add;

//// Patterns and Routines
~carolerP = Pbind(
	\instrument, \warbleTri,
	\stretch, 60/66,
	\dur, Prand((4, 5..10), inf),
	\att, Pwhite(1.0, 2.0, inf),
	\rel, Pwhite(2.0, 4.0, inf),
	\legato, Pwhite(0.7, 1.0, inf),
	\midinote, Pfunc({ ~carolPitch[(~min..~max)].choose })
	+ Pif(Pfunc({0.1.coin}), 12, 0, 0),
	\width, Pwhite(0.45, 0.55, inf),
	\amp, Pwhite(0.15, 0.25, inf),
	\modHz, Prand([1/3, 2/5, 1/2, 2/3, 1], inf),
	\mod, Pwhite(-0.3, 0.3, inf),
	\pan, Pwhite(-0.5, 0.5, inf),
);

~carolerBassP = Pbind(
	\instrument, \warbleTri,
	\stretch, 60/66,
	\dur, Prand((4, 5..10), inf),
	\att, Pwhite(1.0, 2.0, inf),
	\rel, Pwhite(2.0, 4.0, inf),
	\legato, Pwhite(0.7, 1.0, inf),
	\midinote, Pfunc({ ~carolPitch[(~min..(~min+1))].choose - 12 }),
	\width, Pwhite(0.45, 0.55, inf),
	\amp, Pwhite(0.15, 0.25, inf),
	\modHz, Prand([1/3, 2/5, 1/2, 2/3, 1], inf),
	\mod, Pwhite(-0.3, 0.3, inf),
	\pan, Pwhite(-0.5, 0.5, inf),
);

~carolTimer = Routine({inf.do{ |i|
	var elapsed = i.asInteger;

	switch (elapsed)
	{ 0 } { ~min = 0; ~max = 6 }
	{ 40 } { ~min = 0; ~max = 8 }
	{ 50 } { ~min = 7; ~max = 13 }
	{ 90 } { ~min = 7; ~max = 15 }
	{ 100 } { ~min = 14; ~max = 20 }
	{ 140 } { ~min = 14; ~max = 22 }
	{ 150 } { ~min = 21; ~max = 26 }
	{ 190 } { ~min = 21; ~max = 28 }
	{ 200 } { ~min = 27; ~max = 34 }
	{ 240 } { ~min = 27; ~max = 36 }
	{ 250 } { ~min = 35; ~max = 40 }
	{ 290 } { ~min = 35; ~max = 42 }
	{ 300 } { ~min = 41; ~max = 51 }
	{ 340 } { ~min = 41; ~max = 53 }
	{ 350 } { ~min = 52; ~max = 56 }
	{ 390 } { ~min = 52; ~max = 58 }
	{ 400 } { ~min = 57; ~max = 60 }
	{ 440 } { ~min = 57; ~max = 62 }
	{ 450 } { ~min = 61; ~max = 64 }
	{ 490 } { ~min = 61; ~max = 66 }
	{ 500 } { ~min = 65; ~max = 68 }
	{ 540 } { ~min = 65; ~max = 70 }
	{ 550 } { ~min = 69; ~max = 77 };

	~carolTimerText.value_(
		(elapsed/60).trunc(1).asInteger.asString ++ ":"
		++ (elapsed%60).trunc(1).asInteger.asString.padLeft(2, "0")
	);
	~carolMinMaxText.value_(~min.asString ++ "/" ++ ~max.asString);

	1.wait;
}});

~carolMIDI = Routine({inf.do{
	Pbind(
		\type, \midi,
		\midicmd, \noteOn,
		\midiout, ~mio,
		\chan, 0,
		\lag, 0.2,
		\midinote, Pfin({ rrand(12, 36) },
			Pseq(~carolPitch[(~min..~max)].pyramid(rrand(1, 10)).sputter(0.3))
			+ Pif(Pfunc({ 0.3.coin }), 12, 0)
		),
		\stretch, 60/66,
		\dur, Prand([
			Pwrand([1/8, Rest(1/8)], [3, 1].normalizeSum, Prand([8, 16], inf)),
			Pwrand([1/5, Rest(1/5)], [4, 1].normalizeSum, 5),
			Pwrand([1/3, Pseq([1/6], 2), Rest(1/3)], [4, 1, 1].normalizeSum, 3),
			Rest(1/4),
			Rest(1/2),
		], inf),
		\legato, Pwhite(0.2, 0.5, inf),
		\amp, Pwhite(0.4, 0.6, inf),
	).play(quant: 60/66);

	["Ho, ho, ho!", "Merry Christmas!", "メリークリスマス"].choose.postln;
	rrand(~carolMinMIDI, ~carolMaxMIDI).wait;
}});

//// GUI
w = Window("Carolers", Rect(1060, 574, 440, 78))
.front
.alwaysOnTop_(true);

// Carolers
StaticText(w, Rect(10, 10, 80, 24))
.string_("carolers")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(100, 10, 24, 24))
.states_([["-"]])
.font_(Font("IBM Plex Mono", 16))
.action_({
	if( ~carolers.size > 0,
		{ ~carolers.pop.stop },
		{ "No more carolers".postln }
	);
	~carolerCount.doAction;
});

Button(w, Rect(134, 10, 24, 24))
.states_([["+"]])
.font_(Font("IBM Plex Mono", 16))
.action_({
	if( ~carolers.size == 0,
		{ ~carolers.addFirst(~carolerBassP.play(quant: 60/66)) },
		{ ~carolers.add(~carolerP.play(quant: 60/66)) }
	);
	~carolerCount.doAction;
});

~carolerCount = StaticText(w, Rect(168, 10, 32, 24))
.string_(~carolers.size)
.font_(Font("IBM Plex Mono", 16))
.align_(\left)
.action_({ |obj|
	obj.string_(~carolers.size);
});

// Timer
StaticText(w, Rect(10, 44, 80, 24))
.string_("timer")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(100, 44, 40, 24))
.states_([["OFF"], ["ON", Color.white, Color.green]])
.font_(Font("IBM Plex Mono", 16))
.action_({ |obj|
	if( obj.value == 0,
		{ ~carolTimer.stop },
		{
			~carolTimer.reset;
			~carolTimer.play(AppClock);
		}
	);
});

~carolTimerText = TextField(w, Rect(150, 44, 75, 24))
.enabled_(false)
.string_("0:00")
.font_(Font("IBM Plex Mono", 16))
.align_(\center);

// Min/max
StaticText(w, Rect(225, 44, 80, 24))
.string_("min/max")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

~carolMinMaxText = TextField(w, Rect(315, 44, 75, 24))
.enabled_(false)
.string_(~min.asString ++ "/" ++ ~max.asString)
.font_(Font("IBM Plex Mono", 16))
.align_(\center);

// MIDI
StaticText(w, Rect(240, 10, 94, 24))
.string_("play MIDI")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(344, 10, 40, 24))
.states_([["OFF"], ["ON", Color.white, Color.green]])
.font_(Font("IBM Plex Mono", 16))
.action_({ |obj|
	if( obj.value == 0,
		{ ~carolMIDI.stop },
		{
			~carolMIDI.reset;
			~carolMIDI.play(SystemClock);
		}
	);
});
)



//// Functions for setting timing
(12 * 40) + (11 * 10) / 60;
(
~temp = 0;
22.collect({ |i|
	if (i.even, {~temp = ~temp + 40}, {~temp = ~temp + 10});
	~temp;
})
)
