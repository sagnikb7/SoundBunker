"""Copy a verified local Catalyst .app and create a metadata-preserving ZIP."""
import argparse
import plistlib
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from mac_artifacts import validate_mac_app, validate_mac_zip


def package(app, output):
    app, output = Path(app), Path(output)
    info = validate_mac_app(app)
    version = info['CFBundleShortVersionString']
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or output.name != f'Cassette-{version}-mac.app':
        raise ValueError('Mac app filename must include the built app version: Cassette-' + version + '-mac.app')
    if app.resolve() == output.resolve() or output.is_symlink():
        raise ValueError('Mac output must be a separate generated bundle, not a symlink')
    output.parent.mkdir(parents=True, exist_ok=True)
    archive = output.with_suffix('.app.zip')
    if archive.is_symlink(): raise ValueError('Mac ZIP output must not be a symlink')
    with tempfile.TemporaryDirectory(prefix='.mac-package-', dir=output.parent) as temp:
        temporary = Path(temp)
        staged = temporary / output.name
        # ditto preserves executable bits, symbolic links and bundle metadata/signatures.
        subprocess.run(['ditto', str(app), str(staged)], check=True)
        validate_mac_app(staged)
        staged_zip = temporary / archive.name
        subprocess.run(['ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(staged), str(staged_zip)], check=True)
        validate_mac_zip(staged, staged_zip)
        previous = temporary / 'previous.app'
        previous_zip = temporary / 'previous.app.zip'
        if output.exists(): output.rename(previous)
        if archive.exists(): archive.rename(previous_zip)
        try:
            staged.rename(output)
            staged_zip.rename(archive)
        except Exception:
            if output.exists(): shutil.rmtree(output)
            if archive.exists(): archive.unlink()
            if previous.exists(): previous.rename(output)
            if previous_zip.exists(): previous_zip.rename(archive)
            raise
    return output, archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    result = package(args.app, args.output)
    for path in result: print(path.resolve())
    print('Local ad-hoc signed Mac Catalyst app; public distribution requires appropriate signing/notarization.')
