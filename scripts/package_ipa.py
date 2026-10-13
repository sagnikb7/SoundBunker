"""Package an unsigned iphoneos .app for re-signing with a sideloading tool.

Usage: python3 scripts/package_ipa.py /path/to/OfflineMusicPlayer.app dist/Cassette-unsigned-1.1.4.ipa
This does not create a provisioning profile or an installable development signature.
"""
import argparse
import plistlib
import re
import zipfile
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('app', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
app = args.app.resolve()
if not app.is_dir() or app.suffix != '.app':
    parser.error('Input must be an existing .app directory')
with (app / 'Info.plist').open('rb') as source:
    info = plistlib.load(source)
if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
    parser.error('Use an iphoneos device build, not a simulator or Mac Catalyst build')
if not (app / info['CFBundleExecutable']).is_file():
    parser.error('The app executable is missing')
if list(app.rglob('*.xctest')):
    parser.error('Test bundles must not be included in the IPA')
if any(file.name.lower().startswith('testtone') for file in app.rglob('*')):
    parser.error('Test audio must not be shipped in the app')
version = info.get('CFBundleShortVersionString', '')
if not re.fullmatch(r'\d+\.\d+\.\d+', version):
    parser.error('Built app must have a three-part release version')
if args.output.name != f'Cassette-unsigned-{version}.ipa':
    parser.error('IPA filename must include the built app version: Cassette-unsigned-' + version + '.ipa')
args.output.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(args.output, 'w', compression=zipfile.ZIP_DEFLATED) as ipa:
    for file in sorted(app.rglob('*')):
        if file.is_symlink():
            parser.error(f'Unexpected symlink: {file}')
        if file.is_file():
            ipa.write(file, Path('Payload') / app.name / file.relative_to(app))
with zipfile.ZipFile(args.output) as ipa:
    if ipa.testzip() is not None:
        raise RuntimeError('IPA archive integrity check failed')
print(args.output.resolve())
print(f"Bundle: {info['CFBundleIdentifier']}; minimum iOS: {info['MinimumOSVersion']}")
print('Unsigned package: must be signed/provisioned by Sideloadly before installation.')
