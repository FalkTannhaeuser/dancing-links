#!/usr/bin/bash
cd $(dirname $0)

header() {
    local str COLUMNS
    COLUMNS=$(tput cols)
    printf -v str "%-${COLUMNS}s" ' '
    echo
    echo "${str// /_}"
    figlet -t "$@"
}

compile_all() {
    for compiler in "$@" ; do
        header "${HOSTNAME}  -  ${compiler}"
        ./my_build.sh --${compiler} --all --test
    done
}

start_timestamp_file=$(mktemp)
trap "rm -f ${start_timestamp_file}" SIGTERM SIGINT EXIT
case $(uname -o) in
    Cygwin)
        compile_all gcc clang msvc

        linux_dir=$(pwd | sed -e 's,^/cygdrive/\w/\(\w\+\)/,/media/sf_\1/,')
        case ${HOSTNAME} in
            bermudes*)  vbox_linux_user=ns3 ;;
            *)          vbox_linux_user=${USER,,}
        esac
        header Calling Linux in VirtualBox
        ssh -Y -t -p 2222 ${vbox_linux_user}@localhost "${linux_dir}/$(basename $0)" --nosummary ||
        echo ssh returned with status $?
        ;;
    *Linux)
        compile_all gcc clang
        ;;
    *)
        echo "Unknown platform $(uname -o)" > /dev/stderr
        exit 1
esac
if [ "$1" != "--nosummary" ] ; then
    header Summary:
    find build/ -iname '*.xml' -newer ${start_timestamp_file} -ls | tee >(echo Generated $(wc -l) test output files.)
fi
