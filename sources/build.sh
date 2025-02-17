#!/bin/bash
set -e
### WIP macOS build script for Work Sans Upright and Italic VF, based on a build script by Mike LaGuttuta

# Setting the Source and VF name, determine if it's for Italic or Upright source from the argument passed to this script

# glyphsSource="ForecasterWorkSans.glyphs WorkSans-Italic.glyphs"
glyphsSource="ForecasterWorkSans.glyphs"

for i in $glyphsSource; do

	if [ $i == "ForecasterWorkSans.glyphs" ]; then
		style="Upright"
		VFname="ForecasterWorkSans-VF"
		# GXname="ForecasterWorkSansGX"
		# BraceGlyphs="a,ae,e,s"
	elif [ $i == "WorkSans-Italic.glyphs" ]; then
		style="Italic"
		VFname="WorkSans-Italic-VF"
		# GXname="WorkSansItalicGX"
		# BraceGlyphs="ae,e,s"
	fi

	# Generate -build version of .glyphs files with bracket tricks enabled, also add extra OpenType code for featureVariation to work
	python tools/makeBuildGlyphsFile.py "${i}"
	glyphsBuildSource=${i/".glyphs"/"-build.glyphs"}

	# Call fontmake to generate variable font
	echo "\tBuilding ${i}..."
	fontmake -o variable -g $glyphsBuildSource
	echo "\t${VFname}.ttf generated"

	# Clean up files
	mv variable_ttf/${VFname}.ttf ${VFname}.ttf
	rm $glyphsBuildSource
	rm -rf master_ufo
	rm -rf instance_ufo
	rm -rf variable_ttf

	# ttx ${VFname}.ttf
	# rm ${VFname}.ttf
	# ttx ${GXname}.ttf
	# mv ${GXname}.ttx tools/${GXname}.ttx

	# # Copy brace glyphs from variable font generated from Glyphs App

	# # Run script to find and copy TTGlyph and glyphVariations elements from source file and copy into target file
	# # Could probably be done just with fonttools...
	# echo "\tAdding brace glyphs..."
	# xml tr tools/replaceBraceGlyphs.xsl \
	#     -s replacements=${GXname}.ttx \
	#     -s replacenames=$BraceGlyphs \
	#     ${VFname}.ttx > ${VFname}-brace.ttx

	# # Use fontTools to replace brace glyphs
	# python tools/replaceBraceGlyphs.py ${VFname}.ttf ${GXname}.ttf $BraceGlyphs

	# # Clean up files
	# rm tools/${GXname}.ttx
	# rm ${VFname}.ttx
	# ttx ${VFname}-brace.ttx
	# rm ${VFname}-brace.ttx
	# mv ${VFname}-brace.ttf ${VFname}.ttf

	# Add featureVariation for bracket trick glyphs
	echo "\tAdding bracket glyphs..."
	python tools/replaceBracketTrick.py ${VFname}.ttf "$1"
	mv ${VFname}-swap.ttf ${VFname}.ttf

	# Fix non-hinting and GASP table
	echo "\tFixing non-hinting and GASP table"
	gftools fix-nonhinting ${VFname}.ttf ${VFname}.ttf
	gftools fix-gasp ${VFname}.ttf

	# Clean up files
	rm ${VFname}-backup-fonttools-prep-gasp.ttf
	# rm ${GXname}.ttf
done


# Fix VF Metadata
# VFfonts=""
# for i in *.ttf; do
# 	VFfonts+="$i "
# done
# VFfonts="WorkSans-Italic-VF.ttf ForecasterWorkSans-VF.ttf"
VFfonts="ForecasterWorkSans-VF.ttf"
echo "\tFixing VF Family Metadata..."
python3 tools/gftools-fix-vf-meta.py $VFfonts


# Clean up VFs
for i in $VFfonts; do
	rm "$i"
done


# VFfontsFix="WorkSans-Italic-VF.ttf.fix ForecasterWorkSans-VF.ttf.fix"
VFfontsFix="ForecasterWorkSans-VF.ttf.fix"


# ttfautohint-vf
for i in $VFfontsFix; do
	echo "\tttfautohint-vf $i..."
	tools/ttfautohint-vf --stem-width-mode nnn "$i" "$i".ttfa
	rm "$i"
	ifix="${i}.ttfa"
	mv $ifix ${ifix/".ttf.fix.ttfa"/".ttf"}
done


# Fix DSIG
for i in $VFfonts; do
	echo "\tFixing DSIG $i..."
	gftools fix-dsig --autofix "$i"
done


# mv ForecasterWorkSans-VF.ttf WorkSans-Roman-VF.ttf
