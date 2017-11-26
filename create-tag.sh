#!/bin/bash

set -eux

TAG="v0.7"
DESC="Version bump to latest kernel 4.14.2 and latest u-boot"

OWNER=stefan-langenmaier
REPO=cubox-i-autodeploy-image

sed -i "s/TAG=\".*\"$/TAG=\"$TAG\"/" remote/deploy.sh

if [ -z ${TOKEN+x} ]; then
	echo "GitHub TOKEN is unset"
	exit 1
else
	git add .
	git commit -m "preparing new tag $TAG"
	git tag "$TAG"
	git push
fi

#curl -i -H 'Authorization: token '$TOKEN \
#	https://api.github.com/user

# DELETE IF EXISTS
#curl -i -H 'Authorization: token '$TOKEN \
#https://api.github.com/repos/$OWNER/$REPO/releases/$ID

curl -i -H 'Authorization: token '$TOKEN -d '{ "tag_name": "'"$TAG"'",  "target_commitish": "master", "name": "'"$TAG"'", "body": "'"$DESC"'" }' \
	https://api.github.com/repos/$OWNER/$REPO/releases

ID=$(curl -H 'Authorization: token '$TOKEN \
	https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG | \
    python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
echo $ID

REMOTE_FOLDER="remote"
mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d ${REMOTE_FOLDER}/boot.txt ${REMOTE_FOLDER}/boot.scr

curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @${REMOTE_FOLDER}/boot.scr \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=boot.scr
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @remote/deploy.sh \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=deploy.sh
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @u-boot-bin/SPL \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=SPL
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @u-boot-bin/u-boot.img \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=u-boot.img
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @kernel-bin/imx6q-cubox-i.dtb \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=imx6q-cubox-i.dtb
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @kernel-bin/zImage \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=zImage
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @output/autodeploy.img \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=autodeploy.img
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @../lxc-gentoo-build-tools/.packaged-subvolumes/cubox-i.xz \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=cubox-i.xz
