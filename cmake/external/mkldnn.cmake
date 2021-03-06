#===============================================================================
# Copyright 2016-2018 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#===============================================================================

# MKLDNN is only used for gtest reference code and benchmark comparion
if(NOT (${WITH_BENCHMARK} OR ${WITH_GTEST}))
  return()
endif()

include(ExternalProject)

set(MKLDNN_PROJECT        "extern_mkldnn")
set(MKLDNN_SOURCES_DIR    ${THIRD_PARTY_PATH}/mkldnn)
set(MKLDNN_INSTALL_DIR    ${THIRD_PARTY_INSTALL_PATH}/mkldnn)
set(MKLDNN_INC_DIR        "${MKLDNN_INSTALL_DIR}/include" CACHE PATH "mkldnn include directory." FORCE)
set(MKLDNN_LIB "${MKLDNN_INSTALL_DIR}/lib/libmkldnn.so" CACHE FILEPATH "mkldnn library." FORCE)
message(STATUS "Set ${MKLDNN_INSTALL_DIR}/lib to runtime path")
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}" "${MKLDNN_INSTALL_DIR}/lib")

include_directories(${MKLDNN_INC_DIR})

set(MKLDNN_DEPENDS   ${MKLML_PROJECT})
message(STATUS "Build MKLDNN with MKLML ${MKLML_ROOT}")

if(${CMAKE_C_COMPILER_VERSION} VERSION_LESS "5.4")
  set(MKLDNN_CFLAG)
else()
  set(MKLDNN_CFLAG "${CMAKE_C_FLAGS} -Wno-error=strict-overflow \
  -Wno-unused-but-set-variable -Wno-unused-variable -Wno-format-truncation")
endif()

if(${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS "5.4")
  set(MKLDNN_CXXFLAG)
else()
  set(MKLDNN_CXXFLAG "${CMAKE_CXX_FLAGS} -Wno-error=strict-overflow \
  -Wno-unused-but-set-variable -Wno-unused-variable -Wno-format-truncation")
endif()

# TODO: MKL-DNN have build error on gcc8.0 "within lambda, error: lvalue required as unary ‘&’ operand"
# so here force to use lowwer gcc(5.4) to build MKL-DNN
# but VNNI is only supported after gcc8.0, so need follow-up when VNNI is needed!
set(MKLDNN_C_COMPILER "/usr/bin/gcc")
set(MKLDNN_CXX_COMPILER "/usr/bin/g++")
ExternalProject_Add(
    ${MKLDNN_PROJECT}
    ${EXTERNAL_PROJECT_LOG_ARGS}
    DEPENDS             ${MKLDNN_DEPENDS}
    GIT_REPOSITORY      "https://github.com/01org/mkl-dnn.git"
    GIT_TAG             "8758fe6ec8a1695b6ac1570b749818a188d0ad66" #based on Mar 32th, or try "v0.13"
    PREFIX              ${MKLDNN_SOURCES_DIR}
    UPDATE_COMMAND      ""
    CMAKE_ARGS          -DCMAKE_INSTALL_PREFIX=${MKLDNN_INSTALL_DIR}
    CMAKE_ARGS          -DMKLROOT=${MKLML_ROOT}
    CMAKE_ARGS          -DCMAKE_C_COMPILER=${MKLDNN_C_COMPILER}
    CMAKE_ARGS          -DCMAKE_CXX_COMPILER=${MKLDNN_CXX_COMPILER}
    CMAKE_ARGS          -DCMAKE_C_FLAGS=${MKLDNN_CFLAG}
    CMAKE_ARGS          -DCMAKE_CXX_FLAGS=${MKLDNN_CXXFLAG}
    CMAKE_CACHE_ARGS    -DCMAKE_INSTALL_PREFIX:PATH=${MKLDNN_INSTALL_DIR}
                        -DMKLROOT:PATH=${MKLML_ROOT}
)

add_library(mkldnn SHARED IMPORTED GLOBAL)
SET_PROPERTY(TARGET mkldnn PROPERTY IMPORTED_LOCATION ${MKLDNN_LIB})
add_dependencies(mkldnn ${MKLDNN_PROJECT})
message(STATUS "MKLDNN library: ${MKLDNN_LIB}")
list(APPEND external_project_dependencies mkldnn)
