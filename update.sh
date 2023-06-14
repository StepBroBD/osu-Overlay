#!/usr/bin/env nix-shell
#!nix-shell -i bash -p unzip curl jq

set -eo pipefail

old_version="2023.610.0"

new_version=$(curl -s "https://api.github.com/repos/ppy/osu/releases?per_page=1" | jq -r ".[].name")
if [[ "$new_version" == "$old_version" ]]; then
	echo "Already up to date."
	exit 0
else
	echo "TAG=$new_version" >>$GITHUB_ENV
	echo "PUSH=true" >>$GITHUB_ENV
	echo "osu-lazer-bin: $old_version -> $new_version"
	sed -Ei.bak '6s/( *old_version=")[^"]+/\1'"$new_version"'/' update.sh
	rm update.sh.bak
fi

for pair in \
	"aarch64-darwin osu.app.Apple.Silicon.zip" \
	"x86_64-darwin osu.app.Intel.zip" \
	"x86_64-linux osu.AppImage"; do
	set -- $pair
	url="https://github.com/ppy/osu/releases/download/$new_version/$2"
	prefetch_output=$(nix --extra-experimental-features nix-command store prefetch-file --json --hash-type sha256 "$url")
	if [[ "$1" == *"darwin"* ]]; then
		store_path=$(jq -r ".storePath" <<<"$prefetch_output")
		tmpdir=$(mktemp -d)
		unzip -q "$store_path" -d "$tmpdir"
		hash=$(nix --extra-experimental-features nix-command hash path "$tmpdir")
		rm -r "$tmpdir"
	else
		hash=$(jq -r ".hash" <<<"$prefetch_output")
	fi
	printf "$1 = {\n\tsrc = \"$url\";\n\tsha256 = \"$hash\";\n};\n"
	printf "\"$url\"" >"systems/$1/url.nix"
	printf "\"$hash\"" >"systems/$1/sha256.nix"
done
