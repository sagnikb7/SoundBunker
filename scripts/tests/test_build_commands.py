import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class BuildCommandTests(unittest.TestCase):
    def test_help_and_invalid_platform_do_not_stage_or_change_a_release(self):
        manifest = ROOT / 'release/version.json'
        info = ROOT / 'OfflineMusicPlayer/Info.plist'
        before = (manifest.read_bytes(), info.read_bytes())
        for command, expected in [(['--help'], 0), (['--platform=watch'], 2), (['--platform'], 2), (['--unknown'], 2)]:
            result = subprocess.run([str(ROOT / 'build'), *command], capture_output=True, text=True)
            self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        self.assertEqual((manifest.read_bytes(), info.read_bytes()), before)

    def test_overlapping_build_is_rejected_before_preparation(self):
        lock = ROOT / 'dist/.build-lock'
        if lock.exists(): self.skipTest('Real release build is running')
        lock.mkdir(parents=True)
        try:
            result = subprocess.run([str(ROOT / 'build'), '--platform=mac'], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Another release build is running', result.stderr)
        finally: lock.rmdir()
