"""Unit tests for the legacy UI inventory and migration baseline."""
import unittest
from legacy_ui_inventory import inspect


class TestLegacyInventory(unittest.TestCase):
    def test_tracks_method_and_property_usage(self):
        source = (
            '__bundle_register("Luma", function(require)\n'
            'local Library = require("GUI/Library")\n'
            'Library:Notify("loaded")\n'
            'local color = Library.AccentColor\nend)\n'
            '__bundle_register("Utility/Another", function(require)\n'
            'return true\nend)\n'
        )
        report = inspect(source)
        self.assertEqual(report["registered_modules"], 2)
        self.assertEqual(report["legacy_dependents"], 1)
        self.assertEqual(report["modules"][0]["methods"], ["Notify"])
        self.assertEqual(report["modules"][0]["properties"], ["AccentColor"])
        self.assertEqual(report["unexpected_new_dependencies"], [])

    def test_rejects_return_of_migrated_floating_window_import(self):
        source = (
            '__bundle_register("Menu/Objects/FloatingWindow", function(require)\n'
            'local Library = require("GUI/Library")\n'
            'end)\n'
        )
        report = inspect(source)
        self.assertEqual(report["regressed_migrations"], ["Menu/Objects/FloatingWindow"])

    def test_identifies_new_legacy_consumers(self):
        source = (
            '__bundle_register("NewConsumer", function(require)\n'
            'local GUI = require("GUI/Library")\nend)\n'
        )
        report = inspect(source)
        self.assertEqual(report["unexpected_new_dependencies"], ["NewConsumer"])
        self.assertIn("Luma", report["baseline_dependencies_removed"])


if __name__ == "__main__":
    unittest.main()
