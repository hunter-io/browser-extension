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

     manifest.applications = { "gecko": { "id": "firefox@hunter.io" } };
     delete manifest.externally_connectable;
     grunt.file.write("./build-firefox/manifest.json", JSON.stringify(manifest, null, 2));
     grunt.log.writeln("Manifest updated for Firefox");
  });

  // Default task
  grunt.registerTask("default", ["watch"]);
}
