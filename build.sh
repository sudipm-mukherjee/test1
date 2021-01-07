#!/bin/bash

process_blacklist() {
	cat cocci.blacklist | while read line; do
		var1=$(echo $line | cut -d ':' -f1 | sed 's/\//\\\//g')
		var2=`echo $line | cut -d ':' -f2`
		sed -i "/$var1.*$var2/d" $1
	done
}

next_tag=`date +%Y%m%d`

if [ "$1" == "clang" ]; then
	NR_CPU=$(cat /proc/cpuinfo | grep ^processor | wc -l)
	make CC=clang $2
	scripts/config -d CONFIG_DRM
	scripts/config -d CONFIG_SOUND
	scripts/config -d CONFIG_USB_SUPPORT
	make CC=clang olddefconfig
	make CC=clang clang-analyzer -j${NR_CPU} 2>&1 | tee clang_log
	tar -cjvf clang_log.tar.bz2 clang_log
elif [ "$1" == "clangbuild" ]; then
	tar -xf build.tar.bz2
	./keep_alive.sh &
	alive_pid=$!
	cd build
	echo "#!/bin/bash" > cla.sh
	echo "python3 ../scripts/clang-tools/run-clang-tools.py clang-analyzer compile_commands.json 2>&1" >> cla.sh
	chmod a+x cla.sh
	timeout -s KILL 175m ./cla.sh | tee clang_log
	kill -9 $alive_pid
	sed -i 's/\.\.\///g' clang_log
	tail -n 10 clang_log
	tar -cjvf ../clang_log.tar.bz2 clang_log
elif [ "$1" == "cocci1" ]; then
	rm -rf scripts/coccinelle/iterators
	rm -rf scripts/coccinelle/locks
	rm -rf scripts/coccinelle/misc
	rm -rf scripts/coccinelle/null
	rm -rf scripts/coccinelle/tests
	./keep_alive.sh &
	alive_pid=$!
	timeout -s KILL 165m make coccicheck | tee cocci_err1
	kill -9 $alive_pid
	tar -cjvf cocci_err1.tar.bz2 cocci_err1
elif [ "$1" == "cocci2" ]; then
	rm -rf scripts/coccinelle/api
	rm -rf scripts/coccinelle/free
	rm -rf scripts/coccinelle/misc
	rm -rf scripts/coccinelle/null
	rm -rf scripts/coccinelle/tests
	./keep_alive.sh &
	alive_pid=$!
	timeout -s KILL 165m make coccicheck | tee cocci_err2
	kill -9 $alive_pid
	tar -cjvf cocci_err2.tar.bz2 cocci_err2
elif [ "$1" == "cocci3" ]; then
	rm -rf scripts/coccinelle/api
	rm -rf scripts/coccinelle/free
	rm -rf scripts/coccinelle/iterators
	rm -rf scripts/coccinelle/locks
	rm -rf scripts/coccinelle/null
	rm -rf scripts/coccinelle/tests
	./keep_alive.sh &
	alive_pid=$!
	timeout -s KILL 165m make coccicheck | tee cocci_err3
	kill -9 $alive_pid
	tar -cjvf cocci_err3.tar.bz2 cocci_err3
elif [ "$1" == "cocci4" ]; then
	rm -rf scripts/coccinelle/api
	rm -rf scripts/coccinelle/free
	rm -rf scripts/coccinelle/iterators
	rm -rf scripts/coccinelle/locks
	rm -rf scripts/coccinelle/misc
	rm -rf scripts/coccinelle/tests
	./keep_alive.sh &
	alive_pid=$!
	timeout -s KILL 165m make coccicheck | tee cocci_err4
	kill -9 $alive_pid
	tar -cjvf cocci_err4.tar.bz2 cocci_err4
elif [ "$1" == "cocci5" ]; then
	rm -rf scripts/coccinelle/api
	rm -rf scripts/coccinelle/free
	rm -rf scripts/coccinelle/iterators
	rm -rf scripts/coccinelle/locks
	rm -rf scripts/coccinelle/misc
	rm -rf scripts/coccinelle/null
	./keep_alive.sh &
	alive_pid=$!
	timeout -s KILL 165m make coccicheck | tee cocci_err5
	kill -9 $alive_pid
	tar -cjvf cocci_err5.tar.bz2 cocci_err5
