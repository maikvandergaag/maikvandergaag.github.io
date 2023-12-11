#Cheat Sheet

## Build Jeckyll

```Shell
bundle exec jekyll serve
```

## Force Passphrase in WSL terminal windows to be able to sign commit
```Shell
export GPG_TTY=$(tty)
echo "test" | gpg --clearsign
```

## Time in WSL

```Shell
date
```

## Sync clock in WSL
Sometimes the clock is out of sync with Windows in WSL with the below command you can sync it again.
```Shell
sudo hwclock -s
```