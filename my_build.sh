#!/usr/bin/bash
cd $(dirname $0)
set -e -o pipefail
fresh=
debug=
test=
msvc=
while [ "$1" != "" ] ; do
    case $1 in
        -f|--fresh) fresh=1 ; shift ;;
        -d|--debug) debug=1 ; shift ;;
        -t|--test)  test=1  ; shift ;;
        -m|--msvc)  msvc=1  ; shift ;;
        *)          echo "Unknown option '$1'" > /dev/stderr ; exit 1
    esac
done

case $(uname -o) in
    Cygwin)
        if [ ${msvc:=0} -eq 1 ] ; then
            env PATH="$ORIGINAL_PATH" $(cygpath "$COMSPEC") /c my_build.bat --nopause ${fresh:+--fresh} ${debug:+--debug} ${test:+--test}
            exit
        fi
        build_dir=build/Cygwin
        ;;
    *Linux)
        if [ ${msvc:=0} -eq 1 ] ; then
            echo "Microsoft Visual C++ id not available on this platform" > /dev/stderr
            exit 1
        fi
        build_dir=build/Linux
        ;;
    *)
        echo "Unknown platform $(uname -o)" > /dev/stderr
        exit 1
        ;;
esac

if [ ! -d ${build_dir} ] || [ ${fresh:=0} -eq 1 ] ; then
    cmake -S . -B ${build_dir} -G "Ninja Multi-Config" --fresh
fi

# Choose Debug / Release / RelWithDebInfo
if [ ${debug:=0} -eq 1 ] ; then config=Debug ; else config=Release ; fi

cmake --build ${build_dir} --config ${config} --parallel

if [ ${test:=0} -eq 1 ] ; then
    xml=Testing/junit_output_${config}_$(date +"%F_%H-%M-%S").xml
    ctest --test-dir ${build_dir} -C ${config} -j $(nproc) --output-junit ${xml} --test-output-size-passed 1048576 --output-on-failure --test-output-size-failed 1048576 --timeout 5 ||
    err=$?
    echo "ctest status = ${err} ; wrote test output to ${xml}"
    exit ${err:=0}
fi
