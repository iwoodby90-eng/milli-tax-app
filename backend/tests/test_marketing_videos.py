"""Tests for marketing video endpoints and public (gofile) mirrors."""
import os
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "https://wingman-mem-390f651f-e7a4-4197-9ea8-79b7db44303a-d5a1266a.preview.emergentagent.com").rstrip("/")

EXPECTED_IDS = [
    "01_cinematic_luxury",
    "02_driver_pov_hud",
    "03_lifestyle_gigworker",
    "04_product_kinetic_type",
    "05_hero_montage",
]

EXPECTED_PUBLIC = {
    "01_cinematic_luxury": "https://gofile.io/d/dmw9cd",
    "02_driver_pov_hud": "https://gofile.io/d/UpE6dC",
    "03_lifestyle_gigworker": "https://gofile.io/d/jZZxif",
    "04_product_kinetic_type": "https://gofile.io/d/KRCB7W",
    "05_hero_montage": "https://gofile.io/d/x7ni2g",
}


@pytest.fixture(scope="module")
def listing():
    r = requests.get(f"{BASE_URL}/api/marketing/videos", timeout=30)
    assert r.status_code == 200, r.text
    return r.json()


def test_list_shape(listing):
    assert "clips" in listing
    assert len(listing["clips"]) == 5


def test_list_order_and_fields(listing):
    ids = [c["id"] for c in listing["clips"]]
    assert ids == EXPECTED_IDS
    for c in listing["clips"]:
        assert c["ready"] is True
        assert c["status"] == "done"
        assert c["url"] and c["url"].startswith("/api/marketing/videos/")
        assert c["public_url"], f"missing public_url for {c['id']}"
        assert c["public_url"].startswith("https://gofile.io/d/")
        assert c["title"]
        assert c["size"]
        assert c["duration"]
        assert c["orientation"] in ("vertical", "landscape")


def test_public_url_values(listing):
    got = {c["id"]: c["public_url"] for c in listing["clips"]}
    for cid, url in EXPECTED_PUBLIC.items():
        assert got.get(cid) == url


@pytest.mark.parametrize("cid", EXPECTED_IDS)
def test_pod_mp4_range(cid):
    url = f"{BASE_URL}/api/marketing/videos/{cid}.mp4"
    r = requests.get(url, headers={"Range": "bytes=0-1023"}, timeout=30)
    assert r.status_code in (200, 206), f"{cid}: {r.status_code}"
    assert r.headers.get("Content-Type", "").startswith("video/mp4"), r.headers
    assert len(r.content) > 0


@pytest.mark.parametrize("cid,url", list(EXPECTED_PUBLIC.items()))
def test_gofile_public_url(cid, url):
    r = requests.get(url, allow_redirects=True, timeout=30)
    assert r.status_code == 200, f"{cid} -> {url}: {r.status_code}"
