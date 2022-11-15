# Usage

doggos are in root directory change there before upload
## put doggos
```bash
cd ../../.images
curl -v --data-binary "@doge.jpg" -H "filename: doge.jpg" -X POST https://aru6ekjosfyokozlh6v46fy7gi0azdxx.lambda-url.us-east-1.on.aws/
```

## put more doggos
```bash
cd ../../.images
curl -v --data-binary "@pun.jpg" -H "filename: pun.jpg" -X POST https://aru6ekjosfyokozlh6v46fy7gi0azdxx.lambda-url.us-east-1.on.aws/
```
## request gif processing

Delay is 100th of a second
```bash
curl -v -X POST \
    -H "Content-Type: application/json" \
    --data '{"images": ["doge.jpg", "pun.jpg"], "delays": [100,100], "output":"doggo.gif"}' \
    https://dnaiz3es5ifqbpqyv6ankkdj6m0pnrdd.lambda-url.us-east-1.on.aws/
```

## get doggos
```bash
curl -v https://ytrrfcdftipes5jf26og6zsqjy0kndpi.lambda-url.us-east-1.on.aws/doggo.gif -o doggo.gif
```
