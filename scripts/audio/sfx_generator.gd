class_name SFXGenerator
extends RefCounted

## SFXGenerator — Procedural sound synthesis creating AudioStreamWAV assets in-memory.
## Zero disk footprint, pure mathematical sound design for medieval combat audio.

static func create_stream_from_buffer(samples: PackedByteArray, sample_rate: int = 44100) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = samples
	return stream

static func generate_sword_swing() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.22
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var progress: float = t / duration
		# Filtered white noise with pitch sweep for whoosh
		var env: float = sin(progress * PI)
		var noise: float = (randf() * 2.0 - 1.0) * 0.7
		var tone: float = sin(2.0 * PI * (320.0 - progress * 140.0) * t) * 0.3
		var sample: float = (noise + tone) * env * 0.8
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_weapon_impact(is_heavy: bool = false) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.35 if is_heavy else 0.2
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	var base_freq: float = 90.0 if is_heavy else 160.0

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * (14.0 if is_heavy else 22.0))
		# Transient snap + deep bass body
		var snap: float = (randf() * 2.0 - 1.0) * exp(-t * 80.0) * 0.8
		var body: float = sin(2.0 * PI * (base_freq * exp(-t * 8.0)) * t) * 0.7
		var sample: float = (snap + body) * env
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_parry_ring() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.65
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 6.0)
		# Dual high resonant metallic ring frequencies (1420Hz & 2160Hz)
		var ring1: float = sin(2.0 * PI * 1420.0 * t) * 0.5
		var ring2: float = sin(2.0 * PI * 2160.0 * t) * 0.35
		var ring3: float = sin(2.0 * PI * 3480.0 * t) * 0.15
		var strike: float = (randf() * 2.0 - 1.0) * exp(-t * 90.0) * 0.5
		var sample: float = (ring1 + ring2 + ring3 + strike) * env
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_shield_block() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.28
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 18.0)
		var wood_body: float = sin(2.0 * PI * 110.0 * t) * 0.7
		var iron_rim: float = sin(2.0 * PI * 680.0 * t) * 0.3 * exp(-t * 30.0)
		var sample: float = (wood_body + iron_rim) * env
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_dodge_whoosh() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.3
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = sin((t / duration) * PI)
		var low_air: float = (randf() * 2.0 - 1.0) * 0.5
		var low_tone: float = sin(2.0 * PI * 140.0 * t) * 0.5
		var sample: float = (low_air + low_tone) * env * 0.7
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_death_collapse() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.5
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 8.0)
		var thump: float = sin(2.0 * PI * (80.0 * exp(-t * 6.0)) * t) * 0.8
		var armor_clatter: float = (randf() * 2.0 - 1.0) * exp(-t * 15.0) * 0.4
		var sample: float = (thump + armor_clatter) * env
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_ultimate_activation() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.8
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = sin(minf(1.0, t / 0.2) * (PI * 0.5)) * exp(-t * 2.0)
		# Deep sub-bass hum (55Hz) + eerie 5th overtone (82.5Hz)
		var sub: float = sin(2.0 * PI * 55.0 * t) * 0.7
		var fifth: float = sin(2.0 * PI * 82.5 * t) * 0.3
		var dark_noise: float = (randf() * 2.0 - 1.0) * 0.15 * exp(-t * 3.0)
		var sample: float = (sub + fifth + dark_noise) * env * 0.85
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_ultimate_buildup() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 1.4
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var prog: float = t / duration
		var env: float = pow(prog, 1.8) # Exponential rise
		var freq: float = 80.0 + pow(prog, 2.5) * 520.0
		var tone1: float = sin(2.0 * PI * freq * t) * 0.5
		var tone2: float = sin(2.0 * PI * (freq * 1.5) * t) * 0.3
		var shimmer: float = sin(2.0 * PI * (freq * 3.0) * t) * 0.2 * sin(t * 40.0)
		var sample: float = (tone1 + tone2 + shimmer) * env * 0.8
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_ultimate_sword_rise() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.9
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 2.5)
		# Resonant singing steel (980Hz, 1470Hz, 2450Hz)
		var chime1: float = sin(2.0 * PI * 980.0 * t) * 0.4
		var chime2: float = sin(2.0 * PI * 1470.0 * t) * 0.35
		var chime3: float = sin(2.0 * PI * 2450.0 * t) * 0.25
		var sample: float = (chime1 + chime2 + chime3) * env * 0.75
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_ultimate_climax() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 1.6
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env_snap: float = exp(-t * 30.0)
		var env_body: float = exp(-t * 3.5)
		# Initial thunderous transient crack
		var crack: float = (randf() * 2.0 - 1.0) * env_snap * 0.9
		# Massive bass rumble (45Hz downward sweep)
		var rumble: float = sin(2.0 * PI * (55.0 * exp(-t * 2.0)) * t) * env_body * 0.8
		# Celestial ring resonance (880Hz decaying)
		var celestial: float = sin(2.0 * PI * 880.0 * t) * exp(-t * 4.0) * 0.35
		var sample: float = (crack + rumble + celestial)
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_ultimate_dissolution() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 1.1
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 3.0)
		# Particle crackle fizz
		var crackle: float = 0.0
		if randf() < 0.25:
			crackle = (randf() * 2.0 - 1.0) * 0.6
		var ethereal_whisper: float = sin(2.0 * PI * (1200.0 + sin(t * 25.0) * 300.0) * t) * 0.2
		var sample: float = (crackle + ethereal_whisper) * env * 0.7
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)

static func generate_ultimate_victory() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 2.0
	var num_samples: int = int(sample_rate * duration)
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = minf(1.0, t / 0.4) * exp(-t * 1.2)
		# D-Major triumphant triad (D3=146.83, F#3=185.00, A3=220.00, D4=293.66)
		var d3: float = sin(2.0 * PI * 146.83 * t) * 0.35
		var fsharp3: float = sin(2.0 * PI * 185.00 * t) * 0.28
		var a3: float = sin(2.0 * PI * 220.00 * t) * 0.28
		var d4: float = sin(2.0 * PI * 293.66 * t) * 0.20
		var sample: float = (d3 + fsharp3 + a3 + d4) * env * 0.8
		var sample_int: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	return create_stream_from_buffer(buffer, sample_rate)
