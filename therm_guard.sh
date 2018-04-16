#!/bin/bash

# gov files
GOVDIR=/sys/devices/system/cpu/cpufreq/policy0
FREQFILE=$GOVDIR/scaling_available_frequencies
MAXFREQFILE=$GOVDIR/scaling_max_freq

# therm files
THERMDIR=/sys/class/hwmon/hwmon0/device
THERMFILE=$THERMDIR/temp3_input

# limits in Celsius ( = (Fahrenheit-32) * 5 / 9)
HOT=65
COOL=50

freqs=( $(cat $FREQFILE | sed 's/ /\
	/g' | sort -n | grep ..) )
maxfreq=$(cat $FREQFILE | wc -w)
(( maxfreq -= 1 )) # freqs[] is a zero-based array

curfreq=$maxfreq

# forever
while [ "A" == "A" ] ; do
	curtmp=$(cat $THERMFILE)
	curtmp=${curtmp:0:2} # just the first 2 digits
	if [ $curtmp -le $COOL -a $curfreq -eq $maxfreq ] ; then
		sleep 20
	else
		sleep 5
		changed=NO
		if [ $curtmp -ge $HOT ] ; then
			if [ $curfreq -gt 0 ] ; then
				# clamping
				(( curfreq -= 1 ))
				changed=YES
			fi
		fi
		if [ $curtmp -le $COOL ] ; then
			if [ $curfreq -lt $maxfreq ] ; then
				# releasing
				(( curfreq += 1 ))
				changed=YES
			fi
		fi

		# set new maximum CPU frequency
		[ $changed == "YES" ] && echo ${freqs[$curfreq]} > $MAXFREQFILE
	fi
done
