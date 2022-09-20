# @CONF
# # SECRET FILE DUMMY (place it to {{ secrets-path }}):
#
# declare -A apiportal=(
#   # project home directory
#   [home_dir]=
# )
#
# declare -A apiportal_docker=(
#   # sth like <axway-registry>/apiportal-base
#   [img_name_base]=
#   # sth like dev-apiportal-web
#   [img_name_web]=
#   [db_host]=
#   [db_pass]=
# )
# @/CONF

alias et.dev1="et servant@dev1.axway.vm"
alias et.dev2="et servant@dev2.axway.vm"
alias et.int1="et servant@int1.axway.vm"

alias cd.portal="apiportal_cd_portal"
alias cd.docker="apiportal_cd_docker"

alias docker.build-base=apiportal_docker_build_base
alias docker.build-web=apiportal_docker_build_web

apiportal_docker_build_base() {
  . "$(_apiportal_secrets_path)" || return 1

  local tag
  local name="${apiportal_docker[img_name_base]}"
  tag="$(date +%Y%m%d)-1"

  _apiportal_docker_build_trap_help apiportal_docker_build_base "${tag}" "${@}" && return $?

  [[ -n "${1}" ]] \
    && tag="${1}" \
    || echo "Falling back to TAG='${tag}'" >/dev/stderr

  (
    cd.docker
    set -x
    docker image build -t "${name}:${tag}" -f dockerfiles/base.Dockerfile .
  ) 2> >(
    sed -e 's/\( build -t \)[^\/]\+/\1*****/g' >/dev/stderr
  ) | sed -e 's/^\(Successfully tagged \)[^\/]\+/\1*****/g'
}

apiportal_docker_build_web() {
  . "$(_apiportal_secrets_path)" || return 1

  local -A db=(
    [host]="${apiportal_docker[db_host]}"
    [port]='3306'
    [name]='apiportal_ci'
    [user]='root'
    [pass]="${apiportal_docker[db_pass]}"
  )
  local tag=dev
  local name="${apiportal_docker[img_name_web]}"

  _apiportal_docker_build_trap_help apiportal_docker_build_web "${tag}" "${@}" && return

  [[ -n "${1}" ]] \
    && tag="${1}" \
    || echo "Falling back to TAG='${tag}'" >/dev/stderr

  (
    cd.docker
    set -x
    docker image build --network host -t "${name}:${tag}" \
      --build-arg MYSQL_HOST="${db[host]}" \
      --build-arg MYSQL_PORT="${db[port]}" \
      --build-arg MYSQL_DATABASE="${db[name]}" \
      --build-arg MYSQL_USER="${db[user]}" \
      --build-arg MYSQL_PASSWORD="${db[pass]}" \
      -f dockerfiles/web.Dockerfile .
  ) 2> >(
    sed -e 's/\( --build-arg MYSQL_PASSWORD=\)[^ ]\+/\1*****/g' \
      -e 's/\( --build-arg MYSQL_HOST=\)[^ ]\+/\1*****/g' >/dev/stderr
  ) \
  | sed -e 's/\(ARG APIPORTAL_BASE_IMG=\)[^\/]\+/\1*****/g'
}

apiportal_genconf() {
  _apiportal_genconf_trap_help "${@}" && return 0

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
    | _envar_template_compile --secrets-path "$(_apiportal_secrets_path)"
  )"

  _envar_file2dest --tag APIPORTAL_CONF --tag-prefix '#' \
    -- <(cat <<< "${conf}" ) "${@}"
}

apiportal_cd_portal() {
  cd "$(_apiportal_get_home_dir)"
}

apiportal_cd_docker() {
  cd "$(_apiportal_get_home_dir)/src/main/docker"
}

#
# PRIVATES
#

_apiportal_genconf_trap_help() {
  [[ "${1}" =~ ^(-h|-\?|--help)$ ]] && {
    echo "USAGE:"
    echo "  apiportal_genconf [DEST...]"
    echo
    echo "Default DEST is stdout"
    return 0
  }

  return 1
}

_apiportal_docker_build_trap_help() {
  local func="${1}"
  local tag="${2}"

  [[ "${3}" =~ ^(-h|-\?|--help)$ ]] && {
    echo "USAGE:"
    echo "  ${func} [TAG]"
    echo
    echo "TAG is '${tag}' by default"
    return 0
  }

  return 1
}

_apiportal_get_home_dir() {
  . "$(_apiportal_secrets_path)" || return 1

  printf -- '%s' "${apiportal[home_dir]:-$(
    printf -- '%s' ~/Projects/axway/apiportal
  )}"
}

_apiportal_secrets_path() {
  declare self; self="$(realpath -- "${BASH_SOURCE[0]}")"

  printf -- '%s/%s\n' \
    "$(realpath -- "$(dirname -- "${self}")/../..")" \
    "secrets/work/apiportal.env"
}
