module.exports.tasks = {
  // Compile coffee
  coffee: {
    background_load: {
      options: { bare: true },
      src: "src/background.coffee",
      dest: "build-chrome/background.js"
    },
    background: {
      options: { bare: true, join: true },
      src: "src/background/*.coffee",
      dest: "build-chrome/js/background.js"
    },
    browser_action: {
      options: { bare: true },
      src: "src/browser_action/js/*.coffee",
      dest: "build-chrome/js/browser_action.js"
    },
    shared: {
      options: { bare: true, join: true },
      src: "src/shared/js/*.coffee",
      dest: "build-chrome/js/shared.js"
    },
    hunter_content_script: {
      options: { bare: true },
      src: "src/content_script/js/hunter-*.coffee",
      dest: "build-chrome/js/hunter_content_script.js"
    },
    websites_content_script: {
      options: { bare: true },
      src: "src/content_script/js/websites-*.coffee",
      dest: "build-chrome/js/websites_content_script.js"
    },
    source_popup: {
      src: "src/source_popup/js/source-popup.coffee",
      dest: "build-chrome/js/source_popup.js"
    }
  },

  // Process the Handlebars template
  handlebars: {
    compile: {
      options: {
        namespace: "JST"
      },
      files: {
        "build-chrome/js/templates.js": ["src/**/*.hbs"]
      }
    }
  },

  // SASS compilation
  compass: {
    browser_action: {
      options: {
        sourcemap: false,
        noLineComments: true,
        outputStyle: "compact",
        sassDir: "src/browser_action/css",
        cssDir: "build-chrome/css"
      }
    },

    websites_content_script: {
      options: {
        sourcemap: false,
        noLineComments: true,
        outputStyle: "compact",
        sassDir: "src/content_script/css",
        cssDir: "build-chrome/css"
      }
    },

    source_popup: {
      options: {
        sourcemap: false,
        noLineComments: true,
        outputStyle: "compact",
        sassDir: "src/source_popup/css",
        cssDir: "build-chrome/css"
      }
    }
  },

  // Copy the libraries already in CSS
  cssmin: {
    shared: {
      src: "src/shared/css/*.css",
      dest: "build-chrome/css/shared.min.css"
    }
  },

  // Copy other files (HTML, libraries, images and fonts)
  copy: {
    browser_action: {
      src: "src/browser_action/popup.html",
      dest: "build-chrome/html/browser_popup.html"
    },
    source_popup: {
      src: "src/source_popup/popup.html",
      dest: "build-chrome/html/source_popup.html"
    },
    images: {
      expand: true,
      cwd: "src/shared/img/",
      src: ["**"],
      dest: "build-chrome/img/"
    },
    fonts: {
      expand: true,
      cwd: "src/shared/fonts/",
      src: ["**"],
      dest: "build-chrome/fonts/",
      options: {
        processContentExclude: ["*.{ttf,woff,woff2}"]
      }
    },
    js_libs: {
      expand: true,
      cwd: "src/shared/js/lib",
      src: ["**"],
      dest: "build-chrome/js/lib"
    },
    css_libs: {
      expand: true,
      cwd: "src/shared/css/lib",
      src: ["**"],
      dest: "build-chrome/css/lib"
    },
    manifest: {
      src: "src/manifest.json",
      dest: "build-chrome/manifest.json"
    }
  },

  replace: {
    // This prevents an error to be displayed in Chrome console because the
    // source map doesn't exist. For the Firefox add-on, we don't do any
    // modification because Mozilla required to use unaltered library files.
    source_map_removal: {
      src: ["build-chrome/js/lib/purify.min.js"],
      overwrite: true,
      replacements: [{
        from: "//# sourceMappingURL=purify.min.js.map",
        to: ""
      }]
    }
  }
}
