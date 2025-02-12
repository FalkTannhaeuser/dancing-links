#!/usr/bin/bash
cd $(dirname $0)
set -e -o pipefail
compiler=gcc
fresh=
debug=
configlist=Release
all=
test=
while [ "$1" != "" ] ; do
    case $1 in
        -c|--clang) compiler=clang ; shift ;;
        -g|--gcc)   compiler=gcc   ; shift ;;
        -m|--msvc)  compiler=msvc  ; shift ;;
        -f|--fresh) fresh=1 ; shift ;;
        -d|--debug) debug=1 ; configlist=Debug ; shift ;;
        # Choose Debug / Release / RelWithDebInfo
        -a|--all)   all=1   ; configlist="Release Debug" ; shift ;;
        -t|--test)  test=1  ; shift ;;
        *)          echo "Unknown option '$1'" > /dev/stderr ; exit 1
    esac
done

case $(uname -o) in
    Cygwin)
        case ${compiler} in
            clang)
                build_dir=build/Cygwin_clang
                cmake_init_env() {
                    CC=clang CXX=clang++ cmake "$@"
                }
                ;;
            gcc)
                build_dir=build/Cygwin
                cmake_init_env() {
                    cmake "$@"
                }
                ;;
            msvc)
                env PATH="$ORIGINAL_PATH" $(cygpath "$COMSPEC") /c my_build.bat --nopause --ninja ${fresh:+--fresh} ${debug:+--debug} ${all:+--all} ${test:+--test}
                exit
                ;;
        esac
        ;;
    *Linux)
        case ${compiler} in
            clang)
                build_dir=build/Linux_clang
                cmake_init_env() {
                    # Caution: "-D CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=/usr/bin/clang-scan-deps-19" may be needed
                    # with clang++-19 under Ubuntu unless we set "set(CMAKE_CXX_SCAN_FOR_MODULES OFF)" in CMakeLists.txt
                    CC=clang CXX=clang++ cmake "$@"
                }
                ;;
            gcc)
                build_dir=build/Linux
                cmake_init_env() {
                    cmake "$@"
                }
                ;;
            *)
                echo "${compiler} is not available on this platform" > /dev/stderr
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Unknown platform $(uname -o)" > /dev/stderr
        exit 1
        ;;
esac

if [ ! -d ${build_dir}/CMakeFiles ] || [ ${fresh:=0} -eq 1 ] ; then
    cmake_init_env -S . -B ${build_dir} -G "Ninja Multi-Config" --fresh
fi

for config in ${configlist} ; do
    figlet -t Building with ${compiler} in config ${config}
    cmake --build ${build_dir} --config ${config} --parallel
    if [ ${test:=0} -eq 1 ] ; then
        figlet -t Testing in config ${config}
        xml=Testing/junit_output_${config}_$(date +"%F_%H-%M-%S").xml
        ctest --test-dir ${build_dir} -C ${config} -j $(nproc) --output-junit ${xml} --test-output-size-passed 1048576 --output-on-failure --test-output-size-failed 1048576 --timeout 5 ||
        err=$?
        echo "ctest status = ${err:-0} ; wrote test output to ${xml}"
    fi
done
