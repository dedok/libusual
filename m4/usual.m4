
dnl Those depend on correct order:
dnl  AC_USUAL_PORT_CHECK
dnl  AC_USUAL_PROGRAM_CHECK
dnl  AC_USUAL_HEADER_CHECK
dnl  AC_USUAL_TYPE_CHECK
dnl  AC_USUAL_FUNCTION_CHECK
dnl Order does not matter:
dnl  AC_USUAL_CASSERT
dnl  AC_USUAL_WERROR
dnl  AC_USUAL_DEBUG

dnl
dnl  AC_USUAL_PORT_CHECK: Sets PORTNAME=win32/unix
dnl
dnl  Also defines port-specific flags:
dnl   _GNU_SOURCE, _WIN32_WINNT, WIN32_LEAN_AND_MEAN
dnl
AC_DEFUN([AC_USUAL_PORT_CHECK], [
AC_MSG_CHECKING([target host type])
xhost="$host_alias"
if test "x$xhost" = "x"; then
  xhost=`uname -s`
fi
case "$xhost" in
*cygwin* | *mingw* | *pw32* | *MINGW*)
   LIBS="$LIBS -lws2_32"
   PORTNAME=win32;;
*) PORTNAME=unix ;;
esac
AC_SUBST(PORTNAME)
AC_MSG_RESULT([$PORTNAME])
dnl Set the flags before any feature tests.
if test "$PORTNAME" = "win32"; then
  AC_DEFINE([WIN32_LEAN_AND_MEAN], [1], [Define to request cleaner win32 headers.])
  AC_DEFINE([_WIN32_WINNT], [0x0501], [Define to max win32 API version (0x0400, 0x0501).])
else
  AC_DEFINE([_GNU_SOURCE], [1], [Define to get working glibc.])
fi
])


