## Helper script to remove compiled .exe files from the workspace.
## Usage: nim e tools/clean.nims
## Or:    nimble cleanup

import std/strutils

let root = getCurrentDir()
const dirs = ["tests", "examples", "build", "src"]

for dir in dirs:
  let full = root & "/" & dir
  if dirExists(full):
    for f in listFiles(full):
      if f.endsWith(".exe"):
        rmFile(f)
        echo "Removed: ", f

for f in listFiles(root):
  if f.endsWith(".exe"):
    rmFile(f)
    echo "Removed: ", f

echo "Clean complete."
