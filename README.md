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
./run.sh -sa
```

Or set custom `local.list` file and run:

```bash
./run.sh -ll -sa
```

Or just run:

```bash
./run.sh
```

You can just download zones to local catalog:

```bash
./run.sh -do
```

You can pass country code with `-c` option:

```bash
./run.sh -c "br"
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

## AllZones from IpDeny 

If [ipdeny.com](https://www.ipdeny.com/ipblocks/) restricted from your region, you can download regularly updated file from this repo.

![geo2drop update all IP zones date](https://raw.githubusercontent.com/m0zgen/geo2drop/data/badge_date.svg)

Download example:

```bash
wget https://github.com/m0zgen/geo2drop/raw/data/all-zones.tar.gz
```

