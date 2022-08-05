#!/bin/bash

# NETEASE_API_LYRICS='http://music.163.com/api/song/media'
# NETEASE_API_METADATA='http://music.163.com/api/search/get'

# NETEASE_SONG_ID=1458398560
# NETEASE_QUERY="Diamond Eyes,23"

search_song() {
	NETEASE_RQ=$(curl -s --get "http://music.163.com/api/search/get" --data "type=1" --data "limit=1" --data-urlencode "s=$1")

	echo -e ""
	echo "${NETEASE_RQ}"

	NETEASE_SONG_ID=$(echo "${NETEASE_RQ}" | jq '.result.songs[0].id')
	return "${NETEASE_SONG_ID}"
}

fetch_song_by_id() {
	echo -e "Getting metadata for song ID ${NETEASE_SONG_ID}"
	echo -e ""

	NETEASE_RQ=$(curl -s --get "http://music.163.com/api/search/get" \
	--data "type=1" \
	--data "limit=1" \
	--data-urlencode "s=${NETEASE_SONG_ID}")

	echo -e ""
	echo "${NETEASE_RQ}"
	echo -e ""

	NETEASE_SONG_NAME=$(echo "${NETEASE_RQ}" | jq --raw-output '.result.songs[0].name')
	NETEASE_ARTIST_NAME=$(echo "${NETEASE_RQ}" | jq --raw-output '.result.songs[0].artists[0].name')
	# NETEASE_ALBUM_ID=$(echo "${NETEASE_RQ}" | jq '.result.songs[0].album.id')
	NETEASE_ALBUM_NAME=$(echo "${NETEASE_RQ}" | jq --raw-output '.result.songs[0].album.name')
}

fetch_lyrics() {
	echo -e "Fetching lyrics ..."

	NETEASE_RQ=$(curl -s --get "http://music.163.com/api/song/media" \
	--data "csrf_token=" \
	--data "hlpretag=" \
	--data "hlposttag=" \
	--data "type=1" \
	--data "offset=0" \
	--data "total=true" \
	--data "limit=1" \
	--data-urlencode "id=${NETEASE_SONG_ID}")

	echo -e ""
	echo "${NETEASE_RQ}"

	NETEASE_LYRICS=$(echo "${NETEASE_RQ}" | jq -r '.lyric')

	# echo -e "${NETEASE_LYRICS}\n"
}

save_lrc() {
	echo "Saving LRC file for song ID ${NETEASE_SONG_ID}"

	NETEASE_LRC_PATH="./.163lrc/${NETEASE_ARTIST_NAME}/${NETEASE_ALBUM_NAME}"
	
	NETEASE_LRC_FILE="${NETEASE_LRC_PATH}/${NETEASE_ARTIST_NAME} - ${NETEASE_SONG_NAME}"
	
	mkdir -p "${NETEASE_LRC_PATH}" && echo "${NETEASE_LYRICS}" >"${NETEASE_LRC_FILE}.lrc" && echo -e "Saved LRC to ${NETEASE_LRC_FILE}"

	echo -e ""
}

main() {
# 	cat <<- EOM

# _____ _______ _______ __           
# | _   |   _   |   _   |  .----.----.
# |.|   |   1___|___|   |  |   _|  __|
# \`-|.  |.     \ _(__   |__|__| |____|
#   |:  |:  1   |:  1   |             
#   |::.|::.. . |::.. . |             
#   \`---\`-------\`-------'             

# EOM

	if [[ $1 =~ .*[A-Za-z].* ]]; then
		echo -e "Search query entered: ${1}\n"
		search_song "${1}"
	elif [[ $1 =~ ^[0-9]+$ ]]; then
		echo -e "Numeric ID entered: ${1}\n"
		NETEASE_SONG_ID=${1}
	else
	cat <<-EOM
		163lrc is a tool to download time-synched lyrics (as LRC files) from 
		https://music.163.com, for use with Plexamp and other media players.

		Usage:  ${0} [arguments]

		Available argumets:
		  search_query  search for a song by artist and title; use best match
		  song_id       specify a song by its numeric ID on https://music.163.com"

		EOM

		kill -INT $$
	fi

	fetch_song_by_id "${NETEASE_SONG_ID}"

	fetch_lyrics "${NETEASE_SONG_ID}"

	if [[ "${NETEASE_LYRICS}" =~ \[00.*\] ]]; then
		echo -e "Found timestamp in lyrics, assuming they are synced LRC"
		save_lrc
	else
		echo -e "ERROR: Could not fetch synced lyrics for ${NETEASE_SONG_ID};$NETEASE_ARTIST_NAME;$NETEASE_SONG_NAME" | tee "./error_163lrc.log"
	fi
}

main "${@}"
# unset ${!NETEASE*}
sleep 5
clear
