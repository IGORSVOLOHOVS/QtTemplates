rm -rf coverage_report
lcov --capture --directory . --output-file coverage.info
sleep 2
lcov --remove coverage.info '/usr/*' '*/test/*' '*/third_party/*' '*/build/*' '*/lib/*' '*/include/*' '*/src/*' '*/tests/*' -o coverage.info
genhtml coverage.info --output-directory coverage_report
google-chrome coverage_report/index.html

# in global cmakelists.txt add
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage")
