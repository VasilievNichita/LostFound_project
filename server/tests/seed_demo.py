"""Explicit optional demo data. Not called by the server or application."""

from check_base import call


def account(email, name):
    body = {"email": email, "password": "campus123", "name": name}
    status, data = call("POST", "/auth/register", body)
    if status == 409:
        status, data = call("POST", "/auth/login", body)
    assert status in (200, 201), data
    return data["token"]


if __name__ == "__main__":
    owner = account("library@example.org", "Ирина, библиотека")
    student = account("student@example.org", "Никита")
    current = call("GET", "/items?mine=1&limit=100", token=owner)[1]["items"]
    if not current:
        names = [
            "Синий футляр для очков",
            "Связка ключей с зелёным брелком",
            "Белые наушники",
            "Тетрадь по математике",
            "Чёрный зонт",
            "Флешка в металлическом корпусе",
            "Серая термокружка",
            "Папка с конспектами",
        ]
        places = ["Библиотека", "Корпус №3", "Столовая", "Двор кампуса"]
        for n in range(25):
            title = names[n % len(names)] + (
                f" ({n // len(names) + 1})" if n >= len(names) else ""
            )
            status, item = call(
                "POST",
                "/items",
                {
                    "type": "found",
                    "title": title,
                    "description": "Демонстрационное объявление. Уточните приметы в заявке.",
                    "location": places[n % len(places)],
                },
                owner,
            )
            assert status == 201, item
        print("Created 25 demo announcements.")
    else:
        print("Demo owner already has announcements; left unchanged.")
    print("Demo users: student@example.org / library@example.org; password: campus123")
