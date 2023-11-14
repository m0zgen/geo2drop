# Ban Countries

With installed firewalld drop zone and ipset, you can block countries with the following script.

Change the variable `COUNTRIES` to the country you want to block.

```bash
ZONES="br cn in"
```

## Features

- [x] Download defined zones from ipdeny.com
- [x] Download all zones from ipdeny.com with archive
- [x] Download zones to local folder
- [x] Setup ipsets from local downloaded zones
- [x] Setup ipset from downloaded archive
- [x] Delete ipset from firewalld
- [x] Setup ipset from local downloaded zones
- [x] Setup ipset from downloaded archive
- [x] Add zones from files located in repo (if ipdeny site not available)
- [x] Use alternative zones mirror (if ipdeny site not available)

## Usage

You can use the script with the following command:

```bash
./run.sh -daz; ./run.sh -sa
```

Or just run:

```bash
./run.sh
```

Or from try download zones, if it not available install it from repo located zones:

```bash
./run.sh -dl; ./run.sh -lz
```

You can pass multiple argument to the script:

```bash
./run.sh -c "br" -sl
```

Script will try to download `br` zone from ipdeny.com and setup ipset from local downloaded zones, if ipdeny site not available, script will setup ipset from repo located zones.

## Usage commands

You can use the script with the following command `./run.sh -h`:

```bash
Usage: ./run.sh [options]
Options:
  -ln, --list-name <list>      Name of the ipset list (default: blcountries)
  -mx, --maxelem <maxelem>     Maximum number of elements in the ipset list (default: 131072)
  -hx, --hashsize <hashsize>   Hash size of the ipset list (default: 32768)
  -am, --alternative-mirror    Another IP source mirror (default: ipdeny.com)
  -daz, --download-all-zones   Download all country zones from ipdeny.com (all-zones.tar.gz)
  -di, --delete-ipset          Delete ipset from firewalld (default: blcountries)
  -dl, --download-local        Download zones to local folder
  -sl, --setup-from-local      Setup ipsets from local downloaded zones
  -sa, --setup-from-archive    Setup ipset from downloaded archive
  -h, --help                   Show this message (help)
```
