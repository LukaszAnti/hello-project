# Wybierz bazowy obraz z Pythonem
FROM python:3.9-slim

# Skopiuj plik aplikacji do kontenera
COPY app.py /app/app.py

# Ustaw katalog roboczy
WORKDIR /app

# Zainstaluj Flask
RUN pip install flask

# Otwórz port 80
EXPOSE 5000

# Uruchom aplikację
CMD ["python", "app.py"]
