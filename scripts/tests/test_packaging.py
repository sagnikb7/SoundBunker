import plistlib
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / 'package_ipa.py'


class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / 'OfflineMusicPlayer.app'
        self.app.mkdir()
        (self.app / 'Info.plist').write_bytes(plistlib.dumps({
            'CFBundleSupportedPlatforms': ['iPhoneOS'], 'CFBundleExecutable': 'Player',
            'CFBundleShortVersionString': '1.2.3', 'CFBundleIdentifier': 'com.local.offlinemusicplayer',
            'MinimumOSVersion': '15.0'}))
        (self.app / 'Player').write_bytes(b'Packaging fixture; not a device executable')

    def test_versioned_zip_contains_identical_versioned_ipa(self):
        ipa = self.root / 'Cassette-unsigned-1.2.3.ipa'
        result = subprocess.run([sys.executable, str(SCRIPT), str(self.app), str(ipa)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        with zipfile.ZipFile(ipa) as archive:
            self.assertIsNone(archive.testzip())
        with zipfile.ZipFile(ipa.with_suffix('.ipa.zip')) as archive:
            self.assertEqual(archive.namelist(), [ipa.name])
            self.assertEqual(archive.read(ipa.name), ipa.read_bytes())

    def test_wrong_filename_version_is_rejected_before_output(self):
        ipa = self.root / 'Cassette-unsigned-9.9.9.ipa'
        result = subprocess.run([sys.executable, str(SCRIPT), str(self.app), str(ipa)], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('filename must include the built app version', result.stderr)
        self.assertFalse(ipa.exists())


if __name__ == '__main__': unittest.main()
