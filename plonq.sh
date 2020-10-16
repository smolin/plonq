#!/usr/bin/env bash
#
# curl www.molin.org | pandoc -f html - -t commonmark -o -

PLONQ_DIR=~/Archive

[ -e /sbin/md5 ] && hash_cmd=/sbin/md5
[ -e /bin/md5sum ] && hash_cmd=/bin/md5sum

function usage {
  echo '''usage: plonq subcommand arguments
subcommand: one of archive, log
    plonq archive <URL> [<tag> ...] : d/l webpage, tag with tags
environment:
    PLONQ_DIR: defaults to ~/Archive (must exist)
dependencies:
    readable (https://gitlab.com/gardenappl/readability-cli)
    md5 or md5sum
    pandoc
'''
}

function archive {
  uri="$1" ; shift
  #if [[ "$#" -gt 0 ]]; then echo "Unknown extra argument(s): $@"; usage ; exit 1; fi
  tags="$@"

  # cribbed from https://stackoverflow.com/questions/6174220/parse-url-in-shell-script
  # extract the protocol
  #protocol="$(echo $uri | grep :// | sed -e's,^\(.*://\).*,\1,g')"
  # remove the protocol
  #etc=$(echo $uri | sed -e s,$protocol,,)
  # extract the domain
  #domain=$(echo $etc | awk -F. '{print $(NF-1)}')
  #TODO: convert this whole script to Python
  #domain=$(python -c "import urlparse; print('.'.join([i for i in urlparse.urlparse(\"$uri\").netloc.split('.') if not i in ['www','www2']]))")
  domain=$(python -c "import urlparse; print(urlparse.urlparse(\"$uri\").netloc)")
  if [ -z "$domain" ]
  then
    echo "error: domain not found in URI"
    exit 1
  fi

  hash=$(echo "$uri" | "$hash_cmd")
  outfile="$PLONQ_DIR/${domain}-$hash.md"

  if [ -e "$outfile" ]
  then
    echo "error: destination $outfile exists"
    exit 1
  fi

  #echo uri: "$uri" > "$outfile" ; echo "" >> "$outfile"
  echo """    > original: $uri
    > downloaded: $(date)
    > agent: plonq webpage archiver
    > tags: $tags

""" > "$outfile"

  # w3m -dump "$uri" | sed 's/^/    /' >> "$PLONQ_DIR/${domain}-$hash.md"
  readable "$uri" | pandoc -f html - -t commonmark -o - >> "$outfile"
  echo wrote "$outfile"
  read -p 'hit enter to edit it> ' response
  $EDITOR "$outfile"
  exit 0
}

function log {
  echo logging $1
  echo and $2
  exit 0
}

if [[ "$#" -eq 0 ]]; then usage ; exit 1; fi
while [[ "$#" -gt 0 ]]; do case "$1" in
  a|archive) shift; archive $@ ;;
  l|log) shift; log $@ ;;
  *) echo "Unknown parameter passed: $1"; usage; exit 1;;
esac; shift; done
