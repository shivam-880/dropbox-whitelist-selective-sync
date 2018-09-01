# docker-dropbox-whitelist-selective-sync
Docker Image for whitelisting based selective sync for Dropbox

## Build Docker Image
```
$ docker build -t codingkapoor/dropbox https://github.com/codingkapoor/docker-dropbox-whitelist-selective-sync.git
```

## Create Dropbox Whitelist
Create a file named `.dropbox-whitelist` under dropbox directory on your host machine with a list of relative paths of files and directories that you wish to whitelist. Make sure these paths don't end with '/'.
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

## Run Docker Container
```
$ docker run -d --name=dropbox --volume=path-to-your-dropbox-directory:/dbox/Dropbox codingkapoor/dropbox
```
