# dep-lister

This tool generates a csv file listing buildpack dependencies (v2/v3) from a
line delimited input file.

```sh
usage: generate.sh [-h] -o OUTFILE -i FILE -v TYPE
    -h  display this help
    -i  input file path
    -o  output csv file path
    -v  2 or 3 (i.e. v2b or cnb)
```

### Run

```sh
# Generate output files
./generate.sh -i inputs/v2 -o outputs/v2.csv -v 2
./generate.sh -i inputs/v3 -o outputs/v3.csv -v 3
```

```sh
# Concat and add header
cat <(echo "Dependency, Source, Example URI, Generation") <(cat outputs/v2.csv outputs/v3.csv | sort -u) > outputs/combined.csv
```

`combined.csv` is generated in your `outputs` dir. Now upload this to your
google spreadsheets. If you want to, quickly combine rows with same dependency
for v2 and v3 using some spreadsheet formula or by hand.

### Requirements:

* [jq](https://stedolan.github.io/jq/)
* [yj](https://github.com/sclevine/yj)
