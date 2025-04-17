# Usage

## Swig usage

Add it main CMakeLists.txt
```cmake
add_subdirectory(swig)
```

Change it swig/python/interface.i
```sh
%{
#include "my_class/my_class.h"
%}
%include "my_class/my_class.h"
```

Change it  swig/CMakeLists.txt
```cmake
set(LIBS_FOR_SWIG set_it)
```

## Coverage usage
Add it main CMakeLists.txt
```cmake
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage")
```

## Protobuf usage
1. Change structs/structs.proto
2. Paste it
```cmake
find_package(Protobuf REQUIRED)
include_directories(${Protobuf_INCLUDE_DIRS} "structs")
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS "structs/structs.proto")
add_executable(my_app main.cpp ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(my_app PRIVATE ${Protobuf_LIBRARIES})
```
3. Test it
Create server in `struct` folder
```sh
g++ \
  $(pkg-config --cflags protobuf grpc++) \
  -std=c++17 \
  -I. \
  structs_server_example.cc \
  structs.pb.cc \
  structs.grpc.pb.cc \
  -o structs_server \
  $(pkg-config --libs protobuf grpc++)
```
Create client in `struct` folder
```sh
g++ \
  $(pkg-config --cflags protobuf grpc++) \
  -std=c++17 \
  -I. \
  structs_client_example.cc \
  structs.pb.cc \
  structs.grpc.pb.cc \
  -o structs_client \
  $(pkg-config --libs protobuf grpc++)
```