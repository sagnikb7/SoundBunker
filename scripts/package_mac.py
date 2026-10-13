"""Copy a verified local Catalyst .app."""
import argparse
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from mac_artifacts import validate_mac_app


def package(app, output):
    app, output = Path(app), Path(output)
    info = validate_mac_app(app)
    version = info['CFBundleShortVersionString']
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or output.name != 'Cassette.app':
        raise ValueError('Mac app filename must be Cassette.app')
    if app.resolve() == output.resolve() or output.is_symlink():
        raise ValueError('Mac output must be a separate generated bundle, not a symlink')
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.mac-package-', dir=output.parent) as temp:
        temporary = Path(temp)
        staged = temporary / output.name
        # ditto preserves executable bits, symbolic links and bundle metadata/signatures.
        subprocess.run(['ditto', str(app), str(staged)], check=True)
        validate_mac_app(staged)
        previous = temporary / 'previous.app'
        if output.exists(): output.rename(previous)
        try:
            staged.rename(output)
        except Exception:
            if output.exists(): shutil.rmtree(output)
            if previous.exists(): previous.rename(output)
            raise
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    result = package(args.app, args.output)
    print(result.resolve())
    print('Local ad-hoc signed Mac Catalyst app; public distribution requires appropriate signing/notarization.')
