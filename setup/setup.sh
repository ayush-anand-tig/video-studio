#!/bin/zsh
# One-shot bootstrap from the transfer bundle: copies both projects to ~/code, runs their installers and tests,
# commits exactly what was tested, then creates the GitHub repos (public by default) and pushes.
# Safe to re-run: completed steps are detected and skipped. Nothing is published until every check passes.
# Usage: ./setup.sh --user <github-username> [--dest ~/code] [--private] [--skip-tests]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/code"; USER_EXPECTED=""; VIS="public"; SKIP_TESTS=0
PROJECTS=(shravan video-studio)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) USER_EXPECTED="${2:?--user needs a value}"; shift 2 ;;
    --dest) DEST="${2:?--dest needs a value}"; shift 2 ;;
    --private) VIS="private"; shift ;;
    --skip-tests) SKIP_TESTS=1; shift ;;   # skips Shravan's editor tests only; builds and installs still run
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done
step() { print -P "\n%B==> $1%b"; }
die()  { echo "STOP: $1"; exit 1; }

step "1/6 Tools + identity"
for t in git gh; do command -v $t >/dev/null || die "missing $t (brew install $t)"; done
git config --global user.name >/dev/null || die "set git identity: git config --global user.name 'Your Name'; git config --global user.email you@example.com"
gh auth status >/dev/null 2>&1 || die "not logged in to GitHub. Run: gh auth login, then re-run"
GH_USER="$(gh api user --jq .login)"; echo "GitHub: $GH_USER"
[[ -n "$USER_EXPECTED" ]] || die "re-run with --user $GH_USER to confirm this is your PERSONAL account"
[[ "$GH_USER" == "$USER_EXPECTED" ]] || die "logged in as $GH_USER, not $USER_EXPECTED"
mkdir -p "$DEST"; DEST="$(cd "$DEST" && pwd -P)"

step "2/6 Preflight GitHub (before anything is published)"
for p in $PROJECTS; do
  url="https://github.com/$GH_USER/$p"
  if gh repo view "$GH_USER/$p" >/dev/null 2>&1; then
    origin="$(git -C "$DEST/$p" config --get remote.origin.url 2>/dev/null || true)"
    [[ "${origin%.git}" == "$url" || "${origin%.git}" == "git@github.com:$GH_USER/$p" ]] \
      || die "$url already exists and isn't the origin of $DEST/$p. Rename/delete it on GitHub, or link it: git -C $DEST/$p remote add origin $url"
    v="$(gh repo view "$GH_USER/$p" --json visibility --jq .visibility | tr 'A-Z' 'a-z')"
    [[ "$v" == "$VIS" ]] || die "$url is $v but $VIS was requested. Change it on GitHub or pass the matching flag"
    echo "resume: $url ($v)"
  else
    echo "new: $url"
  fi
done

step "3/6 Copy to $DEST"
for p in $PROJECTS; do
  d="$DEST/$p"
  [[ -L "$d" ]] && die "$d is a symlink. Remove it and re-run"
  if [[ -d "$d/.git" ]]; then
    [[ -f "$d/setup/START_HERE.md" ]] || die "$d is a git repo not created by this script. Move it away or use --dest"
    echo "existing: $d"
  elif [[ -e "$d" ]]; then die "$d exists but isn't a git repo. Move it away and re-run"
  else
    cp -R "$HERE/$p" "$d"
    mkdir -p "$d/setup"; cp "$HERE/setup.sh" "$HERE/START_HERE.md" "$d/setup/"
    git -C "$d" init -q -b main
    echo "copied: $d"
  fi
done

step "4/6 Install + test"
(cd "$DEST/video-studio" && ./install.sh) || die "video-studio install failed: fix it and re-run"
if [[ $SKIP_TESTS == 1 ]]; then (cd "$DEST/shravan" && ./install.sh --skip-tests) || die "shravan build failed: fix it and re-run"
else (cd "$DEST/shravan" && ./install.sh) || die "shravan tests failed: fix them, or re-run with --skip-tests if only Apple Intelligence cases fail"; fi

step "5/6 Commit exactly what was tested"
for p in $PROJECTS; do
  d="$DEST/$p"
  git -C "$d" add -A
  if ! git -C "$d" rev-parse -q --verify HEAD >/dev/null; then git -C "$d" commit -q -m "Initial import"; echo "committed: $p"
  elif ! git -C "$d" diff --cached --quiet; then git -C "$d" commit -q -m "Setup fixes"; echo "committed changes: $p"
  else echo "clean: $p"; fi
  [[ -z "$(git -C "$d" status --porcelain)" ]] || die "$d still has uncommitted changes"
done

step "6/6 Publish ($VIS)"
for p in $PROJECTS; do
  d="$DEST/$p"
  if git -C "$d" remote get-url origin >/dev/null 2>&1; then git -C "$d" push -q -u origin main; echo "pushed: $p"
  else (cd "$d" && gh repo create "$p" --$VIS --source . --push >/dev/null); echo "created: https://github.com/$GH_USER/$p"; fi
done

echo; for p in $PROJECTS; do echo "https://github.com/$GH_USER/$p"; done
echo "Next: cd $DEST/<project> && claude"
