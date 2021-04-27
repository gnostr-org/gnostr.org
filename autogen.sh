#!/bin/sh

# https://github.com/leleliu008/autogen.sh

cd "$(dirname "$0")" || exit 1
CURRENT_DIR="$PWD"

COLOR_RED='\033[0;31m'          # Red
COLOR_GREEN='\033[0;32m'        # Green
COLOR_YELLOW='\033[0;33m'       # Yellow
COLOR_BLUE='\033[0;34m'         # Blue
COLOR_PURPLE='\033[0;35m'       # Purple
COLOR_OFF='\033[0m'             # Reset

print() {
    printf "%b" "$*"
}

echo() {
    print "$*\n"
}

info() {
    echo "$COLOR_PURPLE==>$COLOR_OFF $COLOR_GREEN$@$COLOR_OFF"
}

success() {
    print "${COLOR_GREEN}[✔] $*\n${COLOR_OFF}"
}

warn() {
    print "${COLOR_YELLOW}🔥 $*\n${COLOR_OFF}"
}

error() {
    print "${COLOR_RED}[✘] $*\n${COLOR_OFF}"
}

die() {
    print "${COLOR_RED}[✘] $*\n${COLOR_OFF}"
    exit 1
}

# examples:
# exists file FILEPATH    --check if file    exists
# exists command NAME     --check if command exists
exists() {
    [ $# -eq 2 ] || warn "exists function accept 2 arguments."
    case $1 in
        file)    [ -n "$2" ] && [ -e "$2" ]  ;;
        command) command -v "$2" > /dev/null ;;
        *) warn "$1: not support." ; return 1
    esac
}

die_if_file_is_not_exist() {
    exists file "$1" || die "$1 is not exists."
}

executable() {
    exists file "$1" && [ -x "$1" ]
}

die_if_not_executable() {
    executable "$1" || die "$1 is not executable."
}

step() {
    STEP_NUM=$(expr ${STEP_NUM-0} + 1)
    STEP_MESSAGE="$@"
    echo
    echo "${COLOR_PURPLE}=>> STEP ${STEP_NUM} : ${STEP_MESSAGE} ${COLOR_OFF}"
}

run() {
    info "$*"
    eval "$*"
}

list() {
    for item in $@
    do
        echo "$item"
    done
}

list_length() {
    echo $#
}

shiftn() {
    shift "$1" && shift && echo "$@"
}

sed_in_place() {
    if command -v gsed > /dev/null ; then
        gsed -i "$1" "$2"
    elif command -v sed  > /dev/null ; then
        sed -i    "$1" "$2" 2> /dev/null ||
        sed -i "" "$1" "$2"
    else
        die "please install sed utility."
    fi
}

base64_encode() {
    if [ $# -eq 0 ] ; then
        if exists command base64 ; then
            # https://superuser.com/questions/1225134/why-does-the-base64-of-a-string-contain-n
            base64 | tr -d \\n
        elif exists command b64encode ; then
            b64encode qwe | sed -n 2p
        else
            die "please install GNU coreutils."
        fi
    else
        if exists command base64 ; then
            # https://superuser.com/questions/1225134/why-does-the-base64-of-a-string-contain-n
            printf "%s" "$*" | base64 | tr -d \\n
        elif exists command b64encode ; then
            printf "%s" "$*" | b64encode qwe | sed -n 2p
        else
            die "please install GNU coreutils."
        fi
    fi
}

base64_decode() {
    if [ $# -eq 0 ] ; then
        if exists command base64 ; then
            base64 -d
        elif exists command b64encode ; then
            b64decode qwe | sed -n 2p
        else
            die "please install GNU coreutils."
        fi
    else
        if exists command base64 ; then
            printf "%s" "$*" | base64 -d
        elif exists command b64encode ; then
            printf "%s" "$*" | b64decode qwe | sed -n 2p
        else
            die "please install GNU coreutils."
        fi
    fi
}




__get_os_name_from_uname_a() {
    if command -v uname > /dev/null ; then
        unset V
        V=$(uname -a | cut -d ' ' -f2)
        case $V in
            opensuse*) return 1 ;;
            *-*) echo "$V" | cut -d- -f1 ;;
            *)   return 1
        esac
    else
        return 1
    fi
}

__get_os_version_from_uname_a() {
    if command -v uname > /dev/null ; then
        unset V
        V=$(uname -a | cut -d ' ' -f2)
        case $V in
            opensuse*) return 1 ;;
            *-*) echo "$V" | cut -d- -f2 ;;
            *)   return 1
        esac
    else
        return 1
    fi
}

