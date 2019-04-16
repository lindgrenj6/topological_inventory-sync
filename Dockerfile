FROM manageiq/ruby:latest

RUN yum -y install centos-release-scl-rh && \
    yum -y install --setopt=tsflags=nodocs \
                   # To compile native gem extensions
                   gcc-c++ \
                   # For git based gems
                   git \
                   # For checking service status
                   nmap-ncat \
                   # To compile pg gem
                   rh-postgresql10-postgresql-devel \
                   rh-postgresql10-postgresql-libs \
                   && \
    yum clean all

ENV WORKDIR /opt/topological_inventory-sync/
ENV RAILS_ROOT $WORKDIR
WORKDIR $WORKDIR

COPY . $WORKDIR
COPY docker-assets/entrypoint /usr/bin
COPY docker-assets/run_sync /usr/bin

RUN source /opt/rh/rh-postgresql10/enable && \
    echo "gem: --no-document" > ~/.gemrc && \
    gem install bundler --conservative --without development:test && \
    bundle install --jobs 8 --retry 3 && \
    find ${RUBY_GEMS_ROOT}/gems/ | grep "\.s\?o$" | xargs rm -rvf && \
    rm -rvf ${RUBY_GEMS_ROOT}/cache/* && \
    rm -rvf /root/.bundle/cache

RUN chgrp -R 0 $WORKDIR && \
    chmod -R g=u $WORKDIR

ENTRYPOINT ["entrypoint"]
CMD ["run_sources_sync"]
