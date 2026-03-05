EXPIRE_DATE="2026-03-03"
USERS=(kornilkov_an donovskaya_tv)
for user in "${USERS[@]}"; do
    sudoers_file="/etc/sudoers.d/$user"
    echo "# expire $EXPIRE_DATE
    $user ALL=(root) ALL" > "$sudoers_file"
done
