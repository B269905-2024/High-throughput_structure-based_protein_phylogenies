#!/bin/bash

nwk_file="full_p_value_JCVI_no_nan.nwk"
mapping_file="protein_names.tsv"
output_file="full_p_value_JCVI_no-nan_named.nwk"
failed_log="failed_to_replace.tsv"

#run only if mapping file exists in current dir
if [[ ! -f "$mapping_file" ]]; then
    echo "Error: Mapping file '$mapping_file' not found. Exiting."
    exit 1
fi

declare -A name_map

while IFS=$'\t' read -r code accession rest; do
#    rest=$(echo "$rest" | xargs)
    rest=$(echo "$rest" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    full_name="${accession}_${rest}"
    name_map["$code"]="$full_name"
done < "$mapping_file"

#extraxt leaf labels
grep -o '[^(:),]*:[0-9eE+.-]*' "$nwk_file" | cut -d':' -f1 | sort -u > all_labels.txt

#new nwk file
cp "$nwk_file" "$output_file"
> "$failed_log"

#replace leaf labels with full protein names
while read -r code; do
    code=$(echo "$code" | xargs)
    if [[ -n "$code" && -n "${name_map["$code"]}" ]]; then
        safe_name=$(printf '%s\n' "${name_map["$code"]}" | sed -e 's/[\/&]/\\&/g')
        sed -i "s/\b$code\b/$safe_name/g" "$output_file"
    else
        echo "$code" >> "$failed_log"
    fi
done < all_labels.txt

rm all_labels.txt

echo "leaf names repalced with full protein names"
echo "named tree: $output_file"
echo "unmatched leaf names: $failed_log"

