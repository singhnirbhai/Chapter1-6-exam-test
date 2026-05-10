#!/usr/bin/env bash
# Auto-checker for "Linux Practical Test - Chapters 1-6"
# Run as root after the student finishes:
#   sudo bash linux_exam_autocheck.sh [exam_work_directory]
#
# Example:
#   sudo bash linux_exam_autocheck.sh /root
#
# The PDF leaves a few relative-path tasks unspecified. For those, this script
# checks EXAM_DIR first, then common admin locations, then does a short find.

set -u

EXAM_DIR="${1:-/root}"
TOTAL=0
MAX=0
PASS_COUNT=0
FAIL_COUNT=0
WARNINGS=()
DETAILS=()

GREEN=""
RED=""
YELLOW=""
RESET=""
if [ -t 1 ]; then
  GREEN="$(printf '\033[32m')"
  RED="$(printf '\033[31m')"
  YELLOW="$(printf '\033[33m')"
  RESET="$(printf '\033[0m')"
fi

add() {
  local q="$1" desc="$2" got="$3" max="$4" note="${5:-}"
  TOTAL=$((TOTAL + got))
  MAX=$((MAX + max))
  if [ "$got" -eq "$max" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    DETAILS+=("${GREEN}PASS${RESET} Q${q}: ${desc} (${got}/${max}) ${note}")
  elif [ "$got" -gt 0 ]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    DETAILS+=("${YELLOW}PART${RESET} Q${q}: ${desc} (${got}/${max}) ${note}")
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    DETAILS+=("${RED}FAIL${RESET} Q${q}: ${desc} (${got}/${max}) ${note}")
  fi
}

warn() {
  WARNINGS+=("$1")
}

exists_cmd() {
  command -v "$1" >/dev/null 2>&1
}

mode_of() {
  stat -c '%a' "$1" 2>/dev/null
}

owner_of() {
  stat -c '%U' "$1" 2>/dev/null
}

group_of() {
  stat -c '%G' "$1" 2>/dev/null
}

user_exists() {
  getent passwd "$1" >/dev/null 2>&1
}

group_exists() {
  getent group "$1" >/dev/null 2>&1
}

user_in_group() {
  id -nG "$1" 2>/dev/null | tr ' ' '\n' | grep -qx "$2"
}

user_shell() {
  getent passwd "$1" | awk -F: '{print $7}'
}

user_home() {
  getent passwd "$1" | awk -F: '{print $6}'
}

same_inode() {
  [ -e "$1" ] && [ -e "$2" ] && [ "$(stat -c '%d:%i' "$1" 2>/dev/null)" = "$(stat -c '%d:%i' "$2" 2>/dev/null)" ]
}

find_file() {
  local name="$1"
  local candidate
  for candidate in \
    "$EXAM_DIR/$name" \
    "$(pwd)/$name" \
    "/root/$name" \
    "/opt/$name" \
    "/opt/project/$name" \
    "/tmp/$name"; do
    [ -e "$candidate" ] && { printf '%s\n' "$candidate"; return 0; }
  done

  if exists_cmd timeout; then
    timeout 4s find / -xdev -name "$name" -print -quit 2>/dev/null
  else
    find / -xdev -name "$name" -print -quit 2>/dev/null
  fi
}

acl_has() {
  local file="$1" pattern="$2"
  exists_cmd getfacl || return 2
  getfacl -cp "$file" 2>/dev/null | grep -Eq "$pattern"
}

shadow_password_matches() {
  local user="$1" pass="$2"
  [ "$(id -u 2>/dev/null)" = "0" ] || return 2
  [ -r /etc/shadow ] || return 2
  exists_cmd python3 || return 2
  python3 - "$user" "$pass" <<'PY'
import crypt
import spwd
import sys

user, password = sys.argv[1], sys.argv[2]
try:
    encrypted = spwd.getspnam(user).sp_pwdp
except Exception:
    sys.exit(2)
if encrypted in ("!", "*", "!!") or encrypted.startswith("!"):
    sys.exit(1)
sys.exit(0 if crypt.crypt(password, encrypted) == encrypted else 1)
PY
}

check_password() {
  local q="$1" user="$2" pass="$3"
  if shadow_password_matches "$user" "$pass"; then
    add "$q" "password for $user matches expected value" 1 1
  else
    local rc=$?
    if [ "$rc" -eq 2 ]; then
      warn "Could not verify plaintext password for $user; run as root with python3 for password checks."
      add "$q" "password for $user is auto-verifiable" 0 1 "manual check needed"
    else
      add "$q" "password for $user matches expected value" 0 1
    fi
  fi
}

sudo_nopasswd_for_group() {
  local group="$1"
  grep -RE "^[[:space:]]*%${group}[[:space:]].*NOPASSWD:[[:space:]]*ALL" /etc/sudoers /etc/sudoers.d 2>/dev/null | grep -q .
}

password_status_locked() {
  passwd -S "$1" 2>/dev/null | awk '{print $2}' | grep -Eq '^(L|LK)$'
}

password_status_unlocked() {
  passwd -S "$1" 2>/dev/null | awk '{print $2}' | grep -Eq '^(P|PS|NP)$'
}

echo "Linux Practical Test Auto-check"
echo "Exam directory for relative files: $EXAM_DIR"
echo "Started: $(date)"
echo

if [ "$(id -u)" != "0" ]; then
  warn "Run with sudo/root for reliable checks of users, groups, /root, /etc/shadow, ACLs, and sudoers."
fi

# 1
[ -d /opt/projectdata ] && add 1 "/opt/projectdata directory exists" 1 1 || add 1 "/opt/projectdata directory exists" 0 1
for f in dev.txt test.txt prod.txt; do
  [ -f "/opt/projectdata/$f" ] && add 1 "/opt/projectdata/$f exists" 1 1 || add 1 "/opt/projectdata/$f exists" 0 1
done

# 2
[ -d /securedata ] && add 2 "/securedata directory exists" 1 1 || add 2 "/securedata directory exists" 0 1
[ -f /securedata/secret.txt ] && add 2 "/securedata/secret.txt exists" 1 1 || add 2 "/securedata/secret.txt exists" 0 1
[ -f /securedata/secret.txt ] && [ "$(mode_of /securedata/secret.txt)" = "600" ] && add 2 "secret.txt permission is 600" 2 2 || add 2 "secret.txt permission is 600" 0 2

# 3
for n in 1 2 3 4 5; do
  [ -f "/var/log/testlogs/server${n}.log" ] && add 3 "server${n}.log exists" 1 1 || add 3 "server${n}.log exists" 0 1
done

# 4
user_exists devopsuser && add 4 "devopsuser exists" 1 1 || add 4 "devopsuser exists" 0 1
[ "$(id -u devopsuser 2>/dev/null)" = "2001" ] && add 4 "devopsuser UID is 2001" 1 1 || add 4 "devopsuser UID is 2001" 0 1
[ "$(user_home devopsuser)" = "/training/devopsuser" ] && add 4 "devopsuser home is /training/devopsuser" 1 1 || add 4 "devopsuser home is /training/devopsuser" 0 1
[ "$(user_shell devopsuser)" = "/bin/bash" ] && add 4 "devopsuser shell is /bin/bash" 1 1 || add 4 "devopsuser shell is /bin/bash" 0 1
check_password 4 devopsuser 'DevOps@123'

# 5
group_exists projectteam && add 5 "projectteam group exists" 1 1 || add 5 "projectteam group exists" 0 1
for u in rahul aman zoya; do
  user_exists "$u" && add 5 "$u user exists" 1 1 || add 5 "$u user exists" 0 1
  user_in_group "$u" projectteam && add 5 "$u is secondary/member of projectteam" 1 1 || add 5 "$u is secondary/member of projectteam" 0 1
done

# 6
user_exists backupadmin && add 6 "backupadmin user exists" 1 1 || add 6 "backupadmin user exists" 0 1
chage -l backupadmin 2>/dev/null | grep -q "Account expires.*Dec 31, 2026" && add 6 "backupadmin account expiry is 2026-12-31" 2 2 || add 6 "backupadmin account expiry is 2026-12-31" 0 2
chage -l backupadmin 2>/dev/null | grep -q "Maximum number of days between password change[[:space:]]*:[[:space:]]*15" && add 6 "backupadmin password expiry is 15 days" 2 2 || add 6 "backupadmin password expiry is 15 days" 0 2

# 7
if user_exists rahul; then
  if password_status_unlocked rahul; then
    add 7 "rahul account is currently unlocked after lock/unlock task" 2 2
    warn "Q7 can only confirm final unlocked status; the script cannot prove the account was locked earlier and then unlocked."
  else
    add 7 "rahul account is currently unlocked after lock/unlock task" 0 2
  fi
else
  add 7 "rahul account exists for lock/unlock verification" 0 2
fi

# 8
[ -d /sharedproject ] && add 8 "/sharedproject exists" 1 1 || add 8 "/sharedproject exists" 0 1
[ "$(group_of /sharedproject)" = "projectteam" ] && add 8 "/sharedproject group is projectteam" 1 1 || add 8 "/sharedproject group is projectteam" 0 1
mode="$(mode_of /sharedproject)"
perm="${mode: -3}"
if [ -n "$mode" ] && (( (8#$perm & 0070) == 0070 && (8#$perm & 0007) == 0 )); then
  add 8 "/sharedproject grants group rwx and blocks others" 2 2
else
  add 8 "/sharedproject grants group rwx and blocks others" 0 2
fi

# 9
user_exists audituser && add 9 "audituser exists" 1 1 || add 9 "audituser exists" 0 1
chage -l audituser 2>/dev/null | grep -q "Maximum number of days between password change[[:space:]]*:[[:space:]]*20" && add 9 "audituser password expiry is 20 days" 2 2 || add 9 "audituser password expiry is 20 days" 0 2
chage -l audituser 2>/dev/null | grep -q "Number of days of warning before password expires[[:space:]]*:[[:space:]]*5" && add 9 "audituser warning period is 5 days" 2 2 || add 9 "audituser warning period is 5 days" 0 2

# 10
group_exists admins && add 10 "admins group exists" 1 1 || add 10 "admins group exists" 0 1
sudo_nopasswd_for_group admins && add 10 "admins group has passwordless sudo ALL" 4 4 || add 10 "admins group has passwordless sudo ALL" 0 4

# 11
user_exists temporaryuser && add 11 "temporaryuser exists" 1 1 || add 11 "temporaryuser exists" 0 1
if [ "$(user_shell temporaryuser)" = "/sbin/nologin" ] || [ "$(user_shell temporaryuser)" = "/usr/sbin/nologin" ] || [ "$(user_shell temporaryuser)" = "/bin/false" ]; then
  add 11 "temporaryuser has non-interactive shell" 2 2
else
  add 11 "temporaryuser has non-interactive shell" 0 2
fi
home="$(user_home temporaryuser)"
[ -n "$home" ] && [ ! -d "$home" ] && add 11 "temporaryuser has no home directory created" 2 2 || add 11 "temporaryuser has no home directory created" 0 2

# 12
[ -d /root/userbackup ] && add 12 "/root/userbackup exists" 1 1 || add 12 "/root/userbackup exists" 0 1
for f in passwd shadow group; do
  [ -f "/root/userbackup/${f}.bak" ] && add 12 "${f}.bak backup exists" 1 1 || add 12 "${f}.bak backup exists" 0 1
  [ -f "/root/userbackup/${f}.bak" ] && cmp -s "/etc/$f" "/root/userbackup/${f}.bak" && add 12 "${f}.bak matches /etc/$f" 1 1 || add 12 "${f}.bak matches /etc/$f" 0 1
done

# 13
[ -d /teamdata ] && add 13 "/teamdata exists" 1 1 || add 13 "/teamdata exists" 0 1
[ -f /teamdata/project.txt ] && add 13 "/teamdata/project.txt exists" 1 1 || add 13 "/teamdata/project.txt exists" 0 1
acl_has /teamdata/project.txt '^user:rahul:rw-' && add 13 "ACL gives rahul read/write on project.txt" 2 2 || add 13 "ACL gives rahul read/write on project.txt" 0 2
acl_has /teamdata/project.txt '^user:aman:r--' && add 13 "ACL gives aman read-only on project.txt" 2 2 || add 13 "ACL gives aman read-only on project.txt" 0 2

# 14
finance_file="$(find_file finance.txt | head -n1)"
[ -n "$finance_file" ] && add 14 "finance.txt exists ($finance_file)" 1 1 || add 14 "finance.txt exists" 0 1
[ -n "$finance_file" ] && [ "$(mode_of "$finance_file")" = "740" ] && add 14 "finance.txt permission is 740" 3 3 || add 14 "finance.txt permission is 740" 0 3

# 15
if [ "$(umask)" = "0027" ] || [ "$(umask)" = "027" ]; then
  add 15 "current shell umask is 027" 2 2
else
  add 15 "current shell umask is 027" 0 2
  warn "Q15 temporary umask is hard to auto-grade after the student's shell exits. Ask students to create known evidence files, or run this checker inside their exam shell."
fi
evidence_file="$(find "$EXAM_DIR" -maxdepth 2 -type f -perm 0640 -print -quit 2>/dev/null)"
evidence_dir="$(find "$EXAM_DIR" -maxdepth 2 -type d -perm 0750 -print -quit 2>/dev/null)"
[ -n "$evidence_file" ] && add 15 "found a 640 verification file under EXAM_DIR" 1 1 "$evidence_file" || add 15 "found a 640 verification file under EXAM_DIR" 0 1
[ -n "$evidence_dir" ] && add 15 "found a 750 verification directory under EXAM_DIR" 1 1 "$evidence_dir" || add 15 "found a 750 verification directory under EXAM_DIR" 0 1

# 16
user_exists operator && add 16 "operator user exists" 1 1 || add 16 "operator user exists" 0 1
operator_umask_ok=0
if user_exists operator && exists_cmd runuser; then
  tmp="/tmp/operator_umask_check_$$"
  mkdir -p "$tmp"
  chmod 777 "$tmp"
  if runuser -u operator -- sh -c "cd '$tmp' && rm -f f && rm -rf d && touch f && mkdir d && [ \"\$(stat -c '%a' f)\" = 600 ] && [ \"\$(stat -c '%a' d)\" = 700 ]" >/dev/null 2>&1; then
    operator_umask_ok=1
  fi
  rm -rf "$tmp"
else
  warn "Q16 live operator umask check needs runuser and an existing operator user."
fi
[ "$operator_umask_ok" -eq 1 ] && add 16 "operator permanent umask creates files 600 and dirs 700" 4 4 || add 16 "operator permanent umask creates files 600 and dirs 700" 0 4

# 17
[ -d /publicdata ] && add 17 "/publicdata exists" 1 1 || add 17 "/publicdata exists" 0 1
mode="$(mode_of /publicdata)"
if [ -n "$mode" ] && (( (8#$mode & 01000) == 01000 && (8#$mode & 0002) == 0002 )); then
  add 17 "/publicdata has sticky bit and is writable for users" 4 4
else
  add 17 "/publicdata has sticky bit and is writable for users" 0 4
fi

# 18
important_file="$(find_file important.conf | head -n1)"
[ -n "$important_file" ] && add 18 "important.conf exists ($important_file)" 1 1 || add 18 "important.conf exists" 0 1
if [ -n "$important_file" ]; then
  m="$(mode_of "$important_file")"
  if (( (8#$m & 0100) == 0100 && (8#$m & 0007) == 0 )); then
    add 18 "important.conf has owner execute and no permissions for others" 3 3
  else
    add 18 "important.conf has owner execute and no permissions for others" 0 3
  fi
else
  add 18 "important.conf has owner execute and no permissions for others" 0 3
fi

# 19
[ -d /acltest ] && add 19 "/acltest exists" 1 1 || add 19 "/acltest exists" 0 1
[ -f /acltest/dev.txt ] && add 19 "/acltest/dev.txt exists" 1 1 || add 19 "/acltest/dev.txt exists" 0 1
[ -f /acltest/prod.txt ] && add 19 "/acltest/prod.txt exists" 1 1 || add 19 "/acltest/prod.txt exists" 0 1
acl_has /acltest/dev.txt '^user:rahul:rwx' && add 19 "ACL gives rahul full permission on dev.txt" 2 2 || add 19 "ACL gives rahul full permission on dev.txt" 0 2
acl_has /acltest/prod.txt '^user:aman:r--' && add 19 "ACL gives aman read-only on prod.txt" 2 2 || add 19 "ACL gives aman read-only on prod.txt" 0 2

# 20
[ -f /opt/project/database.txt ] && add 20 "/opt/project/database.txt exists" 1 1 || add 20 "/opt/project/database.txt exists" 0 1
same_inode /opt/project/database.txt /opt/project/db_hard && add 20 "db_hard is a hard link to database.txt" 2 2 || add 20 "db_hard is a hard link to database.txt" 0 2
[ -L /opt/project/db_soft ] && [ "$(readlink /opt/project/db_soft)" = "/opt/project/database.txt" ] && add 20 "db_soft points to database.txt" 2 2 || add 20 "db_soft points to database.txt" 0 2

# 21
webconfig="$(find_file webconfig | head -n1)"
[ -n "$webconfig" ] && [ -L "$webconfig" ] && add 21 "webconfig symlink exists ($webconfig)" 1 1 || add 21 "webconfig symlink exists" 0 1
[ -n "$webconfig" ] && [ "$(readlink "$webconfig")" = "/etc/httpd/conf/httpd.conf" ] && add 21 "webconfig points to /etc/httpd/conf/httpd.conf" 3 3 || add 21 "webconfig points to /etc/httpd/conf/httpd.conf" 0 3

# 22
group_exists sysadmin && add 22 "sysadmin group exists" 1 1 || add 22 "sysadmin group exists" 0 1
for u in ryan sarah harry; do
  user_exists "$u" && add 22 "$u user exists" 1 1 || add 22 "$u user exists" 0 1
  check_password 22 "$u" atenorth
done
for u in ryan sarah; do
  user_in_group "$u" sysadmin && add 22 "$u is member of sysadmin" 1 1 || add 22 "$u is member of sysadmin" 0 1
done
if user_exists harry && ! user_in_group harry sysadmin; then
  add 22 "harry is not a member of sysadmin" 1 1
else
  add 22 "harry is not a member of sysadmin" 0 1
fi
if [ "$(user_shell harry)" = "/sbin/nologin" ] || [ "$(user_shell harry)" = "/usr/sbin/nologin" ] || [ "$(user_shell harry)" = "/bin/false" ]; then
  add 22 "harry has no interactive shell" 1 1
else
  add 22 "harry has no interactive shell" 0 1
fi

# 23
[ -d /common/admin ] && add 23 "/common/admin exists" 1 1 || add 23 "/common/admin exists" 0 1
[ "$(group_of /common/admin)" = "sysadmin" ] && add 23 "/common/admin group is sysadmin" 2 2 || add 23 "/common/admin group is sysadmin" 0 2
mode="$(mode_of /common/admin)"
perm="${mode: -3}"
if [ -n "$mode" ] && (( (8#$perm & 0070) == 0070 && (8#$perm & 0007) == 0 )); then
  add 23 "/common/admin group has rwx and others have no access" 3 3
else
  add 23 "/common/admin group has rwx and others have no access" 0 3
fi
if [ -n "$mode" ] && (( (8#$mode & 02000) == 02000 )); then
  add 23 "/common/admin has setgid for inherited group ownership" 3 3
else
  add 23 "/common/admin has setgid for inherited group ownership" 0 3
fi

echo "Detailed Results"
printf '%s\n' "${DETAILS[@]}"
echo

if [ "${#WARNINGS[@]}" -gt 0 ]; then
  echo "Warnings / Manual Review"
  printf '%s\n' "${WARNINGS[@]}"
  echo
fi

percent=0
if [ "$MAX" -gt 0 ]; then
  percent=$((TOTAL * 100 / MAX)
  grade="F"
if [ "$percent" -ge 90 ]; then
  grade="A"
elif [ "$percent" -ge 80 ]; then
  grade="B"
elif [ "$percent" -ge 70 ]; then
  grade="C"
elif [ "$percent" -ge 60 ]; then
  grade="D"
fi

echo "Summary"
echo "Score: $TOTAL / $MAX"
echo "Percentage: ${percent}%"
echo "Grade: $grade"
echo "Passed checks: $PASS_COUNT"
echo "Failed/partial checks: $FAIL_COUNT"
