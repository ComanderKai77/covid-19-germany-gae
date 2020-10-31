#!/usr/bin/env bash
set -o errexit
set -o errtrace
#set -o nounset
set -o pipefail

set +e
RNDSTR=$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 5 | head -n 1)
set -e

BRANCH_NAME="data-update-$(date +"%m-%d")-${RNDSTR}"

git checkout master
git pull
git branch "${BRANCH_NAME}" || true
git checkout "${BRANCH_NAME}"

source tools/env.sh

make update-csv
git status --untracked=no --porcelain
git commit data.csv -m "data.csv: update $(date +"%m-%d")" || true

make update-jhu-data

python tools/build-rki-csvs.py
git status --untracked=no --porcelain
git commit -a -m "RKI data: update: $(date +"%m-%d")" || true

python tools/build-rl-csvs.py
git status --untracked=no --porcelain
git commit -a -m "cases-rl-*: update: $(date +"%m-%d")" || true

python tools/plot-compare-sources.py
git add gae/static/data-sources-comparison-2020-* gae/static/case-rate-rw-*
git commit -a -m 'landing page update'

git push

