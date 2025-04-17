# create swig folder if it doesn't exist
if [ ! -d ../../swig ]; then
    mkdir -p ../../swig
fi

# create python folder if it doesn't exist
if [ ! -d ../../swig/python ]; then
    mkdir -p ../../swig/python
fi

# Create SWIG interface file if it doesn't exist
if [ ! -f ../../swig/python/interface.i ]; then
    echo "Creating SWIG interface file..."
    cat <<EOL > ../../swig/python/interface.i
%module my_module
%{
#include "my_class/my_class.hpp"
%}
%include "my_class/my_class.hpp"
%include <std_string.i>
%include <std_vector.i>
%include <std_map.i>
%include <std_pair.i>
%include <std_set.i>
EOL
else
    echo "SWIG interface file already exists"
fi

# Create CMakeLists.txt if it doesn't exist
if [ ! -f ../../swig/CMakeLists.txt ]; then
    echo "Creating CMakeLists.txt..."
    cat <<EOL > ../../swig/CMakeLists.txt
set(LIBS_FOR_SWIG set_it)

find_package(Threads REQUIRED)
find_package(SWIG REQUIRED)
include(\${SWIG_USE_FILE})

add_subdirectory(python)
EOL
else
    echo "CMakeLists.txt already exists"
fi
# Create python/CMakeLists.txt if it doesn't exist
if [ ! -f ../../swig/python/CMakeLists.txt ]; then

    echo "Creating python/CMakeLists.txt..."
    cat <<EOL > ../../swig/python/CMakeLists.txt
find_package(PythonLibs 3 REQUIRED)
find_package(PythonInterp ${PYTHONLIBS_VERSION_STRING} REQUIRED)
include_directories(\${PYTHON_INCLUDE_DIRS})

set_property(SOURCE interface.i PROPERTY CPLUSPLUS ON)
swig_add_library(swig_python
    TYPE SHARED
    LANGUAGE python
    OUTPUT_DIR \${CMAKE_CURRENT_BINARY_DIR}
    SOURCES interface.i
)
swig_link_libraries(swig_python PUBLIC \${LIBS_FOR_SWIG} \${CMAKE_THREAD_LIBS_INIT} \${PYTHON_LIBRARIES})
target_include_directories(swig_python PUBLIC \${CMAKE_CURRENT_SOURCE_DIR}/../.. \${PYTHON_INCLUDE_PATH})
set_target_properties(swig_python PROPERTIES OUTPUT_NAME swig_python)
set_target_properties(swig_python PROPERTIES SWIG_USE_TARGET_INCLUDE_DIRECTORIES TRUE)
set_target_properties(swig_python PROPERTIES USE_SWIG_DEPENDENCIES TRUE)
EOL
else
    echo "python/CMakeLists.txt already exists"
fi




