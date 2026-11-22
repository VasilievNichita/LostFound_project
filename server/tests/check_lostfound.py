"""Domain regression checks against a running API. Creates only random test accounts."""

from check_base import call
from urllib.parse import urlencode
import uuid


def run():
    checks = 0

    def check(ok, label):
        nonlocal checks
        assert ok, label
        checks += 1
        print("PASS", label)

    def account(name):
        status, user = call(
            "POST",
            "/auth/register",
            {
                "email": uuid.uuid4().hex + "@example.org",
                "password": "sample123",
                "name": name,
            },
        )
        assert status == 201
        return user["token"]

    owner, claimant, stranger = (
        account("Owner"),
        account("Claimant"),
        account("Stranger"),
    )
    for route in ["/items", "/claims", "/messages", "/campus"]:
        check(call("GET", route)[0] == 401, route + " requires auth")
    draft = {
        "type": "found",
        "title": "Синий футляр",
        "description": "Возле окна",
        "location": "Библиотека",
        "imageUrl": "",
    }
    status, item = call("POST", "/items", draft, owner)
    check(status == 201 and item["userId"] > 0, "server assigns item id and author")
    path = "/items/" + str(item["id"])
    check(call("GET", path, token=claimant)[0] == 200, "campus board is shared")
    check(call("PUT", path, draft, stranger)[0] == 404, "foreign item cannot be edited")
    check(
        call("DELETE", path, token=stranger)[0] == 404, "foreign item cannot be deleted"
    )
    check(
        call("POST", "/items", {**draft, "location": "Unknown"}, owner)[0] == 400,
        "location validation",
    )
    check(
        call("POST", "/items", {**draft, "title": " "}, owner)[0] == 400,
        "empty title validation",
    )
    claim = {
        "itemId": item["id"],
        "message": "На внутренней стороне написаны мои инициалы.",
    }
    check(call("POST", "/claims", claim, owner)[0] == 400, "cannot claim own item")
    status, result = call("POST", "/claims", claim, claimant)
    check(status == 201, "claim created")
    claim_path = "/claims/" + str(result["id"])
    check(
        call("POST", "/claims", claim, claimant)[0] == 409,
        "duplicate active claim rejected",
    )
    check(call("GET", claim_path, token=owner)[0] == 200, "owner sees incoming claim")
    check(
        call("GET", claim_path, token=stranger)[0] == 404, "claim hidden from outsider"
    )
    check(call("GET", "/claims", token=stranger)[1]["total"] == 0, "claim list private")
    message = {"claimId": result["id"], "text": "Можем встретиться у входа?"}
    check(
        call("POST", "/messages", message, stranger)[0] == 404, "outsider cannot send"
    )
    status, sent = call("POST", "/messages", message, claimant)
    check(status == 201, "claimant sends message")
    check(
        call("POST", "/messages", {**message, "text": "Да, после пары."}, owner)[0]
        == 201,
        "owner replies",
    )
    thread = "/messages?claimId=" + str(result["id"])
    check(call("GET", thread, token=owner)[1]["total"] == 2, "both messages visible")
    check(call("GET", thread, token=stranger)[0] == 404, "thread private")
    check(
        call("DELETE", "/messages/" + str(sent["id"]), token=owner)[0] == 404,
        "cannot delete other message",
    )
    check(
        call("DELETE", "/messages/" + str(sent["id"]), token=claimant) == (204, b""),
        "delete own message",
    )
    check(
        call("PUT", claim_path, {"status": "closed"}, owner)[0] == 200,
        "owner closes claim",
    )
    check(
        call("POST", "/messages", message, claimant)[0] == 409,
        "closed thread rejects sends",
    )
    check(
        call("PUT", claim_path, {"status": "discussion"}, claimant)[0] == 200,
        "claim status update",
    )
    check(
        call("PUT", path, {**draft, "status": "returned"}, owner)[0] == 200,
        "return item",
    )
    check(
        call("POST", "/messages", message, claimant)[0] == 409,
        "returned item blocks conversation",
    )
    check(
        call("POST", "/claims", claim, stranger)[0] == 409,
        "returned item blocks claims",
    )
    check(call("DELETE", claim_path, token=claimant)[0] == 204, "delete claim")
    check(call("GET", thread, token=owner)[0] == 404, "claim deletion cascades")
    check(call("DELETE", path, token=owner)[0] == 204, "delete item")
    check(call("GET", path, token=owner)[0] == 404, "deleted item missing")
    marker = uuid.uuid4().hex[:8]
    ids = []
    for n in range(25):
        status, row = call(
            "POST", "/items", {**draft, "title": f"ФУТЛЯР {marker} {n}"}, owner
        )
        assert status == 201
        ids.append(row["id"])
    query = {
        "search": "футляр " + marker,
        "limit": 20,
        "type": "found",
        "location": "Библиотека",
    }
    one = call("GET", "/items?" + urlencode({**query, "page": 1}), token=claimant)[1]
    two = call("GET", "/items?" + urlencode({**query, "page": 2}), token=claimant)[1]
    check(
        one["total"] == 25 and len(one["items"]) == 20 and len(two["items"]) == 5,
        "Unicode server search and two pages",
    )
    check(
        not ({r["id"] for r in one["items"]} & {r["id"] for r in two["items"]}),
        "pages have no duplicates",
    )
    check(
        call("GET", "/items?mine=1", token=claimant)[1]["total"] == 0,
        "own items filter",
    )
    for item_id in ids:
        assert call("DELETE", "/items/" + str(item_id), token=owner)[0] == 204
    print(
        f"PASS: {checks} LostFound API checks. These are own tests, not official conformance."
    )


if __name__ == "__main__":
    run()