# https://www.freedesktop.org/software/systemd/man/os-release.html
__get_os_name_from_etc_os_release() {
    if [ -f /etc/os-release ] ; then
        unset F
        F=$(mktemp) &&
        cat /etc/os-release > "$F" &&
        echo 'echo "$ID"'  >> "$F" &&
        sh "$F"
    else
        return 1
    fi
}

__get_os_version_from_etc_os_release() {
    if [ -f /etc/os-release ] ; then
        unset F
        F=$(mktemp) &&
        cat /etc/os-release > "$F" &&
        echo 'echo "$VERSION_ID"'  >> "$F" && {
            unset V
            V=$(sh "$F")
            if [ -z "$V" ] ; then
                echo 'rolling'
            else
                echo "$V"
            fi
        }
    else
        return 1
    fi
}

# https://refspecs.linuxfoundation.org/LSB_3.0.0/LSB-PDA/LSB-PDA/lsbrelease.html
__get_os_name_from_lsb_release() {
    if command -v lsb_release > /dev/null ; then
        lsb_release --id | cut -f2
    else
        return 1
    fi
}

__get_os_version_from_lsb_release() {
    if command -v lsb_release > /dev/null ; then
        lsb_release --release | cut -f2
    else
        return 1
    fi
}

__get_os_name_from_getprop() {
    if command -v getprop > /dev/null && command -v app_process > /dev/null ; then
        echo 'android'
    else
        return 1
    fi
}

__get_os_version_from_getprop() {
    if command -v getprop > /dev/null ; then
        getprop ro.build.version.release
    else
        return 1
    fi
}

__get_os_arch_from_getprop() {
    if command -v getprop > /dev/null ; then
        getprop ro.product.cpu.abi
    else
        return 1
    fi
}

__get_os_arch_from_uname() {
    if command -v uname > /dev/null ; then
        uname -m 2> /dev/null
    else
        return 1
    fi
}

__get_os_arch_from_arch() {
    if command -v arch > /dev/null ; then
        arch
    else
        return 1
    fi
}

os() {
    if [ $# -eq 0 ] ; then
        printf "current-machine-os-kind : %s\n" "$(os kind)"
        printf "current-machine-os-type : %s\n" "$(os type)"
        printf "current-machine-os-name : %s\n" "$(os name)"
        printf "current-machine-os-vers : %s\n" "$(os version)"
        printf "current-machine-os-arch : %s\n" "$(os arch)"
    elif [ $# -eq 1 ] ; then
        case $1 in
            -h|--help)
                cat <<'EOF'
os -h | --help
os -V | --version
os kind
os type
os arch
os name
os version
EOF
                ;;
            -V|--version)
                printf "%s\n" '2021.03.28.23'
                ;;
            kind)
                case $(uname | tr A-Z a-z) in
                    msys*)    echo "windows" ;;
                    mingw32*) echo "windows" ;;
                    mingw64*) echo "windows" ;;
                    cygwin*)  echo 'windows' ;;
                    *)  uname | tr A-Z a-z
                esac
                ;;

            type)
                case $(uname | tr A-Z a-z) in
                    msys*)    echo "msys"    ;;
                    mingw32*) echo "mingw32" ;;
                    mingw64*) echo "mingw64" ;;
                    cygwin*)  echo 'cygwin'  ;;
                    *)  uname | tr A-Z a-z
                esac
                ;;
            name)
                case $(os kind) in
                    freebsd) echo 'FreeBSD' ;;
                    openbsd) echo 'OpenBSD' ;;
                    netbsd)  echo 'NetBSD'  ;;
                    darwin)  sw_vers -productName ;;
                    linux)
                        __get_os_name_from_uname_a ||
                        __get_os_name_from_etc_os_release ||
                        __get_os_name_from_lsb_release
                        ;;
                    windows)
                        systeminfo | grep 'OS Name:' | cut -d: -f2 | head -n 1 | sed 's/^[[:space:]]*//' ;;
                    *)  uname | tr A-Z a-z
                esac
                ;;
            arch)
                __get_os_arch_from_uname ||
                __get_os_arch_from_arch  ||
                __get_os_arch_from_getprop
                ;;
            version)
                case $(os kind) in
                    freebsd) freebsd-version ;;
                    openbsd) uname -r ;;
                    netbsd)  uname -r ;;
                    darwin)  sw_vers -productVersion ;;
                    linux)
                        __get_os_version_from_uname_a ||
                        __get_os_version_from_etc_os_release ||
                        __get_os_version_from_lsb_release
                        ;;
                    windows)
                        systeminfo | grep 'OS Version:' | cut -d: -f2 | head -n 1 | sed 's/^[[:space:]]*//' | cut -d ' ' -f1 ;;
                esac
                ;;
            *)  echo "$1: not support item."; return 1
        esac
    else
        echo "os command only support one item."; return 1
    fi
}

