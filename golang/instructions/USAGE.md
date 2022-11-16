# Usage

doggos are in root directory change there before upload
## put doggos
```bash
cd ../../.images
curl -v --data-binary "@doge.jpg" -H "filename: doge.jpg" -X POST https://wlrtgh6i4sszth7ajrp5f72gne0qcwgc.lambda-url.us-east-1.on.aws/
```

## put more doggos
```bash
cd ../../.images
curl -v --data-binary "@pun.jpg" -H "filename: pun.jpg" -X POST https://wlrtgh6i4sszth7ajrp5f72gne0qcwgc.lambda-url.us-east-1.on.aws/
```
## request gif processing

Delay is 100th of a second
```bash
curl -v -X POST \
    -H "Content-Type: application/json" \
    --data '{"images": ["doge.jpg", "pun.jpg"], "delays": [100,100], "output":"doggo.gif"}' \
    https://vbgbsh7ifepdennb2vyujyfzzq0pzbng.lambda-url.us-east-1.on.aws/
```

## get doggos
```bash
curl -v https://u6665nncjg7cfx33fzpi7aet3i0thxln.lambda-url.us-east-1.on.aws/doggo.gif -o doggo.gif
```
