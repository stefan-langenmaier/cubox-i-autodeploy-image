#!/bin/bash

set -eux

# this is the version that will be used for the next tag
TAG="v0.51"
DESC="Version bump to latest kernel"

OWNER=stefan-langenmaier
REPO=cubox-i-autodeploy-image

sed -i "s/TAG=\".*\"$/TAG=\"$TAG\"/" remote/deploy.sh
sed -i 's#^\(.*\)v0.*\(/.*\)$#\1'$TAG'\2#' config/autodeploy-script-source


SUBTAG=${TAG:3:5}
NEXT_SUBTAG=$(( SUBTAG + 1 ))
sed -i "s/TAG=\".*\"$/TAG=\"v0.$NEXT_SUBTAG\"/" create-tag.sh

if [ -z ${TOKEN+x} ]; then
	echo "GitHub TOKEN is unset"
	exit 1
else
	git add .
	git commit -m "preparing new tag $TAG" || /bin/true #if the commit is already prepared
	git tag "$TAG"
	git push
#	true
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

#REMOTE_FOLDER="remote"
#mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d ${REMOTE_FOLDER}/boot.txt ${REMOTE_FOLDER}/boot.scr

curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @remote/extlinux.conf \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=extlinux.conf
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @remote/deploy.sh \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=deploy.sh
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @u-boot-bin/SPL \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=SPL
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @u-boot-bin/u-boot.img \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=u-boot.img
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @kernel-bin/imx6q-cubox-i.dtb \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=imx6q-cubox-i.dtb
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @kernel-bin/imx6q-cubox-i-emmc-som-v15.dtb \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=imx6q-cubox-i-emmc-som-v15.dtb
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @kernel-bin/imx6q-cubox-i-som-v15.dtb \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=imx6q-cubox-i-som-v15.dtb
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @kernel-bin/zImage \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=zImage
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @output/autodeploy.img \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=autodeploy.img
curl -i -H 'Authorization: token '$TOKEN --header "Content-Type:application/binary" --data-binary @rootfs-bin/cubox-i.tar.xz \
	https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets?name=cubox-i.tar.xz
