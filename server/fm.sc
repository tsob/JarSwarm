// a simple FM synth

(
SynthDef(\simpFM,
{ | outbus=0, freq=200, modfreq=290, modamp=0.5, amp=0.3, dur=0.5, pan=0 |
  var sig, mod, env, atk, dec, sus, rel;
  atk = dur*0.01;
  dec = dur*0.5;
  sus = dur*0.02;
  rel = dur*0.47;
  mod = SinOsc.ar(modfreq, 0, 0.5);
  sig = SinOsc.ar(freq + (freq * mod), 0, 1.0);
  env = Env([0, 1, 0.6, 0.4, 0]*amp, [atk, dec, sus, rel], curve: \squared);
  Out.ar(outbus,Pan2.ar(sig * EnvGen.kr(env, doneAction: 2),pan));
}).add;
)

// 4 channel

(
SynthDef(\simpFM4,
{ | outbus=0, freq=200, modfreq=290, modamp=0.5, amp=0.3, dur=0.5, pan1=0, pan2=0 |
  var sig, mod, env, atk, dec, sus, rel;
  atk = dur*0.01;
  dec = dur*0.5;
  sus = dur*0.02;
  rel = dur*0.47;
  mod = SinOsc.ar(modfreq, 0, 0.5);
  sig = SinOsc.ar(freq + (freq * mod), 0, 1.0);
  env = Env([0, 1, 0.6, 0.4, 0]*amp, [atk, dec, sus, rel], curve: \squared);
  Out.ar(outbus,Pan4.ar(sig * EnvGen.kr(env, doneAction: 2), pan1, pan2));
}).add;
)



(
Pbind(
  \instrument, \simpFM4,
  \freq, Pxrand([69,42,65,78].midicps, 15),
  \modfreq, Pxrand([69,42,65,78].midicps, 15),
  \dur,  Prand([0.075,0.1,0.1,0.1,0.2,0.2,0.2,0.166667,0.333333,0.5,1], inf),
  \pan1,  Prand([-1,1], inf),
  \pan2,  Prand([-1,1], inf),
  \amp,  Prand([0.5, 0.7,1.0], inf)
).play;
)


// PANAZ

(
SynthDef(\simpFMAZ,
{ | outbus=0, freq=200, modfreq=290, modamp=0.5, amp=0.3, dur=0.5, pos=0 |
  var sig, mod, env, atk, dec, sus, rel;
  atk = dur*0.01;
  dec = dur*0.5;
  sus = dur*0.02;
  rel = dur*0.47;
  mod = SinOsc.ar(modfreq, 0, 0.5);
  sig = SinOsc.ar(freq + (freq * mod), 0, 1.0);
  env = Env([0, 1, 0.6, 0.4, 0]*amp, [atk, dec, sus, rel], curve: \squared);
  Out.ar(outbus,PanAz.ar(4,sig * EnvGen.kr(env, doneAction: 2), pos));
}).add;
)

(
Pbind(
  \instrument, \simpFMAZ,
  \freq, Pxrand([69,42,65,78].midicps, 15),
  \modfreq, Pxrand([69,42,65,78].midicps, 15),
  \dur,  Prand([0.075,0.1,0.1,0.1,0.2,0.2,0.2,0.166667,0.333333,0.5,1], inf),
  \pos,  Prand([0,0.5,1,1.5], inf),
  \amp,  Prand([0.5, 0.7,1.0], inf)
).play;
)
