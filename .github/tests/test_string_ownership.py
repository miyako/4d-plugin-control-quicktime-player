"""Compile actual first-party source and the full bundled SDK, never replacement APIs."""

import os
from pathlib import Path
import platform
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(os.environ.get("OWNERSHIP_SOURCE_ROOT", ROOT))


@unittest.skipUnless(platform.system() == "Darwin", "Requires macOS frameworks and clang")
class StringOwnershipTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="quicktime-ownership-")
        cls.addClassCleanup(cls.temp.cleanup)
        cls.binary = Path(cls.temp.name) / "ownership"
        command = [
            "clang++", "-std=c++11", "-g", "-O1", "-fno-omit-frame-pointer",
            "-fsanitize=address,undefined", "-fno-sanitize-recover=all",
            "-Wno-deprecated-declarations", "-Wno-multichar",
            "-I", str(SOURCE), "-I", str(SOURCE / "4D Plugin API"),
            "-I", str(SOURCE / "support"), "-x", "objective-c++",
            "-I", str(SOURCE / "4D Plugin API/Classes"),
            str(ROOT / ".github/tests/string_ownership.mm"),
            str(SOURCE / "support/4DPlugin-JSON.cpp"),
            str(SOURCE / "4D Plugin API/4DPluginAPI.c"),
            str(SOURCE / "4D Plugin API/Classes/ARRAY_TEXT.cpp"),
            str(SOURCE / "4D Plugin API/Classes/C_TEXT.cpp"),
            "-framework", "Cocoa", "-framework", "ScriptingBridge",
            "-framework", "Security", "-framework", "CoreGraphics",
            "-o", str(cls.binary),
        ]
        result = subprocess.run(command, capture_output=True, text=True, timeout=120)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)

    def run_scenario(self, scenario):
        for empty in ("allocated", "null"):
            with self.subTest(empty=empty):
                result = subprocess.run(
                    [str(self.binary), scenario, empty], capture_output=True,
                    text=True, timeout=30,
                    env={**os.environ, "ASAN_OPTIONS": "detect_leaks=0",
                         "UBSAN_OPTIONS": "halt_on_error=1"},
                )
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_string_setters(self):
        self.run_scenario("setters")

    def test_property_results(self):
        self.run_scenario("getters")

    def test_document_names(self):
        self.run_scenario("documents")

    def test_sdk_array_contract(self):
        self.run_scenario("arrays")


if __name__ == "__main__":
    unittest.main()
