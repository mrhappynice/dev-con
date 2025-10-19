# dev-con
When coding, I like to have a base clean Linux system. I install docker and load a development container with all needed compilers/frameworks/etc. 

---
- build the image
- set script in /usr/local/bin
- chmod the shell files:
  - ```sh
    chmod +x build.sh run.sh
    ```
- in dev folder run 'dev-con':
  - ```sh
    cp run.sh /usr/local/bin/dev-con
    ```
- In your dev folder simply type dev-con to enter your dev environment. save environment in the dev folder, exit when done.
