#!/bin/bash

# Recommended For Ubuntu 18.04 or Higher
export LC_ALL=C

echo -e "\e[36m\e[1m---------------------------Random Script By Twel12---------------------------"

# Some Useful Stuff
server=$USER
update_date=`date '+%Y-%m-%d'`
LOCAL_PATH="$(pwd)"
telegramMSG=1 #Enable Message By Default Unlike for test builds

# Some Check For First Times
function firsttime() {
    echo "Performing Some Tests before running scripts"
    if stat --printf='' /home/$server/OTA 2>/dev/null; then
        echo "OTA Folder Check Complete."
    else
        echo -e "\033[01;31m\n Failed Finding OTA Folder \n "
        echo "Cloning OTA Folder"
        git clone https://github.com/PixelOS-Pixelish/OTA-Devices /home/$server/OTA
    fi

    if stat --printf='' /home/$server/telegram.sh 2>/dev/null; then
        echo "telegram script check complete"
    else
        echo -e "\033[01;31m\n Failed Finding Telegram Folder 033[0m"
        git clone git@github.com:Twel12/telegram.sh.git /home/$server/telegram.sh

    fi
}

# Telegram
telegram () {
if [[ $telegramMSG = 1 ]]; then
    ~/telegram.sh/telegram "$1" "$2" "$3" "$4" "$5"
fi
}

# Function to Check Error and Upload Build Log in case build fails
function build_error() {
if [[ $exitcodez != 0 ]]; then
	if [[ $1 != "" ]]; then
		echo "$1"
		echo "Exiting with status $exitcodez"
		telegram -c "-1001349538519" -f log.txt "Build Failed at $timefinal"
	else
		echo "An error was detected, exiting"
		telegram -c "-1001349538519" -f log.txt "An Error Was Detected Build Failed at $timefinal"
	fi
	exit $exitcodez
fi
}

# Command to check script error and abort if needed
function script_error() {
exitcode=$?
if [[ $exitcode != 0 ]]; then
	if [[ $1 != "" ]]; then
		echo "Exiting with status $exitcode"
	else
		echo "An error was detected, exiting"
	fi
	exit $exitcode
fi
}

# Time
function timechange() {
    hr=$(bc <<< "${1}/3600")
    min=$(bc <<< "(${1}%3600)/60")
    sec=$(bc <<< "${1}%60")
    printf "%02dHours, %02dMintues, %02dSeconds\n" $hr $min $sec
}

# Place Local Manifest in Place
function init_local_repo() {
    echo -e "\033[01;33m\nCopy local manifest.xml... \033[0m"
    mkdir -p .repo/local_manifests
    cp "$(dirname "$0")/local_manifest.xml" .repo/local_manifests/default.xml
}

# Initialize Pixel OS repository
function init_main_repo() {
    echo -e "\033[01;33m\nInit main repo... \033[0m"
    repo init -u https://github.com/PixelOS-Pixelish/manifest -b $branch --depth=1
}

# Start Sycing Repo
function sync_repo() {
    echo -e "\033[01;33m\nSync fetch repo... \033[0m"
    repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all) #SAVETIME
}

