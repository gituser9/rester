from conan import ConanFile
from conan.tools.cmake import cmake_layout


class Recipe(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeDeps", "CMakeToolchain"
    default_options = {
        "*:fPIC": True,
        "grpc/*:csharp_plugin": False,
        "grpc/*:csharp_ext": False,
        "grpc/*:node_plugin": False,
        "grpc/*:objective_c_plugin": False,
        "grpc/*:php_plugin": False,
        "grpc/*:python_plugin": False,
        "grpc/*:ruby_plugin": False,
        "protobuf/*:debug_suffix": False,
    }


    def requirements(self):
        self.requires("grpc/1.67.1")
        self.requires("yaml-cpp/0.9.0")
        self.requires("brotli/1.2.0")


    def layout(self):
        cmake_layout(self)
