#!/usr/bin/env sh

cd_repo_root() {
  script_dir="$1"
  cd "$script_dir/../.."
}

web_is_running() {
  docker compose exec -T web true >/dev/null 2>&1
}

compose_run_web() {
  docker compose run --rm web "$@"
}

compose_exec_web() {
  docker compose exec web "$@"
}

compose_web() {
  if web_is_running; then
    compose_exec_web "$@"
    return
  fi

  compose_run_web "$@"
}

postgres_is_running() {
  docker compose ps --status running -q postgres >/dev/null 2>&1 && \
    [ -n "$(docker compose ps --status running -q postgres 2>/dev/null)" ]
}

print_step() {
  printf '\n==> %s\n' "$1"
}
