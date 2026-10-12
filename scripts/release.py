"""Stage version/release notes before a build; commit them only after packaging succeeds."""
import argparse
import hashlib
import json
import plistlib
import re
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo


def source_hash(root):
    digest = hashlib.sha256()
    for path in sorted((root / 'OfflineMusicPlayer').rglob('*')):
        if not path.is_file() or path.name in ('ReleaseNotes.json', '.DS_Store') or path.name.startswith('._'):
            continue
        data = path.read_bytes()
        if path.name == 'Info.plist':
            info = plistlib.loads(data)
            info.pop('CFBundleVersion', None)
            info.pop('CFBundleShortVersionString', None)
            data = plistlib.dumps(info, sort_keys=True)
        digest.update(str(path.relative_to(root)).encode() + b'\0' + data)
    return digest.hexdigest()


def bumped(version, bump):
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        raise ValueError('Use a three-part version, such as 1.1.0')
    major, minor, patch = map(int, version.split('.'))
    if bump == 'major': return f'{major + 1}.0.0'
    if bump == 'minor': return f'{major}.{minor + 1}.0'
    if bump == 'patch': return f'{major}.{minor}.{patch + 1}'
    raise ValueError('Pending changes need a major, minor or patch bump')


def prepare(root):
    manifest = json.loads((root / 'release/version.json').read_text())
    pending = manifest.get('pending')
    if pending and not any(pending.get(key) for key in ('added', 'changed', 'fixed')):
        raise ValueError('Pending release needs feature/fix notes')
    fingerprint = source_hash(root)
    if not pending and manifest.get('source_hash') != fingerprint:
        raise ValueError('Shipping files changed. Record notes and a bump in release/version.json before building.')
    version = bumped(manifest['version'], pending['bump']) if pending else manifest['version']
    build = manifest['build'] + 1
    info_path = root / 'OfflineMusicPlayer/Info.plist'
    info = plistlib.loads(info_path.read_bytes())
    info['CFBundleShortVersionString'] = version
    info['CFBundleVersion'] = str(build)
    info_path.write_bytes(plistlib.dumps(info, sort_keys=False))
    notes = {'version': version, 'sections': []}
    if pending:
        notes['sections'] = [{'title': key.capitalize(), 'items': pending.get(key, [])} for key in ('added', 'changed', 'fixed') if pending.get(key)]
    else:
        existing = root / 'OfflineMusicPlayer/Resources/ReleaseNotes.json'
        if existing.exists(): notes = json.loads(existing.read_text())
    resource = root / 'OfflineMusicPlayer/Resources/ReleaseNotes.json'
    resource.parent.mkdir(parents=True, exist_ok=True)
    resource.write_text(json.dumps(notes, indent=2) + '\n')
    state = {'base_version': manifest['version'], 'base_build': manifest['build'], 'version': version,
             'build': build, 'source_hash': fingerprint, 'pending': pending}
    staging = root / 'dist/.release-state.json'
    staging.parent.mkdir(parents=True, exist_ok=True)
    staging.write_text(json.dumps(state, indent=2) + '\n')
    return state


def finalize(root, app):
    manifest_path = root / 'release/version.json'
    manifest = json.loads(manifest_path.read_text())
    state_path = root / 'dist/.release-state.json'
    state = json.loads(state_path.read_text())
    if (manifest['version'], manifest['build'], manifest.get('pending')) != (state['base_version'], state['base_build'], state['pending']):
        raise ValueError('Release manifest changed during the build; prepare/build again.')
    if source_hash(root) != state['source_hash']:
        raise ValueError('Shipping source changed during the build; rebuild before committing a release.')
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    if (info['CFBundleShortVersionString'], info['CFBundleVersion']) != (state['version'], str(state['build'])):
        raise ValueError('Built app version does not match the prepared release')
    changelog = root / 'docs/product/changelog.md'
    if state['pending']:
        date = datetime.now(ZoneInfo('Asia/Kolkata')).strftime('%d %B %Y')
        entry = f"## {state['version']} — {date}\n\nBuild: {state['build']}.\n\n"
        for key in ('added', 'changed', 'fixed'):
            items = state['pending'].get(key, [])
            if items: entry += f'### {key.capitalize()}\n\n' + ''.join(f'- {item}\n' for item in items) + '\n'
        text = changelog.read_text()
        if f"## {state['version']} —" in text: raise ValueError('Release version already exists in changelog')
        marker = re.search(r'^## (?!Unreleased)', text, flags=re.MULTILINE)
        if marker: text = text[:marker.start()] + entry + text[marker.start():]
        else: text += '\n' + entry
        changelog.write_text(text)
    manifest.update(version=state['version'], build=state['build'], source_hash=state['source_hash'], pending=None)
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    state_path.unlink()
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['prepare', 'finalize'])
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--app', type=Path)
    args = parser.parse_args()
    if args.action == 'finalize' and args.app is None: parser.error('--app is required to finalize')
    state = prepare(args.root) if args.action == 'prepare' else finalize(args.root, args.app)
    print(f"{args.action.capitalize()}: SoundBunker {state['version']} ({state['build']})")


if __name__ == '__main__': main()
