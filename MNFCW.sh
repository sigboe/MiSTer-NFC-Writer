#!/usr/bin/env bash
# shellcheck disable=SC2094 # Dirty hack avoid runcommand to steal stdout

title="MiSTer NFC Writer"
scriptdir="$(dirname "$(readlink -f "${0}")")"
version="0.1"
fullFileBrowser="false"
basedir="/media/fat/"
basedir="${HOME}"
nfcCommand="nfc.sh"
map="/media/fat/nfc.csv"
mapHeader"match_uid,match_text,text"

_depends() {
	if ! [[ -x "$(command -v dialog)" ]]; then
		echo "dialog not installed." >"$(tty)"
		sleep 10
		_exit 1
	fi
}

main() {
	menuOptions=(
		"Read"     "Read NFC Tag"
		"Write"    "Write ROM file paths to NFC Tag"
		"Commands" "Write commands to NFC Tag"
		"Mappings" "Edit the mappings database"
		#"Settings" "Options for ${title}"
		"About"    "About this program"
	)

	selected="$(dialog \
		--backtitle "${title}" \
		--cancel-label "Exit" \
		--default-item "${selected}" \
		--menu "Choose one" \
		22 77 16 "${menuOptions[@]}" 3>&1 1>&2 2>&3 >"$(tty)")"

}

_Read() {
	local nfcSCAN nfcUID nfcTXT
	[[ -f "/tmp/NFCSCAN" ]] && rm /tmp/NFCSCAN
	_yesno "Scan NFC Tag then continue" --yes-label "Continue" --no-label "Back" || return
	nfcSCAN="$(</tmp/NFCSCAN)"
	nfcTXT="${nfcSCAN#*,}"
	nfcUID="${nfcSCAN%,*}"
	[[ -z "${nfcSCAN}" ]] && { _error "Tag not read" ; _Read ; }
	[[ -n "${nfcSCAN}" ]] && _msgbox "Tag contents: ${nfcTXT}\n Tag UID: ${nfcUID}"
}

_Write() {
	local fileSelected extension gameName message
	fileSelected="$(_fselect "${basedir}")"
	[[ ! -f "${fileSelected//.zip\/*/.zip}" ]] && { _error "No file was selected." ; return ; }
	fileSelected="${fileSelected//$basedir}"
	extension="${fileSelected##*.}"
	extension="${extension,,}"
	fileSize="$(du -h "${fileSelected}")"
	fileSize="${fileSize%%	*}"
	txtSize="$(echo -n "${fileSelected}" | wc --bytes)"

	read -rd '' message <<_EOF_
The following file was selected:
${fileSelected}

The NFC Tag needs to be able to fit at least ${txtSize} Bytes to write this tag
_EOF_

	_yesno "${message}" --title "${gameName}"  --ok-label "Write" #--extra-button --extra-label "Delete"

	case $? in
	1 | 255)
		# cancel or esc
		return
		;;

	# extra-button
	#3)
	#	#delete
	#	rm "${fileSelected}" || {
	#		_error "Unable to delete file!!"
	#		return
	#	}
	#	_msgbox "${fileSelected} deleted."
	#	return
	#	;;
	esac

	"${nfcCommand}" -service stop || { _error "Unable to stop NFC service"; return; }
	"${nfcCommand}" -write "${fileSelected}" || { _error "Unable to write NFC Tag"; "${nfcCommand}" -service start;  return; }
	"${nfcCommand}" -service start || _error "Unable to start NFC service"

	_msgbox "${fileSelected} \n successfully written to NFC tag"
}

