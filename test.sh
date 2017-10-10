echo "----------------------- Mac OS Debug Test -----------------------"
rm -rf .bui* && rm -rf *.resolved && swift test 
echo "----------------------- Mac OS Release Build ---------------------"
swift build -c release 
rm -rf .bui* && rm -rf *.resolved && docker run -it -v $PWD:/home rockywei/swift:4.0 /bin/bash -c \
"cd /home && echo '----------------------- Linux Debug Test -----------------------' && \
swift test && echo '----------------------- Linux Release Build ---------------------' && \
swift build -c release"