# Apply Patches (by @Raysenlau)
function apply_patches() {
    echo -e "\033[01;33m\nApplying patches... \033[0m"
    patches="$(readlink -f -- $1)"

    for project in $(cd $patches/patches; echo *);do
        p="$(tr _ / <<<$project)"
        [ "$p" == build ] && p=build/make
        repo sync -l --force-sync $p || continue
        pushd $p
        git clean -fdx; git reset --hard
        for patch in $patches/patches/$project/*.patch;do
            #Check if patch is already applied
            if patch -f -p1 --dry-run -R < $patch > /dev/null;then
                echo -e "\033[01;33m\n Already patched... \033[0m"
                continue
            fi

            if git apply --check $patch;then
                echo -e "\033[01;32m"
                git am $patch
                echo -e "\033[0m"
            elif patch -f -p1 --dry-run < $patch > /dev/null;then
                #This will fail
                echo -e "\033[32m"
                git am $patch || true
                patch -f -p1 < $patch
                git add -u
                git am --continue
                echo -e "\033[0m"
            else
                echo -e "\033[01;31m\n Failed applying $patch ... 033[0m"
            fi
        done
        popd
    done
}

# Setup Build Enviornment
function envsetup() {
    echo -e "\033[01;33m\nEnter Build Type
1.user
2.userdebug
3.eng \033[0m"
    read -p "" choice_buildtype
    if [[ $choice_buildtype == *"1"* ]]; then
        buildtype=user
    elif [[ $choice_buildtype == *"2"* ]]; then
        buildtype=userdebug
    elif [[ $choice_buildtype == *"3"* ]]; then
        buildtype=eng
    else
        echo "Invalid Option"
        envsetup
    fi
    echo -e "\033[01;33m\n---------------- Setting up build environment ---------------- \033[0m"
    export USE_CCACHE=1
    export CCACHE_EXEC=$(command -v ccache)
    export CUSTOM_BUILD_TYPE=OFFICIAL
    . build/envsetup.sh
    lunch aosp_davinci-$buildtype
    script_error
    make installclean
}

# start build and store time taken
function buildbacon() {
    buildstart=$(date +"%s")
    startbuild 2>&1 | tee log.txt
    buildstatus
    buildend=$(date +"%s")
    buildtime=$(($buildend - $buildstart))
    timefinal=$(timechange "$buildtime")
    build_error
}

function startbuild(){
    make bacon -j 20
    echo -e "$?" > Variable.txt
}

# Upload OTA build to sourceforge
function SourceforgeOTA() {
    echo -e "\033[01;33m\n-------------- Uploading Build to SourceForge -------------- \033[0m"
    rsync -Ph $Package twel12@frs.sourceforge.net:/home/frs/project/pixelos-notsopixel/$path/Davinci/
    echo -e "\033[01;31m\n-------------------- Upload Completed --------------------\033[0m"
}

# Test build updates
function testbuild(){
    telegram -c "-1001349538519" -M "Build Compilation Started for $rom

*Host*: $server
*Build Type*: Test
*Starting Time*: $(date)"
        buildbacon
        telegram -c "-1001349538519" -M "Test Build Successfully Completed for $rom

*Time Taken For Build*: $timefinal"
}

#Gdrive Upload
function Google(){
    export link=$(gdrive upload --share out/target/product/davinci/Pixel*.zip | awk '/File is/ {print $NF}') #thanks to @maade69 for simplifying logic
}

# Make Post for Release build
function TelegramOTA() {
    Google
    bash ~/telegram.sh/telegram -i ~/telegram.sh/$rom.jpg -c @fake_twel12 -M "#$rom #Android11 #Davinci #OTAUpdate
*$rom | Android 11.*
*Updated:* _ $update_date  _

▪️ [Download]("$DownloadLINK") | [Mirror]("$link")
▪️ [Changelog](https://raw.githubusercontent.com/PixelOS-Pixelish/OTA-Devices/$branch/davinci_changelogs.txt)
▪️ [Support](t.me/CatPower12)

*By* [Twel12]("t.me/real_twel12")
*Follow* @RedmiK20Updates
*Join* @RedmiK20GlobalOfficial"
sleep 5s #Make sure posted before msg
telegram -c @CatPower12 -M "Builds take _15-20_ mins to appear on sourceforge and ota + changelog might also take 5-10 mins, Please be *patient*."
echo -e "\033[01;31m\n--------------------- Post Created ^_^ ---------------------\033[0m"
}

# Upload Test Build
function TelegramTestPost() {
    Google
bash ~/telegram.sh/telegram -c -1001349538519 -M "#$rom #Android11 #Davinci #TestBuild
*$rom | Android 11*
UPDATE DATE - $update_date

> [Download (Gdrive)]("$link")

*This is a Test Build*
*Time Taken For Build*: $timefinal

*Built By* [Twel12]("t.me/real_twel12")
*Join* @CatPower12 "
}

# Generate OTA json
function OTA(){
    echo -e "\e[36m\e[1m---------------------------Automatic OTA FULL PACKAGE UPDATE---------------------------"
    cd /home/$server/OTA
    git add .
    git commit -m "SAVE CHANGES IF ANY"
    git switch $branch
    echo -e "{\"error\":false,\"maintainers\":[{\"main_maintainer\":false,\"github_username\":\"Twel12\",\"name\":\"Twel12\"}],\"donate_url\":\"\",\"website_url\":\"https://sourceforge.net/projects/pixelosdavinci/files/PixelOS_Davinci/\",\"datetime\":$ota,\"filename\": \"$NAME\",\"id\": \"$md5\",\"size\":$FILESIZE ,\"url\":\"$DownloadLINK\",\"version\": \"eleven\",\"filehash\":\"$md5\",\"is_incremental\":false,\"has_incremental\":false}" > /home/$server/OTA/davinci.json
    git add .
    git commit -m "Automatic OTA update"
    git push git@github.com:PixelOS-Pixelish/OTA-Devices.git HEAD:$branch -f
    cd $LOCAL_PATH
    echo -e "\e[36m\e[1m---------------------------Automatic OTA Update Done---------------------------"
}

# Function To Read Variable for build status
function buildstatus(){
    filename=Variable.txt
    while read line; do
    # reading each line
    exitcodez=$line
    done < $filename
}

# Store Some needed variables
function Variables(){
    Package=./out/target/product/davinci/Pixel*.zip
    FULLNAME=$(basename $(ls out/target/product/davinci/Pixel*.zip))
    ZIP_PATH=$(find ./out/target/product/davinci -maxdepth 1 -type f -name "Pixel*.zip" | sed -n -e "1{p;q}")
    NAME=$(basename $ZIP_PATH)
    FILESIZE=$(ls -al $ZIP_PATH | awk '{print $5}')
    md5=`md5sum $ZIP_PATH | awk '{ print $1 }'`
    DownloadLINK=https://sourceforge.net/projects/pixelos-notsopixel/files/$path/Davinci/"$NAME"/download
    ota=$(cat out/target/product/davinci/system/build.prop | grep ro.system.build.date.utc=)
    ota="${ota#*=}"
}

# Push OTA , POST and Upload build
function buildota() {
echo -e "\033[01;33m\n---------------------------------------------------------------------------------- \033[0m"
    SourceforgeOTA
    TelegramOTA
    OTA
}

# Build Options
function build() {
    read -p "What Type of Build Do You Want??
1. Test Build 
2. Test Build (Upload)
3. Release Build
" choice_build

    if [[ $choice_build == *"1"* ]]; then
        read -p "Do You Want Telegram Messages
1. Yes
2. No " telegramMSG
        echo -e "\033[01;33m\n---------------------------Starting Test Build (*^_^*)--------------------------- \033[0m"
        testbuild
    elif [[ $choice_build == *"2"* ]]; then
        testbuild
        TelegramTestPost
    elif [[ $choice_build == *"3"* ]]; then
        echo -e "\033[01;33m\n------------------------ Starting Release Build (～￣▽￣)～------------------------ \033[0m"
        telegram -c @CatPower12 -M "Build Compilation Started for $rom

*host*: $server
*Build Type*: Release
*Starting Time*: $(date)"
        buildbacon
        Variables
        buildota
    else
        echo "Invalid Option"
        build
    fi
}

# Initial function 
function helloworld() {
echo -e "\033[01;33m\nEnter the number from below for desired option.
> 1.Repo Sync
> 2.Start Bacon
> 3.Push OTA and Build

Enter Number: \033[0m"
read -p "" choice_script

    if [[ $choice_script == *"1"* ]]; then
        init_local_repo
        init_main_repo
        sync_repo
        script_error
        apply_patches patches
        read -p "Do You want to Start Bacon ??(y/n)" choice_bacon
        if [[ $choice_bacon == *"y"* ]]; then
            envsetup
            build
        else
            helloworld
        fi

    elif [[ $choice_script == *"2"* ]]; then
        envsetup
        build

    elif [[ $choice_script == *"3"* ]]; then
        if test -f out/target/product/davinci/$rom*.zip; then
            echo "Build Located! for $rom"
            Variables
            buildota
        else
            echo "You Dont have a build READY!!!"
        fi

    else
        echo -e "\033[01;33m\n---------------------------Invalid Option Entered--------------------------- \033[0m"
        exit

    fi
}

function start(){
    read -p "Choose Branch of ROM
1.PixelOS
2.Pixelish
" rom
    if [[ $rom == "1" ]];then
        rom=PixelOS
        branch=eleven
        path=Pixel_OS
    elif [[ $rom == "2" ]];then
        rom=PixelishExperience
        branch=eleven-plus
        path=Pixelish
    else
        echo "Enter Valid Choice"
        exit
    fi
        helloworld
}
firsttime
start
echo -e "\e[36m\e[1m---------------------------See Ya Later :P---------------------------"

# Turn off VM if host is not twel12 as twel12 is my local build system
if [[ $USER != 'twel12' ]];then
    sudo poweroff
fi
