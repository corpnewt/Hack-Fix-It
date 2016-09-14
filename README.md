#Hack Fix-It

By CorpNewt


----------------------------------------------------------------------------------

### WARNING ###

This script is to be used *ONLY* on the computer it was setup for.  Running it on another machine can cause issues and/or mess up an otherwise working system.  Use with caution!

----------------------------------------------------------------------------------


## Sample File List

* Hack Fix-It
* EFI
* EFIF
* KextList.txt
* ReadMe.txt


### Available Functions

The Hack Fix-It script can do the following:

* Remove extra EFI folders (whether legacy or UEFI)
  * Option set in the script itself - not with companion files
  * Backs them up in zip files on the desktop if it removes them

* Copy over EFI folders (to legacy or UEFI)
  * EFI folder in same directory as this script = UEFI
  * EFIF folder in the same directory as this script = Legacy

* Remove kexts from /S/L/E and /L/E
  * Reads info from KextList.txt in same directory as this script
  * Se below for KextList.txt structure

* Repair permissions and rebuild kext cache
  * Options set in the script itself - not with companion files


## KextList.txt Structure

The KextList.txt accepts two types of entries (one line per each):

1. DIRECTORY:/Path/To/Location
2. KextName.kext

It will cd into the directory listed (all absolute for the time being), then remove all the kexts named below it that it finds.  For a simple KextList.txt that removes FakePCIID.kext and FakePCIID_XHCIMux.kext from both /L/E/ and /S/L/E it would look like:

DIRECTORY:/Library/Extensions
FakePCIID.kext
FakePCIID_XHCIMux.kext
DIRECTORY:/System/Library/Extensions
FakePCIID.kext
FakePCIID_XHCIMux.kext
