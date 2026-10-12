"""Derive the browser project URL from origin, without embedding credentials."""
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import urlparse


def browser_url(remote):
    if remote.startswith('git@github.com:'):
        path = remote.split(':', 1)[1]
    else:
        parsed = urlparse(remote)
        if parsed.hostname != 'github.com' or parsed.scheme not in ('https', 'ssh'):
            raise ValueError('Expected a GitHub origin remote')
        path = parsed.path.lstrip('/')
    path = path.removesuffix('.git')
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', path):
        raise ValueError('Invalid GitHub repository path')
    return 'https://github.com/' + path


def update(root):
    path = root / 'OfflineMusicPlayer/Resources/Project.json'
    result = subprocess.run(['git', 'config', '--get', 'remote.origin.url'], cwd=root, capture_output=True, text=True)
    if result.returncode:
        if path.exists(): return
        raise ValueError('Set origin before creating project metadata')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({'githubURL': browser_url(result.stdout.strip())}, indent=2) + '\n')


if __name__ == '__main__': update(Path(__file__).resolve().parents[1])
