#!/bin/bash

#                                       #
##                                     ##
###                                   ###
####                                 ####

#########################################
#        REVIEW THESE EVERY TIME        #
#########################################

# Repair Perms and Rebuild Kext Cache can
# be Yes/No/Ask

removeEFI="No"
removeEFIF="No"
repairPermissions="Ask"
rebuildKextCache="Ask"
selectDisk="Yes"

#########################################
#        REVIEW THESE EVERY TIME        #
#########################################

####                                 ####
###                                   ###
##                                     ##
#                                       #


# Turn on case-insensitive matching
shopt -s nocasematch
# turn on extended globbing
shopt -s extglob

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

efiDIR="$DIR/EFI"

backupLocation="~/Desktop"

scriptName="Hack Fix-It - CorpNewt"
scriptMessage="Select target drive for Hack Fix-It:"

tDMount=""
tDIdent=""
tDName=""
tDDisk=""
tDPart=""

efiMount=""
efiIdent=""
efiName=""
efiDisk=""
efiPart=""

function expandPath () {
    
    echo "${1/#\~/$HOME}"

}

function resetDisks () {
    tDMount=""
    tDIdent=""
    tDName=""
    tDDisk=""
    tDPart=""
    
    efiMount=""
    efiIdent=""
    efiName=""
    efiDisk=""
    efiPart=""
}

function setDisk () {
	tDName="$( getDiskName "$1" )"
	tDMount="$( getDiskMountPoint "$1" )"
	tDIdent="$( getDiskIdentifier "$1" )"
	tDDisk="$( getDiskNumber "$1" )"
	tDPart="$( getPartitionNumber "$1" )"
    
    if [[ "$tDName" == "" ]]; then
        tDName="Untitled"
    fi
    
    # Set "/" to "" since all functions
    # with directories start with "/"
    if [[ "$tDMount" == "/" ]]; then
        tDMount=""
    fi
}

function setEFI () {
	efiName="$( getDiskName "$1" )"
	efiMount="$( getDiskMountPoint "$1" )"
	efiIdent="$( getDiskIdentifier "$1" )"
    efiDisk="$( getDiskNumber "$1" )"
	efiPart="$( getPartitionNumber "$1" )"
    
    if [[ "$efiName" == "" ]]; then
        efiName="Untitled"
    fi
}

function checkRoot () {
	if [[ "$(whoami)" != "root" ]]; then
		clear
        echo \#\#\# WARNING \#\#\#
        echo
		echo This script requires root privileges.
		echo Please enter your admin password to continue.
		echo 
		sudo "$0" "$1"
		exit $?
	fi

}

function displayWarning () {
	clear
	echo \#\#\# WARNING \#\#\#
	echo 
	echo This script is provided with NO WARRANTY whatsoever.
	echo I am not responsible for ANY problems or issues you
	echo may encounter, or any damages as a result of running
	echo this script.
	echo 
	echo To ACCEPT this warning and FULL RESPONSIBILITY for
	echo using this script, press [enter].
	echo 
	read -p "To REFUSE, close this script."
    checkRoot "MainMenu"
	mainMenu
}

function customQuit () {
	clear
	echo \#\#\# Hack Fix-It \#\#\#
	echo by CorpNewt
	echo 
	echo Thanks for testing it out, for bugs/comments/complaints
	echo send me a message on Reddit, or check out my GitHub:
	echo 
	echo www.reddit.com/u/corpnewt
	echo www.github.com/corpnewt
	echo 
	echo Have a nice day/night!
	echo 
	echo 
	shopt -u extglob
	shopt -u nocasematch
	exit $?
}

