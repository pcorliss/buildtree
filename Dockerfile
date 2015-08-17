FROM phusion/passenger-ruby22:0.9.17

# Manual Switch to prevent caching
# Only commit this as commented
# ENV REFRESHED_AT 2015.08.16

RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common python-software-properties && \
    add-apt-repository ppa:git-core/ppa -y && \
    apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt-get install libpq-dev git && \
    curl -sSL https://get.docker.com/ | sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN ssh-keyscan -H github.com >> ~/.ssh/known_hosts
RUN mkdir /home/app/webapp

## We can maintain our cache if we do this separately for faster builds
WORKDIR /home/app/webapp
ADD Gemfile /home/app/webapp/
ADD Gemfile.lock /home/app/webapp/

RUN bundle install --jobs=4 --deployment --without development test darwin

#RUN mkdir /etc/nginx/ssl
#ADD nginx_config/buildtree.crt /etc/nginx/ssl/
#ADD nginx_config/buildtree.key /etc/nginx/ssl/

ADD nginx_config/nginx.conf /etc/nginx/nginx.conf
ADD nginx_config/webapp_no_ssl.conf /etc/nginx/sites-enabled/webapp.conf
RUN rm /etc/nginx/sites-available/default
ADD nginx_config/prod-env.conf /etc/nginx/main.d/prod-env.conf

CMD ["/sbin/my_init"]

RUN rm -f /etc/service/nginx/down

# Uncomment of the following three lines for SSH access
#RUN rm -f /etc/service/sshd/down
#ADD ssh_keys/your_key.pub /tmp/your_key
#RUN cat /tmp/your_key >> /root/.ssh/authorized_keys && rm -f /tmp/your_key

ENV HOME /home/app

ADD . /home/app/webapp/
RUN rm -rf .env* tmp log # Prevents overriding of passed vars
RUN mkdir -p log tmp
RUN RAILS_ENV=production bundle exec rake assets:clobber assets:precompile
RUN chown -R app. log tmp
