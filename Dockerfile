FROM swift:5.2.3

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . .

WORKDIR /app/Repl

CMD ["swift", "build"]
