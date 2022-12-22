(
//// Setup and SynthDefs
~possBuf = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "posset.wav");
// 3rd pc was 100518
~pcBuf = Buffer.loadCollection(s,[2690, 26298, 40000, 167627, 243014, 345165, 363611, 409032, 502356, 682550, 900385, 1027320]);
~octBuf = Buffer.loadCollection(s, [1, 1, 0.5, 0.4, 0.3, 0.2, 0.1]);
~prevPc = nil;
~prevOct = nil;
~noteNames = Dictionary.newFrom([
	0, 'C', 1, 'C#', 2, 'D', 3, 'D#', 4, 'E', 5, 'F',
	6, 'F#', 7, 'G', 8, 'G#', 9, 'A', 10, 'A#', 11, 'B',
]);

~gtrSampOSC = OSCdef(\tracker, { |msg|
	var amp=msg[3], freq=msg[4], hasFreq=msg[5];

	if (hasFreq == 1, {
		var pitchClass, octave;
		pitchClass = freq.cpsmidi.round(1) % 12;
		octave = (freq.cpsmidi.round(1) - pitchClass) / 12 - 1;

		if ((pitchClass != ~prevPc) || (octave != ~prevOct), {
			~gtrSamp1.set(\gate, 0);
			~gtrSamp2.set(\gate, 0);
			~prevPc = pitchClass;
			~prevOct = octave;
			{
				0.013.wait;
				~gtrSamp1.set(\pc, pitchClass, \oct, octave, \t_trig, 1);
				~gtrSamp2.set(\pc, pitchClass, \oct, octave, \t_trig, 1);
				0.001.wait;
				~gtrSamp1.set(\gate, 1);
				~gtrSamp2.set(\gate, 1);
			}.fork();
		});
	});

	if (amp < 0.005, {
		~gtrSamp1.set(\gate, 0);
		~gtrSamp2.set(\gate, 0);
		~prevPc = nil;
		~prevOct = nil;
	});
}, '/gtrTrack').disable;

~tunerOSC = OSCdef(\tuner, { |msg|
	var freq=msg[3], hasFreq=msg[4];
	if ( hasFreq == 1, {
		var note, dif;
		note = ~noteNames[freq.cpsmidi.round(1) % 12];
		dif = (freq.cpsmidi - freq.cpsmidi.round(1)).trunc(0.01);
		[
			note,
			if( dif >= 0, {'+'}, {'-'} ),
			dif.trunc(0.01).abs
		].postln;
	});
}, '/gtrTune').disable;

SynthDef(\gtrRM, {
	arg hz=450, detune=0.2, in=0, out=0, amp=1.5, mix=0.0;
	var dry, wet, sig;

	dry = SoundIn.ar(in);
	dry = Compander.ar(dry, dry,
		thresh: 0.13,
		slopeAbove: 1/3,
		clampTime: 0.005,
		relaxTime: 0.05
	);
	wet = dry * SinOsc.ar({
		hz.lag(0.5) *
		LFNoise1.kr(Rand(0.6, 0.8)).range((-1*detune).midiratio, detune.midiratio)
	}!2);

	sig = XFade2.ar(dry, wet, mix*2-1);
	Out.ar(out, sig * amp);
}).add;

SynthDef(\gtrReporter, {
	arg in=0, thresh=0.04;
	var sig, freq, amp, gate;

	sig = SoundIn.ar(in);
	amp = Amplitude.kr(sig, releaseTime: 3);
	freq = Pitch.kr(sig, ampThreshold: thresh, median: 4); // consider median

	SendReply.kr(Impulse.kr(100), '/gtrTrack', [amp, freq[0], freq[1]]);
}).add;

SynthDef(\gtrSampler, {
	arg pc=0, pcBuf, oct=2, octBuf, buf, pan=0,
	t_trig=0, gate=0, out=0, amp=0.7;
	var sig, env, ptr, start, length, window;

	start = Index.kr(pcBuf, pc) + TRand.kr(0, 8820, t_trig);
	length = BufSampleRate.kr(buf) * Index.kr(octBuf, oct) + TRand.kr(-1764, 1764, t_trig);
	ptr = Phasor.ar(t_trig, 1 / length);
	window = IEnvGen.kr(Env.linen(0.1, 0.8, 0.1), ptr);

	sig = BufRd.ar(2, buf, ptr * length + start);
	env = EnvGen.kr(Env.asr(0.012, 1, 0.012), gate);
	sig = sig * env * amp * window;

	sig = Balance2.ar(sig[0], sig[1], pan);
	Out.ar(out, sig);
}).add;

SynthDef(\gtrTuner, {
	arg in=0;
	var sig, freq;
	sig = SoundIn.ar(in);

	freq = Pitch.kr(sig, ampThreshold: 0.04, median: 8);
	SendReply.kr(Impulse.kr(24), '/gtrTune', freq);
}).add;

