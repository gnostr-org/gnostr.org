SED=$(which sed)
echo $SED
export SED
GSED=$(which gsed)
echo $GSED
export GSED
SED=${SED:-GSED}
result=${PWD##*/} | $SED 's/[.]+/-/g'
org=${result/-/.}
echo $result
echo $org

gh repo list gnostr-org --limit 1000 | while read -r repo _; do
  gh repo clone "$repo" "$repo" -- -q 2>/dev/null || (
    cd "$repo"
    # Handle case where local checkout is on a non-main/master branch
    # - ignore checkout errors because some repos may have zero commits,
    # so no main or master
    git checkout -q main 2>/dev/null || true
    git checkout -q master 2>/dev/null || true
    git pull -q
  )
done
gh repo list rust-nostr --limit 1000 | while read -r repo _; do
  gh repo clone "$repo" "$repo" -- -q 2>/dev/null || (
    cd "$repo"
    # Handle case where local checkout is on a non-main/master branch
    # - ignore checkout errors because some repos may have zero commits,
    # so no main or master
    git checkout -q main 2>/dev/null || true
    git checkout -q master 2>/dev/null || true
    git pull -q
  )
done
