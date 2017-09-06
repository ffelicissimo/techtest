FROM python:2-slim

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app



COPY requirements.txt /usr/src/app

RUN pip install --no-cache-dir -r requirements.txt

COPY api.py /usr/src/app

EXPOSE 5000

ENV ENV
ENV REDIS_HOST

ENTRYPOINT [ "python", "-u", "api.py" ]

CMD []