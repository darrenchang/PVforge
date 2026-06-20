1. Clone the repository and all the submodules
    ```bash
    git clone https://github.com/darrenchang/pxvirt.git; \
    git submodule update --init --recursive
    ``

2. Build all .deb packages
    ```bash
    ./build.sh 2>&1 | tee log.txt
    ```

