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

