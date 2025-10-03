#!/bin/bash

INPUT_FILE=$1   # LB list file
CHUNK_SIZE=$2   # how many LBs per file
PREFIX="lbs_chunk"

if [ -z "$INPUT_FILE" ] || [ -z "$CHUNK_SIZE" ]; then
  echo "Usage: $0 <input_file> <chunk_size>"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "Input file $INPUT_FILE not found!"
  exit 1
fi

echo "Splitting $INPUT_FILE into chunks of $CHUNK_SIZE LBs..."

lb_count=0
file_index=1
out_file="${PREFIX}_${file_index}.txt"

current_block=""

while IFS= read -r line || [[ -n "$line" ]]; do
  current_block+="$line"$'\n'

  # End of a LB block (blank line)
  if [ -z "$line" ]; then
    # Write LB block to current chunk file
    echo -n "$current_block" >> "$out_file"
    current_block=""
    lb_count=$((lb_count+1))

    # If chunk is full, finalize and prepare for next chunk
    if [ $lb_count -eq $CHUNK_SIZE ]; then
      echo "Created $out_file"
      file_index=$((file_index+1))
      out_file="${PREFIX}_${file_index}.txt"
      lb_count=0
    fi
  fi
done < "$INPUT_FILE"

# Handle any remaining LB(s) in the final chunk
if [ -s "$out_file" ]; then
  echo "Created $out_file (final chunk)"
fi