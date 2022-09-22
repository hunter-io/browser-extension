# Hunter's browser extension
Hunter's browser extension is an easy way to find email addresses from anywhere on the web, with just one click.

* [Chrome Web Store](https://chrome.google.com/webstore/detail/hunter/hgmhmanijnjhaffoampdlllchpolkdnj)
* [Add-on for Edge](https://microsoftedge.microsoft.com/addons/detail/hunter-email-finder-ext/dmgcgojogkfomifjfeeafajhmgilkofk)
* [Add-on for Firefox](https://addons.mozilla.org/en-US/firefox/addon/hunterio/)

[Hunter's API](https://hunter.io/api) is used to fetch the data and users' accounts information.

## Generate the builds

The builds are automatically generated with Grunt for each browser. To install it globally, run:

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

On Edge:

1. Go to the extensions page (edge://extensions/)
2. Click **Load unpacked**
3. Select the folder `build-edge`

On Firefox:

1. Go to the debugging page (about:debugging)
2. Go to the tab **This Firefox**
3. Click **Load Temporary Add-on...**
4. Select a file inside `build-firefox`
