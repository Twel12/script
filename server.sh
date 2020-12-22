#!/bin/bash

# Recommended For Ubuntu 18.04 or Higher
export LC_ALL=C

echo -e "\e[36m\e[1m---------------------------PixelOS Script By Twel12---------------------------"

# Some Useful Stuff
ota=$(date +"%s")
update_date=$(date +'%d %B %Y')
LOCAL_PATH="$(pwd)"

# Telegram
telegram () {
  ~/telegram.sh/telegram "$1" "$2" "$3" "$4" "$5"
}

# Function to Check Error Kanged From Daniel
function build_error() {
exit_code=$?
buildend=$(date +"%s")
buildtime=$(($buildend - $buildstart))
timefinal=$(timechange "$buildtime")
if [[ $exit_code != 0 ]]; then
	if [[ $1 != "" ]]; then
		echo "$1"
		echo "Exiting with status $exit_code"
		telegram -c @CatPower12 "Build Failed at $timefinal"
	else
		echo "An error was detected, exiting"
		telegram -c @CatPower12 "An Error Was Detected Build Failed at $timefinal"
	fi
	exit $exit_code
fi
}

function script_error() {
exit_code=$?
if [[ $exit_code != 0 ]]; then
	if [[ $1 != "" ]]; then
		echo "Exiting with status $exit_code"
	else
		echo "An error was detected, exiting"
	fi
	exit $exit_code
fi
}

#Time
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

# Initialize Pixel Experience repository
function init_main_repo() {
    echo -e "\033[01;33m\nInit main repo... \033[0m"
    repo init -u https://github.com/PixelExperience/manifest -b eleven
}

# Start Sycing Repo
function sync_repo() {
    echo -e "\033[01;33m\nSync fetch repo... \033[0m"
    repo sync -c -q --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all) #SAVETIME
}

# Apply Patches
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
    elif [[ $choice_buildtype == *"1"* ]]; then
        buildtype=userdebug
    elif [[ $choice_buildtype == *"1"* ]]; then
        buildtype=eng
    else
        echo "Invalid Option"
        envsetup
    fi
    echo -e "\033[01;33m\n---------------- Setting up build environment ---------------- \033[0m"
    ccache -M 70G
    export USE_CCACHE=1
    export CCACHE_EXEC=$(command -v ccache)
    export CUSTOM_BUILD_TYPE=OFFICIAL
    . build/envsetup.sh
    lunch aosp_davinci-$buildtype
    make installclean
}


function sourceforgeOTA() {
    echo -e "\033[01;33m\n-------------- Uploading Build to SourceForge -------------- \033[0m"
    rsync -Ph $Package twel12@frs.sourceforge.net:/home/frs/project/pixelosdavinci/PixelOS_Davinci/
    echo -e "\033[01;31m\n-------------------- Upload Completed --------------------\033[0m"
}

# Make Post

