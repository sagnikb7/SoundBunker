import os
import plistlib
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import package_mac
from mac_artifacts import validate_mac_app


@unittest.skipUnless(sys.platform == 'darwin', 'Mac packaging uses macOS ditto')
class MacPackagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / 'Original.app'
        resources = self.app / 'Contents/Resources'
        resources.mkdir(parents=True)
        (self.app / 'Contents/MacOS').mkdir()
        self.info = {'CFBundleShortVersionString': '1.3.0', 'CFBundleVersion': '9', 'CFBundleIdentifier': 'com.local.offlinemusicplayer',
                     'CFBundleDisplayName': 'Cassette', 'CFBundleExecutable': 'Player', 'CFBundleSupportedPlatforms': ['MacOSX'], 'LSMinimumSystemVersion': '12.0'}
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps(self.info))
        (self.app / 'Contents/MacOS/Player').write_bytes(b'Packaging fixture, not a native executable')
        (self.app / 'Contents/MacOS/Player').chmod(0o755)
        (resources / 'Assets.car').write_bytes(b'Fixture asset')
        (resources / 'AppIcon.png').write_bytes(b'Fixture icon')
        (resources / 'Alias').symlink_to('Assets.car')

    def test_mac_bundle_preserve_payload_permissions_and_symlinks(self):
        output = self.root / 'Cassette.app'
        # Executable/signature checks are covered by real build receipts; exercise the actual native copier here.
        with patch.object(package_mac, 'validate_mac_app', return_value=self.info):
            app = package_mac.package(self.app, output)
        self.assertEqual(app, output)
        self.assertFalse(output.with_suffix('.app.zip').exists())
        self.assertTrue(os.access(app / 'Contents/MacOS/Player', os.X_OK))
        self.assertTrue((app / 'Contents/Resources/Alias').is_symlink())
        self.assertEqual((app / 'Contents/Info.plist').read_bytes(), (self.app / 'Contents/Info.plist').read_bytes())

    def test_wrong_name_is_rejected_before_output(self):
        output = self.root / 'Cassette-9.9.9-mac.app'
        with patch.object(package_mac, 'validate_mac_app', return_value=self.info):
            with self.assertRaisesRegex(ValueError, 'filename must be'):
                package_mac.package(self.app, output)
        self.assertFalse(output.exists())

    def test_failed_copy_keeps_previous_app(self):
        output = self.root / 'Cassette.app'
        output.mkdir(); (output / 'previous').write_bytes(b'Keep previous app')
        original_run = subprocess.run
        def run(command, **kwargs):
            if command[0] == 'ditto': raise subprocess.CalledProcessError(1, command)
            return original_run(command, **kwargs)
        with patch.object(package_mac, 'validate_mac_app', return_value=self.info), patch.object(package_mac.subprocess, 'run', side_effect=run):
            with self.assertRaises(subprocess.CalledProcessError): package_mac.package(self.app, output)
        self.assertEqual((output / 'previous').read_bytes(), b'Keep previous app')

    def test_ipod_bundle_is_rejected_as_mac(self):
        self.info['CFBundleSupportedPlatforms'] = ['iPhoneOS']
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps(self.info))
        with self.assertRaisesRegex(AssertionError, 'Expected a Mac app'): validate_mac_app(self.app)
