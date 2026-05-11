#!/bin/bash

# ==========================================
# Linux Practical Exam Auto Checker
# Total Questions: 30
# ==========================================

TOTAL=30
MARKS=0

echo "=========================================="
echo " Linux Practical Exam Auto Checker"
echo "=========================================="

pass() {
    echo "PASS $1"
    ((MARKS++))
}

fail() {
    echo "FAIL $1"
}

# Q1
if [ -d /opt/projectdata ] &&
   [ -f /opt/projectdata/dev.txt ] &&
   [ -f /opt/projectdata/test.txt ] &&
   [ -f /opt/projectdata/prod.txt ]; then
    pass "Q1"
else
    fail "Q1"
fi

# Q2
PERM=$(stat -c %a /securedata/secret.txt 2>/dev/null)
if [ "$PERM" == "600" ]; then
    pass "Q2"
else
    fail "Q2"
fi

# Q3
COUNT=$(ls /var/log/testlogs/server*.log 2>/dev/null | wc -l)
if [ "$COUNT" -eq 5 ]; then
    pass "Q3"
else
    fail "Q3"
fi

# Q4
if id devopsuser &>/dev/null; then
    UIDCHK=$(id -u devopsuser)
    HOMECHK=$(grep "^devopsuser:" /etc/passwd | cut -d: -f6)
    SHELLCHK=$(grep "^devopsuser:" /etc/passwd | cut -d: -f7)

    if [ "$UIDCHK" == "2001" ] &&
       [ "$HOMECHK" == "/training/devopsuser" ] &&
       [ "$SHELLCHK" == "/bin/bash" ]; then
        pass "Q4"
    else
        fail "Q4"
    fi
else
    fail "Q4"
fi

# Q5
if getent group projectteam >/dev/null &&
   id rahul | grep -q projectteam &&
   id aman | grep -q projectteam &&
   id zoya | grep -q projectteam; then
    pass "Q5"
else
    fail "Q5"
fi

# Q6
if id backupadmin &>/dev/null; then
    EXP=$(chage -l backupadmin | grep "Account expires" | grep "Dec")
    PASSMAX=$(chage -l backupadmin | grep "Maximum" | awk '{print $NF}')

    if [ -n "$EXP" ] && [ "$PASSMAX" == "15" ]; then
        pass "Q6"
    else
        fail "Q6"
    fi
else
    fail "Q6"
fi

# Q7
STATUS=$(passwd -S rahul 2>/dev/null | awk '{print $2}')
if [ "$STATUS" == "P" ]; then
    pass "Q7"
else
    fail "Q7"
fi

# Q8
PERM=$(stat -c %a /sharedproject 2>/dev/null)
GROUP=$(stat -c %G /sharedproject 2>/dev/null)

if [ "$PERM" == "2770" ] && [ "$GROUP" == "projectteam" ]; then
    pass "Q8"
else
    fail "Q8"
fi

# Q9
if id audituser &>/dev/null; then
    MAX=$(chage -l audituser | grep "Maximum" | awk '{print $NF}')
    WARN=$(chage -l audituser | grep "warning" | awk '{print $NF}')

    if [ "$MAX" == "20" ] && [ "$WARN" == "5" ]; then
        pass "Q9"
    else
        fail "Q9"
    fi
else
    fail "Q9"
fi

# Q10
if grep -q "^%admins ALL=(ALL) NOPASSWD: ALL" /etc/sudoers ||
   grep -qr "^%admins ALL=(ALL) NOPASSWD: ALL" /etc/sudoers.d/; then
    pass "Q10"
else
    fail "Q10"
fi

# Q11
SHELL=$(grep "^temporaryuser:" /etc/passwd | cut -d: -f7)
HOME=$(grep "^temporaryuser:" /etc/passwd | cut -d: -f6)

if [[ "$SHELL" == "/sbin/nologin" || "$SHELL" == "/bin/false" ]] &&
   [ ! -d "$HOME" ]; then
    pass "Q11"
else
    fail "Q11"
fi

# Q12
if [ -f /root/userbackup/passwd.bak ] &&
   [ -f /root/userbackup/shadow.bak ] &&
   [ -f /root/userbackup/group.bak ]; then
    pass "Q12"
else
    fail "Q12"
fi

