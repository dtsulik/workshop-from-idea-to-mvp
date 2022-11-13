# Usage

doggos are in root directory change there before upload
## put doggos
```bash
cd ..
curl -v --data-binary "@doge.jpg" -H "filename: doge.jpg" -X POST https://r23zoxuywxjlqpacdrkqn463xu0iaees.lambda-url.us-east-1.on.aws/
```

## put more doggos
```bash
cd ..
curl -v --data-binary "@pun.jpg" -H "filename: pun.jpg" -X POST https://r23zoxuywxjlqpacdrkqn463xu0iaees.lambda-url.us-east-1.on.aws/
```
## request gif processing

Delay is 100th of a second
```bash
curl -v -X POST \
    -H "Content-Type: application/json" \
    --data '{"images": ["doge.jpg", "pun.jpg"], "delays": [100,100], "output":"doggo.gif"}' \
    https://wzc3cn7kduvz34e6hh7ti3xvpa0kmdib.lambda-url.us-east-1.on.aws/
```

## get doggos
```bash
curl -v https://fvkn7bdvbny2bnzsakzbbwqxdy0anwln.lambda-url.us-east-1.on.aws/doggo.gif
```