#!/bin/bash

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
        DonAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" https://stellaria.network/)
        if [ $DonAlive -eq 302 ]; then
                break
        fi
                echo "Check Failed: Retry after 5 sec."
                sleep 5s
                sudo systemctl restart caddy
done

echo "[${COMMITHASH}] ✅" | toot --visibility unlisted
