# autogen.sh
`autogen.sh` is a `POSIX` shell script to manage `GNU` `Autotools`(`autoconf` `automake`) and other softwares used by your project.

## how to use
locate `autogen.sh` in your project.

## autogen.sh command usage
*   print the help infomation of `autogen.sh` command

        ./autogen.sh -h
        ./autogen.sh --help

*   print the version of `autogen.sh`

        ./autogen.sh -V
        ./autogen.sh --version

*   gen configure

        ./autogen.sh
        ./autogen.sh -x
        ./autogen.sh -d

## autogen.rc
`autogen.rc` is also a `POSIX` shell script. It is a extension of `autogen.sh`. It will be automatically loaded if it exists.

a typical example of this file looks like as follows:

```bash
required command cc
required command pkg-config ge 0.18
optional command python3    ge 3.5

gen_config_pre() {
    step "gen config pre"
    # do whatever you want."
}

gen_config() {
    step "gen config"
    run autoreconf -ivf
}

gen_config_post() {
    step "gen config post"
    # do whatever you want.
}
```

### the function can be declared in `autogen.rc`
|function|overview|
|-|-|
|`gen_config_pre(){}`|run before `gen_config(){}`|
|`gen_config(){}`|run command `autoreconf -ivf`|
|`gen_config_post(){}`|run after `gen_config(){}`|

### the function should be invoked on top of the `autogen.rc`
|function|overview|
|-|-|
|`required TYPE NAME [OP VERSION]`|declare required `command` / `perl` / `python` modules.|
|`optional TYPE NAME [OP VERSION]`|declare optional `command` / `perl` / `python` modules.|

### the function can be invoked in `autogen.rc`
|function|example|
|-|-|
|`print`|`print 'your message.'`|
|`echo`|`echo 'your message.'`|
|`info`|`info 'your infomation.'`|
|`warn`|`warn "warnning message."`|
|`error`|`error 'error message.'`|
|`die`|`die "please specify a package name."`|
|`success`|`success "build success."`|
|`sed_in_place`|`sed_in_place 's/-mandroid//g' Configure`|

### the variable can be used in `autogen.rc`
|variable|overview|
|-|-|
|`NATIVE_OS_TYPE`|current machine os type.|
|`NATIVE_OS_NAME`|current machine os name.|
|`NATIVE_OS_VERS`|current machine os version.|
|`NATIVE_OS_ARCH`|current machine os arch.|
|`PROJECT_DIR`|the project dir.|
|`PROJECT_NAME`|the project name.|
|`PROJECT_VERSION`|the project version.|
|`AUTOCONF_VERSION_MREQUIRED`|min required version of autoconf.|
