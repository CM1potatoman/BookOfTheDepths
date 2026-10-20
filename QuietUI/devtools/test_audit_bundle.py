"""Local tests for the bundle auditor. Uses synthetic text; executes no Luau."""

from hashlib import sha1
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from audit_bundle import check_bundle


class BundleAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self._temp = TemporaryDirectory()
        self.addCleanup(self._temp.cleanup)
        self.root = Path(self._temp.name)
        self.parts = self.root / "QuietUI" / "parts"
        self.parts.mkdir(parents=True)
        self.source = (
            b'__bundle_register("__root", function() end)\n'
            b'__bundle_register("GUI/Linoria", function() end)\n'
            b'return __bundle_require("__root")\n'
        )
        self.manifest = {
            "parts": {"CM1_Quiet_01.txt": len(self.source)},
            "total_bytes": len(self.source),
            "registered_modules": 2,
        }
        (self.parts / "CM1_Quiet_01.txt").write_bytes(self.source)

    def test_clean_source(self):
        result = check_bundle(self.root, self.manifest)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["module_count"], 2)
        self.assertEqual(result["issues"], [])

    def test_missing_file(self):
        (self.parts / "CM1_Quiet_01.txt").unlink()
        result = check_bundle(self.root, self.manifest)
        self.assertEqual(result["status"], "fail")
        self.assertIn("missing_part", [i["code"] for i in result["issues"]])

    def test_size_mismatch(self):
        self.manifest["parts"]["CM1_Quiet_01.txt"] += 4
        result = check_bundle(self.root, self.manifest)
        self.assertEqual(result["status"], "fail")
        self.assertIn("part_size_mismatch", [i["code"] for i in result["issues"]])

    def test_duplicate_module(self):
        source = self.source.replace(b'"GUI/Linoria"', b'"__root"')
        (self.parts / "CM1_Quiet_01.txt").write_bytes(source)
        result = check_bundle(self.root, self.manifest)
        self.assertEqual(result["status"], "fail")
        self.assertIn("duplicate_module", [i["code"] for i in result["issues"]])

    def test_legacy_warning(self):
        source = self.source.replace(b'function() end)', b'function() require("GUI/Library") end)', 1)
        self.manifest["parts"]["CM1_Quiet_01.txt"] = len(source)
        self.manifest["total_bytes"] = len(source)
        (self.parts / "CM1_Quiet_01.txt").write_bytes(source)
        result = check_bundle(self.root, self.manifest)
        self.assertEqual(result["status"], "pass")
        issues = [i for i in result["issues"] if i["code"] == "legacy_ui_imports"]
        self.assertEqual(issues[0]["modules"], ["__root"])

    def test_hash_mismatch_on_equal_length_change(self):
        original_hash = sha1(b"blob " + str(len(self.source)).encode() + b"\x00" + self.source).hexdigest()
        self.manifest["git_blob_sha1"] = {"CM1_Quiet_01.txt": original_hash}
        modified = self.source.replace(b"Linoria", b"LinoriX")
        self.assertEqual(len(modified), len(self.source))
        (self.parts / "CM1_Quiet_01.txt").write_bytes(modified)
        result = check_bundle(self.root, self.manifest)
        self.assertEqual(result["status"], "fail")
        self.assertIn("part_hash_mismatch", [i["code"] for i in result["issues"]])

    def test_entry_point_required(self):
        source = self.source.replace(b'return __bundle_require("__root")', b'return nil')
        self.manifest["parts"]["CM1_Quiet_01.txt"] = len(source)
        self.manifest["total_bytes"] = len(source)
        (self.parts / "CM1_Quiet_01.txt").write_bytes(source)
        result = check_bundle(self.root, self.manifest)
        self.assertIn("missing_entry_point", [i["code"] for i in result["issues"]])


if __name__ == "__main__":
    unittest.main()
