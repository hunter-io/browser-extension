module.exports.tasks = {
  // Copy the build for Chrome before making the adaptations
  copy: {
    build: {
      expand: true,
      cwd: 'build-chrome/',
      src: ['**'],
      dest: 'build-firefox/'
    }
  },

  // Do all the replacements to adapt from Chrome to Firefox
  replace: {
    browser_api: {
      src: ['build-firefox/**/*.js'],
      overwrite: true,
      replacements: [{
        from: 'chrome.storage.sync',
        to: 'browser.storage.local'
      },
      {
        from: 'chrome.runtime',
        to: 'browser.runtime'
      },
      {
        from: 'chrome.extension.sendMessage',
        to: 'browser.runtime.sendMessage'
      },
      {
        from: 'chrome.extension.onMessage.addListener',
        to: 'browser.runtime.onMessage.addListener'
      },
      {
        from: 'chrome.extension.getURL',
        to: 'browser.extension.getURL'
      },
      {
        from: 'chrome.browserAction.setIcon',
        to: 'browser.browserAction.setIcon'
      },
      {
        from: 'chrome.tabs',
        to: 'browser.tabs'
      },
      {
        from: 'chrome.omnibox',
        to: 'browser.omnibox'
      },
      {
        from: 'chrome.contextMenus',
        to: 'browser.contextMenus'
      }]
    },

    utm_parameters: {
      src: ['build-firefox/**/*.js', 'build-firefox/**/*.html'],
      overwrite: true,
      replacements: [{
        from: 'utm_source=chrome_extension',
        to: 'utm_source=firefox_extension'
      }]
    },

    website_welcome_url: {
      src: ['build-firefox/**/*.js', 'build-firefox/**/*.html'],
      overwrite: true,
      replacements: [{
        from: '/chrome/welcome',
        to: '/firefox/welcome'
      }]
    },

    website_uninstall_url: {
      src: ['build-firefox/**/*.js', 'build-firefox/**/*.html'],
      overwrite: true,
      replacements: [{
        from: '/chrome/uninstall',
        to: '/firefox/uninstall'
      }]
    },

    origin_header: {
      src: ['build-firefox/**/*.js'],
      overwrite: true,
      replacements: [{
        from: '\'Email-Hunter-Origin\': \'chrome_extension\'',
        to: '\'Email-Hunter-Origin\': \'firefox_extension\'',
      }]
    },

    store_link: {
      src: ['build-firefox/html/browser_popup.html'],
      overwrite: true,
      replacements: [{
        from: 'https://chrome.google.com/webstore/detail/email-hunter/hgmhmanijnjhaffoampdlllchpolkdnj/reviews',
        to: 'https://addons.mozilla.org/firefox/addon/hunterio/reviews/add'
      }]
    },

    fonts_path_firefox: {
      src: ['build-firefox/**/*.css'],
      overwrite: true,
      replacements: [{
        from: 'chrome-extension://__MSG_@@extension_id__/',
        to: '../'
      }]
    },

    images_path_firefox: {
      src: ['build-firefox/**/*.js'],
      overwrite: true,
      replacements: [{
        from: 'getURL("shared/img/',
        to: 'getURL("img/'
      }]
    }
  },

  // Add the application ID in the manifest.json
  editmanifestforfirefox: {}
}
