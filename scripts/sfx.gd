extends Node

# 程序生成音效（无外部素材）：点击 / 交换 / 消除 / 连锁 / 过关 / 失败
# 注册为 autoload（project.godot [autoload] SFX）

const RATE := 22050

var player: AudioStreamPlayer
var sounds: Dictionary = {}


func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	sounds["click"] = _tone(880.0, 660.0, 0.045, 0.30)
	sounds["swap"] = _tone(320.0, 210.0, 0.08, 0.32)
	sounds["pop"] = _tone(560.0, 150.0, 0.16, 0.45)
	sounds["combo"] = _tone(700.0, 1050.0, 0.12, 0.32)
	sounds["power"] = _tone(660.0, 1320.0, 0.22, 0.5)
	sounds["mega"] = _arpeggio([523.25, 783.99, 1046.5, 1567.98, 2093.0], 0.07, 0.5)
	sounds["win"] = _arpeggio([523.25, 659.25, 783.99, 1046.5], 0.13, 0.38)
	sounds["lose"] = _arpeggio([392.0, 311.13, 246.94, 196.0], 0.16, 0.38)


func play(name: String) -> void:
	if sounds.has(name):
		player.stream = sounds[name]
		player.play()


func _tone(f0: float, f1: float, dur: float, vol: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var f := lerpf(f0, f1, t / dur)
		var env := pow(1.0 - t / dur, 1.5)
		var s := sin(TAU * f * t) * vol * env
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


func _arpeggio(freqs: Array, step: float, vol: float) -> AudioStreamWAV:
	var total := int(step * freqs.size() * RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		var t := float(i) / RATE
		var idx := clampi(int(t / step), 0, freqs.size() - 1)
		var f: float = freqs[idx]
		var tt := t - float(idx) * step
		var env := pow(maxf(0.0, 1.0 - tt / step), 1.5)
		var s := sin(TAU * f * tt) * vol * env
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
