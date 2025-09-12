#!/bin/bash
# Script to break long lines (>80 chars) in all .yml and .yaml files at spaces
set -e

while true; do
  found_long_line=false
  while IFS= read -r -d '' file; do
    # Use awk to process each line
    awk '{
      line = $0;
      while (length(line) > 80) {
        # Find last space before 80th character
        split_pos = 80;
        for (i = 80; i > 1; i--) {
          if (substr(line, i, 1) == " ") {
            split_pos = i;
            break;
          }
        }
        print substr(line, 1, split_pos);
        line = substr(line, split_pos + 1);
        found_long_line = 1;
      }
      if (length(line) > 0) print line;
    }' "$file" > "$file.tmp"
    if grep -qE '^.{81,}$' "$file.tmp"; then
      found_long_line=true
    fi
    mv "$file.tmp" "$file"
  done < <(find . -type f \( -name "*.yml" -o -name "*.yaml" \) -print0)
  if ! $found_long_line; then
    break
  fi
  # Re-run until no long lines remain
  echo "Looping again to fix remaining long lines..."
done

echo "All YAML lines are now <= 80 characters."