# dev-con
When coding, I like to have a base clean Linux system. I install docker and load a development container with all needed compilers/frameworks/etc. 

### Docker quickstart:
- Pull image
```bash
docker pull mrhappynice/dev-con
```
- Run:
```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -u "$(id -u):$(id -g)" \
  mrhappynice/dev-con:latest bash

```
- set script in /usr/local/bin:
  - ```sh
    cp run.sh /usr/local/bin/dev-con
    ```
- In your dev folder simply type ```dev-con``` to enter your dev environment. venv/node_modules saved in dev folder, exit when done.


### Build image:
---
- chmod the shell files:
  - ```sh
    chmod +x build.sh run.sh
    ```
- build the image:
  - ```sh
    ./build.sh
    ```
- run:
  - ```sh
    ./run.sh

    ```
