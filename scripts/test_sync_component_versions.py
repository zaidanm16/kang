import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class SyncComponentVersionsTest(unittest.TestCase):
    def sync(self, frontend, backend):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scripts = Path(__file__).resolve().parent
            for name in ("sync-component-versions.sh", "update-versions.sh"):
                (root / "scripts").mkdir(exist_ok=True)
                shutil.copy(scripts / name, root / "scripts" / name)
            files = {
                "charts/kang/Chart.yaml": 'version: 3.1.3\nappVersion: "3.1.2"\n',
                "charts/kang/values.yaml": (
                    "backend:\n  image:\n    repository: ghcr.io/zaidanm16/kang-backend\n    tag: v1.1.0\n"
                    "frontend:\n  image:\n    repository: ghcr.io/zaidanm16/kang-frontend\n    tag: v3.1.2\n"
                ),
                "charts/kang/README.md": '| frontend.image.tag | string | `"v3.1.2"` | Frontend image tag. |\n',
                "kubernetes/kang.yaml": "image: ghcr.io/zaidanm16/kang-frontend:v3.0.0\n",
                "kubernetes/README.md": "`ghcr.io/zaidanm16/kang-frontend:v3.0.0`\n",
                "README.md": "release-v3.1.3\ngit tag v3.1.3\ngit push origin v3.1.3\n",
                "compose/.env.example": "",
                "compose/compose.yaml": "",
                "docs/src/content/docs/installation/docker.md": "",
                "docs/src/content/docs/id/installation/docker.md": "",
            }
            for name, contents in files.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(contents)
            binary = root / "bin"
            binary.mkdir()
            curl = binary / "curl"
            curl.write_text(
                "#!/usr/bin/env python3\nimport json, sys\n"
                f"versions = {json.dumps({'kang-frontend': frontend, 'kang-backend': backend})}\n"
                "url = sys.argv[-1]\n"
                "print(json.dumps({'token': 'test'} if '/token?' in url else "
                "{'tags': ['v' + versions[url.split('/')[-3]]] }))\n"
            )
            curl.chmod(0o755)
            result = subprocess.run(
                ["bash", "scripts/sync-component-versions.sh"], cwd=root,
                env={**os.environ, "PATH": str(binary) + os.pathsep + os.environ["PATH"]},
                capture_output=True, text=True, check=True,
            )
            self.assertIn(f"git tag v{result.stdout.strip()}\n", (root / "README.md").read_text())
            for path in ("kubernetes/kang.yaml", "kubernetes/README.md"):
                self.assertIn(f"kang-frontend:v{frontend}", (root / path).read_text())
            self.assertIn(f'`"v{frontend}"`', (root / "charts/kang/README.md").read_text())
            return result.stdout.strip(), (root / "charts/kang/Chart.yaml").read_text(), (root / "charts/kang/values.yaml").read_text()

    def test_frontend_release_does_not_reuse_existing_chart_version(self):
        version, chart, values = self.sync("3.1.3", "1.1.1")
        self.assertEqual(version, "3.1.4")
        self.assertIn('appVersion: "3.1.3"', chart)
        self.assertIn("tag: v1.1.1", values)
        self.assertIn("tag: v3.1.3", values)

    def test_newer_frontend_release_sets_chart_version(self):
        version, chart, _ = self.sync("3.2.0", "1.1.0")
        self.assertEqual(version, "3.2.0")
        self.assertIn('appVersion: "3.2.0"', chart)

    def test_backend_only_release_increments_chart_patch(self):
        version, chart, _ = self.sync("3.1.2", "1.1.1")
        self.assertEqual(version, "3.1.4")
        self.assertIn('appVersion: "3.1.2"', chart)


if __name__ == "__main__":
    unittest.main()
