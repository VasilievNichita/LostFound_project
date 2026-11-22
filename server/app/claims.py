import sqlite3
from fastapi import APIRouter, Depends, Request, Response
from .auth import require_auth
from .db import conn
from .errors import ApiError, json_response, not_found, read_json_body, validation_error
from .topic_helpers import text, page_args, page_result, visible_claim

router = APIRouter()


def view(row):
    return {
        "id": row["id"],
        "itemId": row["item_id"],
        "userId": row["user_id"],
        "message": row["message"],
        "status": row["status"],
    }


@router.get("/claims")
async def list_claims(request: Request, user_id: int = Depends(require_auth)):
    page, limit = page_args(request)
    where = "(c.user_id=? OR i.user_id=?)"
    args = [user_id, user_id]
    if request.query_params.get("itemId"):
        where += " AND c.item_id=?"
        args.append(request.query_params["itemId"])
    source = " FROM claims c JOIN items i ON i.id=c.item_id WHERE " + where
    total = conn.execute("SELECT count(*)" + source, args).fetchone()[0]
    rows = conn.execute(
        "SELECT c.*" + source + " ORDER BY c.id DESC LIMIT ? OFFSET ?",
        args + [limit, (page - 1) * limit],
    ).fetchall()
    return json_response(page_result(rows, total, page, limit, view))


@router.post("/claims")
async def create_claim(request: Request, user_id: int = Depends(require_auth)):
    body = await read_json_body(request)
    if not isinstance(body, dict):
        raise validation_error("Expected object")
    item_id = body.get("itemId")
    if not isinstance(item_id, (int, str)):
        raise validation_error("Invalid item ID")
    item = conn.execute("SELECT * FROM items WHERE id=?", (item_id,)).fetchone()
    if item is None:
        raise not_found("Item not found")
    if item["user_id"] == user_id:
        raise ApiError(400, "OWN_ITEM", "Cannot claim your own item")
    if item["status"] == "returned":
        raise ApiError(409, "ITEM_CLOSED", "Item returned")
    evidence = text(body, "message", 10, 600)
    try:
        cur = conn.execute(
            "INSERT INTO claims(item_id,user_id,message) VALUES (?,?,?)",
            (item_id, user_id, evidence),
        )
    except sqlite3.IntegrityError:
        raise ApiError(409, "CLAIM_EXISTS", "You already have an open claim")
    return json_response(view(visible_claim(cur.lastrowid, user_id)), status=201)


@router.get("/claims/{claim_id}")
async def get_claim(claim_id: str, user_id: int = Depends(require_auth)):
    return json_response(view(visible_claim(claim_id, user_id)))


@router.put("/claims/{claim_id}")
async def update_claim(
    claim_id: str, request: Request, user_id: int = Depends(require_auth)
):
    old = visible_claim(claim_id, user_id)
    body = await read_json_body(request)
    if not isinstance(body, dict):
        raise validation_error("Expected object")
    message = text(body, "message", 10, 600) if "message" in body else old["message"]
    if user_id != old["user_id"] and message != old["message"]:
        raise not_found("Claim not found")
    status = body.get("status", old["status"])
    if status not in ("pending", "discussion", "closed"):
        raise validation_error("Invalid claim status")
    try:
        conn.execute(
            "UPDATE claims SET message=?,status=? WHERE id=?",
            (message, status, claim_id),
        )
    except sqlite3.IntegrityError:
        raise ApiError(409, "CLAIM_EXISTS", "Another open claim exists")
    return json_response(view(visible_claim(claim_id, user_id)))


@router.delete("/claims/{claim_id}")
async def delete_claim(claim_id: str, user_id: int = Depends(require_auth)):
    claim = visible_claim(claim_id, user_id)
    if claim["user_id"] != user_id:
        raise not_found("Claim not found")
    conn.execute("DELETE FROM claims WHERE id=?", (claim_id,))
    return Response(status_code=204)
