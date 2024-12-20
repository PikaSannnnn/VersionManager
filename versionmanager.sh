#!/bin/bash
#####################################################################################
#                                  Version Manager                                  #
#                                  By: Pikasannnnn                                  #
# --------------------------------------------------------------------------------- #
# Reads and writes a version file. Version file will be generated in the same level #
# as ths script. All version files of this manager expects a single file, single    #
# line of the format "version: <version>". Do not deviate, unless you wish to make  #
# changes to the script itself to accommodate.                                      #
#####################################################################################

#####################################################################################
#                            EDIT BELOW AT YOUR OWN RISK                            #
# --------------------------------------------------------------------------------- #
# Honestly, if you're going to edit, try to only edit what you need. If anything,   #
# you should really only be editting whats in get_config. Try not to add anything   #
# that requires you to change get_version_data or any other parts of the script.    #
# you might cause dependency issues or tangle the logic, which isn't good!          #
#####################################################################################

########################
# Functions

# Pretty self explanatory. It tells us how to use it.
usage() {  
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

# Gets the config details
DELIMS=""
FORMAT=""
get_config() {
    if [ ! -f "config.cfg" ]; then
        echo "What?! No config file? Well, here's mine. Check config.cfg!"
cat << EOF > config.cfg
# Config file for version manager. This place is whitespace sensitive! Values with whitespaces don't exist for us!
# Keep everything as \`$setting: <value>\`. Exactly one space between and any spaces in value is ignored.
#   If you know regex. it's basically just \`\^\$[^:]*: <value>\`. If you can read this, it's clear that setting doesn't
#   care if there's spaces or not. If you're adding your own, just make sure you add your own logic in the script.
#   Check the README.md if you need help with this part.

# Delimeters in version string. It's the stuff that separates the numbers and words like "alpha", "beta", etc.
# Default is \`-.\`, you'll see later.
\$delims: -.

# Your version format. It's all the numbers and stuff.
# Some ground rules though:
#       Most important one: THERE MUST BE AT LEAST ONE COMPONENT
#       Make sure you use the delims to separate them! We don't want a "majorminor" component do we?
#       If you want to specify release stage (e.g. beta, alpha), name it \`release\`... we're kinda expecting it, so do that.
#       If you don't, get rid of it! Not having it is okay!
# Default is \`release-major.minor.patch\`. Most people like to use this, so we're making it the norm here.
\$format: release-major.minor.patch
EOF
        exit 1
    else
        DELIMS=$(grep "^\$[^:]*:" config.cfg | grep "delims" | sed 's/^\$[^:]*: //')
        if [ -z "$DELIMS" ]; then
            echo "You didn't set any delims. We don't like that, so we're going to assume you want \`-.\`"
            DELIMS="-."
        fi

        FORMAT=$(grep "^\$[^:]*:" config.cfg | grep "format" | sed 's/^\$[^:]*: //')
        if [ -z "" ]; then
            echo "Did you accidently delete your format? We require at least one component (as stated in the config)!"
            echo "If you need a new config or something, just delete the current one. We'll go ahead and terminate for now."
            exit 1
        fi
    fi
}

VERSION_FORMAT=""   # This is the order of labels
DELIM_FORMAT=""     # This is the order of delims
VERSION_VALS=""    # This is the actual values
RELEASE="alpha"
NUM_VERSION_VALS=0
get_version_data() {
    # Init default version stuff from the config format
    VERSION_FORMAT=($(echo "$FORMAT" | sed "s/[$DELIMS]/ /g"))
    DELIM_FORMAT=($(echo "$FORMAT" | sed "s/[^$DELIMS]/ /g" | sed "s/ */ /g"))

    # Check file exists and validate or create if it doesn't exist
    NUM_VERSION_VALS=${#VERSION_FORMAT[@]}
    local version_vals=($(echo ${VERSION_FORMAT[@]} | sed "s/[^ ]*/0/g"))
    if [ -f "$FILENAME" ]; then
        version_vals=($(grep -E "^version:" "$FILENAME" | awk '{print $2}' | sed "s/[$DELIMS]/ /g"))
        if [ $NUM_VERSION_VALS -ne ${#version_vals[@]} ]; then
            echo "Version file contains ${#version_vals[@]} components, but expecting $NUM_VERSION_VALS"
            echo "Please check params or version file"
            exit 1
        fi
    else
        echo "Wow, that's crazy. Using a version manager without a version file? Anyways, here's mine. Check $FILENAME!"

        # Inefficient, but good for one time. Build default version again before doing it later for real.
        local full_version=""
        for ((i = 0; i < NUM_VERSION_VALS; i++)); do
            if [[ "${VERSION_FORMAT[i]}" == "release" ]]; then
                version_vals[$i]="$RELEASE"
            fi
            if [ $i -ne 0 ]; then
                full_version="$full_version${DELIM_FORMAT[((i - 1))]}"
            fi

            full_version="$full_version${version_vals[i]}"
        done

        echo "format: $FORMAT" > $FILENAME # This is metadata
        echo "version: $full_version" >> $FILENAME
    fi

    VERSION_VALS=${version_vals[@]} # Make it global
}

########################
# SETUP

# All that default value and flag stuff. Please don't edit this.
FILENAME="version"
UPDATE=true
NEW_RELEASE=""
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

# Now all that config stuff. Likewise, please don't edit this... unless you have to.
get_config "config.cfg"
exit

# Deal with version datat. Similar, please don't edit this. Shouldn't need to unless your custom config needs it.
get_version_data
echo ${VERSION_VALS[@]}

# Get number of version components and check validity

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