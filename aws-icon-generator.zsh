#!/bin/zsh +x

#
# aws-icon-generator.zsh
#   https://github.com/saki7/aws-icon-generator
#
# Distributed under the MIT license,
# All icons are All Rights Reserved (Amazon).
#


# --------------------------------------------------------
# Change this if you want
# --------------------------------------------------------
VERSION="17.1.19"
SIZE="128" # You should set 128 for Slack emojis!
# --------------------------------------------------------

APP=aws-icon-generator
TMP="${APP}/${APP}-${VERSION}/${SIZE}x${SIZE}"
CACHE="${APP}/cache/${VERSION}"
NAME="AWS_Simple_Icons_EPS-SVG_v${VERSION}"
REAL_DIR="$NAME"
ZIPBALL="${NAME}.zip"
URL="https://media.amazonwebservices.com/AWS-Design/Arch-Center/${VERSION}_Update/$ZIPBALL"


# mkdir -p "$TMP"
mkdir -p "$CACHE"

ORIGINAL="$CACHE/original"
# mkdir -p "$ORIGINAL"

CONVERTED="$TMP"
mkdir -p "$CONVERTED"

wget -nc -O "$CACHE/$ZIPBALL" "$URL"
if [[ ! -d "$ORIGINAL" ]]; then
  unzip -d "$ORIGINAL" "$CACHE/$ZIPBALL"

  echo "Deleting __MACOSX"
  rm -rf "$ORIGINAL/__MACOSX"

  echo "Deleting GRAYSCALE"
  rm -rf "$ORIGINAL/$REAL_DIR/GRAYSCALE"

  echo "Deleting unused svg files"
  rm -f $ORIGINAL/$REAL_DIR/**/*.svg

  echo "Deleting unused png files"
  rm -f $ORIGINAL/$REAL_DIR/**/*.png
fi


epss=($ORIGINAL/$REAL_DIR/**/*.eps)
echo ""
echo ""
echo "===================================================="
echo "Found ${#epss[@]} eps files"
echo "===================================================="
total_orig=0
total_opt=0
ids=()
i=0

echo ""
echo ""

blacklist=('Migration_AWSDMS' 'Migration_AWSSnowball' 'DesktopAppStreaming_AmazonAppStream2.0')
safe_ignore=('Analytics_')
acronyms=(CloudWatch OpsWorks IoT iOS SDKs API HDFS EMR EFS HTTPS HTTP PIOP MSSQL MySQL SQL VPC MQTT)
dupes=()

for eps in "${epss[@]}"; do
  let ++i
  echo "--------------------------------------------"
  echo "(${i}/${#epss[@]})"
  echo "--------------------------------------------"

  f=$(basename "$eps")
  f="${f%.*}"

  echo "On \"$f.png\""
  for rgx in $blacklist; do
    if [[ "$f" =~ "^${rgx}" ]]; then
      echo "(blacklisted)"
      continue
    fi
  done

  id="$f"

  # 0) Acronyms
  for acr in $acronyms; do
    id=$(echo "$id"|sed -e "s/${acr}/-\\L&-/g")
  done

  # 0.1) Acronyms, special
  id=$(echo "$id"|sed -e 's/^SDKs/sdk-/'|sed -e 's/AWSSTS/-sts-/g')

  # 0.2) Trailing version number
  id=$(echo "$id"|sed -e 's/[0-9]\+.[0-9]\+$/-&/')

  # 1) (Amazon|AWS)* -> *
  id=$(echo "$id"|sed -e 's/^\([^_]\+\)_//'|sed -e 's/^\(Amazon\|AWS\)//i')

  # 1.1) Always prepend dash
  id="-$id"

  # 2) ABC- -> -abc-
  id=$(echo "$id"|sed -e 's/\(\([A-Z]\+\)[-_]\)/-\L\2-/g')

  # 2.9) CODE123 -> -code123-
  id=$(echo "$id"|sed -e 's/[A-Z]\+[0-9]\+/-\L&-/g')

  # 3) BBBfoo -> -bbb-foo
  id=$(echo "$id"|sed -e 's/[A-Z]\{2,\}/-\L&-/g')

  # 4) Name -> -name
  id=$(echo "$id"|sed -e 's/[A-Z]/-\L&/g')

  # 5) Sanitize
  id=$(echo "aws$id"|sed -e 's/[^a-zA-Z0-9]/-/g'|sed -e 's/-\+/-/g'|sed -e 's/-$//')
  ids+="$id"

  echo "id: $id"
  png="$CONVERTED/${id}.png"
  if [[ -f "$png" ]]; then
    ignore=0
    for target in $safe_ignore; do
      if [[ "$f" =~ "^$target" ]]; then
        echo "(ignored safely)"
        ignore=1
        break
      fi
    done

    if [[ ! -z $ignore ]]; then
      continue
    fi

    (
      echo ""
      echo "WARNING: File with ID ${id} already exists!"
      echo "If this is not related to the cache behavior, you must fix this script."
      echo "Otherwise: rm -rf ${TMP}"
      echo ""
    ) 1>&2
    dupes+="$id"
  fi


  inkscape --without-gui --export-png="$png" --export-background=FFFFFF --export-background-opacity=0 --export-dpi=96 -w "$SIZE" -h "$SIZE" "$eps" >/dev/null
  size_orig=$(($(stat --printf="%s" "$png")))
  let total_orig+=$size_orig

  echo "Optimizing..."
  optipng -clobber -nx -strip all -o5 "$png" >/dev/null 2>&1
  size_opt=$(($(stat --printf="%s" "$png")))
  let total_opt+=$size_opt

  if [[ ! "$size_opt" -le $((64*1024)) ]]; then
    printf "FATAL: Optimized image is larger than Slack limit 64KB (%.2fKB)." $(($size_opt / 1024.)) 1>&2
    exit 1
  fi

  size_diff=$((${size_orig} - ${size_opt}))
  size_diff_pct=$((${size_diff} / ${size_orig}. * 100))

  printf "Size: %d - %d = %d (-%.2lf%%)\n" "$size_orig" "$size_diff" "$size_opt" "$size_diff_pct"
done

echo "Success! Navigate to: \"${CONVERTED}\""
(
  echo ""
  echo "-------------------------------------------"
  echo "Summary"
  echo "-------------------------------------------"
  echo "Files processed: ${#epss[@]}"

  total_diff=$((${total_orig} - ${total_opt}))
  total_diff_pct=$((${total_diff} / ${total_orig}. * 100))
  printf "Total size (original):  %s\n" $(numfmt --to=iec-i --suffix=B --format="%.2f" $total_orig)
  printf "Total size (optimized): %s (-%.2lf%%)\n" $(numfmt --to=iec-i --suffix=B --format="%.2f" $total_opt) "$total_diff_pct"

  echo ""
  echo "-------------------------------------------"
  echo "ids"
  echo "-------------------------------------------"
  echo $ids|sort
  echo ""

  echo "-------------------------------------------"
  echo "duplicates (if any)"
  echo "-------------------------------------------"
  echo $dupes|sort

  echo ""
  echo ""
  echo "-------------------------------------------"
  echo "Manual step"
  echo "-------------------------------------------"
  echo ""
  echo "cd $CONVERTED"
  echo ""
  echo ""
  echo "(For Slack emoji)"
  echo "You can use a Chrome extension for bulk upload:"
  echo "https://chrome.google.com/webstore/detail/slack-emoji-tools/anchoacphlfbdomdlomnbbfhcmcdmjej"
  echo ""
)

