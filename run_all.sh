#!/usr/bin/bash
cd $(dirname $0)
linux_dir=$(pwd | sed -e 's,^/cygdrive/\w/\(\w\+\)/,/media/sf_\1/,')

header() {
    local str COLUMNS
    COLUMNS=$(tput cols)
    printf -v str "%-${COLUMNS}s" ' '
    echo
    echo "${str// /_}"
    figlet -t "$@"
}

case $(uname -o) in
    Cygwin)
        start_timestamp_file=$(mktemp)
        trap "rm -f ${start_timestamp_file}" SIGTERM SIGINT EXIT
        ssh_err=0
        for config in "" "--debug" ; do
            for compiler in "" "--clang" ; do
                header Cygwin ${compiler} ${config}
                ./my_build.sh --test ${compiler} ${config}
                if [ ${ssh_err} -eq 0 ] ; then
                    header Linux ${compiler} ${config}
                    ssh -Y -p 2222 ${USER,,}@localhost "${linux_dir}/my_build.sh --test ${compiler} ${config}"
                    ssh_err=$?
                fi
            done
            header MSVC ${config}
            ./my_build.sh --test --msvc ${config}
        done
        header Summary:
        find build/ -iname '*.xml' -newer ${start_timestamp_file} -ls
        ;;
    *)
        echo Not implemented > /dev/stderr
        exit 1
esac
