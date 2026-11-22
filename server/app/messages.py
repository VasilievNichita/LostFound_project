from fastapi import APIRouter, Depends, Request, Response
from .auth import require_auth
from .db import conn, now_iso
from .errors import ApiError, json_response, not_found, read_json_body, validation_error
from .topic_helpers import text, page_args, page_result, visible_claim

router = APIRouter()


def view(row):
    return {
        "id": row["id"],
        "claimId": row["claim_id"],
        "senderId": row["sender_id"],
        "text": row["text"],
        "sentAt": row["sent_at"],
    }


@router.get("/messages")
async def list_messages(request: Request, user_id: int = Depends(require_auth)):
    page, limit = page_args(request)
    where, args = "(c.user_id=? OR i.user_id=?)", [user_id, user_id]
    if request.query_params.get("claimId"):
        visible_claim(request.query_params["claimId"], user_id)
        where += " AND m.claim_id=?"
        args.append(request.query_params["claimId"])
    source = (
        " FROM messages m JOIN claims c ON c.id=m.claim_id JOIN items i ON i.id=c.item_id WHERE "
        + where
    )
    total = conn.execute("SELECT count(*)" + source, args).fetchone()[0]
    rows = conn.execute(
        "SELECT m.*" + source + " ORDER BY m.id LIMIT ? OFFSET ?",
        args + [limit, (page - 1) * limit],
    ).fetchall()
    return json_response(page_result(rows, total, page, limit, view))


@router.post("/messages")
async def create_message(request: Request, user_id: int = Depends(require_auth)):
    body = await read_json_body(request)
    if not isinstance(body, dict) or not isinstance(body.get("claimId"), (int, str)):
        raise validation_error("Invalid claim ID")
    claim = visible_claim(body["claimId"], user_id)
    if claim["status"] == "closed" or claim["item_status"] == "returned":
        raise ApiError(409, "THREAD_CLOSED", "Conversation closed")
    value = text(body, "text", 1, 1000)
    cur = conn.execute(
        "INSERT INTO messages(claim_id,sender_id,text,sent_at) VALUES (?,?,?,?)",
        (claim["id"], user_id, value, now_iso()),
    )
    return json_response(
        view(
            conn.execute(
                "SELECT * FROM messages WHERE id=?", (cur.lastrowid,)
            ).fetchone()
        ),
        status=201,
    )


@router.delete("/messages/{message_id}")
async def delete_message(message_id: str, user_id: int = Depends(require_auth)):
    message = conn.execute(
        "SELECT * FROM messages WHERE id=? AND sender_id=?", (message_id, user_id)
    ).fetchone()
    if message is None:
        raise not_found("Message not found")
    visible_claim(message["claim_id"], user_id)
    conn.execute("DELETE FROM messages WHERE id=?", (message_id,))
    return Response(status_code=204)
