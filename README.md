# dropbox-whitelist-selective-sync
Whitelisting based selective sync for Dropbox. 

This are basically two ways to setup whitelisting based selective sync in dropbox on your host machine:

## Daemon Service
If you already have a dropbox instance running on your machine, you can run whitelisting scheme as a daemon service. However, if for any reason whitelisting exits, dropbox would continue to download all the non-whitelisted data.

**Download This Repository**

```
git clone https://github.com/codingkapoor/dropbox-whitelist-selective-sync.git
cd dropbox-whitelist-selective-sync
```

**Create Whitelist**

```
mkdir -p $HOME/dropbox-whitelist
cat > $HOME/dropbox-whitelist
```

**Copy Whitelisting Script**

```
cp ./dropbox-whitelist-selective-sync.sh $HOME/dropbox-whitelist
```

**Copy systemd Unit File**

But before you could copy this systemd unit file to its destination location, you would need to certain changes to it relevant to your host machine. Whitelisting script should only be executed with the same user the dropbox daemon instance is running as because otherwise it won't be able to invoke dropbox APIs and you may stumble upon *Dropbox isn't running!* issue. You can run the whitelisting daemon with the same user as dropbox instance by updating the systemd unit file with appropriate user and group values.

```
User=<same-user-dropbox-daemon-was-ran-with>
Group=<same-user-dropbox-daemon-was-ran-with>
```

Also, you would need to provide dropbox sync location on your machine. If it contains spaces, quote the string.
```
ExecStart=/bin/bash /home/shivam/dropbox-whitelist/dropbox-whitelist-selective-sync.sh <dropbox-sync-location>
```

Now you can copy the file.
```
cp ./dropbox-whitelist-selective-sync.service /etc/systemd/system
```

**Run As Daemon**

```
systemctl start dropbox-whitelist-selective-sync.service
```

**To Follow Logs**

```
journald -f -u dropbox-whitelist-selective-sync -e
tail -f $HOME/dropbox-whitelist/log/dropbox-whitelist.log
```

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

