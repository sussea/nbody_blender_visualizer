#This script runs and visualizes milkyway_nbody using nbody_blender.
#To run this, simply feed your milkyway_nbody command to ./record.sh
#Example: ./tools/record.sh  ~/milkywayathome_client/bin/milkyway_nbody -f ~/milkywayathome_client/bin/EMD_100k_isotropic2.lua -o example.out -z example.hist -x -e 1337 -P -i 1.9 2 0.5 .5 10 .2
#Unlike nbody_gl, you cannot see the visualization until after the simulation is over.

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
`dirname $0`/generate_orbit_lua.sh $lua_file > $orbit_file

###############
#Run everything
nbody_params=$@
orbit_params=`echo "$@" | sed "s#${lua_file}#${orbit_file}#"` #Since the file paths have "\"s in them, it is easiest to just change our delimiter to #

${orbit_params}
${nbody_params}

blender `dirname $0`/../nbody15.blend --python-text Main closeoncomplete=True
exit

ffmpeg -r 49/30*8 -f image2 -pattern_type glob -i ./pics/'*.png' -vcodec h264 out.mov #For Youtube (High quality)
#ffmpeg -r 49/30*8 -f image2 -pattern_type glob -i ./pics/'*.png' -qscale:v 5 -b:v 6 -vcodec msmpeg4 out.wmv #For Windows screensavers (Low quality, which is the only thing Microsoft understands. Zing)
echo "Recording complete. Please rename your video. (Currently out.mov)"
echo "You started making this movie at ${starttime}"
echo "It finally finished at `date`"