location_of_python_module() {
    PIP_COMMAND=$(command -v pip3) ||
    PIP_COMMAND=$(command -v pip) ||
    die "can't found pip command."

    "$PIP_COMMAND" show $1 | grep 'Location:' | cut -d ' ' -f2
}

version_of_python_module() {
    PIP_COMMAND=$(command -v pip3) ||
    PIP_COMMAND=$(command -v pip) ||
    die "can't found pip command."

    "$PIP_COMMAND" show $1 | grep 'Version:' | cut -d ' ' -f2
}

# retrive the version of a command from it's name or path
version_of_command() {
    case $(basename "$1") in
        cmake) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f3 ;;
         make) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f3 ;;
        gmake) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f3 ;;
       rustup) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
        cargo) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
           go) "$1"   version | cut -d ' ' -f3 | cut -c3- ;;
         tree) "$1" --version | cut -d ' ' -f2 | cut -c2- ;;
   pkg-config) "$1" --version 2> /dev/null | head -n 1 ;;
       m4|gm4) "$1" --version 2> /dev/null | head -n 1 | awk '{print($NF)}';;
    autopoint) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
     automake|aclocal)
               "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
     autoconf|autoheader|autom4te|autoreconf|autoscan|autoupdate|ifnames)
               "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
      libtool) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
   libtoolize|glibtoolize)
               "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
      objcopy) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f5 ;;
         flex) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
        bison) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
         yacc) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
         nasm) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f3 ;;
         yasm) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
        patch) "$1" --version 2> /dev/null | head -n 1 | awk '{print($NF)}' ;;
        gperf) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f3 ;;
        groff) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
     help2man) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f3 ;;
         file) "$1" --version 2> /dev/null | head -n 1 | cut -d '-' -f2 ;;
      itstool) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
       protoc) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
        xmlto) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f3 ;;
      xmllint) ;;
     xsltproc) ;;
         gzip)
            unset TEMP_FILE
            TEMP_FILE=$(mktemp)
            "$1" --version > $TEMP_FILE 2>&1
            cat $TEMP_FILE | head -n 1 | awk '{print($NF)}'
            rm $TEMP_FILE
            unset TEMP_FILE
            ;;
         lzip) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
           xz) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
          zip) "$1" --version 2> /dev/null | sed -n '2p' | cut -d ' ' -f4 ;;
        unzip) "$1" -v        2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
        bzip2)
            unset TEMP_FILE
            TEMP_FILE=$(mktemp)
            "$1" --help 2> $TEMP_FILE
            cat $TEMP_FILE | head -n 1 | cut -d ' ' -f8 | cut -d ',' -f1
            rm $TEMP_FILE
            unset TEMP_FILE
            ;;
          tar)
            VERSION_MSG=$("$1" --version 2> /dev/null | head -n 1)
            case $VERSION_MSG in
                  tar*) echo "$VERSION_MSG" | cut -d ' ' -f4 ;;
               bsdtar*) echo "$VERSION_MSG" | cut -d ' ' -f2 ;;
            esac
            ;;
          git) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f3 ;;
         curl) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
     awk|gawk) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f3 | tr , ' ' ;;
     sed|gsed) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 ;;
         cpan) ;;
         grep) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 | cut -d '-' -f1 ;;
         ruby) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
         perl) "$1" -v | sed -n '2p' | sed 's/.*v\([0-9]\.[0-9][0-9]\.[0-9]\).*/\1/' ;;
    python|python2|python3)
            unset TEMP_FILE
            TEMP_FILE=$(mktemp)
            "$1" --version > $TEMP_FILE 2>&1
            cat $TEMP_FILE | head -n 1 | cut -d ' ' -f2
            rm $TEMP_FILE
            unset TEMP_FILE
            ;;
         pip)  "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
         pip3) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
         node) "$1" --version 2> /dev/null | head -n 1 | cut -d 'v' -f2 ;;
          zsh) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f2 ;;
         bash) "$1" --version 2> /dev/null | head -n 1 | cut -d ' ' -f4 | cut -d '(' -f1 ;;
            *) "$1" --version 2> /dev/null | head -n 1
    esac
}

# retrive the major part of the version of the given command
# Note: the version of the given command must have form: major.minor.patch
version_major_of_command() {
    version_of_command "$1" | cut -d. -f1
}

# retrive the minor part of the version of the given command
# Note: the version of the given command must have form: major.minor.patch
version_minor_of_command() {
    version_of_command "$1" | cut -d. -f2
}

# retrive the major part of the given version
# Note: the given version must have form: major.minor.patch
version_major_of_version() {
    echo "$1" | cut -d. -f1
}

