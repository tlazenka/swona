FROM swift:5.0

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . .

WORKDIR /app/Repl

CMD ["swift", "build"]
