#!/bin/sh

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
os type
os arch
os name
os version
EOF
                ;;
            -V|--version)
                printf "%s\n" '2021.03.28.23'
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
                case $(os type) in
                    freebsd) echo 'FreeBSD' ;;
                    openbsd) echo 'OpenBSD' ;;
                    netbsd)  echo 'NetBSD'  ;;
                    darwin)  sw_vers -productName ;;
                    linux)
                        __get_os_name_from_uname_a ||
                        __get_os_name_from_etc_os_release ||
                        __get_os_name_from_lsb_release
                        ;;
                    msys|mingw*|cygwin)
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
                case $(uname | tr A-Z a-z) in
                    freebsd) freebsd-version ;;
                    openbsd) uname -r ;;
                    netbsd)  uname -r ;;
                    darwin)  sw_vers -productVersion ;;
                    linux)
                        __get_os_version_from_uname_a ||
                        __get_os_version_from_etc_os_release ||
                        __get_os_version_from_lsb_release
                        ;;
                    msys*|mingw*|cygwin*)
                        systeminfo | grep 'OS Version:' | cut -d: -f2 | head -n 1 | sed 's/^[[:space:]]*//' | cut -d ' ' -f1 ;;
                esac
                ;;
            *)  echo "$1: not support item."; return 1
        esac
    else
        echo "only support one item."; return 1
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

get_pacman_package_name_by_command_name() {
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
        dnf)     run $sudo dnf -y install "$2" ;;
        yum)     run $sudo yum -y install "$2" ;;
        zypper)  run $sudo zypper install -y "$2" ;;
        apk)     run $sudo apk add "$2" ;;
        xbps)    run $sudo xbps-install -Sy "$2" ;;
        emerge)  run $sudo emerge "$2" ;;
        pacman)  run $sudo pacman -Syyuu --noconfirm && pacman -S --noconfirm "$2" ;;
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
        print "🔥  ${COLOR_YELLOW}required command${COLOR_OFF} ${COLOR_GREEN}$2 $3 $4${COLOR_OFF}${COLOR_YELLOW}, but${COLOR_OFF} ${COLOR_GREEN}$2${COLOR_OFF} ${COLOR_YELLOW}command not found, try to install it via${COLOR_OFF} ${COLOR_GREEN}$1${COLOR_OFF}\n"
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
required_command_needs_installed() {
    if exists command "$1" ; then
        if [ $# -eq 3 ] ; then
            ! command_version_match $@
        else
            return 1
        fi
    fi
}

# examples:
# required command pkg-config ge 0.18
# required command python3    ge 3.5
# optional python3 libxml2    ge 2.8
# optional python3 libxml2
handle_required_item() {
    shift
    case $1 in
        command)
            shift
            if required_command_needs_installed $@ ; then
                if [ -z "$AVAILABLE_PACKAGE_MANAGER_LIST" ] ; then
                    AVAILABLE_PACKAGE_MANAGER_LIST=$(__available_package_manager_list)
                    if [ -z "$AVAILABLE_PACKAGE_MANAGER_LIST" ] ; then
                        warn "no package manager found."
                        return 1
                    else
                        echo "Found $(list_length $AVAILABLE_PACKAGE_MANAGER_LIST) package manager : ${COLOR_GREEN}$AVAILABLE_PACKAGE_MANAGER_LIST${COLOR_OFF}"
                    fi
                fi
                for pm in $AVAILABLE_PACKAGE_MANAGER_LIST
                do
                    __install_command_via_package_manager "$pm" $@
                done
            else
                printf "required command %-10s %-10s ${COLOR_GREEN}FOUND${COLOR_OFF} %-8s %s\n" "$1" "$2 $3" "$(version_of_command $1)" "$(command -v $1)"
            fi
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

__is_libtool_used() {
    # https://www.gnu.org/software/libtool/manual/html_node/LT_005fINIT.html
    grep 'LT_INIT\s*('     configure.ac ||
    grep 'AC_PROG_LIBTOOL' configure.ac ||
    grep 'AM_PROG_LIBTOOL' configure.ac
}

__decode_required_or_optional() {
    echo "$@" | sed 's|/| |g'
}

__check_required() {
    for item in $@
    do
        handle_required_item $(__decode_required_or_optional "$item")
    done
}

__print_required_or_optional() {
    shift
    case $1 in
        command)
            printf "%-7s %-11s %-10s %-10s %s\n" "$1" "$2" "$3 $4" "$(version_of_command $2)" "$(command -v $2)"
            ;;
        python)
            printf "%-7s %-11s %-10s %-10s %s\n" "$1" "$2" "$3 $4" "$(version_of_python_module $2)" "$(location_of_python_module $2)"
            ;;
        perl)
            printf "%-7s %-11s %-10s %-10s %s\n" "$1" "$2" "$3 $4" "" ""
            ;;
        *)  die "$1: not support."
    esac
}

