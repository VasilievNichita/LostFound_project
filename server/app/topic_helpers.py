from .db import conn
from .errors import not_found, validation_error


def text(body, field, minimum=0, maximum=1000):
    value = body.get(field)
    if not isinstance(value, str) or not minimum <= len(value.strip()) <= maximum:
        raise validation_error("Invalid field: " + field)
    return value.strip()


def page_args(request):
    try:
        page = max(1, int(request.query_params.get("page", "1")))
        limit = min(100, max(1, int(request.query_params.get("limit", "20"))))
    except ValueError:
        raise validation_error("Invalid pagination")
    return page, limit


def page_result(rows, total, page, limit, convert):
    return {
        "items": [convert(row) for row in rows],
        "total": total,
        "page": page,
        "limit": limit,
    }


def visible_claim(claim_id, user_id):
    row = conn.execute(
        """
        SELECT c.*, i.user_id AS owner_id, i.status AS item_status
        FROM claims c JOIN items i ON i.id=c.item_id
        WHERE c.id=? AND (c.user_id=? OR i.user_id=?)
    """,
        (claim_id, user_id, user_id),
    ).fetchone()
    if row is None:
        raise not_found("Claim not found")
    return row
