FROM python:3-alpine
WORKDIR /usr/src/app

ENV BIND_PORT 1234
EXPOSE ${BIND_PORT}

COPY requirements.txt .
RUN echo ${BIND_PORT} && pip install -r requirements.txt

COPY . .

CMD ["python", "app.py"]

HEALTHCHECK --interval=5s \
    CMD nc -uvz 127.0.0.1 ${BIND_PORT}