_Commands() {
	_msgbox "This feature has not been implemented yet"
}
_Mappings() {
	local nfcSCAN nfcUID nfcTXT
	[[ -f "/tmp/NFCSCAN" ]] && rm /tmp/NFCSCAN
	_yesno "Scan NFC Tag then continue" --yes-label "Continue" --no-label "Back" || return
	nfcSCAN="$(</tmp/NFCSCAN)"
	nfcTXT="${nfcSCAN#*,}"
	nfcUID="${nfcSCAN%,*}"
	if [[ -f "${map}" ]]; then
		mapMatchText="$(grep "${nfcUID}" "${map}" | head -n1 | cut -d"," -f2)"
		mappedText="$(grep "${nfcUID}" "${map}" | head -n1 | cut -d"," -f3)"
	fi
	[[ -z "${nfcSCAN}" ]] && { _error "Tag not read" ; _Mappings ; }
	read -rd '' description <<_EOF_
Tag contents: ${nfcTXT}
Tag UID: ${nfcUID}

Do you want to overwrite the mapping for this NFC tag? (NFC tags only have a write once memory, but your MiSTer can remember that you want this NFC tag to do something else)
_EOF_
	[[ -n "${mappedText}" ]] && read -rd '' descriptionExtra <<_EOF_
Current mappedText: ${mapMatchText}
current mappedMatch: ${mapMatchText}
_EOF_
	[[ -n "${nfcSCAN}" ]] && _yesno "${description}\n${descriptionExtra}" || return
	_msgbox "Feature not implemented yet"

}
_About() {
	local about githash builddate gitbranch
	githash="$(git --git-dir="${scriptdir}/.git" rev-parse --short HEAD)"
	gitbranch="$(git --git-dir="${scriptdir}/.git" rev-parse --abbrev-ref HEAD)"
	builddate="$(git --git-dir="${scriptdir}/.git" log -1 --date=short --pretty=format:%cd)"
	read -rd '' about <<_EOF_
${title} ${version}-${gitbranch}-${builddate} + ${githash}

Add useful description here!
_EOF_
	_msgbox "${about}" --title "About"
}

# dialog --fselect broken out to a function,
# the purpouse is that
# if the screen is smaller then what --fselec can handle
# I can do somethig else
# Usage: _fselect "${fullPath}"
# returns the file that is selected including the full path, if full path is used.
_fselect() {
	local termh windowh dirList selected extension fileName fullPath newDir #gameName
	fullPath="${1}"
	[[ -f "${fullPath}" ]] && { echo "${fullPath}"; return; }
	termh="$(tput lines)"
	((windowh = "${termh}" - 10))
	[[ "${windowh}" -gt "22" ]] && windowh="22"
	if "${fullFileBrowser}" && [[ "${windowh}" -ge "8" ]]; then
		dialog \
			--backtitle "${title}" \
			--title "${fullPath}" \
			--fselect "${fullPath}/" \
			"${windowh}" 77 3>&1 1>&2 2>&3 >"$(tty)"

	else
		# in case of a very tiny terminal window
		# make an array of the filenames and put them into --menu instead
		dirList=(
			"goto" "Go to directory (keyboard required)"
			".." "Up one directory"
		)

		while read -r folderName; do
			dirList+=("$(basename "${folderName}")" "Directory")

		done < <(find "${fullPath}" -mindepth 1 -maxdepth 1 ! -name '.*' -type d)

		while read -r fileName; do
			extension="${fileName##*.}"
			case "${extension,,}" in
			"")
				dirList+=("$(basename "${fileName}")")
				dirList+=("")
				;;

			*)
				dirList+=("$(basename "${fileName}")")
				dirList+=("File")
				;;
			esac

		done < <(find "${fullPath}" -maxdepth 1 -type f)

		selected="$(dialog \
			--backtitle "${title}" \
			--title "${fullPath}" \
			--menu "Pick a game to write to NFC Tag" \
			22 77 16 "${dirList[@]}" 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)")"

		[[ "${?}" -ge 1 ]] && return

		case "${selected,,}" in
		"goto")
			newDir="$(_inputbox "Input a directory to go to" "${basedir}")"
			_fselect "${newDir}"
			;;
		"..")
			_fselect "${fullPath%/*}"
			;;
		*.zip)
			echo "${fullPath}/${selected}/$(_browseZip "${fullPath}/${selected}")"
			;;
		*)
			_fselect "${fullPath}/${selected}"
			;;
		esac

	fi

}

