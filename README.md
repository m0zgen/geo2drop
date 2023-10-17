# Ban Countries

With installed firewalld drop zone and ipset, you can block countries with the following script.

Change the variable `COUNTRIES` to the country you want to block.

```bash
COUNTRIES="br cn in"
```

## Usage

You can use the script with the following command:

```bash
./run.sh -u                                                                                            1 ms  master 
Usage: ./run.sh [options]
Options:
  -c, --countries <countries>  Countries to block (default: br cn in id)
  -l, --list <list>            Name of the ipset list (default: blcountries)
  -m, --maxelem <maxelem>      Maximum number of elements in the ipset list (default: 131072)
  -h, --hashsize <hashsize>    Hash size of the ipset list (default: 32768)
  -u, --usage                  Show this message (help)
```