# retrive the minor part of the given version
# Note: the given version must have form: major.minor.patch
version_minor_of_version() {
    echo "$1" | cut -d. -f2
}

version_sort() {
    # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sort.html
    # https://man.netbsd.org/NetBSD-8.1/i386/sort.1
    case $(uname) in
        NetBSD) echo "$@" | tr ' ' '\n' | sort -t. -n -k1,1 -k2,2 -k3,3 -k4,4 ;;
             *) echo "$@" | tr ' ' '\n' | sort -V ;;
    esac
}

# check if match the condition
#
# condition:
# eq  equal
# ne  not equal
# gt  greater than
# lt  less than
# ge  greater than or equal
# le  less than or equal
#
# examples:
# version_match 1.15.3 eq 1.16.0
# version_match 1.15.3 lt 1.16.0
# version_match 1.15.3 gt 1.16.0
# version_match 1.15.3 le 1.16.0
# version_match 1.15.3 ge 1.16.0
version_match() {
    case $2 in
        eq)  [ "$1"  = "$3" ] ;;
        ne)  [ "$1" != "$3" ] ;;
        le)
            [ "$1" = "$3" ] && return 0
            [ "$1" = $(version_sort "$1" "$3" | head -n 1) ]
            ;;
        ge)
            [ "$1" = "$3" ] && return 0
            [ "$1" = $(version_sort "$1" "$3" | tail -n 1) ]
            ;;
        lt)
            [ "$1" = "$3" ] && return 1
            [ "$1" = $(version_sort "$1" "$3" | head -n 1) ]
            ;;
        gt)
            [ "$1" = "$3" ] && return 1
            [ "$1" = $(version_sort "$1" "$3" | tail -n 1) ]
            ;;
        *)  die "version_compare: $2: not supported operator."
    esac
}

