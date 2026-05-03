FROM rockylinux:9

RUN dnf install -y openssh-server sudo shadow-utils acl passwd which && \
    dnf clean all

RUN ssh-keygen -A

RUN sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Create student
RUN useradd student -m -s /bin/bash && \
    echo "student:student123" | chpasswd && \
    echo "root:root123" | chpasswd

# Create exam folder (PROTECTED)
RUN mkdir /exam

COPY questions.txt /exam/questions.txt
COPY check.sh /exam/check.sh

# Restrict access (student can read, not edit)
RUN chmod 500 /exam && \
    chmod 400 /exam/questions.txt && \
    chmod 500 /exam/check.sh

# Student working directories
RUN mkdir -p /home/student/TestFolder \
    

RUN chown -R student:student /home/student

EXPOSE 22

CMD ["/usr/sbin/sshd","-D"]
