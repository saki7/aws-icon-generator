# aws-icon-generator (Slack custom emoji ready :zap:)

## What is this?

- Fetches latest AWS icons from [the official AWS icon distribution](https://aws.amazon.com/architecture/icons/)
- Converts EPS files into PNG
  - (I dicided not to use SVG, since they are *broken*)
- Automatically optimizes PNG using `optipng`
  - Reduces 20+% in size


## Steps

```bash
sudo apt install unzip imagemagick inkscape optipng
```

```bash
./aws-icon-generator.zsh
```

```
cd ./aws-icon-generator/aws-icon-generator-VERSION/SIZE/
```

## Configure custom emoji on Slack

[Use this Chrome extension](https://chrome.google.com/webstore/detail/slack-emoji-tools/anchoacphlfbdomdlomnbbfhcmcdmjej)

## Preview everything on Slack

On icon directory:

```bash
arr=($(ls *.png|sed -e 's/\.png$//'|sed -e 's/.*/\:&\:/'))
echo $arr[0,100]
echo $arr[101,200]
echo $arr[201,300]
```

---

## Troubleshooting

### Got old version / Could not fetch from remote

Submit a pull request on this repo or just change the `VERSION` variable in the script.

### I want larger images

You can scale up to infinite size, original images are vector graphics.

Change the `SIZE` variable in the script.

Note that Slack requires `SIZE=128` for custom emojis!

## About

- Author: Nana Sakisaka (@saki7), hakemimi (@hakemimi)
- License for this script: MIT
- License for original icons: All rights reserved (Amazon)
- Original code: https://github.com/SETNAHQ/aws-icon-generator

