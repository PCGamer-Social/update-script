#!/bin/bash

COMMITHASH=$(git ls-remote https://github.com/PCGamer-Social/mastodon.git HEAD | head -c 7)
cd ~/mastodon
echo "[${COMMITHASH}] 📢 Enrichment Center より最新版のアップデートを開始します。Enrichment Center スタッフが最善の努力を行っていますが、重大な事故が発生する可能性があることを覚えておいてください。" | toot --visibility unlisted
git pull
echo "[${COMMITHASH}] 🗜️ データの取得が完了しました。ビルドを開始します。" | toot --visibility unlisted
docker-compose build
docker-compose run --rm web rails db:migrate
docker-compose run --rm web bin/tootctl cache clear
echo "[${COMMITHASH}] 🔜 デプロイを開始します。利用可能になるまで、あと、3 秒... 2 秒... 1 秒..." | toot --visibility unlisted
docker-compose up -d

while true; do
        DonAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" https://pcgamer.social/)
        if [ $DonAlive -eq 302 ]; then
                break
        fi
                echo "Check Failed: Retry after 2 sec."
                sleep 2s
                sudo systemctl restart nginx
done

echo "[${COMMITHASH}] ✅ アップデートが完了しました。Aperture Science の Mastodon ソーシャルテストにご協力いただき、ありがとうございます。" | toot --visibility unlisted

