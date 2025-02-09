# Tries to find Gperftools.
#
# Usage of this module as follows:
#
#     find_package(Gperftools)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
#  Gperftools_ROOT_DIR  Set this variable to the root installation of
#                       Gperftools if the module has problems finding
#                       the proper installation path.
#
# Variables defined by this module:
#
#  GPERFTOOLS_FOUND              System has Gperftools libs/headers
#  GPERFTOOLS_LIBRARIES          The Gperftools libraries (tcmalloc & profiler)
#  GPERFTOOLS_INCLUDE_DIR        The location of Gperftools headers


# bin/khaiii는 /tmp/bin_khaiii.prof 파일로, test/khaiii는 /tmp/test_khaiii.prof 파일로 생성됩니다.
# 출력 파일명을 지정하고 싶을 경우 CPUPROFILE=/path/to/output bin/khanii와 같이 환경변수와 함께 실행합니다.
# pprof --text bin/khaiii /tmp/bin_khaiii.prof와 같이 실행하면 출력 파일로부터 텍스트 보고서를 생성할 수 있습니다.
# 참고: https://github.com/gperftools/gperftools

find_library(GPERFTOOLS_TCMALLOC
  NAMES tcmalloc
  HINTS ${Gperftools_ROOT_DIR}/lib)

find_library(GPERFTOOLS_PROFILER
  NAMES profiler
  HINTS ${Gperftools_ROOT_DIR}/lib)

find_library(GPERFTOOLS_TCMALLOC_AND_PROFILER
  NAMES tcmalloc_and_profiler
  HINTS ${Gperftools_ROOT_DIR}/lib)

find_path(GPERFTOOLS_INCLUDE_DIR
  NAMES gperftools/heap-profiler.h
  HINTS ${Gperftools_ROOT_DIR}/include)

set(GPERFTOOLS_LIBRARIES ${GPERFTOOLS_TCMALLOC_AND_PROFILER})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  Gperftools
  DEFAULT_MSG
  GPERFTOOLS_LIBRARIES
  GPERFTOOLS_INCLUDE_DIR)

mark_as_advanced(
  Gperftools_ROOT_DIR
  GPERFTOOLS_TCMALLOC
  GPERFTOOLS_PROFILER
  GPERFTOOLS_TCMALLOC_AND_PROFILER
  GPERFTOOLS_LIBRARIES
  GPERFTOOLS_INCLUDE_DIR)