function POSTOTA() {
bash ~/telegram.sh/telegram -i ~/telegram.sh/hello.jpg -c @fake_twel12 -M "#PixelOS #Android11 #Davinci #OTAUpdate

*PixelOS | Android 11*
UPDATE DATE - _ $update_date _

▪️ [Download]("$DownloadLINK")
▪️ [Chat](t.me/CatPower12)
▪️ [Changelog](https://raw.githubusercontent.com/PixelOS-and-Not-So-Pixel/OTA-Devices/eleven/davinci_changelogs.txt)
*Built By* [Twel12]("t.me/real_twel12")

*Follow* @RedmiK20Updates
*Join* @RedmiK20GlobalOfficial"
telegram -c @CatPower12 -M "Builds take _15-20_ mins To Appear As Sourceforge is slow, Please be *patient*."
echo -e "\033[01;31m\n--------------------- Post Created ^_^ ---------------------\033[0m"
}

# Upload Test Build
function PostTEST() {
    rsync -Ph out/target/product/davinci/PixelOS*zip twel12@frs.sourceforge.net:/home/frs/project/pixelosdavinci/TestBuilds/
bash ~/telegram.sh/telegram -c -1001490386589 -M "#PixelOS #Android11 #Davinci #TestBuild
*PixelOS | Android 11*
UPDATE DATE - $update_date

*This is a Test Build*
> [Download (Sourceforge)]("https://sourceforge.net/projects/pixelosdavinci/files/TestBuilds/$(basename $(ls out/target/product/davinci/PixelOS*.zip))")

*Built By* [Twel12]("t.me/real_twel12")
*Join* @CatPower12 "
}

# OTA Full Zip
function OTA() {
    echo -e "\e[36m\e[1m---------------------------Automatic OTA FULL PACKAGE UPDATE---------------------------"
echo -e "{\"error\":true,\"maintainers\":[{\"main_maintainer\":false,\"github_username\":\"Twel12\",\"name\":\"Twel12\"}],\"donate_url\":\"\",\"website_url\":\"https://sourceforge.net/projects/pixelosdavinci/files/PixelOS_Davinci/\",\"datetime\":1608565724,\"filename\": \"$NAME\",\"id\": \"$md5\",\"size\":$FILESIZE ,\"url\":\"$DownloadLINK\",\"version\": \"eleven\",\"filehash\":\"$md5\",\"is_incremental\":false,\"has_incremental\":false}" > /home/shivansh/OTA/davinci.json
cd /home/shivansh/OTA
git add .
git commit -m "Automatic OTA update"
git push git@github.com:PixelOS-and-Not-So-Pixel/OTA-Devices.git HEAD:eleven -f
cd $LOCAL_PATH
echo -e "\e[36m\e[1m---------------------------Automatic OTA Update Done---------------------------"
}

function buildota() {
echo -e "\033[01;33m\n++++++++++++++++++++++++++++ \033[0m"
    Package=./out/target/product/davinci/PixelOS*.zip
    FULLNAME=$(basename $(ls out/target/product/davinci/PixelOS*.zip))
    ZIP_PATH=$(find ./out/target/product/davinci -maxdepth 1 -type f -name "PixelOS*.zip" | sed -n -e "1{p;q}")
    NAME=$(basename $ZIP_PATH)
    FILESIZE=$(ls -al $ZIP_PATH | awk '{print $5}')
    md5=`md5sum $ZIP_PATH | awk '{ print $1 }'`
    DownloadLINK=https://sourceforge.net/projects/pixelosdavinci/files/PixelOS_Davinci/"$NAME"/download
    sourceforgeOTA
    POSTOTA
    OTA
}

function buildbacon() {
    buildstart=$(date +"%s")
    make bacon -j$(nproc --all)
    build_error
    buildend=$(date +"%s")
    buildtime=$(($buildend - $buildstart))
    timefinal=$(timechange "$buildtime")
}

# Clean Repo
function clean_repo() {
    rm -rf .repo/manifests && echo ".repo/manifests/ --- deleted"
    rm -rf .repo/manifests.git && echo ".repo/manifests.git --- deleted"
    rm -rf .repo/repo && echo ".repo/repo/ --- deleted"
    rm -rf .repo/manifest.xml && echo ".repo/manifest.xml --- deleted"
    rm -rf .repo/project.list && echo ".repo/project.list --- deleted"
    rm -rf .repo/.repo_fetchtimes.json && echo ".repo/.repo_fetchtimes.json --- deleted"
    rm -rf patches && echo "patches --deleted"
    echo -e "\033[01;33m\n Clean Successed !!! \033[0m"
    echo -e "\033[01;32m\n Now you can sync new repo ... \033[0m"
}

# Build Options
function build() {
    read -p "What Type of Build Do You Want??
1. Test Build
2. Test Build (Upload)
3. Release Build  " choice_build

    if [[ $choice_build == *"1"* ]] || [[ $choice_build == *"2"* ]]; then
        echo -e "\033[01;33m\n---------------------------Starting Test Build (*^_^*)--------------------------- \033[0m"
        telegram -c @CatPower12 -M "Build Compilation Started for PixelOS

*Android Version*: 11
*Build Type*: Test
*Starting Time*: $(date)"
        buildbacon
        telegram -c @CatPower12 -M "Test Build Successfully Completed for PixelOS

*Android Version*: 11
*Time Taken For Build*: $timefinal"
        if [[ $choice_build == *"2"* ]]; then
            PostTEST
        fi
    elif [[ $choice_build == *"3"* ]]; then
        echo -e "\033[01;33m\n------------------------ Starting Release Build (～￣▽￣)～------------------------ \033[0m"
        telegram -c @CatPower12 -M "Build Compilation Started for PixelOS

*Android Version*: 11
*Build Type*: Release
*Starting Time*: $(date)"
        buildbacon
        buildota
    else
        echo "Invalid Option"
        build
    fi
}

# Start The Script (USING HELLO WORLD CAUSE WHY NOT ITS THE FIRST STEP TO CODING)
function helloworld() {
echo -e "\033[01;33m\nEnter the number from below for desired option.
> 1.Repo Sync
> 2.Start Bacon
> 3.Clean Repo

Enter Number: \033[0m"
read -p "" choice_script

    if [[ $choice_script == *"1"* ]]; then
        init_local_repo
        init_main_repo
        sync_repo
        script_error
        apply_patches patches
        envsetup
        read -p "Do You want to Start Bacon ??(y/n)" choice_bacon
        if [[ $choice_bacon == *"y"* ]]; then
            build
        else
            helloworld
        fi
    elif [[ $choice_script == *"2"* ]]; then
        envsetup
        build
    elif [[ $choice_script == *"3"* ]]; then
        clean_repo
    else
        echo -e "\033[01;33m\n---------------------------Invalid Option Entered--------------------------- \033[0m"
        exit
    fi
}

helloworld
echo -e "\e[36m\e[1m---------------------------See Ya Later :P---------------------------"