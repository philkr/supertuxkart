# root CMakeLists for the SuperTuxKart project
project(SuperTuxKart)
set(PROJECT_VERSION "git")

cmake_minimum_required(VERSION 2.8.4)
if(NOT (CMAKE_MAJOR_VERSION VERSION_LESS 3))
  cmake_policy(SET CMP0043 OLD)
endif()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/cmake")
include(CMakeDependentOption)

set(DEPENDENCIES "dependencies")
# In case of 64-bit windows, use a different path for dependencies
# so that both dependencies can be installed next to each other
if ( WIN32 AND (CMAKE_SIZEOF_VOID_P EQUAL 8 ) )
    set(DEPENDENCIES "dependencies-64bit")
endif()

include(BuildTypeSTKRelease)
if (NOT CMAKE_BUILD_TYPE)
    message(STATUS "No build type selected, default to STKRelease")
    set(CMAKE_BUILD_TYPE "STKRelease")
endif()

option(CHECK_ASSETS "Check if assets are installed in ../stk-assets" ON)
option(USE_SYSTEM_ANGELSCRIPT "Use system angelscript instead of built-in angelscript. If you enable this option, make sure to use a compatible version." OFF)
option(ENABLE_WAYLAND_DEVICE "Enable Wayland device for linux build" OFF)

if (UNIX AND NOT APPLE)
    option(USE_GLES2 "Use OpenGL ES2 renderer" OFF)
endif()

if(UNIX OR MINGW)
    option(DEBUG_SYMBOLS "Compile with debug symbols" OFF)
endif()

option(WIIUSE_BUILD "Build wiiuse lib (only for developers)" OFF)
mark_as_advanced(WIIUSE_BUILD)

option(USE_WIIUSE "Support for wiimote input devices" OFF)

FIND_PACKAGE(Boost REQUIRED COMPONENTS system)
INCLUDE_DIRECTORIES(SYSTEM ${Boost_INCLUDE_DIR})
LINK_DIRECTORIES(${Boost_LIBRARY_DIRS})

set(STK_SOURCE_DIR "src")
set(STK_DATA_DIR "${PROJECT_SOURCE_DIR}/data")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")

# These variables enable MSVC to find libraries located in "dependencies"
if(WIN32)
    set(ENV{PATH} "$ENV{PATH};${PROJECT_SOURCE_DIR}/${DEPENDENCIES}/include")
    set(ENV{LIB} ${PROJECT_SOURCE_DIR}/${DEPENDENCIES}/lib)
    add_definitions(-D_IRR_STATIC_LIB_)
    add_definitions(-DNO_IRR_COMPILE_WITH_X11_)
endif()

if(USE_GLES2)
    add_definitions(-DUSE_GLES2)
    add_definitions(-D_IRR_COMPILE_WITH_OGLES2_ -DNO_IRR_COMPILE_WITH_OPENGL_)
endif()


#if(DISABLE_VPX)
#    add_definitions(-DNO_VPX)
#endif()

if(UNIX OR MINGW)
    if(DEBUG_SYMBOLS)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")
    endif()
endif()

# Build the Bullet physics library
add_subdirectory("${PROJECT_SOURCE_DIR}/lib/bullet")
include_directories("${PROJECT_SOURCE_DIR}/lib/bullet/src")

# Build the ENet UDP network library
add_subdirectory("${PROJECT_SOURCE_DIR}/lib/enet")
include_directories("${PROJECT_SOURCE_DIR}/lib/enet/include")

# Build glew library
if(NOT USE_GLES2)
    add_definitions(-DGLEW_NO_GLU)
    add_subdirectory("${PROJECT_SOURCE_DIR}/lib/glew")
    include_directories("${PROJECT_SOURCE_DIR}/lib/glew/include")
endif()

