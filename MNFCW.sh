#!/usr/bin/env bash
# shellcheck disable=SC2094 # Dirty hack avoid runcommand to steal stdout

title="MiSTer NFC Writer"
scriptdir="$(dirname "$(readlink -f "${0}")")"
version="0.1"
fullFileBrowser="false"
#TODO thoroughly test this regex
url_regex="^(http|https|ftp)://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}(/.*)?$"
basedir="/media/fat/"
[[ -d "${basedir}" ]] || basedir="${HOME}"
nfcCommand="nfc.sh"
map="/media/fat/nfc.csv"
mapHeader="match_uid,match_text,text"
cmdPalette=(
	"system" "This command will launch a system"
	"random" "This command will launch a game a random for the given system"
	"ini" "Loads the specified MiSTer.ini file and relaunches the menu core if open"
	"get" "Perform an HTTP GET request to the specified URL"
	"key" "Press a key on the keyboard using its uinput code"
	"coinp1" "Insert a coin/credit for player 1"
	"coinp2" "Insert a coin/credit for player 2"
	"command" "This command will run a MiSTer Linux command directly"
)
consoles=(
	"AdventureVision" "Adventure Vision"
	"Amiga" "Amiga"
	"Amstrad" "Amstrad CPC"
	"AmstradPCW" "Amstrad PCW"
	"Apogee" "Apogee BK-01"
	"AppleI" "Apple I"
	"AppleII" "Apple IIe"
	"Arcade" "Arcade"
	"Arcadia" "Arcadia 2001"
	"Arduboy" "Arduboy"
	"Atari2600" "Atari 2600"
	"Atari5200" "Atari 5200"
	"Atari7800" "Atari 7800"
	"Atari800" "Atari 800XL"
	"AtariLynx" "Atari Lynx"
	"AcornAtom" "Atom"
	"BBCMicro" "BBC Micro/Master"
	"BK0011M" "BK0011M"
	"Astrocade" "Bally Astrocade"
	"Chip8" "Chip-8"
	"CasioPV1000" "Casio PV-1000"
	"CasioPV2000" "Casio PV-2000"
	"ChannelF" "Channel F"
	"ColecoVision" "ColecoVision"
	"C64" "Commodore 64"
	"PET2001" "Commodore PET 2001"
	"VIC20" "Commodore VIC-20"
	"EDSAC" "EDSAC"
	"AcornElectron" "Electron"
	"FDS" "Famicom Disk System"
	"Galaksija" "Galaksija"
	"Gamate" "Gamate"
	"GameNWatch" "Game & Watch"
	"GameGear" "Game Gear"
	"Gameboy" "Gameboy"
	"Gameboy2P" "Gameboy (2 Player)"
	"GBA" "Gameboy Advance"
	"GBA2P" "Gameboy Advance (2 Player)"
	"GameboyColor" "Gameboy Color"
	"Genesis" "Genesis"
	"Sega32X" "Genesis 32X"
	"Intellivision" "Intellivision"
	"Interact" "Interact"
	"Jupiter" "Jupiter Ace"
	"Laser" "Laser 350/500/700"
	"Lynx48" "Lynx 48/96K"
	"SordM5" "M5"
	"MSX" "MSX"
	"MacPlus" "Macintosh Plus"
	"Odyssey2" "Magnavox Odyssey2"
	"MasterSystem" "Master System"
	"Aquarius" "Mattel Aquarius"
	"MegaDuck" "Mega Duck"
	"MultiComp" "MultiComp"
	"NES" "NES"
	"NESMusic" "NESMusic"
	"NeoGeo" "Neo Geo/Neo Geo CD"
	"Nintendo64" "Nintendo 64"
	"Orao" "Orao"
	"Oric" "Oric"
	"ao486" "PC (486SX)"
	"OCXT" "PC/XT"
	"PDP1" "PDP-1"
	"PMD85" "PMD 85-2A"
	"PSX" "Playstation"
	"PocketChallengeV2" "Pocket Challenge V2"
	"PokemonMini" "Pokemon Mini"
	"RX78" "RX-78 Gundam"
	"SAMCoupe" "SAM Coupe"
	"SG1000" "SG-1000"
	"SNES" "SNES"
	"SNESMusic" "SNES Music"
	"SVI328" "SV-328"
	"Saturn" "Saturn"
	"MegaCD" "Sega CD"
	"QL" "Sinclair QL"
	"Specialist" "Specialist/MX"
	"SuperGameboy" "Super Gameboy"
	"SuperGrafx" "SuperGrafx"
	"SuperVision" "SuperVision"
	"TI994A" "TI-99/4A"
	"TRS80" "TRS-80"
	"CoCo2" "TRS-80 CoCo 2"
	"ZX81" "TS-1500"
	"TSConf" "TS-Config"
	"AliceMC10" "Tandy MC-10"
	"TatungEinstein" "Tatung Einstein"
	"TurboGrafx16" "TurboGrafx-16"
	"TurboGrafx16CD" "TurboGrafx-16 CD"
	"TomyTutor" "Tutor"
	"UK101" "UK101"
	"VC4000" "VC4000"
	"CreatiVision" "VTech CreatiVision"
	"Vector06C" "Vector-06C"
	"Vectrex" "Vectrex"
	"WonderSwan" "WonderSwan"
	"WonderSwanColor" "WonderSwan Color"
	"X68000" "X68000"
	"ZXSpectrum" "ZX Spectrum"
	"ZXNext" "ZX Spectrum Next"
)

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
		"Mappings" "Edit the mappings database"
		"Settings" "Options for ${title}"
		"dbEdit"   "CSV editor, will be merged into Mappings"
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
	#TODO bug wizzo about adding a feature to suspend launching games so we can read tags without interrupting the program
	[[ -f "/tmp/NFCSCAN" ]] && rm /tmp/NFCSCAN
	_yesno "Scan NFC Tag then continue" --yes-label "Continue" --no-label "Back" || return
	nfcSCAN="$(</tmp/NFCSCAN)"
	nfcTXT="${nfcSCAN#*,}"
	nfcUID="${nfcSCAN%,*}"
	[[ -z "${nfcSCAN}" ]] && { _error "Tag not read" ; _Read ; }
	[[ -n "${nfcSCAN}" ]] && _msgbox "Tag contents: ${nfcTXT}\n Tag UID: ${nfcUID}"
	#TODO change to yesno with extra button to do things like remap using mapping file and copy contents to new tag
}

