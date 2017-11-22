cmake_minimum_required(VERSION 2.8.3)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}")

FIND_PACKAGE(PythonInterp "3.0" REQUIRED)
FIND_PACKAGE(PythonLibs "3.0" REQUIRED)
FIND_PACKAGE(NumPy REQUIRED)

set(version ${PYTHONLIBS_VERSION_STRING})

STRING( REPLACE "." "" boost_py_version ${version} )
find_package(Boost 1.55 COMPONENTS "python-py${boost_py_version}")
set(Boost_PYTHON_FOUND ${Boost_PYTHON-PY${boost_py_version}_FOUND})

while(NOT "${version}" STREQUAL "" AND NOT Boost_PYTHON_FOUND)
        STRING( REGEX REPLACE "([0-9.]+).[0-9]+" "\\1" version ${version} )
        
        STRING( REPLACE "." "" boost_py_version ${version} )
        find_package(Boost 1.55 COMPONENTS "python-py${boost_py_version}" filesystem system)
        set(Boost_PYTHON_FOUND ${Boost_PYTHON-PY${boost_py_version}_FOUND})
        
        STRING( REGEX MATCHALL "([0-9.]+).[0-9]+" has_more_version ${version} )
        if("${has_more_version}" STREQUAL "")
                break()
        endif()
endwhile()
if(NOT Boost_PYTHON_FOUND)
        find_package(Boost 1.55 COMPONENTS python filesystem system)
endif()
INCLUDE_DIRECTORIES(${Boost_INCLUDE_DIRS} ${PYTHON_INCLUDE_DIRS} ${PROJECT_SOURCE_DIR} ${PYTHON_NUMPY_INCLUDE_DIR})

# Add the python library
add_library(pykart SHARED pykart.cpp)
target_link_libraries(pykart ${Boost_LIBRARIES} ${PYTHON_LIBRARIES} ${NumPy_LIBRARIES})
set_target_properties(pykart PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_target_properties(pykart PROPERTIES PREFIX "")
set_target_properties(pykart PROPERTIES SUFFIX .so)
set_target_properties(pykart PROPERTIES MACOSX_RPATH on)

if(UNIX AND NOT APPLE)
        target_link_libraries(pykart rt)
endif()
