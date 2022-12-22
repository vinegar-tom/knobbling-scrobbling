(
//// Setup and SynthDefs
~maxDetune = 24;

SynthDef(\bell, { // usable freq range ~300-1200
	arg freq=300, detune=0.2, pan=0, amp=0.7, out=0;
	var sig, partialArr, freqArr, relArr, attArr, envArr, hit;

	partialArr = [0.5, 1, 1.183, 1.506, 2, 2.514, 2.662, 3.011, 4.166, 5.433, 6.796];
	freqArr = partialArr.collect({ |partial|
		Array.fill(2, {
			partial * freq * Rand((-1*detune).midiratio, detune.midiratio);
		});
	});

	relArr = Array.geom(11, 10, 0.912);
	relArr = relArr.collect({ |rel|
		rel * Rand(0.8, 1.2);
	});

	attArr = Array.geom(11, 1, 0.501);
	attArr = attArr.collect({ |att|
		att * Rand(0.8, 1.2);
	});
	envArr = freqArr.collect({ |freqPair, i|
		EnvGen.kr(Env.perc(
			attArr[i],
			relArr[i],
			AmpCompA.kr(freqPair[0], 120, 0.25),
			-6
		));
	});
	FreeSelfWhenDone.kr(envArr[0]);

	sig = freqArr.collect({ |freqPair, i|
		var sinMix;
		sinMix = Mix.ar(SinOsc.ar(freqPair)) * envArr[i] * 1/6;
	});

	//hit = SinOsc.ar(freq * 3.06 + SinOsc.ar(freq * 1.85, mul:Rand(2500, 3500)));
	hit = SinOsc.ar(freq * 2.88 + SinOsc.ar(freq * 1.7, mul:Rand(2500, 3000)));
	hit = hit * EnvGen.kr(Env.perc(0.001, 0.6, 1, -5)) * 0.5;

	sig = (Mix.ar(sig) + (hit * 0.6)) * amp;
	sig = Pan2.ar(sig, pan);
	Out.ar(out, sig);
}).add;

//// Routines
~bellTimer = Routine({121.do{
	arg time;
	~maxDetune = time.lincurve(0, 120, 24, 0.15, -5);

	~bellTimerText.value_(
		(time/60).trunc(1).asInteger.asString ++ ":"
		++ (time%60).trunc(1).asInteger.asString.padLeft(2, "0")
	);
	~bellDetuneText.value_(~maxDetune.round(0.01).asString);

	1.wait;
}});

//// Patterns
~detuneBellP = Ppar([
	Pbind(
		\instrument, \bell,
		\dur, 1,
		\stretch, 1.5,
		\midinote, Pwrand([66, 78, Rest(1)], [4, 1, 3].normalizeSum, inf),
		\amp, Pwhite(0.2, 0.3, inf),
		\detune, Pwhite(Pfunc({ ~maxDetune-0.1 }), Pfunc({ ~maxDetune}), inf),
	),
	Pwrand([
		Pbind(// Rest
			\instrument, \bell,
			\stretch, 1.5,
			\dur, Pseq([Rest(4), 1]),
			\midinote, Rest(1),
		),
		Pbind(// Low 1
			\instrument, \bell,
			\stretch, 1.5,
			\dur, Pseq([Rest(7/8), 1/8, 3], 1),
			\midinote, Pseq([Rest(1), 73, 65], inf),
			\amp, Pwhite(0.3, 0.4, inf),
			\pan, Pwhite(-0.5, 0.5, inf),
			\detune, Pwhite(Pfunc({ ~maxDetune-0.1 }), Pfunc({ ~maxDetune}), inf),
		),
		Pbind(// Low 2
			\instrument, \bell,
			\stretch, 1.5,
			\dur, Pseq([Rest(7/8), 1/8, 3], 1),
			\midinote, Pseq([Rest(1), 68, 65], inf),
			\amp, Pwhite(0.3, 0.4, inf),
			\pan, Pwhite(-0.5, 0.5, inf),
			\detune, Pwhite(Pfunc({ ~maxDetune-0.1 }), Pfunc({ ~maxDetune}), inf),
		),
		Pbind(// Low 3
			\instrument, \bell,
			\stretch, 1.5,
			\dur, Pseq([Rest(1/3 + 1), 1/3, 1/3 + 2], 1),
			\midinote, Pseq([Rest(1), 67, 69], inf),
			\amp, Pwhite(0.3, 0.4, inf),
			\pan, Pwhite(-0.5, 0.5, inf),
			\detune, Pwhite(Pfunc({ ~maxDetune-0.1 }), Pfunc({ ~maxDetune}), inf),
		),
		Pbind(// High 1
			\instrument, \bell,
			\stretch, 1.5,
			\dur, Pseq([Rest(1/2 + 1), 1/2, 1/2, 1/2 + 1], 1),
			\midinote, Pseq([Rest(1), 80, 74, 76], inf),
			\amp, Pwhite(0.3, 0.4, inf),
			\pan, Pwhite(-0.5, 0.5, inf),
			\detune, Pwhite(Pfunc({ ~maxDetune-0.1 }), Pfunc({ ~maxDetune}), inf),
		),
		Pbind(// High 2
			\instrument, \bell,
			\stretch, 1.5,
			\dur, Pseq([Rest(1/2 + 1), 1/2, 1/2, 1/2 + 1], 1),
			\midinote, Pseq([Rest(1), 78, 72, 74], inf),
			\amp, Pwhite(0.3, 0.4, inf),
			\pan, Pwhite(-0.5, 0.5, inf),
			\detune, Pwhite(Pfunc({ ~maxDetune-0.1 }), Pfunc({ ~maxDetune}), inf),
		),
	], [3, 1, 1, 1, 2, 2].normalizeSum, inf)
]);

~messiaenBellP = Pseq([
	Pbind(
		\instrument, \bell,
		\stretch, Pwhite(1.0, 1.2, inf),
		\dur, Pseq([1.59, 0.210, 0.172, 0.156, 1.74, 0.186, 2.94, 3.93], 4) * Pwhite(0.9, 1.1, inf),
		\midinote, Pseq([85, 84, 83, 82, 79, 68, 73, 78], inf) + Pwhite(0.0, 0.1, inf),
		\pan, Pwhite(-0.5, 0.5, inf),
		\amp, Pwhite(0.4, 0.6, inf),
		\detune, Pwhite(0.1, 0.15, inf),
	),
	Pbind(
		\instrument, \bell,
		\dur, Pwhite(5.5, 7, 6),
		\midinote, 66,
		\pan, Pwhite(-0.5, 0.5, inf),
		\amp, Pwhite(0.6, 0.7, inf),
		\detune, Pwhite(0.1, 0.15, inf),
	),
	Pbind(
		\instrument, \bell,
		\dur, Pseq([ Pwhite(2.5, 3, 7), 5.3, 1 ], 1),
		\midinote, Pseq([61, 64, 67, 64], inf),
		\pan, Pwhite(-0.5, 0.5, inf),
		\amp, Pwhite(0.6, 0.7, inf),
		\detune, Pwhite(0.1, 0.15, inf),
	)
], 1);

~joyBellP = Pseq([
	Pbind(
		\instrument, \bell,
		\dur, Pseq([ Pwhite(0.005, 0.025, 4), Pwhite(2.7, 3.3, 4) ], 3),
		\midinote, Pseq([ Pshuf([67, 69, 72, 75, 77], 1), 77, 72, 77 ], inf),
		\pan, Pwhite(-0.5, 0.5, inf),
		\amp, Pwhite(0.4, 0.6, inf),
		\detune, Pwhite(0.1, 0.15, inf),
	),
	Pbind(
		\instrument, \bell,
		\dur, Pwhite(1.25, 1.35, 8),
		\stretch, Pseq((1.5, 1.35..0), inf),
		\midinote, Pseq([72, 77], inf),
		\pan, Pwhite(-0.5, 0.5, inf),
		\amp, Pwhite(0.4, 0.6, inf),
		\detune, Pwhite(0.1, 0.15, inf),
	),
	Pbind(
		\instrument, \bell,
		\dur, Pseq([ Pwhite(0.02, 0.04, 1), Pwhite(0.55, 0.65, 1) ], 10),
		\midinote, Pseq([77, 72, 77, 75], inf),
		\pan, Pwhite(-0.5, 0.5, inf),
		\amp, Pwhite(0.4, 0.6, inf),
		\detune, Pwhite(0.1, 0.15, inf),
	)
], 1);

~bellsMIDI = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\midiout, ~mio,
	\chan, 0,
	\a, Pseq([
		Pseq([78, 81, 79, 78, 74, 76, 79, 78, 81, 78, 74, 79, 76], 3),
		Pseq([78, 81, 79, 78, 74, 76, 79, 78, 79, 81, 79, 78, 76], 1),
		Pseq([78, 81, 79, 78, 74, 76, 79, 78, 81, 78, 74, 79, 76], 3),
		Pseq([78, 81, 78, 74, 79, 76], 2),
	], inf),
	\midinote, Ptuple([Pkey(\a, inf), Pkey(\a, inf) + 12], inf),
	\dur, Pseq([
		Pseq([0.27, 0.135, 0.135, Pn(0.27, 10)], 7),
		Pseq([0.27], 12),
	], inf),
	\stretch, Pseg(Pwhite(1.0, 1.7), Pwhite(6, 12), \lin, inf),
	\legato, Pwhite(0.6, 1.0, inf),
	\amp, Pwhite(0.4, 0.6, inf),
);

