echo "I NEED TO FIX THIS. EXITING."
return

###############################################
#Semi-automatic file cleaning prevents mistakes
if [ -s out.mov ]; then
    echo "File out.mov already exists. Delete it? (y/q) (Default q)"
    read delete
    if [ "$delete" == "y" ]; then
        rm out.mov
        echo "Deleted"
    else
        echo "Cancelled"
        exit
    fi
fi
if [ "$(ls ./pics)" != "" ]; then
    echo "There are still frames in ./pics from your last recording. They must be removed before making a new recording. Delete them? (y/q) (Default q)"
    read delete
    if [ "$delete" == "y" ]; then
        rm ./pics/*
        echo "Deleted"
    else
        echo "Cancelled"
        exit
    fi
fi

startdate=`date`

###########################################################
#Prepare the lua and its _orbit (one particle) counterpart.
found_lua=false #We want to iterate over the arguments one extra time after finding "-f"

for arg in "$@"
do
    if [[ ${found_lua} == true ]]; then break; fi
    if [[ ${arg} == "-f" ]]; then found_lua=true; fi
done

if [[ found_lua == false ]]; then echo "Error: Did you forget to specify a lua file?"; exit; fi

lua_file=${arg}
lua_base=`basename ${lua_file} .lua`
orbit_file=`echo ${lua_file} | sed "s/\(.*\)${lua_base}.lua/\1${lua_base}_orbit.lua/"`

cat ${lua_file} | sed "s/\(model1Bodies =\).*$/\1 1/" > ${orbit_file}

###############
#Run everything
nbody_params=$@
orbit_params=`echo "$@" | sed "s#${lua_file}#${orbit_file}#"` #Since the file paths have "\"s in them, it is easiest to just change our delimiter to #

../bin/milkyway_nbody ${orbit_params}
../bin/milkyway_nbody ${nbody_params} &

sleep 10
#Starting now, you can safely begin nbody_blender even though the simulation isn't done. Blender is so slow it won't catch up with milkyway_nbody.
blender nbody15.blend --python-text Main

ffmpeg -r 49/30*8 -f image2 -pattern_type glob -i ./pics/'*.png' -vcodec h264 out.mov #For Youtube (High quality)
#ffmpeg -r 49/30*8 -f image2 -pattern_type glob -i ./pics/'*.png' -qscale:v 5 -b:v 6 -vcodec msmpeg4 out.wmv #For Windows screensavers (Low quality, which is the only thing Microsoft understands. Zing)
echo "Recording complete. Please rename your video. (Currently out.mov)"
echo Start Time: ${starttime}
echo End Time: `date`
