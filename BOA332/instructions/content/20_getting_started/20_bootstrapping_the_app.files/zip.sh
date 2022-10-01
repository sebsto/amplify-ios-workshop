#!/bin/bash

unzip HandlingUserInput.zip
cp ../../../../code/scripts/* amplify-ios-workshop/scripts 
zip -r -X HandlingUserInput.zip amplify-ios-workshop/*
rm -r amplify-ios-workshop