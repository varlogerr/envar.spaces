# @CONF
# # SECRET FILE DUMMY (place it to {{ secrets-path }}):
#
# declare -A hosts=(
#   # pve1 default user and host ip / domain name.
#   # format <user>@<host>
#   [pve1]=
#   # vpn1 default user and host ip / domain name.
#   # format <user>@<host>
#   [vpn1]=
# )
# @/CONF

alias ssh.pve1="_homelab_connect ssh pve1"
alias ssh.vpn1="_homelab_connect ssh vpn1"
alias et.pve1="_homelab_connect et pve1"
alias et.vpn1="_homelab_connect et vpn1"

homelab_genconf() {
  _homelab_genconf_trap_help "${@}" && return 0

  local self="${BASH_SOURCE[0]}"
  (
    typeset -F _envar_tag_node_get \
    && typeset -F _envar_file2dest \
    && typeset -F _envar_template_compile
  ) >/dev/null || return 1

  local conf; conf="$(
    cat "${self}" \
    | _envar_tag_node_get --prefix '# @' --strip -- CONF \
    | sed 's/^# \?//' \
    | _envar_template_compile --secrets-path "$(_homelab_secrets_path)"
  )"

  _envar_file2dest --tag HOMELAB_CONF --tag-prefix '#' \
    -- <(cat <<< "${conf}" ) "${@}"
}

#
# PRIVATES
#

_homelab_genconf_trap_help() {
  [[ "${1}" =~ ^(-h|-\?|--help)$ ]] && {
    echo "USAGE:"
    echo "  homelab_genconf [DEST...]"
    echo
    echo "Default DEST is stdout"
    return 0
  }

  return 1
}

_homelab_connect() {
  _homelab_connect_trap_help "${@}" && return $?

  . "$(_homelab_secrets_path)" || return 1

  local type="${1}"; shift
  local name="${1}"; shift
  local user_in="${1}"; shift

  [[ -n "${hosts["$name"]}" ]] || {
    echo "Configuration not defined for ${type} name: ${name}" >&2
    return 1
  }

  local user_host="${hosts["$name"]}"
  local user_host_rev="$(rev <<< "${user_host}")"
  local host_rev; host_rev="$(cut -d@ -f1 <<< "${user_host_rev}@")"
  local user_rev; user_rev="$(cut -d@ -f2 <<< "${user_host_rev}@")"

  [[ -n "${user_in}" ]] && user_rev="$(rev <<< "${user_in}")"

  user_host_rev="${host_rev}"
  [[ -n "${user_rev}" ]] && user_host_rev+="@${user_rev}"

  user_host="$(rev <<< "${user_host_rev}")"

  ${type} "${user_host}"
}

_homelab_connect_trap_help() {
  local type="${1}"; shift
  local name="${1}"; shift

  [[ "${1}" =~ ^(-h|-\?|--help)$ ]] && {
    echo "USAGE:"
    echo "  ${type}.${name} [USER]"
    echo
    echo "Inline USER takes precedence over the one from the configuration."
    return 0
  }

  return 1
}

_homelab_secrets_path() {
  declare self; self="$(realpath -- "${BASH_SOURCE[0]}")"

  printf -- '%s/%s\n' \
    "$(realpath -- "$(dirname -- "${self}")/..")" \
    "secrets/homelab.env"
}
