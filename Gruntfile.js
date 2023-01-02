module.exports = function (grunt) {
  // Load the plugins
  grunt.loadNpmTasks("grunt-contrib-watch");
  grunt.loadNpmTasks("grunt-contrib-coffee");
  grunt.loadNpmTasks("grunt-contrib-compass");
  grunt.loadNpmTasks("grunt-contrib-cssmin");
  grunt.loadNpmTasks("grunt-contrib-copy");
  grunt.loadNpmTasks("grunt-text-replace");
  grunt.loadNpmTasks("grunt-contrib-handlebars");

  // Load the various task configuration files
  var configs = require("load-grunt-configs")(grunt);
  grunt.initConfig(configs);

  grunt.registerTask("editmanifestforfirefox", function() {
    var manifest = grunt.file.readJSON("./src/manifest.json");

    // On Firefox, with Manifest V3, we use "background" files and not service workers
    manifest.background.scripts =["js/lib/jquery.min.js", "js/shared.js", "js/background.js"]
    delete manifest.background.service_worker;

    // On Firefox, with Manifest V3, we have to sign the extension with our unique ID
    manifest.browser_specific_settings = { "gecko": { "id": "firefox@hunter.io" } };

    grunt.file.write("./build-firefox/manifest.json", JSON.stringify(manifest, null, 2));
    grunt.log.writeln("Manifest updated for Firefox");
  });

  // Default task
  grunt.registerTask("default", ["watch"]);
}
