FROM ruby:2.6

ENV APP_ROOT /usr/src/app

WORKDIR $APP_ROOT

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN gem install bundler
RUN bundle install

COPY main.rb main.rb

ENTRYPOINT ["bundle", "exec"]
CMD ["./main.rb", "-p", "8080", "-o", "0.0.0.0"]
