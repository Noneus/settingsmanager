#!/bin/sh

HOME="$HOME"
SETTINGSDIR="$(cd "$(dirname "$0")"; pwd)"
SETTINGSDB="$SETTINGSDIR/settingsdb"

getanswer() {
	echo -n "$1 [y/n] "
	read answer
	while [ "$answer" != "y" ] && [ "$answer" != "n" ]; do
		echo -n "$1 [y/n]"
		read answer
	done
	[ "$answer" == "y" ] && return 0 || return 1
}

conv_space_to() {
	echo "$1" | sed "s/ /####/g"
}

conv_space_from() {
	echo "$1" | sed "s/####/ /g"
}

settingexist() {
	[ ! -f "$SETTINGSDB" ] && return 0
	[ "X$(cat "$SETTINGSDB" | cut -f 2 -d ' ')" != "X" ] && return 1 || return 0
}

print_help() {
	echo "$0 - Settings Manager

USAGE:
	$0 [COMMAND] [OPTIONS ...]

COMMANDS:
	add [SOURCEDIR]: add a new Settings
	createall: create all Settings
	showall: showall settings
"
}

if [ $# -eq 0 ]; then
	print_help
fi

case "$1" in
	add)
		#ensure setting is in homedir and strip homedir from absolute path
		SETTING="$(readlink -f "$2")"
		if [ "X$(echo $SETTING | grep $HOME)" = "X" ]; then
			echo "ERROR: New setting '$SETTING' is not in the home directory!"
			exit 1
		fi
		SETTING="$(echo "$SETTING" | sed "s@$HOME/@@g")"
		
		#check if starting with a .
		if [ "$(echo $SETTING | cut -b 1)" != "." ]; then
			getanswer "Really a setting? Does not start with a dot. Continue?"
			[ $? -ne 0 ] && exit 0
		fi
		
		#calculate new relpath
		STOREPATH=$SETTING
		if [ "`dirname "$SETTING"`" != "$HOME" ]; then
			STOREPATH="$(basename $SETTING)"
		fi
		if [ "$(echo $STOREPATH | cut -b 1)" == "." ]; then
			STOREPATH="$(echo $STOREPATH | cut -b 2-)"
		fi
		STOREPATH=$(echo $STOREPATH | sed "s/ /__/g")

		#error if already exists
		settingexist $(conv_space_to $STOREPATH)
		if [ $? -eq 1 ]; then
			echo "ERROR: Setting $STOREPATH does already exist."
			exit 1
		fi

		#move to settingsdir and symnlink
		echo "moving setting '$HOME/$SETTING' to '$SETTINGSDIR/$STOREPATH'"
		echo $(conv_space_to $SETTING) $STOREPATH >> "$SETTINGSDB"
		mv "$HOME/$SETTING" "$SETTINGSDIR/$STOREPATH"
		ln -s "$SETTINGSDIR/$STOREPATH" "$HOME/$SETTING"
		;;
	showall)
		#exit if it does not exist
		if [ ! -f "$SETTINGSDB" ]; then
			echo "No settings yet."
			exit 0
		fi

		#print line by line
		cat "$SETTINGSDB" | while read LINE
		do
			SETTING="$(conv_space_from $(echo $LINE | cut -f 1 -d ' '))"
			STOREPATH=$(echo $LINE | cut -f 2 -d ' ')
			echo "\"$SETTING\" -> \"$STOREPATH\""
		done
		;;
	#symlink all settings if they do not exist
	createall)
		#exit if it does not exist
		if [ ! -f "$SETTINGSDB" ]; then
			echo "No settings yet."
			exit 0
		fi

		#create settings line by line
		cat "$SETTINGSDB" | while read LINE
		do
			SETTING="$(conv_space_from $(echo $LINE | cut -f 1 -d ' '))"
			STOREPATH=$(echo $LINE | cut -f 2 -d ' ')
			
			if [ -e "$HOME/$SETTING" ]; then
				echo "Ommitting \"$SETTING\". Already exists."
			else
				echo "\"$SETTINGSDIR/$STOREPATH\" -> \"$SETTING\""
				if [ ! -d "$(dirname "$HOME/$SETTING")" ]; then
					mkdir -p "$(dirname "$HOME/$SETTING")"
				fi
				ln -s "$SETTINGSDIR/$STOREPATH" "$HOME/$SETTING"
			fi
		done
		;;
	#print help on rest
	*)
		print_help
		;;
esac