_Write() {
	local fileSelected message txtSize
	text="$(_commandPalette)"
	txtSize="$(echo -n "${text}" | wc --bytes)"
	read -rd '' message <<_EOF_
The following file was selected:
${text}

The NFC Tag needs to be able to fit at least ${txtSize} Bytes to write this tag
_EOF_
	_yesno "${message}" --title "${title}"  --yes-label "Write to Tag" --extra-button --extra-label "Write to Map"
	answer="${?}"
	[[ -z "${text}" ]] && { _msgbox "Nothing selected for writing" ; return ; }
	[[ "${text}" =~ ^\*\*command:* ]] && { _msgbox "Writing system commands to NFC tags are disabled" ; return ; }
	case "${answer}" in
		0)
			_writeTag "${text}"
			;;
		3)
			# Extra button
			#TODO _writeTextToMap
			_msgbox "Feature not implemented yet, but you can currently do this through dbEdit (or Mappings if I have come as far as merging those two yet)"
			;;
		1|255)
			return
			;;
	esac
}

# Gives the user the ability to enter text manually, pick a file, or use a command palette
# Usage: _commandPalette
# Returns a text string
# Example: text="$(_commandPalette)"
_commandPalette() {
	local menuOptions selected
	menuOptions=(
		"Input"     "Input text manually, requires a keyboard"
		"Pick"    "Pick a file, including files inside zip files"
		"Commands" "Craft a custom command using a command palette"
	)

	selected="$(dialog \
		--backtitle "${title}" \
		--cancel-label "Exit" \
		--default-item "${selected}" \
		--menu "Choose one" \
		22 77 16 "${menuOptions[@]}" 3>&1 1>&2 2>&3 >"$(tty)")"

	case "${selected}" in
		Input)
			inputText="$( _inputbox "Replace match text" "${match_text}" || return )"
			echo "${inputText}"
			;;
		Pick)
			fileSelected="$(_fselect "${basedir}")"
			[[ ! -f "${fileSelected//.zip\/*/.zip}" ]] && { _error "No file was selected." ; return ; }
			fileSelected="${fileSelected//$basedir}"
			echo "${fileSelected}"
			;;
		Commands)
			#TODO: implement a palette for commands here
			text="$(_craftCommand)"
			echo "${text}"
			;;
	esac

}

