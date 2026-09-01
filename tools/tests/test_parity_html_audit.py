import tempfile
import unittest
from pathlib import Path
from tools.parity_html_audit import audit


class TestAudit(unittest.TestCase):
    def test_valid_encoded_and_current_fragments(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'sub').mkdir()
            (root / 'sub/asset.svg').write_text('<svg/>')
            (root / 'sub/page.html').write_text('<h1 id="x y">Page</h1>')
            (root / 'index.html').write_text('<a href="sub/page#x%20y">Page</a><img src="sub/asset.svg"><h1 id="home">Home</h1><a href="#home">Self</a><a href="?q=1#home">Query</a><a href="/">Root</a><a href="https://outside.invalid/">External</a><img src="data:image/png;base64,AA==">')
            self.assertEqual(audit(root)[-1], [])
            self.assertEqual(audit(root)[3], 3)

    def test_missing_page_fragment_and_asset(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'page.html').write_text('<h1 id="present">Page</h1>')
            (root / 'index.html').write_text('<a href="nope">Page</a><a href="page#absent">Fragment</a><img src="absent.svg">')
            failures = audit(root)[-1]
            self.assertEqual(len(failures), 3)
            self.assertTrue(any('missing fragment' in f for f in failures))

    def test_directories_queries_and_excluded_packages(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'dir').mkdir()
            (root / 'dir/index.html').write_text('<h1 id="ok">Page</h1>')
            (root / 'empty').mkdir()
            (root / 'node_modules').mkdir()
            (root / 'node_modules/bad.html').write_text('<a href="absent">Bad</a>')
            (root / 'index.html').write_text('<a href="dir#ok">OK</a><a href="empty">Empty</a><a href="#absent">Missing</a><a href="?q=1#absent">Missing query</a>')
            result = audit(root)
            self.assertEqual(len(result[0]), 2)
            self.assertEqual(len(result[-1]), 3)

    def test_symlink_candidates_cannot_escape(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryDirectory() as outside:
            root = Path(directory)
            target = Path(outside) / 'outside.html'
            target.write_text('<h1 id="present">Outside</h1>')
            (root / 'out.html').symlink_to(target)
            (root / 'dir').mkdir()
            (root / 'dir/index.html').symlink_to(target)
            for route in ('out.html', 'out', 'out#present', 'dir', 'dir#present'):
                with self.subTest(route=route):
                    (root / 'index.html').write_text(f'<a href="{route}">Outside</a>')
                    failures = audit(root)[-1]
                    self.assertEqual(len(failures), 1)
                    self.assertIn('outside target', failures[0])

    def test_empty_or_absent_build_is_not_success(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertTrue(audit(directory)[-1])
            self.assertTrue(audit(Path(directory) / 'missing')[-1])

    def test_assets_do_not_resolve_to_html_fallbacks(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'photo.html').write_text('Not an image')
            (root / 'index.html').write_text('<img src="photo">')
            self.assertEqual(len(audit(root)[-1]), 1)

    def test_stylesheet_icon_and_preload_require_exact_assets(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'absent.css.html').write_text('Not CSS')
            for rel in ('stylesheet', 'icon', 'preload'):
                with self.subTest(rel=rel):
                    (root / 'index.html').write_text(f'<link rel="{rel}" href="absent.css">')
                    self.assertEqual(len(audit(root)[-1]), 1)

    def test_srcset_fails_with_explicit_scope_diagnostic(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'present.svg').write_text('<svg/>')
            (root / 'index.html').write_text('<img src="present.svg" srcset="absent-2x.svg 2x">')
            failures = audit(root)[-1]
            self.assertEqual(len(failures), 1)
            self.assertIn('unsupported srcset', failures[0])


if __name__ == '__main__':
    unittest.main()
