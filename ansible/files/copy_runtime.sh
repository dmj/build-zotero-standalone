#!/bin/bash
set -euo pipefail

# Copyright (c) 2011  Zotero
#                     Center for History and New Media
#                     George Mason University, Fairfax, Virginia, USA
#                     http://zotero.org
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

CALLDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$CALLDIR/config.sh"

#
# Make various modifications to omni.ja
#
function modify_omni {
	mkdir omni
	mv omni.ja omni
	cd omni
	# omni.ja is an "optimized" ZIP file, so use a script from Mozilla to avoid a warning from unzip
	# here and to make it work after rezipping below
	python2.7 "$CALLDIR/scripts/optimizejars.py" --deoptimize ./ ./ ./
	unzip omni.ja
	rm omni.ja
	
	# Modify AddonConstants.jsm in omni.ja to allow unsigned add-ons
	#
	# Theoretically there should be other ways of doing this (e.g., an 'override' statement in
	# chrome.manifest, an enterprise config.js file that clears SIGNED_TYPES in XPIProvider.jsm),
	# but I couldn't get them to work.
	perl -pi -e 's/value: true/value: false/' modules/addons/AddonConstants.jsm
	# Delete binary version of file
	rm -f jsloader/resource/gre/modules/addons/AddonConstants.jsm
	
	# Disable transaction timeout
	perl -pi -e 's/let timeoutPromise/\/*let timeoutPromise/' modules/Sqlite.jsm
	perl -pi -e 's/return Promise.race\(\[transactionPromise, timeoutPromise\]\);/*\/return transactionPromise;/' modules/Sqlite.jsm
	rm -f jsloader/resource/gre/modules/Sqlite.jsm
	
	# Disable unwanted components
	cat components/components.manifest | grep -vi telemetry > components/components2.manifest
	mv components/components2.manifest components/components.manifest
	
	# Change text in update dialog
	perl -pi -e 's/A security and stability update for/A new version of/' chrome/en-US/locale/en-US/mozapps/update/updates.properties
	perl -pi -e 's/updateType_major=New Version/updateType_major=New Major Version/' chrome/en-US/locale/en-US/mozapps/update/updates.properties
	perl -pi -e 's/updateType_minor=Security Update/updateType_minor=New Version/' chrome/en-US/locale/en-US/mozapps/update/updates.properties
	perl -pi -e 's/update for &brandShortName; as soon as possible/update as soon as possible/' chrome/en-US/locale/en-US/mozapps/update/updates.dtd
	
	zip -qr9XD omni.ja *
	mv omni.ja ..
	cd ..
	python2.7 "$CALLDIR/scripts/optimizejars.py" --optimize ./ ./ ./
	rm -rf omni
}

# Add devtools server from browser omni.ja
function extract_devtools {
	set +e
	unzip browser/omni.ja 'chrome/devtools/*' -d devtools-files
	unzip browser/omni.ja 'chrome/en-US/locale/en-US/devtools/*' -d devtools-files
	mv devtools-files/chrome/en-US/locale devtools-files/chrome
	rmdir devtools-files/chrome/en-US
	unzip browser/omni.ja 'components/interfaces.xpt' -d devtools-files
	set -e
}

cd xulrunner/firefox-x86_64

modify_omni
extract_devtools

cd ..

echo Done
