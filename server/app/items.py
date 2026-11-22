from fastapi import APIRouter, Depends, Request, Response
from .auth import require_auth
from .campus import LOCATIONS
from .db import conn, now_iso
from .errors import json_response, not_found, read_json_body, validation_error
from .topic_helpers import text, page_args, page_result

router = APIRouter()


def view(row):
    return {
        "id": row["id"],
        "userId": row["user_id"],
        "type": row["type"],
        "title": row["title"],
        "description": row["description"],
        "imageUrl": row["image_url"],
        "location": row["location"],
        "status": row["status"],
        "createdAt": row["created_at"],
    }


def find(item_id, owner=None):
    sql = "SELECT * FROM items WHERE id=?"
    args = [item_id]
    if owner is not None:
        sql += " AND user_id=?"
        args.append(owner)
    row = conn.execute(sql, args).fetchone()
    if row is None:
        raise not_found("Item not found")
    return row


def fields(body, user_id, old=None):
    if not isinstance(body, dict):
        raise validation_error("Expected object")
    item_type = text(body, "type", 1, 10)
    location = text(body, "location", 1, 80)
    if item_type not in ("lost", "found") or location not in LOCATIONS:
        raise validation_error("Invalid type or location")
    image = text(body, "imageUrl", 0, 300) if "imageUrl" in body else ""
    if image and (old is None or image != old["image_url"]):
        if not image.startswith("/files/") or not image[7:].isdigit():
            raise validation_error("Invalid image URL")
        file = conn.execute(
            "SELECT id,mime_type FROM files WHERE id=? AND user_id=?",
            (int(image[7:]), user_id),
        ).fetchone()
        if file is None or not file["mime_type"].startswith("image/"):
            raise validation_error("Upload your image first")
    status = body.get("status", old["status"] if old else "open")
    if status not in ("open", "returned"):
        raise validation_error("Invalid item status")
    return (
        item_type,
        text(body, "title", 1, 80),
        text(body, "description", 0, 500) if "description" in body else "",
        image,
        location,
        status,
    )


@router.get("/items")
async def list_items(request: Request, user_id: int = Depends(require_auth)):
    page, limit = page_args(request)
    where, args = ["1=1"], []
    q = request.query_params
    for name in ("type", "location"):
        if q.get(name):
            where.append(name + "=?")
            args.append(q[name])
    if q.get("mine") == "1":
        where.append("user_id=?")
        args.append(user_id)
    if q.get("search"):
        where.append("instr(casefold(title || ' ' || description), ?) > 0")
        args.append(q["search"].strip().casefold())
    clause = " AND ".join(where)
    total = conn.execute("SELECT count(*) FROM items WHERE " + clause, args).fetchone()[
        0
    ]
    rows = conn.execute(
        "SELECT * FROM items WHERE " + clause + " ORDER BY id DESC LIMIT ? OFFSET ?",
        args + [limit, (page - 1) * limit],
    ).fetchall()
    return json_response(page_result(rows, total, page, limit, view))


@router.post("/items")
async def create_item(request: Request, user_id: int = Depends(require_auth)):
    values = fields(await read_json_body(request), user_id)
    cur = conn.execute(
        "INSERT INTO items(user_id,type,title,description,image_url,location,status,created_at) VALUES (?,?,?,?,?,?,?,?)",
        (user_id, *values, now_iso()),
    )
    return json_response(view(find(cur.lastrowid)), status=201)


@router.get("/items/{item_id}")
async def get_item(item_id: str, user_id: int = Depends(require_auth)):
    return json_response(view(find(item_id)))


@router.put("/items/{item_id}")
async def update_item(
    item_id: str, request: Request, user_id: int = Depends(require_auth)
):
    old = find(item_id, user_id)
    values = fields(await read_json_body(request), user_id, old)
    conn.execute(
        "UPDATE items SET type=?,title=?,description=?,image_url=?,location=?,status=? WHERE id=?",
        (*values, item_id),
    )
    return json_response(view(find(item_id)))


@router.delete("/items/{item_id}")
async def delete_item(item_id: str, user_id: int = Depends(require_auth)):
    find(item_id, user_id)
    conn.execute("DELETE FROM items WHERE id=?", (item_id,))
    return Response(status_code=204)
