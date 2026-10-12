import json
import plistlib
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import release


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for folder in ['release', 'OfflineMusicPlayer', 'docs/product']:
            (self.root / folder).mkdir(parents=True)
        self.manifest = self.root / 'release/version.json'
        self.manifest.write_text(json.dumps({'version': '1.0.0', 'build': 1, 'source_hash': None,
            'pending': {'bump': 'minor', 'added': ['New settings']}}))
        (self.root / 'OfflineMusicPlayer/Info.plist').write_bytes(plistlib.dumps({
            'CFBundleIdentifier': 'com.local.offlinemusicplayer', 'CFBundleVersion': '1',
            'CFBundleShortVersionString': '1.0.0'}))
        (self.root / 'OfflineMusicPlayer/App.swift').write_text('// App')
        (self.root / 'docs/product/changelog.md').write_text('# Changelog\n\n## Unreleased\n\n## 1.0.0 — Baseline\n')

    def built_app(self):
        app = self.root / 'Built.app'
        app.mkdir(exist_ok=True)
        shutil.copy(self.root / 'OfflineMusicPlayer/Info.plist', app / 'Info.plist')
        return app

    def test_retry_reserves_same_version_and_success_records_notes(self):
        first = release.prepare(self.root)
        self.assertEqual((first['version'], first['build']), ('1.1.0', 2))
        self.assertEqual(release.prepare(self.root), first)
        self.assertEqual(json.loads(self.manifest.read_text())['build'], 1)
        release.finalize(self.root, self.built_app())
        log = (self.root / 'docs/product/changelog.md').read_text()
        self.assertEqual(log.count('## 1.1.0 —'), 1)
        self.assertIn('New settings', log)
        next_build = release.prepare(self.root)
        self.assertEqual((next_build['version'], next_build['build']), ('1.1.0', 3))

    def test_source_change_without_notes_rejected(self):
        release.prepare(self.root)
        release.finalize(self.root, self.built_app())
        (self.root / 'OfflineMusicPlayer/App.swift').write_text('// Changed')
        with self.assertRaisesRegex(ValueError, 'Record notes'):
            release.prepare(self.root)

    def test_change_during_build_cannot_finalize(self):
        release.prepare(self.root)
        app = self.built_app()
        (self.root / 'OfflineMusicPlayer/App.swift').write_text('// Changed')
        with self.assertRaisesRegex(ValueError, 'changed during'):
            release.finalize(self.root, app)
        self.assertEqual(json.loads(self.manifest.read_text())['build'], 1)

    def test_wrong_built_version_cannot_finalize(self):
        release.prepare(self.root)
        app = self.built_app()
        (app / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleShortVersionString': '1.0.0', 'CFBundleVersion': '1'}))
        with self.assertRaisesRegex(ValueError, 'does not match'):
            release.finalize(self.root, app)

    def test_fingerprint_ignores_finder_metadata(self):
        before = release.source_hash(self.root)
        (self.root / 'OfflineMusicPlayer/.DS_Store').write_bytes(b'Finder metadata')
        (self.root / 'OfflineMusicPlayer/._App.swift').write_bytes(b'AppleDouble metadata')
        self.assertEqual(release.source_hash(self.root), before)

    def test_semantic_bumps(self):
        self.assertEqual(release.bumped('1.2.3', 'patch'), '1.2.4')
        self.assertEqual(release.bumped('1.2.3', 'minor'), '1.3.0')
        self.assertEqual(release.bumped('1.2.3', 'major'), '2.0.0')
        with self.assertRaises(ValueError): release.bumped('1.0', 'minor')


if __name__ == '__main__': unittest.main()
