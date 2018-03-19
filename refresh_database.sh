#!/usr/bin/env bash

DOR_BRANCH=${DOR_BRANCH:-master}

die () {
  local st=$?
  warn "$@"
  exit "$st"
}

warn() {
  local fmt=$1
  shift
  printf "${BASH_SOURCE##*/}: $fmt\n" "$@" >&2
}

if ! type -P aws >/dev/null || ! aws iam get-user --region us-east-1 &>/dev/null
then
    die "The aws command must be in your PATH and credentials must be configured. This is needed to retrieve the docker image for dor"
fi

if ! creds=$(aws ecr get-login --region us-east-1 --no-include-email); then
    die "Failed to get ECR credentials needed to retrieve image"
fi
eval $creds &>/dev/null

args=(--local --local-username "$(id -un)" "$@")
docker_args=()

if [[ -e "${BASH_SOURCE%/*}/config/database.yml" ]]
then
    if [[ $(uname -s) == 'Linux' ]]
    then
        args+=(--database-yml "/database.yml")
        # readlink and realpath are not POSIX, so we need to use a more hacky approach
        pushd "${BASH_SOURCE%/*}" > /dev/null
        db_yml_path="$(pwd -P)/config/database.yml"
        popd > /dev/null
        docker_args+=(-v "$db_yml_path:/database.yml")
    else
        args+=(--database-yml "${BASH_SOURCE%/*}/config/database.yml")
    fi
fi

usercount=$(psql -At -d postgres -c "SELECT count(*) FROM pg_user WHERE usename='knotweed';")

if [ $usercount -eq 0 ]
then
    if ! psql -d postgres -c  "CREATE USER knotweed WITH PASSWORD 'knotweed';"
    then
        die "failed to create knotweed user in database"
    fi
fi

if [[ -e /tmp/.s.PGSQL.5432 ]];
then
    docker_args+=(-v /tmp/.s.PGSQL.5432:/var/run/postgresql/.s.PGSQL.5432)
elif [[ -e /var/run/postgresql/.s.PGSQL.5432 ]]; then
    docker_args+=(-v /var/run/postgresql/.s.PGSQL.5432:/var/run/postgresql/.s.PGSQL.5432)
fi

# only setup a tunnel if we are not on an ec2 instance (eg dev-web)
if ! curl --connect-timeout 1 -s http://169.254.169.254/latest/meta-data/ &>/dev/null
then
    host_arg="dev-web.subtext.org"
    if [[ $SSH_USERNAME ]]
    then
        host_arg="${SSH_USERNAME}@${host_arg}"
    fi
    # create a tunnel to dev-web. We use -f instead of backgrounding ourselves so that a passphrase can still be prompted if needed
    # This has the downside of requiring we pass a command, and also requiring us to use pgrep to find the pid
    if ! ssh -f -L 54320:prod-002.cogj3v9uqpkv.us-east-1.rds.amazonaws.com:5432 "$host_arg" "sleep $((60*60*2))"
    then
        die "failed to create a tunnel through reports.subtext.org via ssh. If you need to specify a username, set the SSH_USERNAME environment variable"
    fi
    ssh_pid=$(pgrep -f 'ssh -f -L 54320:prod-002.cogj3v9uqpkv.us-east-1.rds.amazonaws.com:5432')
    trap "kill $ssh_pid" EXIT
    args+=(--database-source-host 'localhost' --database-source-port '54320')
fi

if [[ $(uname -s) == 'Linux' ]]
then
    # pull manually so we get the latest image
    docker pull 465559955196.dkr.ecr.us-east-1.amazonaws.com/dor:master >/dev/null
    docker run -t -i --rm --net=host "${docker_args[@]}" 465559955196.dkr.ecr.us-east-1.amazonaws.com/dor:$DOR_BRANCH refresh-database "${args[@]}"
elif [[ $(uname -s) == 'Darwin' ]] # this can be removed once socket sharing support is added to docker on mac
then
    if ! type -P virtualenv >/dev/null; then
        sudo pip install virtualenv
    fi
    virtualenv /tmp/dor_venv
    . /tmp/dor_venv/bin/activate
    if ! pip install --process-dependency-links -e git+ssh://git@github.com/subtextmedia/dor@$DOR_BRANCH#egg=dor
    then
        die 'failed to install dor'
    fi
    dor refresh-database "${args[@]}"
fi
