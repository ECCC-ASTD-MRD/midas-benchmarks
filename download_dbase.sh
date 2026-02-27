#!/bin/bash

set -euo pipefail

MIDAS_DBASE_URL=http://collaboration.cmc.ec.gc.ca/science/outgoing/midas-benchmarks

declare -A archiveDatabase
archiveDatabase[midas_observations.tar.gz]="e143732aea1058eb2875821a0d1ce757 observations"
archiveDatabase[midas_constants.tar.gz]="561726eeb354d53f63d7c626fb753e46 constants"
archiveDatabase[midas_results.tar.gz]="2822c5c45252b3795efdd697a558b42b reference"
#archiveDatabase[midas_ensemble.tar]="75c54da9ac1f41fa314f3306bfab5842 ensemble"
#archiveDatabase[midas_ensemble_0.tar]="b76118d94c50cbeed74a186eeffe4833 ensemble"
#archiveDatabase[midas_ensemble_1.tar]="6d8537671c87cdba618b22a45600c3d9 ensemble"
#archiveDatabase[midas_ensemble_2.tar]="29e8f402cc97ee3e2922eab79658b110 ensemble"
#archiveDatabase[midas_ensemble_3.tar]="ff8b06a882cdbb92b9caa7a6e1a02af6 ensemble"
#archiveDatabase[midas_ensemble_4.tar]="957641bf46c8d37852f1efa9410889f4 ensemble"
#archiveDatabase[midas_ensemble_5.tar]="2b2d99f7feeb4cc1ae41f4d4dade91bc ensemble"
#archiveDatabase[midas_ensemble_6.tar]="128daf301d056d5a5d0fb821b844b9a9 ensemble"
#archiveDatabase[midas_ensemble_7.tar]="4ac552c8e6d0dcad7a607e0f77612f69 ensemble"
#archiveDatabase[midas_ensemble_8.tar]="3e805b2d96f3fba0f805bb11d64ad645 ensemble"
#archiveDatabase[midas_ensemble_9.tar]="ad2fa9f002cde53453221ade17ba310d ensemble"
archiveDatabase[midas_ensemble_100km.tar]="12e4dd4e06b8bfc248a3d6c5b6c8a332 ensemble"
archiveDatabase[midas_ensemble_10km_control.tar]="d55775eca16d55d6cb3da6f5e5b31619 ensemble_control"

printUsage() {
    echo -e "Download a sample database of data files needed to run MIDAS benchmarks."
    echo -e "If a local database archive is provided, use it instead"
    echo -e "The environment variable 'DOWNLOAD_DBASE_TRANSFER_COMMAND' is used"
    echo -e "to set the transfer command for remote archive.  It defaults to 'scp'."
    echo -e "Usage:"
    echo -e "./$(basename $0) <MIDAS-DATABASE-STORAGE> [Local MIDAS dbase archive path]\n"
} ## End of function 'printUsage()'

checkMd5() {
    # $1 File path
    # Return: 0 if matching; 1 otherwise
    typeset -r archiveName=${1}
    typeset -r md5=$(md5sum ${archiveName} | cut -d' ' -f1)

    typeset -r fileName=$(basename ${archiveName})
    typeset -r md5_reference=$(echo ${archiveDatabase[${fileName}]} | cut -d' ' -f1)

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
    if [[ "${2}" =~ ^[0-9a-zA-Z_-]+: ]]; then
        archiveSource=
        for archiveName in "${!archiveDatabase[@]}"; do
            echo Downloading ${2}/${archiveName} to ${archiveName}
            ${DOWNLOAD_DBASE_TRANSFER_COMMAND:-scp} ${2}/${archiveName} .
        done
    elif [[ ! -r "$2" ]]; then
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

if [[ "${DOWNLOAD_DBASE_CHECK_MD5SUM:-yes}" = yes ]]; then
    for archiveName in "${!archiveDatabase[@]}"; do
        echo "Checking md5sum of ${archiveSource}${archiveName}"
        if checkMd5 ${archiveSource}${archiveName}; then
            echo "    MD5 check OK"
        else
            echo "The MD5 does not match what was expected.  The file might be corrupted."
            exit 1
        fi
    done ## End of 'for archiveName in "${!archiveDatabase[@]}"'
fi

for archiveName in "${!archiveDatabase[@]}"; do
    destination=${archivePath}/$(echo ${archiveDatabase[${archiveName}]} | cut -d' ' -f2)

    if [[ ! -d "${destination}" ]]; then
        echo "Create directory ${destination}"
        mkdir ${destination}
    fi

    if [[ "${archiveName}" = *.tar.gz || "${archiveName}" = *.tar ]]; then
        echo "Deflate ${archiveName} to ${destination}"
        if [[ "${archiveName}" = *.tar.gz ]]; then
            decompress_option=z
        else
            decompress_option=
        fi

        tar x${decompress_option}vf ${archiveSource}${archiveName} -C ${destination}

        ## If this file exists, it means it has been downloaded and can be
        ## erased.
        archiveDestinationName=${destination}/${archiveName}
        if [[ -f "${archiveDestinationName}" ]]; then
            echo "Erase ${archiveDestinationName}"
            rm ${archiveDestinationName}
        fi
    fi
done

echo "MIDAS benchmark database download successful!"