elif [ "$1" == "smatchdb" ]; then
	cp defconfig .config
	make $2
	if [ -e backup.tar.bz2 ]; then
		tar -xjvf backup.tar.bz2
		cp -r smatchbackup/smatch_data /smatch/.
		cp smatchbackup/smatch_db.sqlite .
	else
		echo "backup.tar.bz2 not found"
	fi
	scripts/config -d CONFIG_DRM
	scripts/config -d CONFIG_SOUND
	scripts/config -d CONFIG_USB_SUPPORT
	scripts/config -d CONFIG_WLAN
	scripts/config -d CONFIG_WIRELESS
	scripts/config -d CONFIG_NFC
	scripts/config -d CONFIG_MEDIA_SUPPORT
	scripts/config -d CONFIG_SUSPEND
	make olddefconfig
	./keep_alive.sh &
	alive_pid=$!
	/smatch/smatch_scripts/build_kernel_data.sh
	kill -9 $alive_pid
	mkdir -p smatchbackup
	rm -rf smatchbackup/*
	cp smatch_db.sqlite smatchbackup/. || true
	cp -r /smatch/smatch_data smatchbackup/.
	tar -cjvf ./backup.tar.bz2 smatchbackup
elif [ "$1" == "smatchdb2" ]; then
	NR_CPU=$(cat /proc/cpuinfo | grep ^processor | wc -l)
	export ARCH=x86_64
	export CROSS_COMPILE=/x86_64-linux/bin/x86_64-linux-
	make $2
	if [ -e backup.tar.bz2 ]; then
		tar -xjvf backup.tar.bz2
		cp -r smatchbackup/smatch_data /smatch/.
		cp smatchbackup/smatch_db.sqlite .
		rm -rf smatchbackup
		rm backup.tar.bz2
	else
		echo "backup.tar.bz2 not found"
	fi
	scripts/config -d CONFIG_DRM
	scripts/config -d CONFIG_SOUND
	scripts/config -d CONFIG_USB_SUPPORT
	make olddefconfig
	nice -n 5 ./keep_alive.sh &
	alive_pid=$!
	/smatch/smatch_scripts/build_kernel_data.sh
	kill -9 $alive_pid
	mkdir -p smatchbackup
	rm -rf smatchbackup/*
	cp smatch_db.sqlite smatchbackup/. || true
	cp -r /smatch/smatch_data smatchbackup/.
	tar -cjvf ./backup.tar.bz2 smatchbackup
elif [ "$1" == "smatch" ]; then
	cp defconfig .config
	export ARCH=x86_64
	export CROSS_COMPILE=/x86_64-linux/bin/x86_64-linux-
	make $2
	if [ -e backup.tar.bz2 ]; then
		tar -xjvf backup.tar.bz2
		cp -r smatchbackup/smatch_data /smatch/.
		cp smatchbackup/smatch_db.sqlite .
	else
		echo "backup.tar.bz2 not found"
	fi
	scripts/config -d CONFIG_DRM
	scripts/config -d CONFIG_SOUND
	scripts/config -d CONFIG_USB_SUPPORT
	scripts/config -d CONFIG_WLAN
	scripts/config -d CONFIG_WIRELESS
	scripts/config -d CONFIG_NFC
	scripts/config -d CONFIG_MEDIA_SUPPORT
	scripts/config -d CONFIG_SUSPEND
	make olddefconfig
	/smatch/smatch_scripts/test_kernel.sh --print-names
	tar -cjvf smatch_warns.txt.tar.bz2 smatch_warns.txt
elif [ "$1" == "report" ]; then
	source /codechecker/venv/bin/activate
	export PATH=$PATH:/codechecker/CodeChecker/bin
	tar -xf smatch_warns.txt.tar.bz2
	tar -xf clang_log.tar.bz2
	tar -xf cocci_err1.tar.bz2
	tar -xf cocci_err2.tar.bz2
	tar -xf cocci_err3.tar.bz2
	tar -xf cocci_err4.tar.bz2
	tar -xf cocci_err5.tar.bz2
	report-converter -t clang-tidy -o report_out1 clang_log
	echo "clang-tidy done"
	echo "starting smatch"
	report-converter -t smatch -o report_out2 smatch_warns.txt
	echo "smatch done"
	process_blacklist cocci_err1
	report-converter -t coccinelle -o report_out3 cocci_err1
	echo "cocci1 done"
	report-converter -t coccinelle -o report_out4 cocci_err2
	echo "cocci2 done"
	report-converter -t coccinelle -o report_out5 cocci_err3
	echo "cocci3 done"
	report-converter -t coccinelle -o report_out6 cocci_err4
	echo "cocci4 done"
	report-converter -t coccinelle -o report_out7 cocci_err5
	echo "cocci5 done"
	mkdir -p report_out
	cp -r report_out1/* report_out/.
	cp -r report_out2/* report_out/.
	cp -r report_out3/* report_out/.
	cp -r report_out4/* report_out/.
	cp -r report_out5/* report_out/.
	cp -r report_out6/* report_out/.
	cp -r report_out7/* report_out/.
	echo "starting html gen"
	CodeChecker parse -e html -o ./reports_html report_out
fi