__list__required_or_optional() {
    printf "%-7s %-11s %-10s %-10s %s\n" TYPE NAME EXPECTED ACTUAL LOCATION
    for item in $@
    do
        __print_required_or_optional $(__decode_required_or_optional "$item")
    done
}

__encode_required_or_optional() {
    case $2 in
        command|python|python2|python3|perl)
            echo "$(echo $@ | tr ' ' /)" ;;
        *) die "$2 : not support" ;;
    esac
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
            REQUIRED="$(__encode_required_or_optional required $@)"
        else
            REQUIRED="$REQUIRED $(__encode_required_or_optional required $@)"
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
            OPTIONAL=$(__encode_required_or_optional optional $@)
        else
            OPTIONAL="$OPTIONAL $(__encode_required_or_optional optional $@)"
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

main() {
    unset DEBUG

    unset STEP_NUM
    unset STEP_MESSAGE

    unset REQUIRED
    unset OPTIONAL

    unset PROJECT_DIR
    unset PROJECT_NAME
    unset PROJECT_VERSION

    unset NATIVE_OS_TYPE
    unset NATIVE_OS_NAME
    unset NATIVE_OS_VERS
    unset NATIVE_OS_ARCH

    unset AUTOCONF_VERSION_MREQUIRED

    echo "${COLOR_GREEN}autogen.sh is a POSIX shell script to manage GNU Autotools(autoconf automake) and other softwares used by this project.${COLOR_OFF}"

    case $1 in
        -h|--help)
            cat <<EOF
./autogen.sh -h | --help
./autogen.sh -V | --version
./autogen.sh [ -x | -d ]
EOF
            return 0
            ;;
        -V|--version)
            echo "$PROJECT_VERSION"
            return 0
            ;;
        -x) set -x ;;
        -d) DEBUG=true ;;
        '') ;;
        *)  die "$1: not support action."
    esac

    if [ "$(whoami)" != root ] ; then
        sudo=sudo
    fi
    
    step "show current machine os info"
    NATIVE_OS_TYPE=$(os type)
    NATIVE_OS_NAME=$(os name)
    NATIVE_OS_VERS=$(os version)
    NATIVE_OS_ARCH=$(os arch)
    echo "NATIVE_OS_TYPE  = $NATIVE_OS_TYPE"
    echo "NATIVE_OS_NAME  = $NATIVE_OS_NAME"
    echo "NATIVE_OS_VERS  = $NATIVE_OS_VERS"
    echo "NATIVE_OS_ARCH  = $NATIVE_OS_ARCH"

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
    AUTOCONF_VERSION_MREQUIRED=$(grep 'AC_PREREQ\s*(\[[0-9]\.[0-9]\+\])' configure.ac | sed 's/AC_PREREQ\s*(\[\(.*\)\])/\1/')
     
    step "load autogen.rc"
    if exists file autogen.rc ; then
        if . ./autogen.rc ; then
            success "autogen.rc loaded successfully."
        else
            die "autogen.rc load failed."
        fi
    else
        warn "autogen.rc not exist. skipped."
    fi

    step "check required"
    
    required command autoconf ge "$AUTOCONF_VERSION_MREQUIRED"
    required command automake
    required command m4
    required command perl
    required command make
    optional command gmake
    optional command bmake

    __is_libtool_used && required command libtoolize

    if [ "$DEBUG" = 'true' ] ; then
        echo "REQUIRED=$REQUIRED"
        echo "OPTIONAL=$OPTIONAL"
    fi

    __check_required $REQUIRED

    step "list required"
    if [ -z "$REQUIRED" ] ; then
        warn "no required."
    else
        __list__required_or_optional $REQUIRED
    fi

    step "list optional"
    if [ -z "$REQUIRED" ] ; then
        warn "no optional."
    else
        __list__required_or_optional $OPTIONAL
    fi

    gen_config_pre  || return 1
    gen_config      || return 1
    gen_config_post || return 1
    
    echo
    success "Done."
}

main $@
