#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

input=
output=
output_file=dependencies.csv
tmpd="$(mktemp -d -t dashboardXXXX)"

usage() {
cat <<EOF
usage: ${0##*/} [-h] -o OUTFILE -i FILE -v TYPE
    -h  display this help
    -i  input file path
    -o  output csv file path
    -v  2 or 3 (i.e. v2b or cnb)
EOF
exit 1
}

writeout() { output="$output""$1\n"; }

parse_repo() {
    repotmp="$tmpd/$1"
    rm -rf "$repotmp" && mkdir -p "$repotmp"
    pushd "$repotmp" > /dev/null
      if [ "$type" == 2 ]; then
        curl -sLO "https://raw.githubusercontent.com/$1/master/manifest.yml"
        yj -yj < manifest.yml > descriptor.json
        path=".dependencies"
        depkey=".name"
      else
        curl -sLO "https://raw.githubusercontent.com/$1/main/buildpack.toml"
        yj -tj < buildpack.toml > descriptor.json
        path=".metadata.dependencies"
        depkey=".id"
      fi
      deps=$(jq -r "$path" descriptor.json)
      if [ "$deps" == "[]" ] || [ "$deps" == "null" ]; then
        echo "No dependencies in $1. Skipping."
        popd > /dev/null
        return
      fi

      echo "Parsing $1"
      out=$(jq -rc "$path[] | [$depkey, .source, .uri, $type] | @csv" descriptor.json | sort -r | sort -u -t, -k1,1)
      writeout "$out"
    popd > /dev/null
}

command -v yj > /dev/null || { echo "Need yj and jq"; exit 1; }
command -v jq > /dev/null || { echo "Need yj and jq"; exit 1; }
[ "$#" -lt 6 ] && usage

OPTIND=1
while getopts ":ho:i:v:" opt; do
  case $opt in
      i)
          input="$OPTARG"
          ;;
      o)
          output_file="$OPTARG"
          ;;
      v)
          type="$OPTARG"
          ;;
      *)
          usage
          ;;
  esac
done

# writeout "Dependency, Source, Example URI, Generation"
echo Generating info for "${input}"...
while read -r line; do
    [[ "$line" = \#* ]] && continue
    [ -z "$line" ] && continue
    parse_repo "$line"
done < <(cat "$input")

echo -e "$output" | head -n -1 > "$output_file"
echo Wrote to "$output_file"
rm -rf "$tmpd"
