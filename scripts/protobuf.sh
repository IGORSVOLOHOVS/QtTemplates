#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration ---
PROTO_DIR="../../structs" # Directory to store .proto files and generated code
PROTO_FILE="structs.proto"      # Name of the proto definition file
PROTO_PATH="${PROTO_DIR}/${PROTO_FILE}"

# --- Check for protoc ---
if ! command -v protoc &> /dev/null; then
    echo "Error: 'protoc' (Protobuf compiler) not found."
    echo "Please install Protocol Buffers development tools."
    echo "On Debian/Ubuntu: sudo apt-get install protobuf-compiler libprotobuf-dev"
    echo "On Fedora: sudo dnf install protobuf-compiler protobuf-devel"
    echo "On macOS (Homebrew): brew install protobuf"
    exit 1
fi
echo "Protobuf compiler (protoc) found."

# --- Check for gRPC C++ plugin ---
if ! command -v grpc_cpp_plugin &> /dev/null; then
    echo "Error: 'grpc_cpp_plugin' not found."
    echo "Please install gRPC development tools (which includes the plugin)."
    echo "On Debian/Ubuntu: sudo apt-get install libgrpc++-dev grpc_cpp_plugin"
    echo "On Fedora: sudo dnf install grpc-devel grpc-plugins"
    echo "On macOS (Homebrew): brew install grpc"
    echo "Alternatively, build from source: https://grpc.io/docs/languages/cpp/quickstart/"
    exit 1
fi
GRPC_PLUGIN_PATH=$(command -v grpc_cpp_plugin)
echo "gRPC C++ plugin found at: ${GRPC_PLUGIN_PATH}"


# --- Create directories ---
echo "Creating directory: ${PROTO_DIR}"
mkdir -p "${PROTO_DIR}"

# --- Create .proto file ---
if [ ! -f "${PROTO_PATH}" ]; then
    echo "Creating Protobuf definition file: ${PROTO_PATH}"
    # Removed the cc_generic_services option as it conflicts with modern gRPC C++ plugin
    cat <<EOL > "${PROTO_PATH}"
syntax = "proto3"; // Specify proto3 syntax

package tutorial; // Optional: Define a package to prevent name clashes

// Option for generating generic services, useful for gRPC
// option cc_generic_services = true; // <-- REMOVED/COMMENTED OUT THIS LINE

// Simple message definition for a Person
message Person {
  string name = 1;
  int32 id = 2;        // Unique ID number for this person.
  string email = 3;    // Optional

  enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
  }

  message PhoneNumber {
    string number = 1;
    PhoneType type = 2;
  }

  repeated PhoneNumber phones = 4; // A person can have multiple phone numbers
}

// Simple request message for the Greeter service
message HelloRequest {
  string name = 1;
}

// Simple response message for the Greeter service
message HelloReply {
  string message = 1;
}

// Definition of a simple gRPC service
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  // Sends a greeting using a Person object
  rpc GreetPerson (Person) returns (HelloReply) {}
}
EOL
    echo "Protobuf definition file created successfully."
else
    echo "Protobuf definition file already exists: ${PROTO_PATH}"
    # Optional: Add logic here if you want to *force* overwrite/update the existing file
    # echo "Warning: ${PROTO_PATH} already exists. Generation might use the existing file content."
    # echo "Consider removing the file or modifying the script to overwrite if you want to apply changes."
fi

# --- Generate C++ code (Protobuf + gRPC) ---
echo "Generating C++ Protobuf and gRPC code from ${PROTO_FILE} into ${PROTO_DIR}..."
# protoc --proto_path=<IMPORT_PATH> --cpp_out=<OUTPUT_DIR> --grpc_out=<OUTPUT_DIR> --plugin=protoc-gen-grpc=<PLUGIN_PATH> <PROTO_FILES>
# IMPORT_PATH is where protoc looks for imports (we use the dir containing the file)
# OUTPUT_DIR is where the generated C++ files (.pb.h, .pb.cc, .grpc.pb.h, .grpc.pb.cc) will be placed
protoc \
    --proto_path="${PROTO_DIR}" \
    --cpp_out="${PROTO_DIR}" \
    --grpc_out="${PROTO_DIR}" \
    --plugin=protoc-gen-grpc="${GRPC_PLUGIN_PATH}" \
    "${PROTO_PATH}"

