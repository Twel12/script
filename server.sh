#!/bin/bash

# Recommended For Ubuntu 18.04 or Higher
export LC_ALL=C

echo -e "\e[36m\e[1m---------------------------Random Script By Twel12---------------------------"

# Some Useful Stuff
ota=$(date +"%s")
server=$USER
update_date=`date '+%Y-%m-%d'`
LOCAL_PATH="$(pwd)"
telegramMSG=1 #Enable Message By Default Unlike for test builds

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

function script_error2() {
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
    repo init -u https://github.com/PixelOS-and-Not-So-Pixel/manifest -b eleven
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
    #make installclean
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
    rsync -Ph $Package twel12@frs.sourceforge.net:/home/frs/project/pixelos-notsopixel/Pixel_OS/Davinci/
    echo -e "\033[01;31m\n-------------------- Upload Completed --------------------\033[0m"
}

# test build updates
function testbuild(){
    telegram -c "-1001349538519" -M "Build Compilation Started for PixelOS

*Android Version*: 11
*Host*: $server
*Build Type*: Test
*Starting Time*: $(date)"
        buildbacon
        telegram -c "-1001349538519" -M "Test Build Successfully Completed for PixelOS

*Android Version*: 11
*Time Taken For Build*: $timefinal"
}

# Make Post for Release build
function TelegramOTA() {
bash ~/telegram.sh/telegram -i ~/telegram.sh/hello.jpg -c @fake_twel12 -M "#PixelOS #Android11 #Davinci #OTAUpdate
*PixelOS | Android 11*
*Updated* - $update_date

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
function TelegramTestPost() {
    rsync -Ph out/target/product/davinci/PixelOS*zip twel12@frs.sourceforge.net:/home/frs/project/pixelosdavinci/TestBuilds/
telegram -c  -M "Test Build Successfully Completed for PixelOS

*Android Version*: 11
*Time Taken For Build*: $timefinal"
bash ~/telegram.sh/teleexport exitcodez=$?gram -c "-1001349538519" -M "#PixelOS #Android11 #Davinci #TestBuild
*PixelOS | Android 11*
UPDATE DATE - $update_date

*This is a Test Build*
> [Download (Sourceforge)]("https://sourceforge.net/projects/pixelosdavinci/files/TestBuilds/$(basename $(ls out/target/product/davinci/PixelOS*.zip))")

*Built By* [Twel12]("t.me/real_twel12")
*Join* @CatPower12 "
}

# Generate OTA json
function OTA() {
    echo -e "\e[36m\e[1m---------------------------Automatic OTA FULL PACKAGE UPDATE---------------------------"
echo -e "{\"error\":false,\"maintainers\":[{\"main_maintainer\":false,\"github_username\":\"Twel12\",\"name\":\"Twel12\"}],\"donate_url\":\"\",\"website_url\":\"https://sourceforge.net/projects/pixelosdavinci/files/PixelOS_Davinci/\",\"datetime\":1608565724,\"filename\": \"$NAME\",\"id\": \"$md5\",\"size\":$FILESIZE ,\"url\":\"$DownloadLINK\",\"version\": \"eleven\",\"filehash\":\"$md5\",\"is_incremental\":false,\"has_incremental\":false}" > /home/$server/OTA/davinci.json
cd /home/$server/OTA
git add .
git commit -S -m "Automatic OTA update"
if [[ $choice_build == *"4"* ]]; then
    git push git@github.com:PixelOS-and-Not-So-Pixel/OTA-Devices.git HEAD:eleven -f
fi
cd $LOCAL_PATH
echo -e "\e[36m\e[1m---------------------------Automatic OTA Update Done---------------------------"
}

#Push Ota and Build
function OTAandPush(){
    SourceforgeOTA
    cd /home/$server/OTA
    git push git@github.com:PixelOS-and-Not-So-Pixel/OTA-Devices.git HEAD:eleven -f
    cd $LOCAL_PATH
    TelegramOTA
}

#Function To Read Variable for build status
function buildstatus(){
    #!/bin/bash
filename=Variable.txt
while read line; do
# reading each line
exitcodez=$line
done < $filename
}


# Store Some needed variables
function Variables(){
    Package=./out/target/product/davinci/PixelOS*.zip
    FULLNAME=$(basename $(ls out/target/product/davinci/PixelOS*.zip))
    ZIP_PATH=$(find ./out/target/product/davinci -maxdepth 1 -type f -name "PixelOS*.zip" | sed -n -e "1{p;q}")
    NAME=$(basename $ZIP_PATH)
    FILESIZE=$(ls -al $ZIP_PATH | awk '{print $5}')
    md5=`md5sum $ZIP_PATH | awk '{ print $1 }'`
    DownloadLINK=https://sourceforge.net/projects/pixelos-notsopixel/Pixel_OS/Davinci/"$NAME"/download

}

# Push OTA , POST and Upload build
function buildota() {
echo -e "\033[01;33m\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ \033[0m"
    SourceforgeOTA
    TelegramOTA
    OTA
}

# Build Options
function build() {
    read -p "What Type of Build Do You Want??
1. Test Build 
2. Test Build (Upload)
3. Release Build (HOLD)
4. Release Build (PUSH)  " choice_build

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
        telegram -c @CatPower12 -M "Build Compilation Started for PixelOS

*Android Version*: 11
*Build Type*: Release
*Starting Time*: $(date)"
        buildbacon
        echo "Making File For Checking OTA"
        echo -e Henlo > IEXIST.txt # Create A File for OTA Check LATER
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
        FILE=IEXIST.txt
        if test -f "$FILE"; then
            echo "Pushing OTA"
            OTAandPush
            rm -rf IEXIST.txt #Remove File for next time until regenerated
        else
            echo "You dont have an update repo so you cant push OTA"
        fi

    else
        echo -e "\033[01;33m\n---------------------------Invalid Option Entered--------------------------- \033[0m"
        exit

    fi
}

# Some Check For First Times
function firsttime() {
    echo "Performing Some Tests before running scripts"
if stat --printf='' /home/$server/OTA 2>/dev/null; then
    echo "OTA Folder Check Complete."
else
    echo -e "\033[01;31m\n Failed Finding OTA Folder \n "
    echo "Cloning OTA Folder"
    git clone https://github.com/PixelOS-and-Not-So-Pixel/OTA-Devices /home/$server/OTA
fi

if stat --printf='' /home/$server/telegram.sh 2>/dev/null; then
    echo "telegram script check complete"
else
    echo -e "\033[01;31m\n Failed Finding Telegram Folder 033[0m"
    git clone https://github.com/Twel12/telegram.sh /home/$server/telegram.sh
fi

}

firsttime
helloworld
echo -e "\e[36m\e[1m---------------------------See Ya Later :P---------------------------"