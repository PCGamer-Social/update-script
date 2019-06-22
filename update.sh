#!/bin/bash

SECONDS=0
INSTANCE=stellaria.network
REPOSITORY=https://github.com/stellarianetwork/mastodon
COMMITHASH=$(git ls-remote ${REPOSITORY}.git HEAD | head -c 7)

cd ~/stellaria

echo "[${COMMITHASH}] アピデ:${REPOSITORY}/tree/${COMMITHASH}" | toot --visibility unlisted
git fetch
git reset --hard origin/master

echo "[${COMMITHASH}] Build" | toot --visibility unlisted
docker-compose build
echo "[${COMMITHASH}] Buildおわり" | toot --visibility unlisted

docker-compose run --rm web rails db:migrate
docker-compose run --rm web bin/tootctl cache clear

echo "[${COMMITHASH}] Deploy" | toot --visibility unlisted
docker-compose up -d

while true; do
        sleep 5s
        DonAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" https://${INSTANCE}/)
        if [ $DonAlive -eq 302 ]; then
                break
        fi
        echo "Check Failed: Retry after 5 sec."
done

VERSION=curl -s https://${INSTANCE}/api/v1/instance | jq -r '.version'
TIME=date -u -d @${SECONDS} +"%T"
echo "[${COMMITHASH}] ${VERSION} ✅ Update Time: $TIME" | toot --visibility unlisted
