"""Publisher guardrails only: no Roblox API calls."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("publisher", Path(__file__).parents[1] / "scripts/publish.py")
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class PublisherTests(unittest.TestCase):
    def test_dry_run_has_no_network(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "sample.rbxl"
            path.write_bytes(b"<roblox!\x89\xff\r\n\x1a\n" + b"test fixture")
            with patch.object(publisher, "publish") as call:
                self.assertEqual(publisher.main(["--file", str(path), "--place-id", "123"]), 0)
                call.assert_not_called()

    def test_rejects_non_binary_artifact(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "wrong.rbxl"
            path.write_text("<roblox />")
            with self.assertRaises(ValueError):
                publisher.inspect_artifact(path, "123")

    def test_rejects_bad_place_ids(self):
        for place_id in ["0", "-1", "1/other", "https://example.com", "", "1;echo"]:
            with self.assertRaises(ValueError):
                publisher.inspect_artifact("unused", place_id)

    def test_requires_matching_target_and_reviewed_digest(self):
        env = {"ROBLOX_ALLOWED_PLACE_ID": "123", "ROBLOX_APPROVED_SHA256": "abc", "ROBLOX_OPEN_CLOUD_API_KEY": "test-only"}
        publisher.authorize("123", "abc", env)
        for key in env:
            altered = dict(env)
            altered.pop(key)
            with self.assertRaises(ValueError):
                publisher.authorize("123", "abc", altered)

    def test_operation_path_cannot_redirect_credentials(self):
        self.assertEqual(publisher.operation_path({"path": "operations/abc-123"}), "operations/abc-123")
        for value in ["https://example.com", "../assets/1", "operations/../bad", "operations/a?x=1", None]:
            with self.assertRaises(ValueError):
                publisher.operation_path({"path": value})

    def test_pending_upload_is_not_success(self):
        self.assertIsNone(publisher.published_revision({"done": False}, "123"))

    def test_error_and_unpublished_revision_are_not_success(self):
        for response in [{"error": {"code": 1}}, {"done": True, "response": {"path": "assets/123", "isPublished": False}}, {"done": True, "response": {"path": "assets/999", "isPublished": True, "revisionId": 2}}]:
            with self.assertRaises(RuntimeError):
                publisher.published_revision(response, "123")

    def test_success_requires_correct_asset_and_published_revision(self):
        self.assertEqual(publisher.published_revision({"done": True, "response": {"path": "assets/123", "isPublished": True, "revisionId": "7"}}, "123"), "7")

    def test_redirect_handler_refuses_redirect(self):
        with self.assertRaises(RuntimeError):
            publisher.NoRedirect().redirect_request(None, None, 302, "", {}, "https://example.com")


if __name__ == "__main__":
    unittest.main()