# Q13
ACL1=$(getfacl /teamdata/project.txt 2>/dev/null | grep "user:rahul:rw")
ACL2=$(getfacl /teamdata/project.txt 2>/dev/null | grep "user:aman:r--")

if [ -n "$ACL1" ] && [ -n "$ACL2" ]; then
    pass "Q13"
else
    fail "Q13"
fi

# Q14
PERM=$(stat -c %a finance.txt 2>/dev/null)

if [ "$PERM" == "640" ]; then
    pass "Q14"
else
    fail "Q14"
fi

# Q15
FILEPERM=$(stat -c %a testfile 2>/dev/null)
DIRPERM=$(stat -c %a testdir 2>/dev/null)

if [ "$FILEPERM" == "640" ] && [ "$DIRPERM" == "750" ]; then
    pass "Q15"
else
    fail "Q15"
fi

# Q16
if grep -q "umask 077" /training/operator/.bashrc 2>/dev/null ||
   grep -q "umask 077" /etc/profile; then
    pass "Q16"
else
    fail "Q16"
fi

# Q17
PERM=$(stat -c %a /publicdata 2>/dev/null)

if [ "$PERM" == "1777" ]; then
    pass "Q17"
else
    fail "Q17"
fi

# Q18
PERM=$(stat -c %a important.conf 2>/dev/null)

if [ "$PERM" == "700" ] || [ "$PERM" == "744" ]; then
    pass "Q18"
else
    fail "Q18"
fi

# Q19
ACL1=$(getfacl /acltest/dev.txt 2>/dev/null | grep "user:rahul:rwx")
ACL2=$(getfacl /acltest/prod.txt 2>/dev/null | grep "user:aman:r--")

if [ -n "$ACL1" ] && [ -n "$ACL2" ]; then
    pass "Q19"
else
    fail "Q19"
fi

# Q20
if [ -f /opt/project/database.txt ] &&
   [ -f /opt/project/db_hard ] &&
   [ -L /opt/project/db_soft ]; then
    pass "Q20"
else
    fail "Q20"
fi

# Q21
if [ -L webconfig ]; then
    pass "Q21"
else
    fail "Q21"
fi

# Q22
if getent group sysadmin >/dev/null &&
   id ryan | grep -q sysadmin &&
   id sarah | grep -q sysadmin; then
    pass "Q22"
else
    fail "Q22"
fi

# Q23
PERM=$(stat -c %a /common/admin 2>/dev/null)
GROUP=$(stat -c %G /common/admin 2>/dev/null)

if [ "$PERM" == "2770" ] && [ "$GROUP" == "sysadmin" ]; then
    pass "Q23"
else
    fail "Q23"
fi

# Q24
UIDCHK=$(id -u james 2>/dev/null)

if [ "$UIDCHK" == "2112" ]; then
    pass "Q24"
else
    fail "Q24"
fi

# Q25
MAXDAYS=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')

if [ "$MAXDAYS" == "20" ]; then
    pass "Q25"
else
    fail "Q25"
fi

# Q26
if grep -q "wired" /tmp/data 2>/dev/null; then
    pass "Q26"
else
    fail "Q26"
fi

# Q27
if grep -q "umask 333" /home/rahul/.bashrc 2>/dev/null; then
    pass "Q27"
else
    fail "Q27"
fi

# Q28
if [ -f /opt/projectdata/grass.txt ]; then
    pass "Q28"
else
    fail "Q28"
fi

# Q29
PERM=$(stat -c %a /etc/passwd 2>/dev/null)

if [[ "$PERM" == 1* ]]; then
    pass "Q29"
else
    fail "Q29"
fi

# Q30
PERM=$(stat -c %a /secureproject 2>/dev/null)
GROUP=$(stat -c %G /secureproject 2>/dev/null)
ACL=$(getfacl /secureproject 2>/dev/null | grep "default:user:aman:rw")

if [ "$GROUP" == "devteam" ] &&
   [[ "$PERM" == *770 || "$PERM" == *3770 || "$PERM" == *2770 || "$PERM" == *3770 ]] &&
   [ -n "$ACL" ]; then
    pass "Q30"
else
    fail "Q30"
fi

echo "=========================================="
echo "FINAL SCORE : $MARKS / $TOTAL"
echo "=========================================="