//// GUI
w = Window("Guitar things", Rect(1060, 140, 240, 216))
.front
.alwaysOnTop_(true);

// Guitar RM
StaticText(w, Rect(10, 10, 90, 24))
.string_("guitar RM")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(120, 10, 40, 24))
.states_([["OFF"], ["ON", Color.white, Color.green]])
.font_(Font("IBM Plex Mono", 16))
.action_({ |obj|
	if( obj.value == 0,
		{ ~gtrRM.free },
		{
			~gtrRM = Synth(\gtrRM, [
				\mix, ~mixSlider.value.linlin(0, 1, 0, 1),
				\amp, ~ampSlider.value.linlin(0, 1, 0, 2),
				\detune, ~detuneSlider.value.linlin(0, 1, 0, 2),
				\hz, ~hzNumBox.value
			]).register;
		}
	);
});

// Mix
StaticText(w, Rect(10, 44, 60, 24))
.string_("mix")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

~mixSlider = Slider(w, Rect(80, 44, 80, 24))
.value_(0)
.action_({ |obj|
	var mix = obj.value.linlin(0, 1, 0, 1);
	if( ~gtrRM.isPlaying,
		{ ~gtrRM.set(\mix, mix) }
	);
	~mixNumBox.value_(mix);
});

~mixNumBox = NumberBox(w, Rect(170, 44, 50, 24))
.value_(~mixSlider.value.linlin(0, 1, 0, 1))
.font_(Font("IBM Plex Mono", 16))
.decimals_(2)
.align_(\center)
.enabled_(false);

// Amp
StaticText(w, Rect(10, 78, 60, 24))
.string_("amp")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

~ampSlider = Slider(w, Rect(80, 78, 80, 24))
.value_(1.5.linlin(0, 2, 0, 1))
.action_({ |obj|
	var amp = obj.value.linlin(0, 1, 0, 2);
	if( ~gtrRM.isPlaying,
		{ ~gtrRM.set(\amp, amp) }
	);
	~ampNumBox.value_(amp);
});

~ampNumBox = NumberBox(w, Rect(170, 78, 50, 24))
.value_(~ampSlider.value.linlin(0, 1, 0, 2))
.font_(Font("IBM Plex Mono", 16))
.decimals_(2)
.align_(\center)
.enabled_(false);

// Detune
StaticText(w, Rect(10, 112, 60, 24))
.string_("detune")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

~detuneSlider = Slider(w, Rect(80, 112, 80, 24))
.value_(0.2.linlin(0, 2, 0, 1))
.action_({ |obj|
	var detune = obj.value.linlin(0, 1, 0, 2);
	if( ~gtrRM.isPlaying,
		{ ~gtrRM.set(\detune, detune) }
	);
	~detuneNumBox.value_(detune);
});

~detuneNumBox = NumberBox(w, Rect(170, 112, 50, 24))
.value_(~detuneSlider.value.linlin(0, 1, 0, 2))
.font_(Font("IBM Plex Mono", 16))
.decimals_(2)
.align_(\center)
.enabled_(false);

StaticText(w, Rect(10, 146, 60, 24))
.string_("hz")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

~hzNumBox = NumberBox(w, Rect(80, 146, 80, 24))
.value_(450)
.font_(Font("IBM Plex Mono", 16))
.decimals_(2)
.align_(\center)
.action_({ |obj|
	if( ~gtrRM.isPlaying,
		{ ~gtrRM.set(\hz, obj.value) }
	);
});

// Sampler
StaticText(w, Rect(10, 180, 90, 24))
.string_("posset")
.font_(Font("IBM Plex Mono", 16))
.align_(\right);

Button(w, Rect(120, 180, 40, 24))
.states_([["OFF"], ["ON", Color.white, Color.green]])
.font_(Font("IBM Plex Mono", 16))
.action_({ |obj|
	if( obj.value == 0,
		{
			~gtrSamp1.free;
			~gtrSamp2.free;
			~gtrRep.free;
			~gtrSampOSC.disable;
		},
		{
			~gtrSamp1 = Synth(\gtrSampler, [
				\buf, ~possBuf, \pcBuf, ~pcBuf, \octBuf, ~octBuf, \pan, -0.5
			]);
			~gtrSamp2 = Synth(\gtrSampler, [
				\buf, ~possBuf, \pcBuf, ~pcBuf, \octBuf, ~octBuf, \pan, 0.5
			]);
			~gtrRep = Synth(\gtrReporter);
			~gtrSampOSC.enable;
		}
	);
});

// Tuner
Button(w, Rect(170, 158, 60, 32))
.states_([["tune?"], ["tune!", Color.white, Color.green]])
.font_(Font("IBM Plex Mono", 16, false, true))
.action_({ |obj|
	if( obj.value == 0,
		{
			~tuner.free;
			~tunerOSC.disable;
		},
		{
			~tuner = Synth(\gtrTuner);
			~tunerOSC.enable;
		}
	);
});
)
