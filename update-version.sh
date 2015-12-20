#!/bin/sh

if [ -z ${1+x} ]; then
	echo "usage: $0 marketingVersion [buildVersion]"
	echo "buildVersion will be incremented if not specified.";
else
	xcrun agvtool new-marketing-version $1;

	if [ -z ${2+x} ]; then
		xcrun agvtool next-version;
	else
		xcrun agvtool new-version $2;
	fi

	echo "Version numbers updated. Remember to update version numbers in README instructions and elsewhere."

fi