# Build a command using a command palette
# Usage: _craftCommand
_craftCommand(){
	local command selected console
	# Test if function is called recursively
	if [[ "${FUNCNAME[0]}" != "${FUNCNAME[1]}" ]]; then
		command="**"
	else
		command="||"
	fi
	selected="$(dialog \
		--backtitle "${title}" \
		--cancel-label "Exit" \
		--default-item "${selected}" \
		--menu "Choose one" \
		22 77 16 "${cmdPalette[@]}" 3>&1 1>&2 2>&3 >"$(tty)")"
	command="${command}${selected}"

	case "${selected}" in
		system | random)
			console="$(dialog \
				--backtitle "${title}" \
				--menu "Choose one" \
				22 77 16 "${consoles[@]}" 3>&1 1>&2 2>&3 >"$(tty)")"
			command="${command}${console}"
			echo "${command}"
			;;
		ini)
			ini="$(dialog \
				--backtitle "${title}" \
				--radiolist "Choose one" \
				22 77 16 1 one off 2 two off 3 three off 4 four off 3>&1 1>&2 2>&3 >"$(tty)")"
			command="${command}${ini}"
			echo "${command}"
			;;
		get)
			http="$(_inputbox "Enter URL" "https://" || return )"
			[[ "${http}" =~ ${url_regex} ]] || { _error "${http} doesnt look like an URL?" ; return ; }
			command="${command}${http}"
			_yesno "Do you wish to execute an additional command?" && command="${command}$(_craftCommand)"
			echo "${command}"
			;;
		coinp1 | coinp2)
			coin="$(_inputbox "Enter number" "1" || return )"
			[[ "${coin}" =~ ^-?[0-9]+$ ]] || { _error "${coin} is not a number" ; return ; }
			command="${command}${coin}"
			echo "${command}"
			;;
		command)
			linuxcmd="$(_inputbox "Enter Linux command" "reboot" || return )"
			[[ -x "${linuxcmd%% *}" ]] || { _error "${linuxcmd%% *} from ${linuxcmd} does not seam to be a valid command" ; return ; }
			command="${command}${linuxcmd}"
			echo "${command}"
			;;
	esac

}

_Mappings() {
	local nfcSCAN nfcUID nfcTXT description
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

Do you want to overwrite the mapping for this NFC tag?
_EOF_
	[[ -n "${mappedText}" ]] && read -rd '' description <<_EOF_
${description}
Current mappedText: ${mapMatchText}
current mappedMatch: ${mapMatchText}
_EOF_
	[[ -n "${nfcSCAN}" ]] && _yesno "${description}" --yes-label Overwrite --no-label Back --extra-button  --extra-button --extra-label "Update Mapped"
	case "${?}" in
	0)
		#yes button
		_Write
		;;
	1 | 255)
		# cancel or esc
		return
		;;
	3)
		#extra button
		_map "${nfcUID}" "$(_fselect)"
		;;
	esac

}

_Settings() {
	local menuOptions selected
	menuOptions=(
		"Enable"     "Enable NFC service"
		"Disable"    "Disable NFC service"
	)

	selected="$(dialog \
		--backtitle "${title}" \
		--menu "Choose one" \
		22 77 16 "${menuOptions[@]}" 3>&1 1>&2 2>&3 >"$(tty)")"

	case "${selected}" in
		Enable)
			"${nfcCommand}" -service start || { _error "Unable to start the NFC service"; return; }
			_msgbox "The NFC service started"
			;;
		Disable)
			"${nfcCommand}" -service stop || { _error "Unable to stop the NFC service"; return; }
			_msgbox "The NFC service stopped"
			;;
	esac
}

