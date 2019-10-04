#!/bin/bash

SECONDS=0
INSTANCE=stellaria.network
REPOSITORY=https://github.com/stellarianetwork/mastodon
COMMITHASH=$(git ls-remote ${REPOSITORY}.git HEAD | head -c 7)

cd ~/stellaria

while getopts :m argument; do
	case $argument in
		m) major=true ;;
		*) echo "正しくない引数が指定されました。" 1>&2
			exit 1 ;;
	esac
done


echo "[${COMMITHASH}] アピデするよ ${REPOSITORY}/tree/${COMMITHASH}" | toot --visibility unlisted
git fetch
git reset --hard origin/master

echo "[${COMMITHASH}] Pull..." | toot --visibility unlisted
docker-compose pull

if [ "$major" = "true" ]; then
	echo "[${COMMITHASH}] Pre-Deployment DB Migration..." | toot --visibility unlisted
	docker-compose run --rm -e SKIP_POST_DEPLOYMENT_MIGRATIONS=true web rails db:migrate
	dokcer-compose up -d

	while true; do
		sleep 5s
		DonAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" https://${INSTANCE}/)
		if [ $DonAlive -eq 302 ]; then
			break
		fi
		echo "Check Failed: Retry after 5 sec."
	done
fi

echo "[${COMMITHASH}] DB Migration..." | toot --visibility unlisted
docker-compose run --rm web bin/tootctl cache clear
docker-compose run --rm web rails db:migrate

echo "[${COMMITHASH}] Deploy..." | toot --visibility unlisted
docker-compose up -d

while true; do
	sleep 5s
	DonAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" https://${INSTANCE}/)
	if [ $DonAlive -eq 302 ]; then
		break
	fi
	echo "Check Failed: Retry after 5 sec."
done

VERSION=$(curl -s https://${INSTANCE}/api/v1/instance | jq -r '.version')
TIME=$(date -u -d @${SECONDS} +"%T")
echo "[${COMMITHASH}] ${VERSION} ✅ Update Time: $TIME" | toot --visibility unlisted
