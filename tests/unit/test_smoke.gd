extends GutTest
## Smoke test that verifies the test setup itself.


func test_runs_on_pinned_engine_version() -> void:
	var info: Dictionary = Engine.get_version_info()
	assert_eq(info["major"], 4, "Engine major version")
	assert_eq(info["minor"], 7, "Engine minor version must match the pinned 4.7 release")
