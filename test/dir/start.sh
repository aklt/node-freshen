#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BIN="$DIR/../../bin"

f="freshenrc-$1"
s="stop-$1.sh"

cd $DIR

[ -z "$1" ] || ! [ -e $f ] && echo "Usage: start.sh <dev|api>" && exit 1

echo "#!/usr/bin/env bash" > $s
${BIN}/freshen $f &
echo "PID_1=$!" >> $s
echo "kill \$PID_1" >> $s
echo "rm -f $DIR/$s" >> $s
chmod 755 $s
