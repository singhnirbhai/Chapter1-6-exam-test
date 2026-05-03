#!/bin/bash

score=0
total=38

echo "========= LINUX EXAM RESULT ========="

pass() { echo "$1 OK"; ((score++)); }
fail() { echo "$1 FAIL"; }

# Q1 Hostname
hostname | grep -w grrassolutions &>/dev/null && pass "Q1" || fail "Q1"

# Q6 TestFolder
[ -d /home/student/TestFolder ] && pass "Q6" || fail "Q6"

# Q7 EmptyDir removed
[ ! -d EmptyDir ] && pass "Q7" || fail "Q7"

# Q8 notes.txt
[ -f notes.txt ] && pass "Q8" || fail "Q8"

# Q9 backup
[ -f /home/student/TestFolder/backup.txt ] && pass "Q9" || fail "Q9"

# Q11 deleted new.txt
[ ! -f new.txt ] && pass "Q11" || fail "Q11"

# Q12 content inside backup
[ -s /home/student/TestFolder/backup.txt ] && pass "Q12" || fail "Q12"

# Q16 common dir
[ -d /home/student/common ] && pass "Q16" || fail "Q16"

# Q17 5 dirs
count=$(ls -d dir* 2>/dev/null | wc -l)
[ "$count" -ge 5 ] && pass "Q17" || fail "Q17"

# Q18 hard link
[ "$(stat -c %i original.txt 2>/dev/null)" == "$(stat -c %i hardcopy.txt 2>/dev/null)" ] && pass "Q18" || fail "Q18"

# Q19 soft link
[ -L softcopy.txt ] && pass "Q19" || fail "Q19"

# Q20 passwd link
[ -L /home/student/passwd_link ] && pass "Q20" || fail "Q20"

# Q21 user student1
id student1 &>/dev/null && pass "Q21" || fail "Q21"

# Q22 group
getent group projectgroup | grep student1 &>/dev/null && pass "Q22" || fail "Q22"

# Q23 primary group
[ "$(id -gn student1 2>/dev/null)" == "projectgroup" ] && pass "Q23" || fail "Q23"

# Q24 student2 deleted
id student2 &>/dev/null && fail "Q24" || pass "Q24"

# Q25 ownership
stat -c "%U:%G" report.txt 2>/dev/null | grep student1:projectgroup &>/dev/null && pass "Q25" || fail "Q25"

# Q26 user lock
passwd -S inactiveuser 2>/dev/null | grep L &>/dev/null && pass "Q26" || fail "Q26"

# Q27 home changed
grep student1 /etc/passwd | grep "/home/newhome" &>/dev/null && pass "Q27" || fail "Q27"

# Q28 permission 744
[ "$(stat -c %a grras.txt 2>/dev/null)" == "744" ] && pass "Q28" || fail "Q28"

# Q29 shared exec
[ -d shared ] && [ -x shared ] && pass "Q29" || fail "Q29"

# Q30 setuid on useradd
stat -c "%A" /usr/bin/useradd 2>/dev/null | grep s &>/dev/null && pass "Q30" || fail "Q30"

# Q31 sticky bit
stat -c "%A" /shared 2>/dev/null | grep t &>/dev/null && pass "Q31" || fail "Q31"

# Q32 setgid Documents
stat -c "%A" Documents 2>/dev/null | grep s &>/dev/null && pass "Q32" || fail "Q32"

# Q33 ACL
getfacl Videos 2>/dev/null | grep student1 &>/dev/null && pass "Q33" || fail "Q33"

# Q34 umask
umask | grep 027 &>/dev/null && pass "Q34" || fail "Q34"

# Q35 permanent umask
grep -r "umask 077" /home/student /etc/profile /etc/bashrc 2>/dev/null && pass "Q35" || fail "Q35"

# Q37 password change date
chage -l student1 2>/dev/null | grep "Jan" &>/dev/null && pass "Q37" || fail "Q37"

# Q38 max password age
chage -l student1 2>/dev/null | grep "90" &>/dev/null && pass "Q38" || fail "Q38"

# Manual Questions
echo "Q2 MANUAL CHECK"
echo "Q3 MANUAL CHECK"
echo "Q4 MANUAL CHECK"
echo "Q5 MANUAL CHECK"
echo "Q13 MANUAL CHECK"
echo "Q14 MANUAL CHECK"
echo "Q15 MANUAL CHECK"
echo "Q36 THEORY"

echo "===================================="
echo "FINAL SCORE: $score / $total"
