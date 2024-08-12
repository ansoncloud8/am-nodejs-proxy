#!/bin/sh

# build.sh
# This is an example of some "process". Here it uses
# pandoc to convert from MarkDown to different formats
# and saves the output into "output_temp"

OUTPUT_DIR="output_temp"

mkdir "$OUTPUT_DIR"


date > "$OUTPUT_DIR"/.build_date.txt

echo "generated_at: $(date)" > variables.yml

#mustache variables.yml index.output.html > "$OUTPUT_DIR"/index.html
#mustache variables.yml README.output.md > "$OUTPUT_DIR"/README.md
