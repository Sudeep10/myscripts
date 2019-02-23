 #
 # Script For Building Android arm Kernel 
 #
 # Copyright (c) 2018-2019 Panchajanya1999 <rsk52959@gmail.com>
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #      http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 # 
 
#! /bin/sh

#Kernel building script

KERNEL_DIR=$PWD

function colors {
	blue='\033[0;34m' cyan='\033[0;36m'
	yellow='\033[0;33m'
	red='\033[0;31m'
	nocol='\033[0m'
}


function clone {
	echo " "
	echo "{yellow}★★Cloning UberTc Toolchain from Android GoogleSource ..{nocol}"
	sleep 2
	git clone --depth 1 --no-single-branch https://bitbucket.org/UBERTC/arm-eabi-4.9.git
	echo "{blue}★★GCC cloning done{nocol}"
	sleep 2
	echo "{cyan}★★Cloning Kinda Done..!!!{nocol}"
}

function exports {
	export KBUILD_BUILD_USER="ci"
	export KBUILD_BUILD_HOST="semaphore"
	export ARCH=arm
	export SUBARCH=arm
}

function tg_post_msg {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" -d text="$1"
}

function tg_post_build {
	curl -F chat_id="$2" -F document=@"$1" $BOT_BUILD_URL
}

function build_kernel {
	#better checking defconfig at first
	if [ -f $KERNEL_DIR/arch/arm/configs/cyanogenmod_ms013g_defconfig ]
	then 
		DEFCONFIG=cyanogenmod_ms013g_defconfig
	else
		echo "{red}Defconfig Mismatch..!!!{nocol}"
		tg_post_msg "☠☠Defconfig Mismatch..!! Build Failed..!!👎👎" "$GROUP_ID"
		echo "{red}Exiting in 5 seconds...{nocol}"
		sleep 5
		exit
	fi
	export CROSS_COMPILE=$KERNEL_DIR/arm-eabi-4.9/bin/arm-eabi-
	make $DEFCONFIG
	BUILD_START=$(date +"%s")
	tg_post_msg "★★ Build Started on $(uname) $(uname -r) ★★" "$GROUP_ID"

	make -j8 2>&1 | tee logcat.txt
	BUILD_END=$(date +"%s")
	BUILD_TIME=$(date +"%Y%m%d-%T")
	DIFF=$((BUILD_END - BUILD_START))	
}

function check_img {
	if [ -f $KERNEL_DIR/arch/arm/boot/zImage ]
	then 
		echo -e "{yellow}Kernel Built Successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds..!!{nocol}"
		tg_post_msg "👍👍Kernel Built Successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds..!!" "$GROUP_ID"
		gen_changelog
		cd arch/arm/boot
		tg_post_build "zImage" "$GROUP_ID"
		#gen_zip
	else 
		echo -e "{red}Kernel failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds..!!{nocol}"
		tg_post_msg "☠☠Kernel failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds..!!" "$GROUP_ID"
		tg_post_build "logcat.txt" "$GROUP_ID"
	fi	
}

function gen_changelog {
	tg_post_msg "★★ ChangeLog --
	$(git log --oneline --decorate --color --pretty=%s --first-parent -7)" "$GROUP_ID"
}

function gen_zip {
	if [ -f $KERNEL_DIR/out/arch/arm/boot/Image.gz-dtb ]
	then 
		echo "{yellow}Zipping Files..{nocol}"
		mv $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb AnyKernel2/Image.gz-dtb
		cd AnyKernel2
		zip -r9 AzurE-X00TD-$BUILD_TIME * -x .git README.md
		tg_post_build "AzurE-X00TD-$BUILD_TIME.zip" "$GROUP_ID"
		cd ..
	fi
}

colors
clone
exports
build_kernel
check_img
