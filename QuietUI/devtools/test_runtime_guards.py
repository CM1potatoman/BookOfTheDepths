"""Static guard regression tests for the QuietUI bundle."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
PARTS = ROOT / "QuietUI" / "parts"
PIN = "1be38aa599bb1f6a7c28f47e6fc13ade52dd0acd"


class TestRuntimeGuards(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = b"".join(
            (PARTS / f"CM1_Quiet_{index:02d}.txt").read_bytes()
            for index in range(1, 5)
        ).decode("utf-8")

    @classmethod
    def module(cls, name):
        marker = f'__bundle_register("{name}", function'
        start = cls.source.find(marker)
        if start < 0:
            raise AssertionError(f"Missing module: {name}")
        end = cls.source.find('__bundle_register("', start + len(marker))
        return cls.source[start:end if end >= 0 else None]

    def test_optional_rpc_guarded(self):
        code = self.module("Luma")
        self.assertIn('type(get_bloxstrap_rpc) == "function"', code)
        self.assertIn("pcall(get_bloxstrap_rpc)", code)
        self.assertNotIn("= get_bloxstrap_rpc()", code)

    def test_profiler_stops_on_detach(self):
        self.assertIn('require("Utility/Profiler").stop()', self.module("Luma"))
        code = self.module("Utility/Profiler")
        self.assertIn("function Profiler.stop()", code)
        self.assertIn("pcall(task.cancel, activeThread)", code)
        self.assertIn("while enabled do", code)
        self.assertNotIn("while true do", code)

    def test_linoria_and_addons_pinned(self):
        library = self.module("GUI/Linoria")
        addons = self.module("GUI/LinoriaAddons")
        self.assertIn(f"LinoriaLib/{PIN}/", library)
        self.assertIn(f"LinoriaLib/{PIN}/addons/", addons)
        self.assertNotIn("LinoriaLib/main/", library + addons)


if __name__ == "__main__":
    unittest.main()
