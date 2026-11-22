from fastapi import APIRouter, Depends
from .auth import require_auth
from .db import conn
from .errors import json_response, unauthorized

LOCATIONS = (
    "Корпус №3",
    "Библиотека",
    "Столовая",
    "Общежитие №1",
    "Спорткомплекс",
    "Двор кампуса",
)
router = APIRouter()


@router.get("/campus")
async def campus(user_id: int = Depends(require_auth)):
    user = conn.execute(
        "SELECT id,name,email FROM users WHERE id=?", (user_id,)
    ).fetchone()
    if user is None:
        raise unauthorized()
    # Public display names, never other people's email addresses.
    names = {
        str(row["id"]): row["name"] for row in conn.execute("SELECT id,name FROM users")
    }
    return json_response(
        {
            "userId": str(user_id),
            "name": user["name"],
            "email": user["email"],
            "group": "Участник кампуса",
            "university": "Технический университет Молдовы",
            "locations": list(LOCATIONS),
            "names": names,
        }
    )
