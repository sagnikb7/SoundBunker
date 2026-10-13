"""Validation shared by local Mac packaging and repository QA."""
import plistlib
import re
import subprocess
from pathlib import Path


def validate_mac_app(app):
    app = Path(app)
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == 'com.local.offlinemusicplayer', 'Mac bundle identity changed'
    assert info['CFBundleDisplayName'] == 'Cassette', 'Wrong Mac display name'
    assert info['CFBundleSupportedPlatforms'] == ['MacOSX'], 'Expected a Mac app'
    assert info['LSMinimumSystemVersion'] == '12.0', 'Unexpected Mac minimum OS'
    executable = app / 'Contents/MacOS' / info['CFBundleExecutable']
    assert set(subprocess.check_output(['xcrun', 'lipo', '-archs', str(executable)], text=True).split()) == {'arm64', 'x86_64'}, 'Mac app must be universal'
    commands = subprocess.check_output(['xcrun', 'vtool', '-show-build', str(executable)], text=True)
    assert len(re.findall(r'platform\s+MACCATALYST\b', commands)) == 2, 'Expected two native Catalyst slices'
    assert not list(app.rglob('*.appex')), 'iOS widget must not be embedded in Mac app'
    assert not list(app.rglob('*.xctest')) and not any(p.name.lower().startswith('testtone') for p in app.rglob('*')), 'Test resources in Mac app'
    assert (app / 'Contents/Resources/Assets.car').is_file(), 'Mac assets missing'
    assert list((app / 'Contents/Resources').glob('AppIcon*')), 'Mac icon missing'
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True, capture_output=True, text=True)
    return info
