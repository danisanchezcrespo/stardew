from __future__ import annotations

import unittest

from compare_runners import first_difference


class CompareRunnersTests(unittest.TestCase):
    def test_numeric_values_use_absolute_tolerance(self) -> None:
        self.assertIsNone(first_difference({"value": 1.0}, {"value": 1.0 + 5e-10}))
        self.assertIn(
            "$.value",
            first_difference({"value": 1.0}, {"value": 1.0 + 2e-9}) or "",
        )

    def test_first_difference_reports_nested_path(self) -> None:
        difference = first_difference(
            {"nodes": [{"inventory": {"wood": 2.0}}]},
            {"nodes": [{"inventory": {"wood": 3.0}}]},
        )
        self.assertEqual(difference, "$.nodes[0].inventory.wood: expected 2.0, got 3.0")

    def test_key_mismatch_is_reported(self) -> None:
        difference = first_difference({"food": 0.0}, {})
        self.assertEqual(difference, "$: key mismatch; missing=['food'], extra=[]")


if __name__ == "__main__":
    unittest.main()