# check if the version of give installed command match the condition
#
# condition:
# eq  equal
# ne  not equal
# gt  greater than
# lt  less than
# ge  greater than or equal
# le  less than or equal
#
# examples:
# command_version_match automake eq 1.16.0
# command_version_match automake lt 1.16.0
# command_version_match automake gt 1.16.0
# command_version_match automake le 1.16.0
# command_version_match automake ge 1.16.0
command_version_match() {
    case $1 in
        /*) executable     "$1" || return 1 ;;
        *)  exists command "$1" || return 1 ;;
    esac
    version_match "$(version_of_command "$1")" "$2" "$3"
}

get_choco_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc-g++' ;;
        make) echo 'make' ;;
       gmake) echo 'make' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf)
              echo "autoconf" ;;
    automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
    pkg-config) 
              echo "pkgconf" ;;
        *) echo "$1"
    esac
}

get_pkg_add_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
        make) echo 'gmake' ;;
       gmake) echo 'gmake' ;;
         gm4) echo 'm4'    ;;
        perl) echo 'perl5' ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf)
              echo "autoconf-2.69p3" ;;
    autoreconf-2.69|autoconf-2.69)
              echo "autoconf-2.69p3" ;;
    automake|autoheader)
              echo "automake-1.16.2" ;;
    automake-1.16|autoheader-1.16)
              echo "automake-1.16.2" ;;
    autopoint) echo "gettext" ;;
    pkg-config) 
              echo "pkgconf" ;;
        *) echo "$1"
    esac
}

get_pkgin_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
        make) echo 'gmake' ;;
       gmake) echo 'gmake' ;;
         gm4) echo 'm4'    ;;
        perl) echo 'perl5' ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf)
              echo "autoconf" ;;
    automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
    pkg-config) 
              echo "pkgconf" ;;
        *) echo "$1"
    esac
}

get_pkg_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
        make) echo 'gmake' ;;
       gmake) echo 'gmake' ;;
         gm4) echo 'm4'    ;;
        perl) echo 'perl5' ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf)
              echo "autoconf" ;;
    automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
    pkg-config) 
              echo "pkgconf" ;;
        *) echo "$1"
    esac
}

get_emerge_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf)
              echo "autoconf" ;;
    automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
    pkg-config) 
              echo "pkgconf" ;;
        *) echo "$1"
    esac
}

__get_pacman_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf)
              echo "autoconf" ;;
    automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
    pkg-config) 
              echo "pkgconf" ;;
        *) echo "$1"
    esac
}

__mingw_w64_i686() {
    if pacman -S -i "mingw-w64-i686-$1" > /dev/null 2>&1 ; then
        echo "mingw-w64-i686-$1"
    else
        echo "$1"
    fi
}

__mingw_w64_x86_64() {
    if pacman -S -i "mingw-w64-x86_64-$1" > /dev/null 2>&1 ; then
        echo "mingw-w64-x86_64-$1"
    else
        echo "$1"
    fi
}

get_pacman_package_name_by_command_name() {
    case $NATIVE_OS_TYPE in
        mingw32) __mingw_w64_i686   $(__get_pacman_package_name_by_command_name "$1") ;;
        mingw64) __mingw_w64_x86_64 $(__get_pacman_package_name_by_command_name "$1") ;;
        *) __get_pacman_package_name_by_command_name "$1"
    esac
}

get_xbps_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf)
              echo "autoconf" ;;
    automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
    pkg-config) 
              echo "pkgconf" ;;
        *) echo "$1"
    esac
}

get_apk_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc libc-dev' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf)
              echo "autoconf" ;;
    automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
    pkg-config) 
              echo "pkgconf" ;;
        *) echo "$1"
    esac
}

get_zypper_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf|automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
        *) echo "$1"
    esac
}

get_dnf_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf|automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
        *) echo "$1"
    esac
}

get_yum_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf|automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
        *) echo "$1"
    esac
}

get_apt_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf|automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
        *) echo "$1"
    esac
}

get_brew_package_name_by_command_name() {
    case $1 in
      cc|gcc) echo 'gcc' ;;
         gm4) echo 'm4'    ;;
       gperf) echo 'gperf' ;;
        gsed) echo 'gnu-sed'  ;;
     objcopy) echo 'binutils' ;;
      protoc) echo 'protobuf' ;;
      ps2pdf) echo "ghostscript" ;;
    libtool|libtoolize|glibtool|glibtoolize)
              echo "libtool" ;;
    autoreconf|autoconf|automake|autoheader)
              echo "automake" ;;
    autopoint) echo "gettext" ;;
        *) echo "$1"
    esac
}

__available_package_manager_list() {
    if exists command brew ; then
        echo brew
    fi

    [ "$NATIVE_OS_TYPE" = 'darwin' ] && return

    if exists command apt ; then
        echo apt
    elif exists command apt-get ; then
        echo apt-get
    elif exists command dnf ; then
        echo dnf
    elif exists command yum ; then
        echo yum
    elif exists command zypper ; then
        echo zypper
    elif exists command apk ; then
        echo apk
    elif exists command xbps-install ; then
        echo xbps
    elif exists command emerge ; then
        echo emerge
    elif exists command pacman ; then
        echo pacman
    elif exists command choco ; then
        echo choco
    elif exists command pkg ; then
        echo pkg
    elif exists command pkgin ; then
        echo pkgin
    elif exists command pkg_add ; then
        echo pkg_add
    fi
}

# $1 package manager name
# $2 package name
__install_package_via_package_manager() {
    case $1 in
        pkg)     run $sudo pkg install -y "$2" ;;
        pkgin)   run $sudo pkgin -y install "$2" ;;
        pkg_add) run $sudo pkg_add "$2" ;;
        brew)    run brew install "$2" ;;
        apt)     run $sudo apt -y install "$2" ;;
        apt-get) run $sudo apt-get -y install "$2" ;;
        dnf)
            # Error: GPG check FAILED
            if [ "$NATIVE_OS_NAME" = 'fedora' ] && [ "$NATIVE_OS_VERS" = 'rawhide' ] ; then
                 run $sudo dnf -y install "$2" --nogpgcheck
            else
                 run $sudo dnf -y install "$2"
            fi
            ;;
        yum)     run $sudo yum -y install "$2" ;;
        zypper)  run $sudo zypper install -y "$2" ;;
        apk)     run $sudo apk add "$2" ;;
        xbps)    run $sudo xbps-install -Sy "$2" ;;
        emerge)  run $sudo emerge "$2" ;;
        pacman)  run $sudo pacman -Syy --noconfirm && run $sudo pacman -S --noconfirm "$2" ;;
        choco)   run choco install -y --source cygwin "$2" ;;
    esac
}

# $1 package manager name
# $2 command name
__install_command_via_package_manager() {
    PACKAGE_NAME="$(eval get_$1_package_name_by_command_name $2)"
    if [ -z "$PACKAGE_NAME" ] ; then
        warn "can not found a package in $1 repo, who contains the $2 command."
        return 1
    else
        print "🔥  ${COLOR_YELLOW}required command${COLOR_OFF} ${COLOR_GREEN}$(shiftn 1 $@)${COLOR_OFF}${COLOR_YELLOW}, but${COLOR_OFF} ${COLOR_GREEN}$2${COLOR_OFF} ${COLOR_YELLOW}command not found, try to install it via${COLOR_OFF} ${COLOR_GREEN}$1${COLOR_OFF}\n"
        if __install_package_via_package_manager "$1" "$PACKAGE_NAME" ; then
            echo
        else
            return 1
        fi
    fi
}

# examples:
# pkg-config ge 0.18
# python3    ge 3.5
# make
__install_command_via_available_package_manager() {
    if required_command_exists_and_version_matched $@ ; then
        printf "command %-10s %-10s ${COLOR_GREEN}FOUND${COLOR_OFF} %-8s %s\n" "$1" "$2 $3" "$(version_of_command $1)" "$(command -v $1)"
    else
        if [ -z "$AVAILABLE_PACKAGE_MANAGER_LIST" ] ; then
            AVAILABLE_PACKAGE_MANAGER_LIST=$(__available_package_manager_list)
            if [ -z "$AVAILABLE_PACKAGE_MANAGER_LIST" ] ; then
                warn "no package manager found."
                return 1
            else
                echo "    Found $(list_length $AVAILABLE_PACKAGE_MANAGER_LIST) package manager : ${COLOR_GREEN}$AVAILABLE_PACKAGE_MANAGER_LIST${COLOR_OFF}"
            fi
        fi
        for pm in $AVAILABLE_PACKAGE_MANAGER_LIST
        do
            __install_command_via_package_manager "$pm" $@
        done
    fi
}

# examples:
# pkg-config ge 0.18
# python3    ge 3.5
# make
required_command_exists_and_version_matched() {
    if exists command "$1" ; then
        if [ $# -eq 3 ] ; then
            command_version_match $@
        fi
    else
        return 1
    fi
}

# examples:
# required command pkg-config ge 0.18
# required command python3    ge 3.5
# optional python3 libxml2    ge 2.8
# optional python3 libxml2
__check_required_item() {
    shift
    case $1 in
        command)
            shift
            case $1 in
                *:*)
                    for item in $(echo "$1" | tr ':' ' ')
                    do
                        if required_command_exists_and_version_matched "$item" $2 $3 ; then
                            eval "REQUIRED_ITEM_$REQUIRED_ITEM_INDEX=$item"
                            printf "command %-10s %-10s ${COLOR_GREEN}FOUND${COLOR_OFF} %-8s %s\n" "$item" "$2 $3" "$(version_of_command $item)" "$(command -v $item)"
                            return 0
                        fi
                    done
                    for item in $(echo "$1" | tr ':' ' ')
                    do
                        if __install_command_via_available_package_manager "$item" $2 $3 ; then
                            eval "REQUIRED_ITEM_$REQUIRED_ITEM_INDEX=$item"
                            return 0
                        fi
                    done
                    ;;
                *)  __install_command_via_available_package_manager $@
            esac
            ;;
        python|python3)
            shift
            if exists command python3 ; then
                if ! python3 -c "import $1" 2> /dev/null ; then
                    if exists command pip3 ; then
                        pip3 install -U "$1" || return 1
                    fi
                fi
            elif exists command python ; then
                if ! python -c "import $1" 2> /dev/null ; then
                    if exists command pip ; then
                        pip install -U "$1" || return 1
                    fi
                fi
            fi
            ;;
        perl)
            shift
            if ! perl -M"$1" -le 'print "installed"' > /dev/null 2>&1 ; then
                cpan -i "$1" || return 1
            fi
            ;;
        *) die "$1 not support."
    esac
}

# examples:
#    $1      $2      $3       $4  $5
# required command pkg-config ge 0.18
# required command python3    ge 3.5
# optional python3 libxml2    ge 2.8
# optional python3 libxml2
__print_required_or_optional_item() {
    case $2 in
        command)
            case $3 in
                *:*)
                    if [ "$1" = 'required' ] ; then
                        REQUIRED_ITEM="$(eval echo \$REQUIRED_ITEM_$REQUIRED_ITEM_INDEX)"
                        printf "%-7s %-11s %-10s %-10s %s\n" "$2" "$REQUIRED_ITEM" "$4 $5" "$(version_of_command $REQUIRED_ITEM)" "$(command -v $REQUIRED_ITEM)"
                    else
                        for item in $(echo "$3" | tr ':' ' ')
                        do
                            printf "%-7s %-11s %-10s %-10s %s\n" "$2" "$item" "$4 $5" "$(version_of_command $item)" "$(command -v $item)"
                        done
                    fi
                    ;;
                *)  printf "%-7s %-11s %-10s %-10s %s\n" "$2" "$3" "$4 $5" "$(version_of_command $3)" "$(command -v $3)"
            esac
            ;;
        python)
            printf "%-7s %-11s %-10s %-10s %s\n" "$2" "$3" "$4 $5" "$(version_of_python_module $3)" "$(location_of_python_module $3)"
            ;;
        perl)
            printf "%-7s %-11s %-10s %-10s %s\n" "$2" "$3" "$4 $5" "" ""
            ;;
        *)  die "$2: type not support."
    esac
}

__encode() {
    if [ $# -eq 0 ] ; then
        tr ' ' '|'
    else
        printf "%s" "$*" | tr ' ' '|'
    fi
}

__decode() {
    if [ $# -eq 0 ] ; then
        tr '|' ' '
    else
        printf "%s" "$*" | tr '|' ' '
    fi
}

# declare required command or python/perl module
#
# $1 type=command|python|python2|python3|perl
#    type can be omitted when it is command
# $2 name
# $3=gt|lt|ge|le|eq|ne
# $4 version
#
# examples:
# required command pkg-config ge 0.18
# required command python     ge 3.5
# required python  libxml2    ge 2.19
required() {
    if [ $# -eq 2 ] || [ $# -eq 4 ] ; then
        if [ -z "$REQUIRED" ] ; then
            REQUIRED="$(__encode "required $*")"
        else
            REQUIRED="$REQUIRED $(__encode "required $*")"
        fi
    else
        die "required $@ : required function accept 2 or 4 argument."
    fi
}

# declare optional command or python/perl module
#
# $1 type=command|python|python2|python3|perl
#    type can be omitted when it is command
# $2 name
# $3=gt|lt|ge|le|eq|ne
# $4 version
#
# examples:
# optional command pkg-config ge 0.18
# optional command python     ge 3.5
# optional python  libxml2    ge 2.19
optional() {
    if [ $# -eq 2 ] || [ $# -eq 4 ] ; then
        if [ -z "$OPTIONAL" ] ; then
            OPTIONAL=$(__encode "optional $*")
        else
            OPTIONAL="$OPTIONAL $(__encode "optional $*")"
        fi
    else
        die "optional $@ : optional function accept 2 or 4 argument."
    fi
}

gen_config_pre() {
    step "gen config pre"
    warn "do nothing, you can overide this function to do whatever you want."
}

gen_config() {
    step "gen config"
    run autoreconf -ivf
}

gen_config_post() {
    step "gen config post"
    warn "do nothing, you can overide this function to do whatever you want."
}

__is_libtool_used() {
    # https://www.gnu.org/software/libtool/manual/html_node/LT_005fINIT.html
    grep 'LT_INIT\s*('     configure.ac ||
    grep 'AC_PROG_LIBTOOL' configure.ac ||
    grep 'AM_PROG_LIBTOOL' configure.ac
}


main() {
    unset DEBUG

    unset STEP_NUM
    unset STEP_MESSAGE

    unset REQUIRED
    unset OPTIONAL

    unset PROJECT_DIR
    unset PROJECT_NAME
    unset PROJECT_VERSION

    unset NATIVE_OS_KIND
    unset NATIVE_OS_TYPE
    unset NATIVE_OS_NAME
    unset NATIVE_OS_VERS
    unset NATIVE_OS_ARCH

    unset AUTOCONF_VERSION_MREQUIRED

    unset REQUIRED_ITEM_INDEX
    unset OPTIONAL_ITEM_INDEX

    unset RC_FILE

    echo "${COLOR_GREEN}autogen.sh is a POSIX shell script to manage GNU Autotools(autoconf automake) and other softwares used by this project.${COLOR_OFF}"

    case $1 in
        '') ;;
        -h|--help)
            cat <<EOF
./autogen.sh -h | --help
./autogen.sh -V | --version
./autogen.sh [ --rc-file=FILE | -x | -d ]
EOF
            return 0
            ;;
        -V|--version)
            echo "$PROJECT_VERSION"
            return 0
            ;;
        -x|-d|--rc-file=*)
            for item in $@
            do
                case $item in
                    -x) set -x ;;
                    -d) DEBUG=true ;;
                    --rc-file=*)
                        RC_FILE=$(echo "$item" | cut -d= -f2)
                        if [ -z "$RC_FILE" ] ; then
                            die "--rc-file=FILE FILE must not empty."
                        else
                            if ! exists file "$RC_FILE" ; then
                                die "$item: file not exists."
                            fi
                        fi
                        ;;
                    *)  die "$item: not support argument."
                esac
            done
            ;;
        *)  die "$1: not support argument."
    esac

    [ -z "$RC_FILE" ] && RC_FILE=autogen.rc

    step "show current machine os info"
    NATIVE_OS_KIND=$(os kind)
    NATIVE_OS_TYPE=$(os type)
    NATIVE_OS_NAME=$(os name)
    NATIVE_OS_VERS=$(os version)
    NATIVE_OS_ARCH=$(os arch)
    echo "NATIVE_OS_KIND  = $NATIVE_OS_KIND"
    echo "NATIVE_OS_TYPE  = $NATIVE_OS_TYPE"
    echo "NATIVE_OS_NAME  = $NATIVE_OS_NAME"
    echo "NATIVE_OS_VERS  = $NATIVE_OS_VERS"
    echo "NATIVE_OS_ARCH  = $NATIVE_OS_ARCH"

    # https://www.openbsd.org/faq/ports/specialtopics.html
    if [ "$NATIVE_OS_KIND" = 'openbsd' ] ; then
        [ -z "$AUTOCONF_VERSION" ] || export AUTOCONF_VERSION='2.69'
        [ -z "$AUTOMAKE_VERSION" ] || export AUTOMAKE_VERSION='1.16'
        
        echo
        echo "export AUTOCONF_VERSION=$AUTOCONF_VERSION"
        echo "export AUTOMAKE_VERSION=$AUTOMAKE_VERSION"
        
        required command autoconf-$AUTOCONF_VERSION ge "$AUTOCONF_VERSION_MREQUIRED"
        required command automake-$AUTOMAKE_VERSION
    fi
    
    if [ "$NATIVE_OS_KIND" != 'windows' ] ; then
        [ "$(whoami)" = root ] || sudo=sudo
    fi
    
    step "show current machine os effective user info"
    id | tr ' ' '\n' | head -n 2

    step "show project info"
    
    PROJECT_DIR="$CURRENT_DIR"

    die_if_file_is_not_exist configure.ac
    
    # https://www.gnu.org/software/autoconf/manual/autoconf-2.69/html_node/Initializing-configure.html
    PROJECT_NAME=$(grep 'AC_INIT\s*(\[.*' configure.ac | sed 's/AC_INIT\s*(\[\(.*\)\],.*/\1/')
    PROJECT_VERSION=$(grep 'AC_INIT\s*(\[.*' configure.ac | sed "s/AC_INIT\s*(\[$PROJECT_NAME\],\[\(.*\)\].*/\1/")

    echo "CURRENT_DIR     = $CURRENT_DIR"
    echo "PROJECT_DIR     = $PROJECT_DIR"
    echo "PROJECT_NAME    = $PROJECT_NAME"
    echo "PROJECT_VERSION = $PROJECT_VERSION"
    
    # https://www.gnu.org/software/autoconf/manual/autoconf-2.69/html_node/Versioning.html
    AUTOCONF_VERSION_MREQUIRED=$(grep 'AC_PREREQ\s*(\[.*\])\s*$' configure.ac | sed 's/AC_PREREQ\s*(\[\(.*\)\])/\1/')
     
    step "load autogen.rc"
    if exists file "$RC_FILE" ; then
        if . "$RC_FILE" ; then
            success "$RC_FILE loaded successfully."
        else
            die "$RC_FILE load failed."
        fi
    else
        warn "autogen.rc not exist. skipped."
    fi

    required command autoconf ge "$AUTOCONF_VERSION_MREQUIRED"
    required command automake
    required command m4
    required command perl
    required command make:gmake:bmake

    __is_libtool_used && required command libtoolize

    if [ "$DEBUG" = 'true' ] ; then
        echo
        echo "REQUIRED=$REQUIRED"
        echo "OPTIONAL=$OPTIONAL"
    fi


    step "check required"
    for item in $REQUIRED
    do
        REQUIRED_ITEM_INDEX=$(expr ${REQUIRED_ITEM_INDEX-0} + 1)
        __check_required_item $(__decode "$item")
    done
    unset REQUIRED_ITEM_INDEX


    step "list required"
    if [ -z "$REQUIRED" ] ; then
        warn "no required."
    else
        printf "%-7s %-11s %-10s %-10s %s\n" TYPE NAME EXPECTED ACTUAL LOCATION
        for item in $REQUIRED
        do
            REQUIRED_ITEM_INDEX=$(expr ${REQUIRED_ITEM_INDEX-0} + 1)
            __print_required_or_optional_item $(__decode "$item")
        done
        unset REQUIRED_ITEM_INDEX
    fi


    step "list optional"
    if [ -z "$OPTIONAL" ] ; then
        warn "no optional."
    else
        printf "%-7s %-11s %-10s %-10s %s\n" TYPE NAME EXPECTED ACTUAL LOCATION
        for item in $OPTIONAL
        do
            OPTIONAL_ITEM_INDEX=$(expr ${OPTIONAL_ITEM_INDEX-0} + 1)
            __print_required_or_optional_item $(__decode "$item")
        done
        unset OPTIONAL_ITEM_INDEX
    fi

    gen_config_pre  || return 1
    gen_config      || return 1
    gen_config_post || return 1
    
    echo
    success "Done."
}

main $@
