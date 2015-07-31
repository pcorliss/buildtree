FROM phusion/passenger-ruby21:0.9.14

# Manual Switch to prevent caching
ENV REFRESHED_AT 2015.08.01

RUN apt-get update -y \
    apt-get dist-upgrade -y \
    apt-get install -y --no-install-recommends libpq-dev \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /home/app/webapp

## We can maintain our cache if we do this separately for faster builds
WORKDIR /home/app/webapp
ADD Gemfile /home/app/webapp/
ADD Gemfile.lock /home/app/webapp/

RUN bundle install --deployment --binstubs --without development test

RUN mkdir /etc/nginx/ssl
ADD nginx_config/gitsentry.crt /etc/nginx/ssl/
ADD nginx_config/gitsentry.key /etc/nginx/ssl/

ADD nginx_config/nginx.conf /etc/nginx/nginx.conf
ADD nginx_config/webapp.conf /etc/nginx/sites-enabled/webapp.conf
RUN rm /etc/nginx/sites-available/default
ADD nginx_config/prod-env.conf /etc/nginx/main.d/prod-env.conf

CMD ["/sbin/my_init"]

RUN rm -f /etc/service/nginx/down
#RUN touch /etc/service/sshd/down
#ADD ssh_keys/your_key.pub /tmp/your_key
#RUN cat /tmp/your_key >> /root/.ssh/authorized_keys && rm -f /tmp/your_key
ENV HOME /home/app

ADD . /home/app/webapp/

RUN RAILS_ENV=production rake assets:clobber assets:precompile
RUN mkdir -p log tmp
RUN chown -R app. log tmp