_About() {
	local about githash builddate gitbranch
	githash="$(git --git-dir="${scriptdir}/.git" rev-parse --short HEAD)"
	gitbranch="$(git --git-dir="${scriptdir}/.git" rev-parse --abbrev-ref HEAD)"
	builddate="$(git --git-dir="${scriptdir}/.git" log -1 --date=short --pretty=format:%cd)"
	#TODO actually write an about page
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

# Map or remap filepath or command for a given NFC tag (written to local database)
# Usage: _map "UID" "Text"
_map() {
	local uid txt
	uid="${1}"
	txt="${2}"
	[[ -e "${map}" ]] ||  printf "match_uid,match_text,text\n" >> "${map}"
	grep -q "^${uid}" "${map}" && sed -i "/^${uid}/d" "${map}"
	printf "%s,,%s\n" "${uid}" "${txt}" >> "${map}"
}

_dbEdit() {
	local oldMap arrayIndex line lineNumber match_uid match_text text menuOptions selected replacement_match_text message
	map="nfc.csv"
	mapfile -t -O 1 -s 1 oldMap < "${map}"
	echo "${oldMap[@]}"

	mapfile -t arrayIndex < <( _numberedArray "${oldMap[@]}" )

	line="$(dialog \
		--backtitle "${title}" \
		--menu "${mapHeader}" \
		22 77 16 "${arrayIndex[@]//\"/}" 3>&1 1>&2 2>&3 >"$(tty)" )"

	#set -x
	#exec &> /tmp/log
	[[ -z "${line}" ]] && return
	lineNumber=$((line + 1))
	match_uid="$(cut -d ',' -f 1 <<< "${oldMap[$line]}")"
	match_text="$(cut -d ',' -f 2 <<< "${oldMap[$line]}")"
	text="$(cut -d ',' -f 3 <<< "${oldMap[$line]}")"
	#set +x

	menuOptions=(
		"1" "${match_uid}"
		"2" "${match_text}"
		"3" "${text}"
	)

	selected="$(dialog \
		--backtitle "${title}" \
		--menu "${mapHeader}" \
		22 77 16 "${menuOptions[@]}" 3>&1 1>&2 2>&3 >"$(tty)")"

	case "${selected}" in
	1)
		# Replace match_uid
		# will break out read into a function before putting it here
		;;
	2)
		# Replace match_text
		replacement_match_text="$( _inputbox "Replace match text" "${match_text}" || return )"
		read -rd '' message <<_EOF_
Replace:
${match_uid},${match_text},${text}
With:
${match_uid},${replacement_match_text},${text}
_EOF_
		_yesno "${message}" || return
		sed -i "${lineNumber}c\\${match_uid},${replacement_match_text},${text}" "${map}"
		;;
	3)
		# Replace text
		replacement_text="$(_commandPalette)"
		[[ -z "${replacement_text}" ]] && { _msgbox "Nothing selected for writing" ; return ; }
		read -rd '' message <<_EOF_
Replace:
${match_uid},${match_text},${text}
With:
${match_uid},${match_text},${replacement_text}
_EOF_
		_yesno "${message}" || return
		sed -i "${lineNumber}c\\${match_uid},${match_text},${replacement_text}" "${map}"
		;;
	esac

}

# Returns array in a numbered fashion
# Usage: _numberedArray "${array[@]}"
# Returns:
# 1 first_element 2 second_element ....
_numberedArray() {
	local array index
	array=("$@")
	index=1

	for element in "${array[@]}"; do
		printf "%s\n" "${index}"
		printf "%s\n" "\"${element}\""
		((index++))
	done
}

# Write text string to physical NFC tag
# Usage: _writeTag "Text"
_writeTag() {
	local txt
	txt="${1}"

	"${nfcCommand}" -service stop || { _error "Unable to stop the NFC service"; return; }
	"${nfcCommand}" -write "${txt}" || { _error "Unable to write the NFC Tag"; "${nfcCommand}" -service start;  return; }
	"${nfcCommand}" -service start || _error "Unable to start the NFC service"

	_msgbox "${txt} \n successfully written to NFC tag"
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