dnl
dnl AC_USUAL_PROGRAM_CHECK:  Simple C environment: CC, CPP, INSTALL
dnl
AC_DEFUN([AC_USUAL_PROGRAM_CHECK], [
AC_PROG_CC_STDC
AC_PROG_CPP
dnl Check if compiler supports __func__
AC_CACHE_CHECK([whether compiler supports __func__], pgac_cv_funcname_func,
  [AC_TRY_COMPILE([#include <stdio.h>], [printf("%s\n", __func__);],
    [pgac_cv_funcname_func=yes], [pgac_cv_funcname_func=no])])
if test x"$pgac_cv_funcname_func" = xyes ; then
  AC_DEFINE(HAVE_FUNCNAME__FUNC, 1,
    [Define to 1 if your compiler understands __func__.])
fi
dnl Check if linker supports -Wl,--as-needed
if test "$GCC" = "yes"; then
  old_LDFLAGS="$LDFLAGS"
  LDFLAGS="$LDFLAGS -Wl,--as-needed"
  AC_MSG_CHECKING([whether linker supports --as-needed])
  AC_LINK_IFELSE([int main(void) { return 0; }],
    [AC_MSG_RESULT([yes])],
    [AC_MSG_RESULT([no])
     LDFLAGS="$old_LDFLAGS"])
fi
dnl Pick good warning flags for gcc
WFLAGS=""
if test x"$GCC" = xyes; then
  AC_MSG_CHECKING([for working warning switches])
  good_CFLAGS="$CFLAGS"
  flags="-Wall -Wextra"
  # turn off noise from Wextra
  flags="$flags -Wno-unused-parameter -Wno-missing-field-initializers"
  # Wextra does not turn those on?
  flags="$flags -Wmissing-prototypes -Wpointer-arith -Wendif-labels"
  flags="$flags -Wdeclaration-after-statement -Wold-style-definition"
  flags="$flags -Wstrict-prototypes -Wundef -Wformat=2"
  for f in $flags; do
    CFLAGS="$good_CFLAGS $WFLAGS $f"
    AC_COMPILE_IFELSE([void foo(void){}], [WFLAGS="$WFLAGS $f"])
  done
  CFLAGS="$good_CFLAGS"
  AC_MSG_RESULT([done])
fi
# autoconf does not want to find 'install', if not using automake...
INSTALL=install
BININSTALL="$INSTALL"
AC_SUBST(INSTALL)
AC_SUBST(WFLAGS)
AC_SUBST(BININSTALL)
AC_CHECK_TOOL([STRIP], [strip])
AC_CHECK_TOOL([AR], [ar])
])


dnl
dnl AC_USUAL_TYPE_CHECK: Basic types for C
dnl
AC_DEFUN([AC_USUAL_TYPE_CHECK], [
AC_C_INLINE
AC_C_RESTRICT
AC_C_BIGENDIAN
AC_SYS_LARGEFILE
AC_TYPE_PID_T
AC_TYPE_UID_T
AC_TYPE_SIZE_T
]) 

dnl
dnl  AC_USUAL_HEADER_CHECK:  Basic headers
dnl
AC_DEFUN([AC_USUAL_HEADER_CHECK], [
AC_CHECK_HEADERS([sys/socket.h poll.h sys/poll.h sys/un.h])
AC_CHECK_HEADERS([arpa/inet.h netinet/in.h netinet/tcp.h])
AC_CHECK_HEADERS([sys/param.h sys/uio.h libgen.h pwd.h grp.h])
AC_CHECK_HEADERS([sys/wait.h sys/mman.h syslog.h netdb.h dlfcn.h])
AC_CHECK_HEADERS([err.h pthread.h endian.h sys/endian.h byteswap.h])
AC_CHECK_HEADERS([malloc.h regex.h])
dnl ucred.h may have prereqs
AC_CHECK_HEADERS([ucred.h sys/ucred.h], [], [], [
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
])])


dnl
dnl  AC_USUAL_FUNCTION_CHECK:  Basic functions
dnl
AC_DEFUN([AC_USUAL_FUNCTION_CHECK], [
### Functions provided if missing
AC_CHECK_FUNCS(basename dirname strlcpy strlcat getpeereid sigaction)
AC_CHECK_FUNCS(inet_ntop poll getline memrchr regcomp)
AC_CHECK_FUNCS(err errx warn warnx getprogname setprogname)
AC_CHECK_FUNCS(posix_memalign memalign valloc)
### Functions provided only on win32
AC_CHECK_FUNCS(localtime_r recvmsg sendmsg)
### Functions used by libusual itself
AC_CHECK_FUNCS(syslog mmap recvmsg sendmsg getpeerucred)
### win32: link with ws2_32
AC_SEARCH_LIBS(WSAGetLastError, ws2_32)
AC_FUNC_STRERROR_R
])

dnl
dnl  AC_USUAL_CASSERT:  --enable-cassert switch to set macro CASSERT
dnl
AC_DEFUN([AC_USUAL_CASSERT], [
AC_ARG_ENABLE(cassert, AC_HELP_STRING([--enable-cassert],[turn on assert checking in code]))
AC_MSG_CHECKING([whether to enable asserts])
if test "$enable_cassert" = "yes"; then
  AC_DEFINE(CASSERT, 1, [Define to enable assert checking])
  AC_MSG_RESULT([yes])
else
  AC_MSG_RESULT([no])
fi
])


dnl
dnl  AC_USUAL_WERROR:  --enable-werror switch to turn warnings into errors
dnl
AC_DEFUN([AC_USUAL_WERROR], [
AC_ARG_ENABLE(werror, AC_HELP_STRING([--enable-werror],[add -Werror to CFLAGS]))
AC_MSG_CHECKING([whether to fail on warnings])
if test "$enable_werror" = "yes"; then
  CFLAGS="$CFLAGS -Werror"
  AC_MSG_RESULT([yes])
else
  AC_MSG_RESULT([no])
fi
])


dnl
dnl  AC_USUAL_DEBUG:  --disable-debug switch to strip binary
dnl
AC_DEFUN([AC_USUAL_DEBUG], [
AC_ARG_ENABLE(debug,
  AC_HELP_STRING([--disable-debug],[strip binary]),
  [], [enable_debug=yes])
AC_MSG_CHECKING([whether to build debug binary])
if test "$enable_debug" = "yes"; then
  LDFLAGS="-g $LDFLAGS"
  BININSTALL="$INSTALL"
  AC_MSG_RESULT([yes])
else
  BININSTALL="$INSTALL -s"
  AC_MSG_RESULT([no])
fi
AC_SUBST(enable_debug)
])


dnl
dnl  AC_USUAL_LIBEVENT:  --with-libevent
dnl
AC_DEFUN([AC_USUAL_LIBEVENT], [
ifelse([$#], [0], [levent=yes], [levent=no])
AC_MSG_CHECKING([for libevent])
AC_ARG_WITH(libevent,
  AC_HELP_STRING([--with-libevent=prefix],[Specify where libevent is installed]),
  [ if test "$withval" = "no"; then
      levent=no
    elif test "$withval" = "yes"; then
      levent=yes
    else
      levent=yes
      CPPFLAGS="$CPPFLAGS -I$withval/include"
      LDFLAGS="$LDFLAGS -L$withval/lib"
    fi
  ], [])

if test "$levent" = "no"; then
  AC_MSG_RESULT([using usual/event])
  AC_DEFINE(HAVE_EVENT_LOOPBREAK, 1, [usual/event.h has it.])
  AC_DEFINE(HAVE_EVENT_BASE_NEW, 1, [usual/event.h has it.])
  have_libevent=no
else # libevent
AC_DEFINE(HAVE_LIBEVENT, 1, [Use real libevent.])
LIBS="-levent $LIBS"
AC_LINK_IFELSE([
  #include <sys/types.h>
  #include <sys/time.h>
  #include <stdio.h>
  #include <event.h>
  int main(void) {
    struct event ev;
    event_init();
    event_set(&ev, 1, EV_READ, NULL, NULL);
    /* this checks for 1.2+ but next we check for 1.3b+ anyway */
    /* event_base_free(NULL); */
  } ],
[AC_MSG_RESULT([found])],
[AC_MSG_ERROR([not found, cannot proceed])])

dnl libevent < 1.3b crashes on event_base_free()
dnl no good way to check libevent version.  use hack:
dnl evhttp.h defines HTTP_SERVUNAVAIL only since 1.3b
AC_MSG_CHECKING([whether libevent version >= 1.3b])
AC_EGREP_CPP([HTTP_SERVUNAVAIL],
[#include <evhttp.h>
  HTTP_SERVUNAVAIL ],
[AC_MSG_ERROR([no, cannot proceed])],
[AC_MSG_RESULT([yes])])

AC_CHECK_FUNCS(event_loopbreak event_base_new)
have_libevent=yes
fi # libevent
AC_SUBST(have_libevent)

]) dnl  AC_USUAL_LIBEVENT

