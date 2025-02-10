cat << EOF > ~/.ssh/config

Host ${hostname}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityfile}
EOF

chmod 600 ~/.ssh/config
