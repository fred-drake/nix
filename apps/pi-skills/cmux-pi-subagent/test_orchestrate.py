import importlib.util
import json
import pathlib
import unittest

MODULE_PATH = pathlib.Path(__file__).with_name("orchestrate.py")
spec = importlib.util.spec_from_file_location("orchestrate", MODULE_PATH)
orchestrate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(orchestrate)


class OrchestrateTests(unittest.TestCase):
    def test_write_run_config_records_runner_inputs(self):
        with self.subTest("config json"):
            import tempfile
            with tempfile.TemporaryDirectory() as td:
                tmp_path = pathlib.Path(td)
                config_path = orchestrate.write_run_config(
                    workdir=str(tmp_path),
                    task_file=str(tmp_path / "task.txt"),
                    result_file=str(tmp_path / "result.txt"),
                    done_file=str(tmp_path / "done"),
                    heartbeat_file=str(tmp_path / "heartbeat"),
                    error_file=str(tmp_path / "error.txt"),
                    cwd="/repo",
                    timeout=123.0,
                    model="test-model",
                )

                data = json.loads(pathlib.Path(config_path).read_text())

                self.assertEqual(data["runner"], str(MODULE_PATH.with_name("runner.py")))
                self.assertEqual(data["task_file"], str(tmp_path / "task.txt"))
                self.assertEqual(data["result_file"], str(tmp_path / "result.txt"))
                self.assertEqual(data["done_file"], str(tmp_path / "done"))
                self.assertEqual(data["heartbeat_file"], str(tmp_path / "heartbeat"))
                self.assertEqual(data["error_file"], str(tmp_path / "error.txt"))
                self.assertEqual(data["cwd"], "/repo")
                self.assertEqual(data["timeout"], 123.0)
                self.assertEqual(data["model"], "test-model")
                self.assertIn("env", data)
                self.assertIn("PATH", data["env"])

    def test_build_launch_command_uses_static_launcher_and_quotes_config_path(self):
        config_path = "/tmp/dir with spaces/config.json"
        command = orchestrate.build_launch_command(config_path)

        self.assertIn(str(MODULE_PATH.with_name("launch.sh")), command)
        self.assertIn("dir with spaces", command)
        self.assertTrue(command.startswith("bash "))
        self.assertIn("'", command)

    def test_launch_runner_uses_respawn_pane_not_send_key(self):
        calls = []

        def fake_cmux(*args, check=True):
            calls.append(args)
            return "OK"

        orchestrate.launch_runner("workspace:2", "surface:9", "/tmp/config.json", fake_cmux)

        self.assertEqual(
            calls,
            [
                (
                    "respawn-pane",
                    "--workspace",
                    "workspace:2",
                    "--surface",
                    "surface:9",
                    "--command",
                    "bash /Users/fdrake/nix/apps/pi-skills/cmux-pi-subagent/launch.sh /tmp/config.json",
                )
            ],
        )


if __name__ == "__main__":
    unittest.main()