# Browse contents of zip file as if it was a folder
# Usage: _browseZip "file.zip"
# returns a file path of a file inside the zip file
_browseZip() {
	local zipFile zipContents dirList currentDir relativeComponents currentDirTree relativePath
	zipFile="${1}"
	currentDir=""
	mapfile -t zipContents < <(unzip -l "${zipFile}" | awk 'NR > 3 {for (i=4; i<=NF; i++) {printf "%s", $i; if (i != NF) printf " ";} printf "\n"}')
	unset "zipContents[-1]" "zipContents[-1]"
	relativeComponents=(
		".." "Up one directory"
	)
	while true; do

		unset currentDirTree
		unset currentDirList
		for entry in "${zipContents[@]}"; do
			if [[ "${entry}" == "$currentDir" ]]; then
				true
			elif [[ "${entry}" == "$currentDir"* ]]; then
				currentDirTree+=( "${entry}" )
			fi
		done

		declare -a currentDirList
		for entry in "${currentDirTree[@]}"; do
			if [[ "${entry%/}" != "${currentDir}/"* ]]; then
				relativePath="${entry#"$currentDir"}"
				if [[ ${relativePath} == *"/"* ]]; then
					[[ "${currentDirList[-2]}" == "${relativePath%%/*}/" ]] && continue 
					currentDirList+=( "${relativePath%%/*}/" )
				else 
					[[ "${currentDirList[-2]}" == "${relativePath}" ]] && continue 
					currentDirList+=( "${relativePath}" )
				fi


				if [[ "${currentDirList[-1]}" == */ ]]; then
					currentDirList+=( "Directory" )
				else
					currentDirList+=( "File" )
				fi
			fi
		done

		dirList=( "${relativeComponents[@]}" )
		dirList+=( "${currentDirList[@]}" )
		selected="$(dialog \
			--backtitle "${title}" \
			--title "${zipFile}" \
			--menu "${currentDir}" \
			22 77 16 "${dirList[@]}" 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)")"

		case "${selected,,}" in
		"..")
			currentDir="${currentDir%/}"
			[[ "${currentDir}" != *"/"* ]] && currentDir=""
			currentDir="${currentDir%/*}"
			[[ -n ${currentDir} ]] && currentDir="${currentDir}/"
			;;
		*/)
			currentDir="${currentDir}${selected}"
			;;
		*)
			echo "${currentDir}${selected}"
			break
			;;
		esac
	done
}

# Ask user for a string
# Usage: _inputbox "My message" "Initial text" [--optional-arguments]
# You can pass additioal arguments to the dialog program
# Backtitle is already set
_inputbox() {
	local msg opts init
	msg="${1}"
	init="${2}"
	shift 2
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		"${opts[@]}" \
		--inputbox "${msg}" \
		22 77 "${init}" 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
}

# Display a message
# Usage: _msgbox "My message" [--optional-arguments]
# You can pass additioal arguments to the dialog program
# Backtitle is already set
_msgbox() {
	local msg opts
	msg="${1}"
	shift
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		"${opts[@]}" \
		--msgbox "${msg}" \
		22 77  3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
}

# Request user input
# Usage: _yesno "My question" [--optional-arguments]
# You can pass additioal arguments to the dialog program
# Backtitle is already set
# returns the exit code from dialog which depends on the user answer
_yesno() {
	local msg opts
	msg="${1}"
	shift
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		"${opts[@]}" \
		--yesno "${msg}" \
		22 77 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
	return "${?}"
}

# Display an error
# Usage: _error "My error" [1] [--optional-arguments]
# If the second argument is a number, the program will exit with that number as an exit code.
# You can pass additioal arguments to the dialog program
# Backtitle and title are already set
# Returns the exit code of the dialog program
_error() {
	local msg opts answer exitcode
	msg="${1}"
	shift
	[[ "${1}" =~ ^[0-9]+$ ]] && exitcode="${1}" && shift
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		--title "ERROR:" \
		"${opts[@]}" \
		--msgbox "${msg}" \
		22 77 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
	answer="${?}"
	[[ -n "${exitcode}" ]] && exit "${exitcode}"
	return "${answer}"
}

_exit() {
	clear
	exit "${1:-0}"
}

# Check if element is in array
# Usage: _isInArray "element" "${array[@]}"
# returns exit code 0 if element is array, returns exitcode 1 if element is in array
_isInArray() {
	local string="${1}"
	shift
	local array=("${@}")
	[[ "${#array}" -eq 0 ]] && return 1

  for item in "${array[@]}"; do
    if [[ "${string}" == "${item}" ]]; then
      return 0
    fi
  done

  return 1
}

_depends

while true; do
	main
	"_${selected:-exit}"
done
