echo "----------------------- Mac OS Debug Build -----------------------"
rm -rf .bui* && rm -rf *.resolved && swift build 
echo "----------------------- Mac OS Release Build ---------------------"
swift build -c release 
echo "----------------------- Mac OS Debug Run -------------------------"
.build/debug/DecisionTreeDemo
echo "----------------------- Mac OS Release Run -----------------------"
.build/release/DecisionTreeDemo
rm -rf .bui* && rm -rf *.resolved && docker run -it -v $PWD:/home rockywei/swift:4.0 /bin/bash -c \
"cd /home && echo '----------------------- Linux Debug Build -----------------------' && \
swift build && echo '----------------------- Linux Release Build ---------------------' && \
swift build -c release && echo '----------------------- Linux Debug Run -------------------------' && \
.build/debug/DecisionTreeDemo && echo '----------------------- Linux Release Run -----------------------' && \
.build/release/DecisionTreeDemo"

