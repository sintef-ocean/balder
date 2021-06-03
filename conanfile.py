from conans import ConanFile, CMake, tools
import os


class BalderConan(ConanFile):
    name = "balder"
    license = "GPLv3"
    url = "https://github.com/sintef-ocean/balder"
    author = "SINTEF Ocean"
    homepage = "https://sintef-ocean.github.io/balder"
    description = \
        "Balder is a decision support application for purse seining"
    topics = ("Qt", "QML", "DDS", "OpenSplice", "sinspekto", "Decision support")
    exports = "version.txt, LICENSE"
    settings = "os", "compiler", "build_type", "arch"
    generators = (
      "virtualrunenv",
      "virtualenv",
      "cmake",
      "cmake_paths",
      "cmake_find_package",
      "qt"
    )
    options = {
      "fPIC": [True, False],
      "with_install": [True, False],
      "with_doc": [True, False],
      "with_console": [True, False],
      "with_CICD": [True, False]
    }
    default_options = (
      "fPIC=True",
      "with_install=False",
      "with_doc=False",
      "with_console=False",
      "with_CICD=False"
    )
    requires = (
      "opensplice-ce/[>=6.9]@sintef/stable",
      "qt/5.15.2@bincrafters/stable",
      "sinspekto/0.4.0@sintef/stable"
    )
    build_subfolder = "build_subfolder"
    _cmake = None

    def requirements(self):
        pass

    def build_requirements(self):

        # Internal Continuous deployment helper scripts
        if self.options.with_CICD:
            self.build_requires("kluster-scripts/[>=0.2.0]@kluster/stable")

        if self.settings.os == "Android":
            self.output.warn("Android")
            self.build_requires("android-cmdline-tools/[>=6858069]@joakimono/testing")

    def configure(self):

        if self.settings.os != "Android":
            self.options["qt"].qttools = True

        self.options["qt"].shared = True
        self.options["qt"].with_mysql = False
        self.options["qt"].qtquickcontrols2 = True
        self.options["qt"].qtquick3d = True  # This is not needed
        self.options["qt"].qtcharts = True
        self.options["libpng"].shared = False  # Why?

        if self.settings.os != 'Windows':
            self.options["qt"].with_vulkan = True
        if self.settings.os == "Android":
            self.options["qt"].qtandroidextras = True

            if self.settings.arch == 'x86_64':
                # QTBUG-86785
                self.options["qt"].config = "-no-avx -no-avx2 -no-avx512"
            self.options["qt"].opengl = "es2"
            self.options["*"].with_glib = False

            self.options["android-cmdline-tools"].extra_packages = \
                "system-images;android-28;google_apis;x86_64,platforms;android-28,\
system-images;android-29;google_apis;x86_64,platforms;android-29,build-tools;28.0.3"

    def export_sources(self):

        self.copy("*", src="cmake", dst="cmake")
        self.copy("*", src="data", dst="data")
        self.copy("*", src="docs", dst="docs")
        self.copy("*", src="include", dst="include")
        self.copy("*", src="src", dst="src")
        self.copy("*", src="test_package", dst="test_package")
        self.copy("*", src="tools", dst="tools")
        self.copy("CMakeLists.txt")
        self.copy("version.txt")
        self.copy("LICENSE")
        self.copy("README.org")

    def set_version(self):
        self.version = tools.load(os.path.join(self.recipe_folder, "version.txt")).strip()

    def _configure_cmake(self):
        if self._cmake is None:
            self._cmake = CMake(self)
            self._cmake.definitions["WITH_CONSOLE"] = self.options.with_console
            self._cmake.definitions["WITH_DOC"] = self.options.with_doc

            if self.settings.os != "Windows":
                self._cmake.definitions["CMAKE_POSITION_INDEPENDENT_CODE"] = self.options.fPIC
            if self.settings.os == "Android":
                self._cmake.definitions["CMAKE_FIND_ROOT_PATH_MODE_PACKAGE"] = "BOTH"
                self._cmake.definitions["WITH_INSTALL"] = self.options.with_install

            self._cmake.configure()
        return self._cmake

    def build(self):
        cmake = self._configure_cmake()
        cmake.build()

        if self.options.with_doc:
            cmake.build(target='doc')

    def package(self):

        if self.settings.os != 'Android':
            cmake = self._configure_cmake()
            if self.settings.os == 'Linux' and self.settings.arch == 'x86_64':
                cmake.build(target='appimage')
            cmake.build(target='package_it')

        # This does not like multiple build folders in source folder.
        self.copy("*.apk", dst=".", keep_path=False)
        self.copy("{}*.AppImage".format(self.name), dst=".", keep_path=False)
        self.copy("{}*.tar.gz".format(self.name), dst=".", keep_path=False)
        self.copy("{}*.exe".format(self.name), dst=".", keep_path=False)
        self.copy("{}*.deb".format(self.name), dst=".", keep_path=False)

    def imports(self):
        self.copy("*", "licenses", "licenses", folder=True)
