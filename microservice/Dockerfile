FROM python:3.8-slim
RUN apt-get update -y
RUN apt-get install -y curl dnsutils
WORKDIR /app
COPY . /app
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8080

CMD ["python", "app.py"]
