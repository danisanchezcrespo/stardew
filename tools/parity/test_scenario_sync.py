from __future__ import annotations

import hashlib
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


class ScenarioSyncTests(unittest.TestCase):
    def test_ancient_egypt_definitions_match_legacy_reference(self) -> None:
        legacy = REPOSITORY_ROOT / "legacy_simcity" / "data" / "entities.json"
        godot = REPOSITORY_ROOT / "godot" / "scenarios" / "ancient_egypt" / "entities.json"

        legacy_digest = hashlib.sha256(legacy.read_bytes()).hexdigest()
        godot_digest = hashlib.sha256(godot.read_bytes()).hexdigest()
        self.assertEqual(godot_digest, legacy_digest)

    def test_godot_savegame_fixtures_match_legacy_reference(self) -> None:
        for filename in ("egypt.json", "eg2.json"):
            with self.subTest(filename=filename):
                legacy = REPOSITORY_ROOT / "legacy_simcity" / "data" / filename
                godot = (
                    REPOSITORY_ROOT
                    / "godot"
                    / "scenarios"
                    / "ancient_egypt"
                    / "fixtures"
                    / filename
                )
                self.assertEqual(
                    hashlib.sha256(godot.read_bytes()).hexdigest(),
                    hashlib.sha256(legacy.read_bytes()).hexdigest(),
                )


if __name__ == "__main__":
    unittest.main()
