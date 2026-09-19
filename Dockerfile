FROM swift:6.4

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . .

CMD ["swift", "build"]