echo "C++ Protobuf and gRPC code generated successfully:"
ls -l "${PROTO_DIR}"/*.pb.* "${PROTO_DIR}"/*.grpc.pb.* # List the generated files

echo ""
echo "Next steps:"
echo "1. Include '${PROTO_DIR}/structs.pb.h' and '${PROTO_DIR}/structs.grpc.pb.h' in your C++ project."
echo "2. Compile '${PROTO_DIR}/structs.pb.cc' and '${PROTO_DIR}/structs.grpc.pb.cc' along with your source code."
echo "3. Link against the Protocol Buffers library (e.g., -lprotobuf) AND the gRPC C++ libraries (e.g., -lgrpc++ -lgrpc --lpthread -ldl)."
echo "   You might need to add '${PROTO_DIR}' to your include paths."
echo "   Example CMake integration:"
echo "   find_package(Protobuf REQUIRED)"
echo "   find_package(gRPC REQUIRED)"
echo "   include_directories(\${Protobuf_INCLUDE_DIRS} \${gRPC_INCLUDE_DIRS} "structs")"
echo "   protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS "structs/structs.proto")"
echo "   protobuf_generate_grpc_cpp(GRPC_SRCS GRPC_HDRS "structs/structs.proto")"
echo "   # add_executable(my_app main.cpp \${PROTO_SRCS} \${PROTO_HDRS} \${GRPC_SRCS} \${GRPC_HDRS})"
echo "   # target_link_libraries(my_app PRIVATE \${Protobuf_LIBRARIES} \${gRPC_LIBRARIES})"


# Create Server example structs_server_example.cc
echo "Creating Server example structs_server_example.cc..."
if [ ! -f "${PROTO_DIR}/structs_server_example.cc" ]; then
    cat <<EOL > "${PROTO_DIR}/structs_server_example.cc"
/*
#include <iostream>
#include <memory>
#include <string>

#include <grpcpp/grpcpp.h> // Include grpcpp/grpcpp.h for newer gRPC versions
#include <grpcpp/server.h>
#include <grpcpp/server_builder.h>
#include <grpcpp/server_context.h>
#include <grpcpp/security/server_credentials.h>
#include "structs.grpc.pb.h"

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;
using tutorial::Greeter;
using tutorial::HelloReply;
using tutorial::HelloRequest;
using tutorial::Person; // Added Person for GreetPerson

// Implementation of the Greeter service
class GreeterServiceImpl final : public Greeter::Service {
    Status SayHello(ServerContext* context, const HelloRequest* request,
                    HelloReply* reply) override {
        std::string prefix("Hello ");
        reply->set_message(prefix + request->name());
        std::cout << "SayHello RPC called for: " << request->name() << std::endl;
        return Status::OK;
    }

    Status GreetPerson(ServerContext* context, const Person* request,
                       HelloReply* reply) override {
        std::string prefix("Greetings ");
        reply->set_message(prefix + request->name() + " (ID: " + std::to_string(request->id()) + ")");
        std::cout << "GreetPerson RPC called for: " << request->name() << std::endl;
        return Status::OK;
    }
};

void RunServer() {
    std::string server_address("0.0.0.0:50051");
    GreeterServiceImpl service;

    ServerBuilder builder;
    // Listen on the given address without any authentication mechanism.
    builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
    // Register "service" as the instance through which we'll communicate with
    // clients. In this case it corresponds to an *synchronous* service.
    builder.RegisterService(&service);
    // Finally assemble the server.
    std::unique_ptr<Server> server(builder.BuildAndStart());
    std::cout << "Server listening on " << server_address << std::endl;

    // Wait for the server to shutdown. Note that some other thread must be
    // responsible for shutting down the server for this call to ever return.
    server->Wait();
}

int main(int argc, char** argv) {
    RunServer();
    return 0;
}
*/
EOL
    echo "Server example structs_server_example.cc created successfully."
