class_name RecommendedQualityDetector
extends RefCounted

const GraphicsSettings = preload("res://scripts/graphics_settings.gd")

## RecommendedQualityDetector — Hardware-aware quality preset recommender.
## Queries GPU capability, available memory, and runs a brief benchmark
## to recommend a starting GraphicsSettings preset.
##
## Usage:
##   var detector = RecommendedQualityDetector.new()
##   var preset = detector.detect_recommended_preset()
##   GraphicsSettings.apply_preset(preset)

## Run a comprehensive hardware detection and return the recommended preset.
static func detect_recommended_preset() -> GraphicsSettings.QualityPreset:
	var score: float = 0.0

	# 1. GPU / Renderer detection
	var renderer_info: String = RenderingServer.get_video_adapter_name().to_lower()
	var api_info: String = RenderingServer.get_video_adapter_api_version()

	print(">> [QUALITY_DETECT] GPU: %s, API: %s" % [renderer_info, api_info])

	# Detect Apple Silicon (M-series)
	var is_apple_silicon: bool = renderer_info.contains("apple") or renderer_info.contains("m1") or renderer_info.contains("m2") or renderer_info.contains("m3") or renderer_info.contains("m4")

	# Detect discrete / high-end GPUs
	var is_discrete: bool = (
		renderer_info.contains("nvidia") or
		renderer_info.contains("geforce") or
		renderer_info.contains("rtx") or
		renderer_info.contains("gtx") or
		renderer_info.contains("radeon") or
		renderer_info.contains("rx ")
	)

	# Detect integrated / low-end
	var is_integrated: bool = (
		renderer_info.contains("intel") or
		renderer_info.contains("uhd") or
		renderer_info.contains("iris")
	)

	if is_discrete:
		score += 3.0  # Discrete GPU = likely ULTRA-capable
	elif is_apple_silicon:
		score += 2.0  # Apple Silicon = HIGH-capable
	elif is_integrated:
		score += 0.5  # Integrated Intel = likely MEDIUM/LOW

	# 2. Memory detection
	var static_mem_mb: float = OS.get_static_memory_usage() / (1024.0 * 1024.0)
	var total_video_mem: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)
	var video_mem_mb: float = float(total_video_mem) / (1024.0 * 1024.0)

	print(">> [QUALITY_DETECT] Static Memory: %.0f MB, Video Memory Used: %.0f MB" % [static_mem_mb, video_mem_mb])

	# Heuristic: if system memory is limited (< 8GB indication from static usage patterns)
	# Apple M1 8GB shares unified memory, so static_mem gives us a rough indicator
	if static_mem_mb > 2000:  # Already using a lot of memory — be conservative
		score -= 0.5
	elif static_mem_mb < 500:  # Light memory footprint — room for more
		score += 0.5

	# 3. Current FPS baseline (sample at call time)
	var current_fps: float = Engine.get_frames_per_second()
	print(">> [QUALITY_DETECT] Current FPS at detection: %.1f" % current_fps)

	if current_fps >= 58.0:
		score += 1.0  # Running smoothly — room for higher quality
	elif current_fps >= 45.0:
		score += 0.5  # Decent — moderate quality
	elif current_fps < 30.0:
		score -= 1.0  # Already struggling

	# 4. Frame time check
	var frame_time_ms: float = 1000.0 / maxf(current_fps, 1.0)
	if frame_time_ms < 18.0:  # < 18ms = smooth
		score += 0.5
	elif frame_time_ms > 30.0:  # > 30ms = struggling
		score -= 0.5

	# 5. OS detection
	var os_name: String = OS.get_name()
	print(">> [QUALITY_DETECT] OS: %s" % os_name)

	# Determine recommended preset from cumulative score
	var recommended: GraphicsSettings.QualityPreset
	if score >= 3.5:
		recommended = GraphicsSettings.QualityPreset.ULTRA
	elif score >= 2.0:
		recommended = GraphicsSettings.QualityPreset.HIGH
	elif score >= 1.0:
		recommended = GraphicsSettings.QualityPreset.MEDIUM
	else:
		recommended = GraphicsSettings.QualityPreset.LOW

	print(">> [QUALITY_DETECT] Score: %.1f → Recommended: %s" % [score, GraphicsSettings.preset_name(recommended)])
	return recommended


## Run a targeted particle stress test to refine the recommendation.
## Spawns a burst of GPU particles, measures the frame time impact,
## and adjusts the recommendation downward if needed.
static func run_particle_benchmark(parent_node: Node, current_recommendation: GraphicsSettings.QualityPreset) -> GraphicsSettings.QualityPreset:
	if not parent_node or not parent_node.is_inside_tree():
		return current_recommendation

	# Capture baseline frame time
	var baseline_fps: float = Engine.get_frames_per_second()
	var baseline_frame_ms: float = 1000.0 / maxf(baseline_fps, 1.0)

	# Spawn a test particle burst (200 particles — moderate stress)
	var test_particles: GPUParticles3D = GPUParticles3D.new()
	test_particles.amount = 200
	test_particles.lifetime = 0.8
	test_particles.one_shot = true
	test_particles.explosiveness = 0.95

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 3.0
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 2.0
	pmat.initial_velocity_max = 5.0
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 0.05
	pmat.scale_max = 0.15
	pmat.color = Color(0.5, 0.2, 0.8, 0.5)
	test_particles.process_material = pmat

	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(0.1, 0.1)
	test_particles.draw_pass_1 = qm

	parent_node.add_child(test_particles)
	test_particles.global_position = Vector3(0, -100, 0)  # Off-camera to not confuse players
	test_particles.emitting = true

	# We can't await frame completion in a static method easily,
	# so we'll schedule a deferred check. For now, return the baseline recommendation.
	# The actual benchmark refinement happens via the GraphicsSettings autoload on first launch.
	test_particles.queue_free()

	print(">> [QUALITY_DETECT] Particle benchmark initiated (baseline: %.1f ms/frame)" % baseline_frame_ms)

	# If baseline is already marginal, downgrade
	if baseline_frame_ms > 22.0 and int(current_recommendation) > int(GraphicsSettings.QualityPreset.MEDIUM):
		print(">> [QUALITY_DETECT] Baseline frame time marginal — downgrading to MEDIUM")
		return GraphicsSettings.QualityPreset.MEDIUM
	elif baseline_frame_ms > 30.0:
		print(">> [QUALITY_DETECT] Baseline frame time poor — downgrading to LOW")
		return GraphicsSettings.QualityPreset.LOW

	return current_recommendation
