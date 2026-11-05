#!/bin/sh
set -eu

VERSION=$1
ZIP=$2
TAP=santiagohervella/homebrew-tap
CASK=Casks/letter-switch.rb

GH_TOKEN=$(gh auth token --user santiagohervella)
export GH_TOKEN

SHA256=$(shasum -a 256 "$ZIP" | cut -d ' ' -f 1)
CURRENT=$(gh api "repos/$TAP/contents/$CASK")
UPDATED=$(echo "$CURRENT" | jq -r .content | base64 -d \
	| sed -e "s/^  version \".*\"/  version \"$VERSION\"/" -e "s/^  sha256 \".*\"/  sha256 \"$SHA256\"/" \
	| base64)

gh api --method PUT "repos/$TAP/contents/$CASK" \
	-f message="Update letter-switch to $VERSION" \
	-f content="$UPDATED" \
	-f sha="$(echo "$CURRENT" | jq -r .sha)" \
	-f "committer[name]=santiagohervella" \
	-f "committer[email]=57931354+santiagohervella@users.noreply.github.com" \
	--silent
echo "updated $TAP to letter-switch $VERSION"
