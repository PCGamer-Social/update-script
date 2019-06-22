#!/bin/bash

SECONDS=0
COMMITHASH=$(git ls-remote https://github.com/stellarianetwork/mastodon.git HEAD | head -c 7)
cd ~/stellaria
echo "[${COMMITHASH}] アピデ: https://github.com/stellarianetwork/mastodon/tree/${COMMITHASH}" | toot --visibility unlisted
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
        DonAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" https://stellaria.network/)
        if [ $DonAlive -eq 302 ]; then
                break
        fi
        echo "Check Failed: Retry after 5 sec."
done

TIME=date -u -d @${SECONDS} +"%T"
echo "[${COMMITHASH}] ✅ Update Time: $TIME" | toot --visibility unlisted
