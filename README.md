# Hunter's browser extension
Hunter's browser extension is an easy way to find email addresses from anywhere on the web, with just one click.

* [Chrome Web Store](https://chrome.google.com/webstore/detail/hunter/hgmhmanijnjhaffoampdlllchpolkdnj)
* [Add-on for Firefox](https://addons.mozilla.org/en-US/firefox/addon/hunterio/)

[Hunter's API](https://hunter.io/api) is used to fetch the data and users's account information.

## Generate the builds

The builds for Chrome and Firefox are automatically generated with Grunt. To install it globally, run:

```shell
npm install -g grunt-cli
```

To watch the changes and launch the builds, change to the project's root directory and run:

```shell
grunt
```

## Test the extension locally

On Chrome:

1. Go to the extensions page (chrome://extensions)
2. Click **Load unpacked extension...**
3. Select the folder `build-chrome`

On Firefox:

1. Go to the debugging page (about:debugging)
2. Click **Enable add-on debugging** if it's not checked yet
3. Click **Load Temporary Add-on**
4. Select a file inside `build-firefox`