if(MSVC OR APPLE)
    if (NOT APPLE)
    # Build zlib library
    add_subdirectory("${PROJECT_SOURCE_DIR}/lib/zlib")
    include_directories("${PROJECT_SOURCE_DIR}/lib/zlib")

    set(ZLIB_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/lib/zlib" "${PROJECT_BINARY_DIR}/lib/zlib/")
    set(ZLIB_LIBRARY zlibstatic)
    endif()

    # Build png library
    set(SKIP_INSTALL_ALL TRUE)
    set(PNG_STATIC TRUE CACHE BOOL "Build static lib")
    set(PNG_TESTS FALSE CACHE BOOL "Build libpng tests")
    set(PNG_SHARED FALSE CACHE BOOL "Build shared lib")
    add_subdirectory("${PROJECT_SOURCE_DIR}/lib/libpng")
    include_directories("${PROJECT_SOURCE_DIR}/lib/libpng")

    set(PNG_PNG_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/lib/libpng/")
    set(PNG_LIBRARY png_static)
endif()

# Add jpeg library
if (APPLE)
    add_subdirectory("${PROJECT_SOURCE_DIR}/lib/jpeglib")
    include_directories("${PROJECT_SOURCE_DIR}/lib/jpeglib")
    set(JPEG_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/lib/jpeglib/")
    set(JPEG_LIBRARY jpeglib)
else()
    find_package(JPEG REQUIRED)
    include_directories(${JPEG_INCLUDE_DIR})
endif()

add_subdirectory("${PROJECT_SOURCE_DIR}/lib/graphics_utils")
include_directories("${PROJECT_SOURCE_DIR}/lib/graphics_utils")

# Build the irrlicht library
add_subdirectory("${PROJECT_SOURCE_DIR}/lib/irrlicht")
include_directories("${PROJECT_SOURCE_DIR}/lib/irrlicht/include")

# Set include paths
include_directories(${STK_SOURCE_DIR})

if(APPLE)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -arch x86_64")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -arch x86_64 -F/Library/Frameworks")
elseif(MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")   # Enable multi-processor compilation (faster)
endif()


add_subdirectory("${PROJECT_SOURCE_DIR}/lib/angelscript/projects/cmake")
include_directories("${PROJECT_SOURCE_DIR}/lib/angelscript/include")
set(Angelscript_LIBRARIES angelscript)

# Freetype
find_package(Freetype)
if(FREETYPE_FOUND)
    include_directories(${FREETYPE_INCLUDE_DIRS})
else()
    message(FATAL_ERROR "Freetype not found. "
        "Freetype is required to display characters in SuperTuxKart. ")
endif()

# OpenGL
if(NOT USE_GLES2)
    find_package(OpenGL REQUIRED)
    include_directories(${OPENGL_INCLUDE_DIR})
endif()

# Set some compiler options
if(UNIX OR MINGW)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++0x")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wno-unused-function")
endif()

if(MINGW AND CMAKE_BUILD_TYPE MATCHES Release)
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--subsystem,windows")
endif()

if(WIN32)
    # By default windows.h has macros defined for min and max that screw up everything
    add_definitions(-DNOMINMAX)

    # And shut up about unsafe stuff
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)

    # Avoid timespec structure redeclaration on Visual Studio 2015
    if (NOT (MSVC_VERSION LESS 1900))
        add_definitions(-DHAVE_STRUCT_TIMESPEC)
    endif()
endif()

if(MSVC)
    # VS will automatically add NDEBUG for release mode, but only _DEBUG in debug mode.
    # Since STK uses DEBUG, this is added for debug compilation only:
    set_property(DIRECTORY PROPERTY COMPILE_DEFINITIONS_DEBUG DEBUG)
else()
    # All non VS generators used create only a single compile mode, so
    # compile flags can be simplye be added
    if(CMAKE_BUILD_TYPE MATCHES Debug)
        add_definitions(-DDEBUG)
    else()
        add_definitions(-DNDEBUG)
    endif()
endif()

# TODO: remove this switch
add_definitions(-DHAVE_OGGVORBIS)

if(WIN32)
    configure_file("${STK_SOURCE_DIR}/../tools/windows_installer/icon_rc.template" "${PROJECT_BINARY_DIR}/tmp/icon.rc")
endif()

# Provides list of source and header files (STK_SOURCES and STK_HEADERS)
include(sources.cmake)

# Generate source groups useful for MSVC project explorer
include(cmake/SourceGroupFunctions.cmake)
source_group_hierarchy(STK_SOURCES STK_HEADERS)


if(APPLE)
    # icon files to copy in the bundle
    set(OSX_ICON_FILES ${PROJECT_SOURCE_DIR}/data/supertuxkart.icns)
    set_source_files_properties(${OSX_ICON_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    set(STK_SOURCES ${STK_SOURCES} ${OSX_ICON_FILES})

    # build the executable and create an app bundle
    add_executable(supertuxkart MACOSX_BUNDLE ${STK_SOURCES})

    find_library(IOKIT_LIBRARY IOKit)
    find_library(QUICKTIME_LIBRARY QuickTime)
    find_library(CARBON_LIBRARY Carbon)
    find_library(AUDIOUNIT_LIBRARY AudioUnit)
    find_library(COCOA_LIBRARY Cocoa)

    target_link_libraries(supertuxkart
         ${IOKIT_LIBRARY}
         ${QUICKTIME_LIBRARY}
         ${CARBON_LIBRARY}
         ${AUDIOUNIT_LIBRARY}
         ${COCOA_LIBRARY})

    # configure CMake to use a custom Info.plist
    set_target_properties(supertuxkart PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${PROJECT_SOURCE_DIR}/data/SuperTuxKart-Info.plist)

    if(CMAKE_GENERATOR MATCHES "Xcode")
        add_custom_command(TARGET supertuxkart POST_BUILD
            COMMAND ln -f -s ${PROJECT_SOURCE_DIR}/data ${CMAKE_BINARY_DIR}/bin/\${CONFIGURATION}/supertuxkart.app/Contents/Resources)
    else()
        add_custom_command(TARGET supertuxkart POST_BUILD
            COMMAND ln -f -s ${PROJECT_SOURCE_DIR}/data ${CMAKE_BINARY_DIR}/bin/supertuxkart.app/Contents/Resources)
    endif()
else()
    if(MSVC)
        set(PTHREAD_NAMES pthreadVC2)
    elseif(MINGW)
        set(PTHREAD_NAMES "winpthread-1" "libwinpthread-1" "pthreadGC2")
    endif()
    find_library(PTHREAD_LIBRARY NAMES pthread ${PTHREAD_NAMES} PATHS ${PROJECT_SOURCE_DIR}/${DEPENDENCIES}/lib)
    mark_as_advanced(PTHREAD_LIBRARY)

    # Set data dir (absolute or relative to CMAKE_INSTALL_PREFIX)
    add_definitions(-DSUPERTUXKART_DATADIR=\".\")


    # Build the final executable
    add_executable(supertuxkart ${STK_SOURCES} ${STK_RESOURCES} ${STK_HEADERS})
    target_link_libraries(supertuxkart ${PTHREAD_LIBRARY})
endif()

# CURL
if(MSVC)
    target_link_libraries(supertuxkart ${PROJECT_SOURCE_DIR}/${DEPENDENCIES}/lib/libcurl.lib)
elseif(MINGW)
    target_link_libraries(supertuxkart ${PROJECT_SOURCE_DIR}/${DEPENDENCIES}/lib/libcurldll.a)
else()
    find_package(CURL REQUIRED)
    include_directories(${CURL_INCLUDE_DIRS})
endif()

if(UNIX AND NOT APPLE)
        target_link_libraries(supertuxkart rt)
endif()
# Common library dependencies
target_link_libraries(supertuxkart
    bulletdynamics
    bulletcollision
    bulletmath
    enet
    stkirrlicht
    ${Boost_LIBRARIES}
    ${Angelscript_LIBRARIES}
    ${CURL_LIBRARIES}
    ${OGGVORBIS_LIBRARIES}
    ${OPENAL_LIBRARY}
    ${FREETYPE_LIBRARIES}
    ${JPEG_LIBRARIES}
    ${TURBOJPEG_LIBRARY}
    #${VPX_LIBRARIES}
    )

if(NOT USE_GLES2)
	target_link_libraries(supertuxkart ${OPENGL_gl_LIBRARY} glew graphics_utils)
else()
	target_link_libraries(supertuxkart GLESv2)
endif()

# FreeBSD does not search in /usr/local/lib, but at least Freetype is installed there :(
if(${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L/usr/local/lib")
endif()

if(APPLE)
    # In theory it would be cleaner to let CMake detect the right dependencies. In practice, this means that if a OSX user has
    # unix-style installs of Vorbis/Ogg/OpenAL/etc. they will be picked up over our frameworks. This is blocking when I make releases :
    # the mac I use to make STK releases does have other installs of vorbis/ogg/etc. which aren't compatible with STK, so letting
    # CMake pick the library it wants essentially means I can't build.
    set_target_properties(supertuxkart PROPERTIES LINK_FLAGS "-arch x86_64 -F/Library/Frameworks -framework OpenAL -framework Ogg -framework Vorbis")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I/Library/Frameworks/OpenAL.framework/Versions/A/Headers")
endif()

if(MSVC OR MINGW)
  target_link_libraries(supertuxkart iphlpapi.lib)
  add_custom_command(TARGET supertuxkart POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${PROJECT_SOURCE_DIR}/${DEPENDENCIES}/dll"
        $<TARGET_FILE_DIR:supertuxkart>)
  add_custom_target(stkshaders SOURCES ${STK_SHADERS})
endif()

if(MINGW)
    find_library(LIBGCC NAMES "libgcc_s_dw2-1.dll" "libgcc_s_sjlj-1.dll" "libgcc_s_seh-1.dll" PATHS ${CMAKE_FIND_ROOT_PATH})
    if(LIBGCC)
        file(COPY ${LIBGCC} DESTINATION ${CMAKE_BINARY_DIR}/bin/)
    endif()
    find_library(LIBSTDCPP NAMES "libstdc++-6.dll" PATHS ${CMAKE_FIND_ROOT_PATH})
    if(LIBSTDCPP)
        file(COPY ${LIBSTDCPP} DESTINATION ${CMAKE_BINARY_DIR}/bin/)
    endif()
    find_library(LIBPTHREAD NAMES "winpthread-1.dll" "libwinpthread-1.dll" "pthreadGC2.dll" PATHS ${CMAKE_FIND_ROOT_PATH})
    if(LIBPTHREAD)
        file(COPY ${LIBPTHREAD} DESTINATION ${CMAKE_BINARY_DIR}/bin/)
    endif()
endif()


# ==== Checking if data folder exists ====
if(NOT IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data)
  message( FATAL_ERROR "${CMAKE_CURRENT_SOURCE_DIR}/data folder doesn't exist" )
endif()

# ==== Checking if stk-assets folder exists ====
if(CHECK_ASSETS)
  if((IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/karts) AND
       (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/library) AND
       (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/textures) AND
       (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/tracks))
    message(STATUS "Assets found in data directory")
  elseif(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../stk-assets)
    set(STK_ASSETS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../stk-assets/)
    message(STATUS "Assets found")
  elseif(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../supertuxkart-assets)
    set(STK_ASSETS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../supertuxkart-assets/)
    message(STATUS "Assets found")
  else()
    set (CUR_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    get_filename_component(PARENT_DIR ${CUR_DIR} PATH)
    message( FATAL_ERROR "${PARENT_DIR}/stk-assets folder doesn't exist. "
      "Please download the stk-assets, or disable this test with -DCHECK_ASSETS=off." )
  endif()
endif()

add_subdirectory(pykart)
