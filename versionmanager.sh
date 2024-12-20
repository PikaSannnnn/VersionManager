#!/bin/bash
### VERSION MANAGER
#   Reads and writes a version file. 
#   Version file will be generated in the same level as ths script.
#   All version files of this manager expects a single file, single line of the format "version: <version>".
#   Do not deviate, unless you wish to make changes to the script itself to accommodate. 
###

########################
# MODIFYABLE PARAMS
# NOTE: IF YOUR PARAM IS NOT HERE, CHECK FLAGS WITH -h FIRST! IT'S PROBABLY THERE!
#
#   VERSION_COMP:   Version composition. The labels of each number.
#                   The number of part labels should be (num of delims) + 1  
#                   Release should always be first (position 0)! 
#                   Otherwise, it's in order of level (high -> low), which is the expected version layout
#
#   DELIMS:         Delimeters in version string.
#

# Default: ("release" "major" "minor" "patch")
export VERSION_COMP=("release" "major" "minor" "patch")

# Default: '-.'
DELIMS='-.'

#
########################

#####################################################################################
#                            EDIT BELOW AT YOUR OWN RISK                            #
#####################################################################################

########################
# SETUP
########################
usage () {
cat << EOF
    Expected Flags:
        [-M|-m|-n|none]: In order of level (i.e. script only sees the highest level)
            -n: Skip update
            -M: Apply major update (minor=patch => 0)
            -m: Apply minor update (patch => 0)
            none: Apply patch update
        Other flags: Ignored
EOF
}

FILENAME="version"
UPDATE=true
RELEASE=""
VER_LVL=1
while getopts ":r:f:Mmndh" opt; do
    case "$opt" in
        M)  VERLVL=3
            ;;
        m)  VERLVL=2
            ;;
        n)  UPDATE=false
            ;;
        h)  usage
            exit 0
            ;;
        f)  FILENAME=$OPTARG
            ;;
        r)  RELEASE=$OPTARG
            ;;
        *)
            ;;
    esac
done

########################
# VERIFICATION
########################
# Get number of version components and check validity
NUM_VERSION_PARTS=${#VERSION_COMP[@]}

if [ -e "$FILENAME" ]; then

else

fi

VERSION=$(grep -E "^version:" "$FILENAME" | awk '{print $2}')
IFS='-.'
read -r -a VERSION_PARTS <<< "$VERSION"

if [ $NUM_VERSION_PARTS -ne ${#VERSION_PARTS[@]} ]; then
    echo "Version file contains ${#VERSION_PARTS[@]} components, but expecting $NUM_VERSION_PARTS"
    echo "Please check params or version file"
    exit 1
fi

export VERSION_PARTS

RESET=false

UPDATE_START_IND=$((NUM_VERSION_PARTS - VER_LVL))
echo "Executing ${VERSION_COMP[UPDATE_START_IND]} update"
NEWVERSION="${version_parts[0]}-"
for ((i = UPDATE_START_IND; i < $NUM_VERSION_PARTS; i++)); do
    PART="${VERSION_COMP[i]}"

    NEWVAL=$((version_parts[i] + 1))
    if [ "$RESET" == "true" ]; then
        NEWVAL=0
    fi
    RESET=true

    echo "\tUpdated [\033[1;33m$PART ${version_parts[i]} -> $NEWVAL\033[0m]"
done

for ((i = 1; i < $NUM_VERSION_PARTS; i++)); do
    NEWVERSION="$NEWVERSION${version_parts[i]}"
    if [ $i -lt $((NUM_VERSION_PARTS - 1)) ]; then
        NEWVERSION="$NEWVERSION."
    fi
done
echo "version: $NEWVERSION"
# echo "version: $NEWVERSION" > "TESTVERSION"