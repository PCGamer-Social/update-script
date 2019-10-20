#!/bin/bash

SECONDS=0
INSTANCE=stellaria.network
REPOSITORY=https://github.com/stellarianetwork/mastodon
COMMITHASH=$(git ls-remote ${REPOSITORY}.git HEAD | head -c 7)
DOCKERREPO=registry.hub.docker.com/eaaaaaaaaaaai/stellaria-mastodon
DOCKERTAG=latest

cd ~/stellaria

while getopts :mh argument; do
	case $argument in
		m) major=true ;;
		h) hub=true ;;
		*) echo "正しくない引数が指定されました。" 1>&2
			exit 1 ;;
	esac
done


echo "[${COMMITHASH}] アピデするよ ${REPOSITORY}/tree/${COMMITHASH}" | toot --visibility unlisted
git fetch
git reset --hard origin/master

if [ "$hub" = "true" ]; then
	echo "[${COMMITHASH}] Container Pull..." | toot --visibility unlisted
	dokcer pull ${DOCKERREPO}:${DOCKERTAG}
	imageid=`docker images ${DOCKERREPO}:${DOCKERTAG} --format "{{.ID}}" | awk 'END{print}'`
	echo "[${COMMITHASH}] Container Pull Finished. DOCKER IMAGE ID: ${imageid}" | toot --visibility unlisted
else
	echo "[${COMMITHASH}] Build..." | toot --visibility unlisted
	docker-compose build
	echo "[${COMMITHASH}] Build Finished." | toot --visibility unlisted
fi

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