function main () {
    
    resetDisks
    
    # Set disk based on preferences
    if [[ "$selectDisk"  == "Yes" ]]; then
        #User selects the working drive
        pickDisk selectedDrive "$scriptName" "$scriptMessage"
        setDisk "$selectedDrive"
    else
        #Work with the boot drive
        setDisk "/"
    fi
    
    clear
    echo \#\#\# Hack Fix-It \#\#\#
    echo
    
    if [[ -e "$DIR/KextList.txt" ]]; then
        echo KextList found, iterating...
        # Load KextList.txt into an array separated
        # by a newline
        old_IFS=$IFS
        IFS=$'\n'
        kextArray=($( cat "$DIR/KextList.txt" )) # array
        IFS=$old_IFS
        
        # Iterate through the list
        # CD on "DIRECTORY:"
        # Remove kexts from cd'ed directory
        for aKext in "${kextArray[@]}"
        do
            if [[ $aKext == DIRECTORY:* ]]; then
                local __newDir="${aKext##*:}"
                if [[ ! $__newDir == /* ]]; then
                    # Directory doesn't start with "/" - add it
                    __newDir="/$__newDir"
                fi
                echo   Scanning \""$__newDir"\"
                cd "$__newDir"
            else
                remove "$aKext"
            fi
        done
    fi
    
    # Check for EFIF to copy over
    # If none exists - fallback on whether to remove
    # existing legacy EFI
    if [[ -d "$DIR/EFIF" ]]; then
        # We have a Legacy EFI folder to copy over
        if [[ -d "$tDMount/EFI" ]]; then
            echo Backing up legacy EFI folder...
            backup "$tDMount/EFI" "$tDName-EFIF-"
            
            echo Removing legacy EFI folder...
            remove "$tDMount/EFI"
            echo
        fi
        
        echo Copying new legacy EFI folder...
        
        copy "$DIR/EFIF" "$tDMount/EFI"
    elif [[ -d "$tDMount/EFI" ]] && [[ "$removeEFIF" == "Yes" ]]; then
        echo Backing up legacy EFI folder...
        backup "$tDMount/EFI" "$tDName-EFIF-"
        
        echo Removing legacy EFI folder...
        if [[ "$tDMount" == "" ]]; then
            cd "/"
        else
            cd "$tDMount"
        fi
        
        remove "EFI"
        echo
    fi
    
    
    # Onto UEFI checks
    efiIdent="$( getEFIIdentifier "$tDIdent" )"
    
    # EFI Checks
    if [[ ! "$efiIdent" == "" ]]; then

        isMounted="$( getDiskMounted "$efiIdent" )"
        echo Located at "$efiIdent", mounting...
        diskutil mount "$efiIdent"
        
        setEFI "$efiIdent"

        # Drive has EFI partition
        if [[ -d "$DIR/EFI" ]]; then
            # We have an EFI to copy over
        
            cd "$efiMount"
          
            if [[ -d "$efiMount/EFI" ]]; then
                # EFI partition contains EFI folder
                # Backup - and remove
                echo Backing up EFI...
                backup "$efiMount/EFI" "$tDName-EFI-"
            
                echo Removing old EFI folder...
                remove "$efiMount/EFI"
            fi
        
            echo Copying new EFI folder...
        
            copy "$efiDIR" "$efiMount"
            
        elif [[ -d "$efiMount/EFI" ]] && [[ "$removeEFI" == "Yes" ]]; then
            # We are removing the UEFI EFI folder from the EFI partition
            # without copying over anything to replace it.
            echo Backing up EFI...
            backup "$efiMount/EFI" "$tDName-EFI-"
            
            echo Removing old EFI folder...
            remove "$efiMount/EFI"
        fi
        
        if [[ "$isMounted" == "No" ]]; then
            #sleep 5
            echo Unmounting EFI partition...
            
            cd "$DIR"
            
            diskutil unmount "$efiIdent"
        fi
        
    fi
    
    echo
    
    if [[ "$repairPermissions" == "Yes" ]]; then
        repairPerms
    elif [[ "$repairPermissions" == "Ask" ]]; then
        checkPerm check
        if [[ "$check" == "1" ]]; then
            repairPerms
        fi
    fi
    
    if [[ "$rebuildKextCache" == "Yes" ]]; then
        rebuildKC
    elif [[ "$rebuildKextCache" == "Ask" ]]; then
        checkReb check
        if [[ "$check" == "1" ]]; then
            rebuildKC
        fi
    fi

    echo Done.
    
    sleep 3
    
    customQuit
}

function checkPerm () {
    clear
    echo \#\#\# Repair Permissions? \#\#\#
    echo
    echo "Do you want to attempt to repair permissions? (y/n):"
    echo
    read toDo

    if [[ "$toDo" == "y" ]]; then
        eval $1=1
    elif [[ "$toDo" == "n" ]]; then
        eval $1=0
    else
        checkPerm $1
    fi
}

function checkReb () {
    clear
    echo "### Rebuild Kext Cache? ###"
    echo
    echo "Do you want to rebuild kext cache? (y/n):"
    echo
    read toDo

    if [[ "$toDo" == "y" ]]; then
        eval $1=1
    elif [[ "$toDo" == "n" ]]; then
        eval $1=0
    else
        checkReb $1
    fi
}

function backup () {
    
    local __source="$1"
    local __name="$2"
    
    local __timeStamp="$( getTimestamp )"
    
    local __sourceParent="${__source%/*}"
    local __sourceName="${__source##*/}"

    echo
    echo Backing up \""$__source"\" to:
    echo \""$backupLocation"/"$__name"-"$__timeStamp".zip\"...

    if [[ "$__sourceParent" == "" ]]; then
        # __sourceParent is root - set to "/"
        __sourceParent="/"
    fi

    echo
    echo Source Parent: "$__sourceParent"
    echo Source Name:   "$__sourceName"
    
    local __currentDirectory="$( pwd )"
    
    cd "$__sourceParent"
    
    zip -r "$backupLocation/$__name$__timeStamp.zip" "$__sourceName"
    
    if [ "$?" -ne 0 ]; then
        echo Failed to create backup - Error Code: "$?"
    fi
    
    cd "$__currentDirectory"
}

function getTimestamp () {
    date +%Y%m%d_%H%M%S%Z
}

function remove () {
    echo     Removing "$1"
    rm -Rf "$1"
    wait
}

function copy () {
    echo     Copying "$1" to "$2"
    cp -R "$1" "$2" &
    wait
}

function repairPerms () {
    echo Repairing permissions...
    if [[ -e "/usr/libexec/repair_packages" ]]; then
        sudo /usr/libexec/repair_packages --repair --standard-pkgs --volume /
    elif [[ -e "$DIR/repair_packages" ]]; then
        sudo "$DIR/repair_packages" --repair --standard-pkgs --volume /
    else
        echo     repair_packages not found - skipping...
    fi
    echo
}

function rebuildKC () {
    echo Removing caches...
    sudo rm -r /System/Library/Caches/com.apple.kext.caches
    echo Touching Extensions...
    sudo touch /System/Library/Extensions
    echo Rebuilding kext-cache...
    sudo kextcache -update-volume /
    echo
}

###################################################
###               Disk Functions                ###
###################################################

function pickDisk () { 
    #$1 = callback drive picked
    #$2 = title
    #$3 = prompt


    local __returnVar="$1"
    local __scriptName="$2"
    local __message="$3"

    clear
    echo \#\#\# "$__scriptName" \#\#\#
    echo
    echo "$__message"
    echo 
    
    local driveList="$( cd /Volumes/; ls -1 | grep "^[^.]" )"
    unset driveArray
    IFS=$'\n' read -rd '' -a driveArray <<<"$driveList"
    
    #driveCount="${#driveArray[@]}"
    local driveCount=0
    local driveIndex=0
    
    for aDrive in "${driveArray[@]}"
    do
        (( driveCount++ ))
        echo "$driveCount". "$aDrive"
    done
    
    driveIndex=$(( driveCount-1 ))
    
    #ls /volumes/
    echo 
    echo 
    read drive

    if [[ "$drive" == "" ]]; then
        drive="/"
        #pickDrive
    fi
    
    #Notice - must have the single brackets or this
    #won't accurately tell if $drive is a number.
    if [ "$drive" -eq "$drive" ] 2>/dev/null; then
        #We have a number - check if it's in the array
        if [  "$drive" -le "$driveCount" ] && [  "$drive" -gt "0" ]; then
            drive="${driveArray[ (( $drive-1 )) ]}"
        else
            echo Index "$drive" out of range, checking for drive name...
        fi
    fi
    
    if [[ "$( isDisk "$drive" )" != "0" ]]; then
        if [[ "$( volumeName "$drive" )" ]]; then
			# We have a valid disk
			drive="$( volumeName "$drive" )"
			#setDisk "$drive"
		else
			# No disk available there
			echo \""$drive"\" is not a valid disk name, identifier
			echo or mount point.
			echo 
			read -p "Press [enter] to return to drive selection..."
			pickDisk "$1" "$2" "$3"
		fi
    fi

    # We have a valid drive - return it's diskIdent
    
    eval $__returnVar="$( getDiskIdentifier "$drive" )"

}

function isDisk () {
	# This function checks our passed variable
	# to see if it is a disk
	# Accepts mount point, diskXsX and an empty variable
	# If empty, defaults to "/"
	local __disk="$1"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Here we run diskutil info on our __disk and see what the
	# exit code is.  If it's "0", we're good.
	diskutil info "$__disk" &>/dev/null
	# Return the diskutil exit code
	echo $?
}

function volumeName () {
	# This is a last-resort function to check if maybe
	# Just the name of a volume was passed.
	local __disk="$1"
	if [[ ! -d "$__disk" ]]; then
		if [ -d "/volumes/$__disk" ]; then
			#It was just volume name
			echo "/Volumes/$__disk"
		fi
	else
		echo "$__disk"
	fi
}

function getDiskMounted () {
	local __disk="$1"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Output the "Volume Name" of __disk
	echo "$( diskutil info "$__disk" | grep 'Mounted' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getDiskName () {
	local __disk="$1"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Output the "Volume Name" of __disk
	echo "$( diskutil info "$__disk" | grep 'Volume Name' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getDiskMountPoint () {
	local __disk="$1"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Output the "Mount Point" of __disk
	echo "$( diskutil info "$__disk" | grep 'Mount Point' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getDiskIdentifier () {
	local __disk="$1"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Output the "Mount Point" of __disk
	echo "$( diskutil info "$__disk" | grep 'Device Identifier' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getDiskNumbers () {
	local __disk="$1"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Output the "Device Identifier" of __disk
	# If our disk is "disk0s1", it would output "0s1"
	echo "$( getDiskIdentifier "$__disk" | cut -d k -f 2 )"
}

function getDiskNumber () {
	local __disk="$1"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Get __disk identifier numbers
	local __diskNumbers="$( getDiskNumbers "$__disk" )"
	# return the first number
	echo "$( echo "$__diskNumbers" | cut -d s -f 1 )"
}

function getPartitionNumber () {
	local __disk="$1"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Get __disk identifier numbers
	local __diskNumbers="$( getDiskNumbers "$__disk" )"
	# return the second number
	echo "$( echo "$__diskNumbers" | cut -d s -f 2 )"	
}

function getPartitionType () {
	local __disk="$1"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Output the "Volume Name" of __disk
	echo "$( diskutil info "$__disk" | grep 'Partition Type' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getEFIIdentifier () {
	local __disk="$1"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi

	# Check if we are on an APFS volume
	local __tempNum="$( getDiskNumber "$__disk" )"
	local __apfsDisk="$( getPhysicalStore "disk$__tempNum" )"
	if [[ "$__apfsDisk" != "" ]]; then
		__disk="$__apfsDisk"
	fi

	local __diskName="$( getDiskName "$__disk" )"
	local __diskNum="$( getDiskNumber "$__disk" )"

	# Output the "Device Identifier" for the EFI partition of __disk
	endOfDisk="0"
	i=1
	while [[ "$endOfDisk" == "0" ]]; do
		# Iterate through all partitions of the disk, and return those that
		# are EFI
		local __currentDisk=disk"$__diskNum"s"$i"
		# Check if it's a valid disk, and if not, exit the loop
		if [[ "$( isDisk "$__currentDisk" )" != "0" ]]; then
			endOfDisk="true"
			continue
		fi

		local __currentDiskType="$( getPartitionType "$__currentDisk" )"

		if [ "$__currentDiskType" == "EFI" ]; then
			echo "$( getDiskIdentifier "$__currentDisk" )"
		fi
		i="$( expr $i + 1 )"
	done
}

function getPhysicalStore () {
	# Helper function to get the physical disk for apfs volume
	local __disk="$1"
	local __diskName="$( getDiskName "$__disk" )"
	local __diskNum="$( getDiskNumber "$__disk" )"
	# If variable is empty, set it to "/"
	if [[ "$__disk" == "" ]]; then
		__disk="/"
	fi
	# Output the physical store disk, if any
	__tempDisk="$( diskutil apfs list "$__disk" 2>/dev/null | grep 'APFS Physical Store Disk' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
	__finalDisk=""
	if [[ "$__tempDisk" != "" ]]; then
		__tempDiskNumber="$( getDiskNumber "$__tempDisk" )"
		__finalDisk="disk$__tempDiskNumber"
	fi
	echo $__finalDisk
}

###################################################
###             End Disk Functions              ###
###################################################

backupLocation="$( expandPath "$backupLocation" )"

if [[ "$1" == "MainMenu" ]]; then
    main
else
    displayWarning
fi
