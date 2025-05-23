#!/bin/sh
set -e

MISE_CLI_INSTALLER_GPG_KEY="0x7413A06D"

# Feature options
if [ ! "$VERSION" = "latest" ]; then
    export MISE_VERSION="$VERSION"
fi
if [ "$INSTALL" = "true" ]; then
    TRUST="true"
fi
# mise installer options
export MISE_INSTALL_PATH="${INSTALLPATH:-/usr/local/bin/mise}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Get the list of GPG key servers that are reachable
get_gpg_key_servers() {
    keyservers="hkp://keyserver.ubuntu.com hkp://keyserver.ubuntu.com:80 hkps://keys.openpgp.org hkp://keyserver.pgp.com"
    urls="http://keyserver.ubuntu.com:11371 http://keyserver.ubuntu.com https://keys.openpgp.org http://keyserver.pgp.com:11371"

    curl_args=""
    keyserver_reachable=0

    if [ -n "$KEYSERVER_PROXY" ]; then
        curl_args="--proxy $KEYSERVER_PROXY"
    fi

    i=1
    for keyserver in $keyservers; do
        # nth URL
        url=$(echo "$urls" | cut -d' ' -f"$i")
        if curl -s $curl_args --max-time 5 "$url" > /dev/null; then
            echo "keyserver ${keyserver}"
            keyserver_reachable=1
        else
            echo "(*) Keyserver $keyserver is not reachable." >&2
        fi
        i=$((i + 1))
    done

    if [ "$keyserver_reachable" -ne 1 ]; then
        echo "(!) No keyserver is reachable." >&2
        exit 1
    fi
}

# Import the specified key in a variable name passed in as
receive_gpg_keys() {
    keys="$1"
    keyring_args=""
    if [ ! -z "$2" ]; then
        keyring_args="--no-default-keyring --keyring $2"
    fi

    # Install curl
    if ! type curl > /dev/null 2>&1; then
        check_packages curl
    fi

    # Use a temporary location for gpg keys to avoid polluting image
    export GNUPGHOME="/tmp/tmp-gnupg"
    mkdir -p ${GNUPGHOME}
    chmod 700 ${GNUPGHOME}
    echo "disable-ipv6\n$(get_gpg_key_servers)" > ${GNUPGHOME}/dirmngr.conf

    # GPG key download sometimes fails for some reason and retrying fixes it.
    retry_count=0
    gpg_ok="false"
    set +e
    until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ];
    do
        echo "(*) Downloading GPG key..."
        ( echo "${keys}" | xargs -n 1 gpg -q ${keyring_args} --recv-keys) 2>&1 && gpg_ok="true"
        if [ "${gpg_ok}" != "true" ]; then
            echo "(*) Failed getting key, retrying in 10s..."
            retry_count=$((retry_count + 1))
            sleep 10s
        fi
    done
    set -e
    if [ "${gpg_ok}" = "false" ]; then
        echo "(!) Failed to get gpg key."
        exit 1
    fi
}

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

install_mise_activate() {
    shell=$1
    rc=$2

    if ! command -v $shell > /dev/null 2>&1; then
        echo "(*) $shell not found. Skipping mise activate for $shell."
        return
    fi
    if [ ! -f $rc ]; then
        echo "(*) $rc not found. Skipping mise activate for $shell."
        return
    fi

    echo "Activating mise for $shell..."
    case "$ACTIVATE" in
        path)
            echo >> $rc
            echo "eval \"\$(mise activate $shell)\"" >> $rc
            ;;
        shims)
            echo >> $rc
            echo "eval \"\$(mise activate $shell --shims)\"" >> $rc
            ;;
    esac
}

check_packages curl ca-certificates apt-transport-https dirmngr gnupg2

# Import the GPG key for the mise CLI
. /etc/os-release
receive_gpg_keys $MISE_CLI_INSTALLER_GPG_KEY

# Get the directory part
install_dir=$(dirname "$MISE_INSTALL_PATH")

# Create a list of directories to potentially create
dirs_to_create=""
current_dir="$install_dir"

# Build the list of non-existent parent directories
while [ ! -d "$current_dir" ] && [ "$current_dir" != "/" ] && [ "$current_dir" != "." ]; do
    dirs_to_create="$current_dir $dirs_to_create"
    current_dir=$(dirname "$current_dir")
done

# Create directories and set ownership
if [ -n "$dirs_to_create" ]; then
    for dir in $dirs_to_create; do
        mkdir -p "$dir"
        chown "${_REMOTE_USER}:$(id -gn ${_REMOTE_USER} 2>/dev/null || echo ${_REMOTE_USER})" "$dir"
        echo "Created directory with correct ownership: $dir"
    done
fi

# Run the mise CLI installer
echo "Installing mise CLI..."
curl -s https://mise.jdx.dev/install.sh.sig | gpg --decrypt | sh

chmod +x ${MISE_INSTALL_PATH}
chown "${_REMOTE_USER}:$(id -gn ${_REMOTE_USER} 2>/dev/null || echo ${_REMOTE_USER})" "${MISE_INSTALL_PATH}"

install_mise_activate bash /etc/bash.bashrc
install_mise_activate zsh /etc/zsh/zshrc

# Setup postCreateCommand for mise
mkdir -p /usr/local/share/mise-feature

post_create_file="/usr/local/share/mise-feature/post-create.sh"
echo "#!/bin/sh" > $post_create_file

if [ "${TRUST}" = "true" ]; then
    echo "Setting up postCreateCommand for 'mise trust'..."
    cat << 'EOF' >> $post_create_file
if [ -x "$(command -v mise)" ]; then
    mise trust --all --yes --verbose
fi
EOF
fi

if [ "${INSTALL}" = "true" ]; then
    echo "Setting up postCreateCommand for 'mise install'..."
    cat << 'EOF' >> $post_create_file
if [ -x "$(command -v mise)" ]; then
    mise install --yes
fi
EOF
fi

chmod +x $post_create_file

# Clean up
rm -rf "/tmp/tmp-gnupg"
rm -rf /var/lib/apt/lists/*
