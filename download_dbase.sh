#!/bin/bash

set -euo pipefail

MIDAS_DBASE_URL=http://collaboration.cmc.ec.gc.ca/science/outgoing/goas/

declare -A archiveDatabase
archiveDatabase[midas_observations.tar.gz]="9c0f114475aa9c0a3f84c4c5ab0865df"
archiveDatabase[midas_constants.tar.gz]="424a7404e26db18585390aff730e2f83"
archiveDatabase[midas_results.tar.gz]="2822c5c45252b3795efdd697a558b42b"
#archiveDatabase[midas_ensemble.tar.gz]="thisisamd5sum"

printUsage() {
    echo -e "Download a sample database of data files needed to run MIDAS benchmarks."
    echo -e "If a local database archive is provided, use it instead"
    echo -e "Usage:"
    echo -e "./$(basename $0) <MIDAS-GIT-DIR> [Local MIDAS dbase archive path]\n"
    echo -e "Usually, MIDAS-GIT-DIR is the current directory, so use:"
    echo -e "./$(basename $0) ."
} ## End of function 'printUsage()'

checkMd5() {
    # $1 File path
    # Return: 0 if matching; 1 otherwise
    typeset -r archiveName=${1}
    typeset -r md5=$(md5sum ${archiveName} | cut -d' ' -f1)

    typeset -r fileName=$(basename ${archiveName})
    typeset -r md5_reference=${archiveDatabase[${fileName}]}

    [[ "${md5}" = "${md5_reference}" ]]
} ## End of function 'checkMd5()'

downloadArchive() {
    # ${1} archive name
    # ${2} archive destination
    typeset -r archiveName=${1}

    echo Downloading ${MIDAS_DBASE_URL}/${archiveName} to ${archiveName}
    if which wget 1>/dev/null 2>&1; then
        wget ${MIDAS_DBASE_URL}/${archiveName} -O ${archiveName}
    elif which curl 1>/dev/null 2>&1; then
        curl -o ${archiveName} ${MIDAS_DBASE_URL}/${archiveName}
    else
        echo "Error: cannot download using wget or curl."
        echo "Please download database at: ${MIDAS_DBASE_URL}"
        exit 1
    fi
} ## End of function 'downloadArchive()'

if [[ "${1}" = -h || "${1}" = -help || "${1}" = --help ]]; then
    printUsage
    exit
fi

archivePath=${1}
if [[ ! -d "${archivePath}" ]]; then
    echo Create ${archivePath}
    mkdir -p ${archivePath}
fi

if [[ $# -eq 2 ]]; then
    if [[ ! -r "$2" ]]; then
        echo "Can't read ${2} !"
        exit 1
    else
        archiveSource=${2}/
    fi
else ## End of 'if [[ $# -eq 2 ]]'
    archiveSource=
    for archiveName in "${!archiveDatabase[@]}"; do
        downloadArchive ${archiveName} ${archivePath}
    done
fi ## End of 'else' associated to 'if [[ $# -eq 2 ]]'

for archiveName in "${!archiveDatabase[@]}"; do
    echo "Checking md5sum of ${archiveSource}/${archiveName}"
    if checkMd5 ${archiveSource}/${archiveName}; then
        echo "    MD5 check OK"
    else
        echo "The MD5 does not match what was expected.  The file might be corrupted."
        exit 1
    fi
done ## End of 'for archiveName in "${!archiveDatabase[@]}"'

for archiveName in "${!archiveDatabase[@]}"; do
    archiveFullName=${archiveSource}${archiveName}
    echo "Deflating ${archiveFullName} to ${archivePath}"
    tar xzvf ${archiveFullName} -C ${archivePath}

    ## If this file exists, it means it has been downloaded and can be
    ## erased.
    archiveDestinationName=${archivePath}/${archiveName}
    if [[ -f "${archiveDestinationName}" ]]; then
        echo "Erase ${archiveDestinationName}"
        rm ${archiveDestinationName}
    fi
done

echo "MIDAS benchmark database download successful!"
