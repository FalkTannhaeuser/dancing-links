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
        for config in "" --debug ; do
            header Cygwin ${config}
            ./my_build.sh --test ${config}

            header Cygwin Clang ${config}
            ./my_build.sh --test --clang ${config}

            header MSVC ${config}
            ./my_build.sh --test --msvc ${config}

            header Linux ${config}
            ssh -Y -p 2222 ${USER,,}@localhost "${linux_dir}/my_build.sh --test ${config}"

            header Linux Clang ${config}
            ssh -Y -p 2222 ${USER,,}@localhost "${linux_dir}/my_build.sh --test --clang ${config}"
        done
        header Summary:
        find build/ -iname '*.xml' -mmin -10 -ls
        ;;
    *)
        echo Not implemented > /dev/stderr
        exit 1
esac
