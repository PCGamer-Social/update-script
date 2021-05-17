#!/bin/bash -eu

SECONDS=0

# env読み込み
if [[ ! -f .env ]]; then
	echo ".envファイルが見つかりません" 1>&2
	exit 1
fi
. .env

echo "---"
echo "MASTODON_PATH: ${MASTODON_PATH}"
echo "INSTANCE: ${INSTANCE}"
echo "REPOSITORY: ${REPOSITORY}"
echo "DOCKERREPO: ${DOCKERREPO}"
echo "DOCKERTAG: ${DOCKERTAG}"
echo "TOOT_VISIBLITY: ${TOOT_VISIBLITY}"
echo "---"

# 引数の処理
major=false
hub=false
while getopts :mh argument; do
	case $argument in
		m) major=true ;;
		h) hub=true ;;
		*) echo "正しくない引数が指定されました。" 1>&2
			exit 1 ;;
	esac
done

function send_toot() {
	echo "[${commithash}] $1" | toot --visibility ${TOOT_VISIBLITY}
}

cd ${MASTODON_PATH}

commithash=$(git ls-remote ${REPOSITORY}.git HEAD | head -c 7)
send_toot "${MESSAGE_BEGIN}"
git fetch
git reset --hard origin/master

if [ $hub = "true" ]; then
	send_toot "${MESSAGE_PULL_BEGIN}"
	docker-compose pull
	send_toot "${MESSAGE_PULL_DONE}"
else
	send_toot "${MESSAGE_BUILD_BEGIN}"
	docker-compose build
	send_toot "${MESSAGE_BUILD_DONE}"
fi

if [ $major = "true" ]; then
	send_toot "${MESSAGE_PRE_DEPLOYMENT_DB_MIGRATION_BEGIN}"
	docker-compose run --rm -e SKIP_POST_DEPLOYMENT_MIGRATIONS=true web rails db:migrate
	send_toot "${MESSAGE_PRE_DEPLOYMENT_DB_MIGRATION_DONE}"
fi

send_toot "${MESSAGE_DEPLOY_BEGIN}"
docker-compose down && docker-compose up -d

while true; do
	sleep 5s
	DonAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" https://${INSTANCE}/)
	if [ $DonAlive -eq 302 ]; then
		break
	fi
	echo "Check Failed: Retry after 5 sec."
done

docker-compose run --rm web bin/tootctl cache clear
send_toot "${MESSAGE_DB_MIGRATION_BEGIN}"
docker-compose run --rm web rails db:migrate
send_toot "${MESSAGE_DB_MIGRATION_DONE}"

docker-compose up -d

current_version=$(curl -s https://${INSTANCE}/api/v1/instance | jq -r '.version')
spend_time=$(date -u -d @${SECONDS} +"%T")
send_toot "${current_version} ${MESSAGE_DEPLOY_DONE} $spend_time"
echo "Finished."
