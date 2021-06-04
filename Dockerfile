FROM swift:5.4

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . .

CMD ["swift", "build"]
