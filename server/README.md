# Сервер LostFound

Python/FastAPI и SQLite. Базовые auth, notes, files, health взяты из выданного Python-порта PAM. Исходное описание сохранено в TEMPLATE_README.md. Упомянутые там conformance и openapi.yaml в полученном архиве отсутствуют.

Установите зависимости из requirements.txt и выполните `python -m app.main` из этой папки. PORT по умолчанию 8080. PAM_DATA_DIR задаёт папку базы и фотографий. JWT_SECRET задаёт ключ подписи; на локальном стенде scripts/backend.ps1 хранит сгенерированный ключ за пределами репозитория.

items.py, claims.py и messages.py содержат правила LostFound. Объявления доступны всем вошедшим пользователям, заявки и сообщения только участникам. Изменять вещь может её автор. Возврат вещи запрещает новые заявки и сообщения. GET /campus отдаёт места и профиль для клиента.

С работающим сервером выполните `python tests/check_base.py` и `python tests/check_lostfound.py`. Для тестов другого порта установите TEST_BASE_URL. seed_demo.py создаёт явно демонстрационные аккаунты и объявления, его запуск необязателен. integration_host.py служит только для локального Android-теста на портах 8081/8082.
