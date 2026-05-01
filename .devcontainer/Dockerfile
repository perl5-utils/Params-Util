ARG PERL_VERSION=5.42
FROM perldocker/perl-tester:${PERL_VERSION}

ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd -g ${USER_GID} perl \
 && useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash perl \
 && mkdir -p /opt/perl5 /home/perl/.cpanm /tmp/build \
 && chown -R perl:perl /opt/perl5 /home/perl /tmp/build

ENV PERL_LOCAL_LIB_ROOT=/opt/perl5 \
    PERL_MB_OPT="--install_base /opt/perl5" \
    PERL_MM_OPT="INSTALL_BASE=/opt/perl5" \
    PERL5LIB=/opt/perl5/lib/perl5
ENV PATH=/opt/perl5/bin:${PATH}

USER perl
WORKDIR /home/perl
