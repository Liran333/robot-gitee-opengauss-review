FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-gitee-opengauss-review
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-gitee-opengauss-review -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 opengauss-review && \
    useradd -u 1000 -g opengauss-review -s /sbin/nologin -m opengauss-review && \
    echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd && \
    mkdir /home/opengauss-review -p && \
    chmod 700 /home/opengauss-review && \
    chown opengauss-review:opengauss-review /home/opengauss-review && \
    echo 'set +o history' >> /root/.bashrc && \
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs && \
    rm -rf /tmp/*

USER opengauss-review

WORKDIR /opt/app

COPY  --chown=opengauss-review --from=BUILDER /go/src/github.com/opensourceways/robot-gitee-opengauss-review/robot-gitee-opengauss-review /opt/app/robot-gitee-opengauss-review

RUN chmod 550 /opt/app/robot-gitee-opengauss-review && \
    echo "umask 027" >> /home/opengauss-review/.bashrc && \
    echo 'set +o history' >> /home/opengauss-review/.bashrc

ENTRYPOINT ["/opt/app/robot-gitee-opengauss-review"]
