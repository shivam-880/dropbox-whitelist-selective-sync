# dropbox-whitelist-selective-sync
Whitelisting based selective sync for Dropbox

This are basically two ways to setup whitelisting based selective sync in dropbox on your host machine:

## Daemon Service
If you already 

## Docker Container
Setting up as a docker container would mean setting up both the dropbox and whitelisting together. This is a preferred appraoch since if whitelisting exits for any reason, so would container resulting in dropbox sync coming to a halt too i.e., none of the non-whitelisted data would be downloaded from the dropbox server saving both space and bandwidth.

**Build Docker Image**

```
$ docker build -t codingkapoor/dropbox https://github.com/codingkapoor/docker-dropbox-whitelist-selective-sync.git
```

**Create Dropbox Whitelist**

Create a file named `.dropbox-whitelist` under `$HOME/dropbox-whitelist` directory on your host machine with a list of paths of files and directories that you wish to whitelist relative to the `$DROPBOX_SYNC_DIR`. Make sure these paths don't end with '/'.
```
$ find $DROPBOX_SYNC_DIR \( ! -regex '.*/\..*' \) | awk '{if(NR>1)print}' | cut -c $(expr $(echo $DROPBOX_SYNC_DIR | wc -c) + 1)-
study material
study material/1 b.txt
study material/1a.txt
study material/xyz
study material/xyz/nginx.txt
study material/xyz/java collections
study material/xyz/java collections/books.txt
study material/xyz/java collections/notes.txt

$ cd $DROPBOX_SYNC_DIR
$ cat .dropbox-whitelist
study material/1a.txt
study material/xyz
```

**Run Docker Container**

```
$ docker run -d --name=dropbox --restart=always --volume=$DROPBOX_SYNC_DIR:/dbox/Dropbox --volume=$HOME/dropbox-whitelist:/root/dropbox-whitelist codingkapoor/dropbox
```

**Link Dropbox Account**

Check the logs of the container to get a URL to link your Dropbox account.

```
docker logs -f dropbox
```

Copy and paste similar link from container logs in a browser to register your dropbox account to the dropbox instance running inside your container.

