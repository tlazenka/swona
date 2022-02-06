FROM swift:5.5

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . .

CMD ["swift", "build"]
