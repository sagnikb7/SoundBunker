"""Read-only repository/release checks, with optional built app and IPA validation."""
import argparse
import json
import plistlib
import re
import subprocess
import sys
import zipfile
from pathlib import Path

from release import bumped, source_hash


def verify(root, app=None, ipa=None):
    manifest = json.loads((root / 'release/version.json').read_text())
    pending = manifest.get('pending')
    expected = bumped(manifest['version'], pending['bump']) if pending else manifest['version']
    if pending:
        assert any(pending.get(k) for k in ('added', 'changed', 'fixed')), 'Pending release needs notes'
    else:
        assert source_hash(root) == manifest['source_hash'], 'Shipping changes need release notes'
    info = plistlib.loads((root / 'OfflineMusicPlayer/Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] in ('com.local.offlinemusicplayer', '$(PRODUCT_BUNDLE_IDENTIFIER)'), 'Update identity changed'
    project = (root / 'OfflineMusicPlayer.xcodeproj/project.pbxproj').read_text()
    assert project.count('PRODUCT_BUNDLE_IDENTIFIER = com.local.offlinemusicplayer;') == 2, 'App target identity changed'
    assert info['CFBundleShortVersionString'] == expected, 'Prepare the release before committing'
    expected_build = manifest['build'] + 1 if pending else manifest['build']
    assert info['CFBundleVersion'] == str(expected_build), 'Build number mismatch'
    notes = json.loads((root / 'OfflineMusicPlayer/Resources/ReleaseNotes.json').read_text())
    assert notes['version'] == expected, 'Bundled release notes mismatch'
    changelog = (root / 'docs/product/changelog.md').read_text()
    assert f"## {manifest['version']} —" in changelog, 'Finalized release missing from changelog'
    for doc in [root / 'README.md', root / 'AGENTS.md', *(root / 'docs').rglob('*.md')]:
        for link in re.findall(r'\]\(([^)]+)\)', doc.read_text()):
            if '://' in link or link.startswith('#'):
                continue
            target = link.split('#')[0]
            assert (doc.parent / target).exists(), f'Broken link: {doc.relative_to(root)} → {link}'
    if app:
        built = plistlib.loads((app / 'Info.plist').read_bytes())
        assert built['CFBundleIdentifier'] == 'com.local.offlinemusicplayer', 'Built identity changed'
        for key in ['CFBundleVersion', 'CFBundleShortVersionString']:
            assert built[key] == info[key], f'Built app mismatch: {key}'
        assert built['CFBundleSupportedPlatforms'] == ['iPhoneOS']
        assert built['MinimumOSVersion'] == '15.0'
        executable = app / built['CFBundleExecutable']
        assert subprocess.check_output(['xcrun', 'lipo', '-archs', str(executable)], text=True).strip() == 'arm64'
        commands = subprocess.check_output(['xcrun', 'vtool', '-show-build', str(executable)], text=True)
        assert re.search(r'platform\s+IOS\b', commands) and re.search(r'minos\s+15\.0\b', commands)
        assert json.loads((app / 'ReleaseNotes.json').read_text()) == notes
        assert not list(app.rglob('*.xctest'))
        assert not any(p.name.lower().startswith('testtone') for p in app.rglob('*'))
        assert list(app.glob('AppIcon*.png')), 'Compiled app icon missing'
    if ipa:
        with zipfile.ZipFile(ipa) as archive:
            assert archive.testzip() is None
            assert archive.read('Payload/OfflineMusicPlayer.app/Info.plist') == (app / 'Info.plist').read_bytes()
        with zipfile.ZipFile(ipa.with_suffix(ipa.suffix + '.zip')) as archive:
            assert archive.testzip() is None
            assert archive.namelist() == [ipa.name]
            assert archive.read(ipa.name) == ipa.read_bytes()
    print(f'Repository/release QA passed: {expected} ({expected_build})')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--app', type=Path)
    parser.add_argument('--ipa', type=Path)
    args = parser.parse_args()
    if args.ipa and not args.app:
        parser.error('--ipa requires --app')
    try:
        verify(args.root, args.app, args.ipa)
    except (AssertionError, ValueError, OSError, KeyError) as error:
        print(f'QA failed: {error}', file=sys.stderr)
        sys.exit(1)
