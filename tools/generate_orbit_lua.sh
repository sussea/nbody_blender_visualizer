# This script is for generating single-particle (orbit) lua files for milkyway@home.
# The generated lua file allows milkyway@home to give nbody_blender an orbit to visualize in its orbit tracer (and to set the camera)
# All this script does is replace the return statement in makeBodies with a single-particle return

if [[ "$#" -lt 1 ]]
then
	echo "You have to give me a lua file."
	exit
fi

commands_with_end="function if while for"
nest_count=0
comment_nesting=false
in_makeBodies=false
in_reverseOrbit=false

# Prevent comments from confusing stuff like the update_nest_count function
function remove_comments () {
	initial_line="$1"
	final_line=""
	for word in "$initial_line"
	do
		if [[ "$comment_nesting" -eq false ]]
		then
			if [[ ${initial_line:0:4} == "--[[" ]]
			then
				comment_nesting=true
			elif [[ ${initial_line:0:2} == "--" ]]
			then
				echo "$final_line"
				return 0
			else
				final_line="${final_line}${word} "
			fi
		else
			if [[ ${initial_line:0:4} == "--]]" ]]
			then
				comment_nesting=false
			fi
		fi
	done
	echo "$final_line"
	return 0
}

# Finds if line $1 contains words $2 or $3 or $4 or..., and returns the matches in the found order (though echo)
function find_word_matches() {
	line=$1
	matches=""
	for word in $line
	do
		for i in `seq 2 $#`
		do
			eval "sought_word=\$$i"
			if [[ "$word" == "$sought_word" ]]
			then
				matches="${matches} ${sought_word}"
			fi
		done
	done
	echo "$matches"
	return 0
}

# Uses lua syntax to keep track of nesting
function update_nest_count () {
	line=$1
	nest_openers=$(find_word_matches "$line" $commands_with_end)
	nest_closers=$(find_word_matches "$line" "end")
	add=`echo "$nest_openers" | wc -w`
	sub=`echo "$nest_closers" | wc -w`
	if [[ "$nest_openers" == "" ]]
	then
		add=0
	fi
	if [[ "$nest_closers" == "" ]]
	then
		sub=0
	fi
	nest_count=`expr "$nest_count" + "$add" - "$sub"`
	return 0
}

while IFS='' read -r line
do
	line=$(remove_comments "$line")
	if [[ "$line" == *"makeBodies"* ]]
	then
		in_makeBodies=true
	fi
	if [[ "$in_makeBodies" == true ]]
	then
		update_nest_count "$line"
		if [[ "$nest_count" -eq 0 ]]
		then
			echo "    bodies = {"
			echo "	Body.create{"
			echo "		mass = dwarfMass,"
			echo "	        position  = finalPosition,"
			echo "	        velocity  = finalVelocity,"
			echo "	        ignore    = false"
			echo "	}"
			echo "     }"
			echo "    return bodies"
			echo "end"
			in_makeBodies=false
		elif [[ "$line" != *"return"* ]]
		then
			echo "$line"
		fi
	else
		echo "$line"
	fi
done < $1
