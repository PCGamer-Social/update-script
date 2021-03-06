Update Script
===

## About

- [@GLaDOS](https://pcgamer.social/@GLaDOS) の中身です。
- [PCGamer-Social/mastodon:origin/master](https://github.com/PCGamer-Social/mastodon) から更新します。

## Required

- git
- docker-compose
- jq
- [glynnbird/toot](https://github.com/glynnbird/toot)
    - recommend: `npm install -g toot`

## Usage

```shell
git pull ||  git reset --hard origin/master && chmod +x update.sh
cp .env.example .env
nano .env
./update.sh [-m] [-h]
```

```shell
-m    Major Version Update, Will Do Pre-Deployment DB Migration.
-h    Use Docker Hub Image.
```

## License

- **Update Script** licensed under [WTFPL](http://www.wtfpl.net/).

```
            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                    Version 2, December 2004

 Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

 Everyone is permitted to copy and distribute verbatim or modified
 copies of this license document, and changing it is allowed as long
 as the name is changed.

            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. You just DO WHAT THE FUCK YOU WANT TO.
```

## Original Author

[@lindwurm](https://github.com/lindwurm)