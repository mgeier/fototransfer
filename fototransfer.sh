#!/bin/sh

# shell script to transfer fotos from a digital camera to the computer

# Specify your appropriate paths in /etc/fototransfer.conf or ~/.fototransferrc

# TODO:
# - if no date is found in file, use file creation date
# - allow more than one source directory (e.g. fotos + videos)

# default vaules
CAMERADIR=DCIM/101CASIO
MOUNTPOINT=/media/disk
TARGETDIR="$HOME/My Photos"

# load config file(s)
if [ -r /etc/fototransfer.conf ]; then
  . /etc/fototransfer.conf
fi
if [ -r ~/.fototransferrc ]; then
  . ~/.fototransferrc
fi

UMOUNT=umount
JHEAD=$(which jhead)
AUTOROT="$JHEAD -autorot"
#EXIFTRAN=/usr/bin/exiftran
# a = auto rotation; i = in-place editing; p = preserve timestamps
#AUTOROT="$EXIFTRAN -aip"
MV='mv -i'
SOURCEDIR="$MOUNTPOINT/$CAMERADIR"

if [ -z $JHEAD ] ; then
  echo \"jhead\" not found! It is needed for this script to work!
  exit 1
fi

if [ ! -d "$SOURCEDIR" ] ; then
  echo source directory \"$SOURCEDIR\" not found!
  echo is the camera connected and mounted?
  exit 1
elif [ ! "$(ls -1 $SOURCEDIR)" ] ; then  
  echo \"$SOURCEDIR\" is empty. Nothing to do!
  echo Unmounting ...
  $UMOUNT $MOUNTPOINT
  exit 0
fi

if [ ! -d "$TARGETDIR" -o ! -w "$TARGETDIR" ] ; then
  echo target directory \"$TARGETDIR\" not found or not writable.
  exit 1
fi

echo moving jpeg files ...
COUNT=0
for IMAGEFILE in "$SOURCEDIR"/*.[Jj][Pp][Gg] ; do
  # if no jpeg files are present, this is needed:
  [ -f $IMAGEFILE ] || continue
  DATE=$($JHEAD "$IMAGEFILE" |
      grep 'Date/Time    : ' |
      cut --characters=16-25 |
      cut --only-delimited --delimiter=':' --output-delimiter='' --fields=1-3)
  if [ -z $DATE ] ; then
    echo no exif-date for \"$IMAGEFILE\"! not moving file ...
    # TODO: use file-creation time instead
  else
    [ -d "$TARGETDIR/$DATE" ] || mkdir "$TARGETDIR/$DATE"
    TARGETFILE="$TARGETDIR/$DATE/$(basename $IMAGEFILE)"
    if [ -e "$TARGETFILE" ] ; then
      echo target file \"$TARGETFILE\" already exists!
    else
      $MV "$IMAGEFILE" "$TARGETDIR/$DATE" 2> /dev/null
      $AUTOROT "$TARGETFILE"
      COUNT=$(($COUNT+1))
    fi
  fi
done
echo moved $COUNT jpeg files.

if [ -n "$(ls -1 ""$SOURCEDIR"")" ] ; then
  echo there are some files left! I didn\'t unmount.
else
  echo all files moved. unmounting ... 
  $UMOUNT $MOUNTPOINT
fi

# Settings for Vim (http://www.vim.org/), please do not remove:
# vim:softtabstop=2:shiftwidth=2:expandtab:textwidth=80
