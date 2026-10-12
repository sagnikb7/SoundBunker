import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_project_metadata import browser_url

class ProjectMetadataTests(unittest.TestCase):
    def test_ssh_and_https_remotes_become_browser_links(self):
        expected = 'https://github.com/sagnikb7/SoundBunker'
        for remote in ['git@github.com:sagnikb7/SoundBunker.git', 'https://github.com/sagnikb7/SoundBunker.git', 'ssh://git@github.com/sagnikb7/SoundBunker.git']:
            self.assertEqual(browser_url(remote), expected)
    def test_credentials_are_not_embedded_and_non_github_is_rejected(self):
        self.assertEqual(browser_url('https://user:secret@github.com/sagnikb7/SoundBunker.git'), 'https://github.com/sagnikb7/SoundBunker')
        with self.assertRaises(ValueError): browser_url('https://example.invalid/project.git')
