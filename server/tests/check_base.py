"""Our HTTP regression checks for the supplied template; not the missing course conformance kit."""

import json, urllib.request, urllib.error, uuid, os

BASE = os.environ.get("TEST_BASE_URL", "http://127.0.0.1:8080")


def call(
    method, path, body=None, token=None, raw=None, content_type="application/json"
):
    headers = {"Content-Type": content_type}
    if token:
        headers["Authorization"] = "Bearer " + token
    data = (
        raw
        if raw is not None
        else (json.dumps(body).encode() if body is not None else None)
    )
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        res = urllib.request.urlopen(req, timeout=10)
    except urllib.error.HTTPError as e:
        res = e
    payload = res.read()
    return res.status, (
        json.loads(payload)
        if payload and "application/json" in res.headers.get("Content-Type", "")
        else payload
    )


def run():
    checks = 0

    def check(condition, label):
        nonlocal checks
        assert condition, label
        checks += 1
        print("PASS", label)

    check(call("GET", "/health") == (200, {"status": "ok"}), "health")
    check(call("GET", "/notes")[0] == 401, "notes require token")
    email = "base-" + uuid.uuid4().hex + "@example.org"
    status, auth = call(
        "POST",
        "/auth/register",
        {"email": email, "password": "sample123", "name": "Base check"},
    )
    check(status == 201 and isinstance(auth["token"], str), "registration")
    token = auth["token"]
    check(
        call(
            "POST",
            "/auth/register",
            {"email": email, "password": "sample123", "name": "Base check"},
        )[0]
        == 409,
        "duplicate account",
    )
    check(
        call("POST", "/auth/login", {"email": email, "password": "wrong"})[0] == 401,
        "wrong password",
    )
    check(
        call("POST", "/auth/login", {"email": email, "password": "sample123"})[0]
        == 200,
        "login",
    )
    check(call("GET", "/me", token=token)[1]["email"] == email, "current user")
    status, note = call(
        "POST", "/notes", {"title": "Покупки", "content": "Молоко"}, token
    )
    check(status == 201 and isinstance(note["id"], int), "create note")
    path = "/notes/" + str(note["id"])
    check(call("GET", path, token=token)[1]["title"] == "Покупки", "get note")
    status, result = call(
        "GET",
        "/notes?search=" + urllib.parse.quote("Покуп") + "&page=1&limit=1",
        token=token,
    )
    check(
        status == 200 and result["total"] == 1 and len(result["items"]) == 1,
        "search and pagination",
    )
    check(
        call("PUT", path, {"title": "Другой заголовок", "content": ""}, token)[0]
        == 200,
        "update note",
    )
    _, other = call(
        "POST",
        "/auth/register",
        {
            "email": "other-" + uuid.uuid4().hex + "@example.org",
            "password": "sample123",
            "name": "Other",
        },
    )
    check(call("GET", path, token=other["token"])[0] == 404, "foreign note hidden")
    check(call("POST", "/notes", {"title": ""}, token)[0] == 400, "validation")
    check(call("DELETE", path, token=token) == (204, b""), "delete empty 204")
    check(call("GET", path, token=token)[0] == 404, "deleted note")
    boundary = "LostFoundCheckBoundary"
    data = (
        "--"
        + boundary
        + '\r\nContent-Disposition: form-data; name="file"; filename="check.txt"\r\nContent-Type: text/plain\r\n\r\nhello\r\n--'
        + boundary
        + "--\r\n"
    ).encode()
    status, file = call(
        "POST",
        "/files",
        token=token,
        raw=data,
        content_type="multipart/form-data; boundary=" + boundary,
    )
    check(status == 201 and file["size"] == 5, "file upload")
    check(call("GET", file["url"])[1] == b"hello", "file download")
    check(
        call(
            "POST",
            "/files",
            token=token,
            raw=b"broken",
            content_type="multipart/form-data; boundary=x",
        )[0]
        == 400,
        "malformed multipart",
    )
    print(f"PASS: {checks} own base API checks. Official conformance kit not supplied.")


if __name__ == "__main__":
    run()
