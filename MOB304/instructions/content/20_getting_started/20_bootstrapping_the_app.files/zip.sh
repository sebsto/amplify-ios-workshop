#!/bin/bash

unzip HandlingUserInput.zip
cp ../../../../code/scripts/* scripts 
zip -r -X HandlingUserInput.zip Complete/ scripts/ ProjectFiles.md
rm -r Complete/ ProjectFiles.md  scripts/