else
    echo "Server example structs_server_example.cc already exists: ${PROTO_DIR}/structs_server_example.cc"
fi

# Create Client example structs_client_example.cc
echo "Creating Client example structs_client_example.cc..."
if [ ! -f "${PROTO_DIR}/structs_client_example.cc" ]; then
    # Continuing the cat command from the previous input
    cat <<EOL > "${PROTO_DIR}/structs_client_example.cc"
/*
#include <iostream>
#include <memory>
#include <string>

#include <grpcpp/grpcpp.h>
#include "structs.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using tutorial::Greeter;
using tutorial::HelloReply;
using tutorial::HelloRequest;
using tutorial::Person; // Added Person for GreetPerson

class GreeterClient {
 public:
  GreeterClient(std::shared_ptr<Channel> channel)
      : stub_(Greeter::NewStub(channel)) {}

  // Assembles the client's payload, sends it and presents the response back
  // from the server.
  std::string SayHello(const std::string& user) {
    // Data we are sending to the server.
    HelloRequest request;
    request.set_name(user);

    // Container for the data we expect from the server.
    HelloReply reply;

    // Context for the client. It could be used to convey extra information to
    // the server and/or tweak RPC behaviors.
    ClientContext context;

    // The actual RPC.
    Status status = stub_->SayHello(&context, request, &reply);

    // Act upon its status.
    if (status.ok()) {
      return reply.message();
    } else {
      std::cerr << status.error_code() << ": " << status.error_message()
                << std::endl;
      return "RPC failed";
    }
  }

  std::string GreetPerson(const std::string& name, int id, const std::string& email) {
      Person request;
      request.set_name(name);
      request.set_id(id);
      if (!email.empty()) {
          request.set_email(email);
      }
      // Example of adding phone numbers
      auto* phone1 = request.add_phones();
      phone1->set_number("555-1234");
      phone1->set_type(tutorial::Person::MOBILE);

      HelloReply reply;
      ClientContext context;

      Status status = stub_->GreetPerson(&context, request, &reply);

      if (status.ok()) {
          return reply.message();
      } else {
          std::cerr << status.error_code() << ": " << status.error_message()
                    << std::endl;
          return "RPC failed";
      }
  }

 private:
  std::unique_ptr<Greeter::Stub> stub_;
};

int main(int argc, char** argv) {
  // Instantiate the client. It requires a channel, out of which the actual RPCs
  // are created. This channel models a connection to a endpoint (in this case,
  // localhost at port 50051). We indicate that the channel isn't authenticated
  // (use of InsecureChannelCredentials()).
  std::string target_str = "localhost:50051";
  // Allow overriding target address via command line argument
  if (argc > 1) {
      target_str = argv[1];
      std::cout << "Connecting to: " << target_str << std::endl;
  }

  GreeterClient greeter(grpc::CreateChannel(
      target_str, grpc::InsecureChannelCredentials()));

  // --- Call SayHello RPC ---
  std::string user("world");
  std::string reply = greeter.SayHello(user);
  std::cout << "Greeter received (SayHello): " << reply << std::endl;

  // --- Call GreetPerson RPC ---
  std::string person_reply = greeter.GreetPerson("Alice", 101, "alice@example.com");
  std::cout << "Greeter received (GreetPerson): " << person_reply << std::endl;

  return 0;
}
*/
EOL
    echo "Client example structs_client_example.cc created successfully."
else
    echo "Client example structs_client_example.cc already exists: ${PROTO_DIR}/structs_client_example.cc"
fi

echo ""
echo "Script finished."