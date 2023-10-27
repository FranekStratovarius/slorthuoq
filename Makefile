LUAJIT_ARGS=-s
IMAGES=game/result.png
VERSION=${shell git rev-list --count master}
BUILD=${PWD}/build
TMP=${BUILD}/tmp
LOVE=${PWD}/build/game.love
LOVE_EXE=${PWD}/build/slorthuoq.exe
SRCLUA = $(wildcard game/*.lua game/plugins/*.lua)
DATA_FILES= $(wildcard game/*.mp3) $(wildcard game/*.ttf) $(wildcard game/*.png)
FILES = $(SRCLUA:game/%.lua=${TMP}/files/%.lua) ${TMP}/files/versionsnummerSlorthuoq.lua ${TMP}/files/tiles.lua $(IMAGES:game/%.png=${TMP}/files/%.png) $(DATA_FILES:game/%=${TMP}/files/%)
APKTOOL_JAR = ${TMP}/apktool.jar
APKTOOL = java -jar ${APKTOOL_JAR}
UBER=uber-apk-signer-1.0.0.jar
APK=${BUILD}/slorthuoq.apk
APKUN=${TMP}/slorthuoq-unsigned.apk
LOVE_APK=${TMP}/love.apk
ANDROID_DIR=${TMP}/love_decoded
LOVE_APK_ROOT=${BUILD}/love_decoded_vanilla
all: windows android linux
test: linux
	love ${LOVE}
linux: ${LOVE}
windows: ${LOVE_EXE}
android: ${APK}
${APKUN}: ${LOVE_APK_ROOT} ${LOVE_APK} ${LOVE}
	rm -f ${APK}
	rm -rf ${ANDROID_DIR}
	cp -r ${LOVE_APK_ROOT} ${ANDROID_DIR}
	mkdir -p ${ANDROID_DIR}/assets
	mkdir -p ${ANDROID_DIR}/res
	cp ${LOVE} ${ANDROID_DIR}/assets/game.love
	sed 's/VERSIONNUM/${VERSION}/g' AndroidManifest.xml > ${ANDROID_DIR}/AndroidManifest.xml
	cp apktool.yml ${ANDROID_DIR}/apktool.yml
	cp res/slorthuoq48.png ${ANDROID_DIR}/res/drawable-mdpi/love.png
	cp res/slorthuoq72.png ${ANDROID_DIR}/res/drawable-hdpi/love.png
	cp res/slorthuoq96.png ${ANDROID_DIR}/res/drawable-xhdpi/love.png
	cp res/slorthuoq144.png ${ANDROID_DIR}/res/drawable-xxhdpi/love.png
	cp res/slorthuoq192.png ${ANDROID_DIR}/res/drawable-xxxhdpi/love.png
	cd ${ANDROID_DIR}/../ && ${APKTOOL} b -o ${APKUN} love_decoded
${APK}: ${APKUN} ${UBER}
	java -jar ${UBER} --apks ${APKUN} -o ${TMP}
	cp ${TMP}/slorthuoq-aligned-debugSigned.apk $@
${LOVE_APK_ROOT}: ${LOVE_APK} ${APKTOOL_JAR} #FORCE
	${APKTOOL} d -f -s -o ${LOVE_APK_ROOT} ${LOVE_APK}
${APKTOOL_JAR}:
	mkdir -p ${TMP}
	wget -O $@ https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.4.0.jar
${LOVE_APK}:
	mkdir -p ${TMP}
	wget -O $@ https://bitbucket.org/rude/love/downloads/love-11.1-android.apk
${UBER}:
	mkdir -p ${TMP}
	wget -O $@ https://github.com/patrickfav/uber-apk-signer/releases/download/v1.0.0/uber-apk-signer-1.0.0.jar
${LOVE_EXE}: ${TMP}/love.exe ${LOVE}
	mkdir -p ${TMP}
	mkdir -p ${BUILD}
	cat ${TMP}/love.exe ${LOVE} > $@
${TMP}/love.zip:
	mkdir -p ${TMP}
	mkdir -p ${BUILD}
	wget -O $@ https://bitbucket.org/rude/love/downloads/love-11.2-win64.zip
${TMP}/love.exe: ${TMP}/love.zip
	mkdir -p ${TMP}/love-windows/
	unzip -u ${TMP}/love.zip -d ${TMP}/love-windows/
	cp ${TMP}/love-windows/*/love.exe $@
${TMP}/files/versionsnummerSlorthuoq.lua: .git/refs/heads/master
	@mkdir -p ${TMP}/files
	echo "return ${VERSION}" > ${TMP}/files/versionsnummerSlorthuoq.lua
$(SRCLUA:game/%.lua=${TMP}/files/%.lua): ${TMP}/files/%.lua: game/%.lua #${SRCLUA} $(@:${TMP}/files/%.lua=game/%.lua)
	@mkdir -p ${TMP}/files/
	@mkdir -p ${TMP}/files/plugins
	luajit -b ${LUAJIT_ARGS} $< $@
$(IMAGES:game/%.png=${TMP}/files/%.png): ${TMP}/files/%.png: game/%.png
	cp $^ $@
${LOVE}: ${FILES}
	@mkdir -p ${TMP}/files/
	cd ${TMP}/files/ && zip -9 -r ${LOVE} .
${TMP}/files/tiles.lua: $(wildcard bilder/data/*.png) $(wildcard bilder/playeranimationen/*.png)
	@mkdir -p ${TMP}/files
	cd bilder && luajit pack.lua ${TMP}/files/tiles
$(DATA_FILES:game/%=${TMP}/files/%): ${TMP}/files/%: game/%
	cp $^ $@
.FORCE:
.PHONY: all windows files android FORCE linux
