# Hunter's browser extension
Hunter's browser extension is an easy way to find email addresses from anywhere on the web, with just one click.

* [Chrome Web Store](https://chrome.google.com/webstore/detail/hunter/hgmhmanijnjhaffoampdlllchpolkdnj)
* [Add-on for Firefox](https://addons.mozilla.org/en-US/firefox/addon/hunterio/)

## Generate the builds

The builds are made with Grunt. To install it globally, run:

```shell
npm install -g grunt-cli
```

To launch the build, change to the project's root directory and run:

```shell
grunt
```

## Test the extension locally

On Chrome:

1. Go to the extensions page (chrome://extensions)
2. Click **Load unpacked extension...**
3. Select the folder `build-chrome`.

On Firefox:

1. Go to the debugging page (about:debugging)
2. Click **Enable add-on debugging** if it's not checked yet
3. Click **Load Temporary Add-on**
4. Select a file inside `build-firefox`
