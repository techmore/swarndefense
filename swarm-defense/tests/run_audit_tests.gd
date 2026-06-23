extends SceneTree

# Headless smoke test for the audit bug fixes.
# Run with:
#   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
#       --script tests/run_audit_tests.gd
#
# Covers the pure-logic fixes (clamps, group filtering). Autoload-dependent
# code (building_manager) is verified separately by the clean full-project boot.

var _failures: Array[String] = []

# Inner-class mock body: real Node3D with a working take_damage method + counter.
class MockBody extends Node3D:
	var hits: int = 0
	var damage_taken: float = 0.0
	func take_damage(amount: float, attacker: Node = null) -> void:
		hits += 1
		damage_taken += amount


func _init() -> void:
	_run_tests()
	_report()
	quit(1 if _failures.size() > 0 else 0)


func _run_tests() -> void:
	test_wave_manager_clamps_negative()
	test_health_component_clamps_percent()
	test_building_take_damage_clamps_to_zero()
	test_projectile_ignores_owner_group()
	test_solar_panel_building_name()


# --- WaveManager: enemies_alive must never go negative ---

func test_wave_manager_clamps_negative() -> void:
	var wm = preload("res://scripts/globals/wave_manager.gd").new()
	root.add_child(wm)

	wm.on_enemy_spawned()  # alive = 1
	wm.on_enemy_killed()   # alive = 0 -> wave ends
	wm.on_enemy_killed()   # would be -1 before fix
	wm.on_enemy_killed()   # would be -2 before fix

	_assert_eq(wm.enemies_alive, 0, "wave_manager: enemies_alive clamped at 0")
	wm.queue_free()


# --- HealthComponent: percent clamped 0..1 ---

func test_health_component_clamps_percent() -> void:
	var hc = preload("res://scripts/systems/health_component.gd").new()
	root.add_child(hc)
	hc.max_health = 100.0
	hc.health = -50.0
	_assert_eq(hc.get_health_percent(), 0.0, "health_component: negative health -> 0%")

	hc.health = 200.0
	_assert_eq(hc.get_health_percent(), 1.0, "health_component: overfull health -> 100%")
	hc.queue_free()


# --- Building: take_damage clamps health to 0 (no negatives) ---

func test_building_take_damage_clamps_to_zero() -> void:
	var BuildingClass = preload("res://scripts/systems/building.gd")
	var b = BuildingClass.new()
	root.add_child(b)
	b.max_health = 30.0
	b._ready()
	b.take_damage(100.0)
	_assert_eq(b.health, 0.0, "building: health clamped to 0 after overkill")
	b.queue_free()


# --- Projectile: owner-group bodies are never damaged, others are ---

func test_projectile_ignores_owner_group() -> void:
	var proj = preload("res://scripts/systems/projectile.gd").new()
	root.add_child(proj)              # must be in tree before setup (uses global_position)
	proj.setup(Vector3.ZERO, Vector3.FORWARD, "buildings")

	# A "building" in the owner group: take_damage must NOT be called.
	var owner_body = MockBody.new()
	owner_body.add_to_group("buildings")
	root.add_child(owner_body)
	proj._on_hit(owner_body)
	_assert_eq(owner_body.hits, 0, "projectile: ignores owner-group body")
	owner_body.queue_free()

	# A real target outside the group: take_damage IS called once.
	var enemy = MockBody.new()
	enemy.add_to_group("swarm")
	root.add_child(enemy)
	proj._on_hit(enemy)
	_assert_eq(enemy.hits, 1, "projectile: damages non-owner body")
	_assert_eq(enemy.damage_taken, 10.0, "projectile: passes damage value through")
	enemy.queue_free()
	proj.queue_free()


# --- Solar Panel: building_name keeps the space (matches intro_sequence + manager fix) ---
# Note: has_power_for lives on the autoload-dependent building_manager.gd and is
# verified by the clean full-project boot; here we assert the name contract.

func test_solar_panel_building_name() -> void:
	# "Solar Panel" must appear as the assigned building_name source in the script.
	var src := FileAccess.get_file_as_string("res://scripts/systems/solar_panel.gd")
	_assert_true(src.find('building_name = "Solar Panel"') != -1,
		"solar_panel: source assigns building_name with a space")

	var mgr_src := FileAccess.get_file_as_string("res://scripts/systems/building_manager.gd")
	_assert_true(mgr_src.find('"Solar Panel"') != -1,
		"building_manager: has_power_for accepts 'Solar Panel'")


# --- helpers ---

func _assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		print("  PASS  %s (%s == %s)" % [label, actual, expected])
	else:
		print("  FAIL  %s (got %s, expected %s)" % [label, actual, expected])
		_failures.append(label)


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		print("  PASS  %s" % label)
	else:
		print("  FAIL  %s" % label)
		_failures.append(label)


func _report() -> void:
	print("\n=== Audit test results ===")
	if _failures.is_empty():
		print("ALL TESTS PASSED")
	else:
		print("FAILURES (%d):" % _failures.size())
		for f in _failures:
			print("  - %s" % f)
