"""Recovery checks must reject damaged bytes/modes even with python -O."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('stash_probe', Path(__file__).parents[1] / 'parity_stash_probe.py')
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)


class RestoreOracleTests(unittest.TestCase):
    def test_saved_hello_and_corruption(self):
        # Known Git object ID for the five bytes b'hello', independent of probe.
        record = {'mode': '100644', 'blob': 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'}
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / 'saved'
            p.write_bytes(b'hello'); p.chmod(0o644)
            probe.verify_file(p, record)
            p.write_bytes(b'hellO')
            with self.assertRaisesRegex(ValueError, 'blob mismatch'):
                probe.verify_file(p, record)
            p.write_bytes(b'hello'); p.chmod(0o755)
            with self.assertRaisesRegex(ValueError, 'mode mismatch'):
                probe.verify_file(p, record)
            p.chmod(0o644)
            link = Path(tmp) / 'link'; link.symlink_to(p)
            with self.assertRaisesRegex(ValueError, 'not a regular file'):
                probe.verify_file(link, record)


if __name__ == '__main__':
    unittest.main()
