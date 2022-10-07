module.exports.tasks = {
  // Copy the build for Chrome before making the adaptations
  copy: {
    build_edge: {
      expand: true,
      cwd: "build-chrome/",
      src: ["**"],
      dest: "build-edge/"
    }
  },

  // Do all the replacements to adapt from Chrome to Edge
  replace: {
    tracking_parameters_edge: {
      src: ["build-edge/**/*.js", "build-edge/**/*.html"],
      overwrite: true,
      replacements: [{
        from: "utm_source=chrome_extension",
        to: "utm_source=edge_addon"
      },
      {
        from: "utm_medium=chrome_extension",
        to: "utm_medium=edge_addon"
      },
      {
        from: "from=chrome_extension",
        to: "from=edge_addon"
      }]
    },

    website_welcome_url_edge: {
      src: ["build-edge/**/*.js", "build-edge/**/*.html"],
      overwrite: true,
      replacements: [{
        from: "/chrome/welcome",
        to: "/edge/welcome"
      }]
    },

    website_uninstall_url_edge: {
      src: ["build-edge/**/*.js", "build-edge/**/*.html"],
      overwrite: true,
      replacements: [{
        from: "/chrome/uninstall",
        to: "/edge/uninstall"
      }]
    },

    origin_header_edge: {
      src: ["build-edge/**/*.js"],
      overwrite: true,
      replacements: [{
        from: "\"Email-Hunter-Origin\": \"chrome_extension\"",
        to: "\"Email-Hunter-Origin\": \"edge_addon\"",
      }]
    },

    store_link_edge: {
      src: ["build-edge/html/browser_popup.html"],
      overwrite: true,
      replacements: [{
        from: "https://chrome.google.com/webstore/detail/email-hunter/hgmhmanijnjhaffoampdlllchpolkdnj/reviews",
        to: "https://microsoftedge.microsoft.com/addons/detail/hunter-email-finder-ext/dmgcgojogkfomifjfeeafajhmgilkofk"
      }]
    }
  }
}