//// GUI
w = Window("Bells from the Deep", Rect(1060, 412, 440, 112))
.front
.alwaysOnTop_(true);

// My bells
StaticText(w, Rect(10, 10, 80, 24))
.string_("my bells")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(100, 10, 40, 24))
.states_([["OFF"], ["ON", Color.white, Color.green]])
.font_(Font("IBM Plex Mono", 16))
.action_({ |obj|
	if( obj.value == 0,
		{ ~detuneBellPlayer.stop },
		{ ~detuneBellPlayer = ~detuneBellP.play }
	);
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
		{ ~bellTimer.stop },
		{
			~bellTimer.reset;
			~bellTimer.play(AppClock);
		}
	);
});

~bellTimerText = TextField(w, Rect(150, 44, 75, 24))
.enabled_(false)
.string_("0:00")
.font_(Font("IBM Plex Mono", 16))
.align_(\center);

// Detune
StaticText(w, Rect(225, 44, 80, 24))
.string_("detune")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

~bellDetuneText = TextField(w, Rect(315, 44, 75, 24))
.enabled_(false)
.string_(~maxDetune.round(0.01).asString)
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
		{ ~bellsMIDIplayer.stop },
		{ ~bellsMIDIplayer = ~bellsMIDI.play }
	);
});

// FROM THE DEEP
StaticText(w, Rect(30, 78, 180, 24))
.string_("from the Deep ...")
.font_(Font("IBM Plex Mono", 16, false, true))
.align_(\center);

Button(w, Rect(220, 78, 100, 24))
.states_([["Messiaen", Color.black, Color(0.7, 0.5, 1)]])
.font_(Font("IBM Plex Mono", 16))
.action_({ ~messiaenBellP.play });


Button(w, Rect(340, 78, 60, 24))
.states_([["Joy", Color.green(0.8), Color.red(0.9)]])
.font_(Font("IBM Plex Mono", 16, true))
.action_({ ~joyBellP.play });
)


// For randomized env length, could free synth early
(4/10).pow(1/10); // (min/max).pow(1/(steps-1))
Array.geom(11, 10, 0.886);
