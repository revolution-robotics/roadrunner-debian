: ${AWK_CMD:='/usr/bin/awk'}
: ${HOSTNAME_CMD:='/usr/bin/hostname'}
: ${ID_CMD:='/usr/bin/id'}
: ${SSH_CMD:='/usr/bin/ssh'}
: ${SSH_ADD_CMD:='/usr/bin/ssh-add'}
: ${SSH_AGENT_CMD:='/usr/bin/ssh-agent'}
: ${SSH_KEYGEN_CMD:='/usr/bin/ssh-keygen'}
: ${SSH_KEYSCAN_CMD:='/usr/bin/ssh-keyscan'}

add-ssh-id () 
{ 
    local pubkey=$HOME/.ssh/id_ed25519.pub;
    if test ."$SSH_AGENT_PID" = ."" || ! kill -0 "$SSH_AGENT_PID" 2> /dev/null; then
        eval $($SSH_AGENT_CMD -s);
    fi;
    if test ! -f "$pubkey"; then
        echo "${FUNCNAME[0]}: $pubkey: No such file.  Unable to add identity.";
    else
        if test ."$($SSH_ADD_CMD -l)" = ."The agent has no identities."; then
            $SSH_ADD_CMD;
        fi;
    fi
}

sship () 
{ 
    local host=$1;
    if [[ ."$host" =~ \.([^@]+@)?([^:]+)(:[^:]+)? ]]; then
        local user_at=${BASH_REMATCH[1]};
        local host=${BASH_REMATCH[2]};
        local colon_path=${BASH_REMATCH[3]};
        local hostname=$($SSH_CMD -G "$host" | $AWK_CMD '/^hostname/ { printf $2 }');
        echo "${user_at}${hostname}${colon_path}";
    fi
}

ssh () 
{ 
    local -i exit_status;
    add-ssh-id;
    $SSH_CMD "$@";
    exit_status=$?;
    set-window-title "$($ID_CMD -un)@$($HOSTNAME_CMD -s)";
    return $exit_status
}

set-window-title () 
{ 
    [ ."$1" != .'' ] && printf "\e]0;$@\a"
}
