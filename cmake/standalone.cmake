# Bootstrap for building OMCompiler-3rdParty on its own.
#
# This directory is normally added as a subdirectory of the OpenModelica
# superproject, which sets up a number of things before it that are not part of
# this repository. This file provides the minimum needed so that
#
#   cmake -S . -B build && cmake --build build -j$(nproc)
#
# works standalone, which is what .github/workflows/build.yml uses to build-test
# this repository.
#
# It is included from CMakeLists.txt ONLY when this directory is the top of the
# build, so nothing here can change how OpenModelica itself is configured.
# include() does not open a new scope, so the macros and options below land in
# the caller exactly as the superproject would have provided them.

# The superproject pins this to "lib" instead of letting GNUInstallDirs pick
# lib64 on RHEL-based distros.
set(CMAKE_INSTALL_LIBDIR "lib")
include(GNUInstallDirs)

# --- from OpenModelica/cmake/omc_utils.cmake -------------------------------
set(CMAKE_MESSAGE_CONTEXT_SHOW ON)
macro(omc_add_subdirectory var)
  list(APPEND CMAKE_MESSAGE_CONTEXT ${var})
  add_subdirectory(${ARGV0} ${ARGV1} ${ARGV2})
  list(POP_BACK CMAKE_MESSAGE_CONTEXT)
endmacro()

# --- from OpenModelica/cmake/omc_check_exists.cmake ------------------------
include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckIncludeFiles)
include(CheckTypeSize)

macro(omc_check_function_exists_and_define func_name)
  string(TOUPPER ${func_name} DEFINE_SUFFIX)
  check_function_exists(${func_name} HAVE_${DEFINE_SUFFIX})
endmacro()

macro(omc_check_functions_exist_and_define_each func_names)
  foreach(func_name ${func_names})
    string(TOUPPER ${func_name} DEFINE_SUFFIX)
    check_function_exists(${func_name} HAVE_${DEFINE_SUFFIX})
  endforeach()
endmacro()

macro(omc_check_header_exists_and_define header_name)
  string(TOUPPER ${header_name} DEFINE_SUFFIX)
  string(REPLACE "." "_" DEFINE_SUFFIX ${DEFINE_SUFFIX})
  string(REPLACE "/" "_" DEFINE_SUFFIX ${DEFINE_SUFFIX})
  check_include_file(${header_name} HAVE_${DEFINE_SUFFIX})
endmacro()

macro(omc_check_headers_exist_and_define_each header_names)
  foreach(header_name ${header_names})
    omc_check_header_exists_and_define(${header_name})
  endforeach()
endmacro()

# --- from OMCompiler/CMakeLists.txt ----------------------------------------
option(OM_OMC_ENABLE_FORTRAN "Enable Fortran support." ON)
if(OM_OMC_ENABLE_FORTRAN)
  enable_language(Fortran)
endif()
option(OM_OMC_ENABLE_OPTIMIZATION "Build the old Optimization Runtime (moo, ipopt)." ON)
option(OM_OMC_ENABLE_PRIMME "Build PRIMME." ON)
option(OM_OMC_ENABLE_COLPACK "Build ColPack." ON)

# --- from OpenModelica/cmake/OMCPThreads.cmake -----------------------------
# gc links to this. Only the non-MSVC branch is reproduced: the standalone
# build targets GCC and MSYS2/UCRT64, both of which take that branch. An MSVC
# standalone build would additionally need PThreads4W (e.g. from vcpkg).
find_package(Threads)
add_library(OMCPThreads INTERFACE)
target_link_libraries(OMCPThreads INTERFACE Threads::Threads ${CMAKE_DL_LIBS})
target_compile_definitions(OMCPThreads INTERFACE OM_HAVE_PTHREADS)
add_library(OMCPThreads::OMCPThreads ALIAS OMCPThreads)

# --- from OpenModelica/CMakeLists.txt --------------------------------------
# SUNDIALS is configured with LAPACK enabled below, and moo/ipopt needs BLAS.
find_package(BLAS)
find_package(LAPACK)
