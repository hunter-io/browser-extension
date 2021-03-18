module.exports.tasks = {
  // Watch any modification to the package
  watch: {
    scripts: {
      files: ["src/**/*.js", "src/**/*.css", "src/**/*.scss", "src/**/*.html", "src/**/*.json", "src/**/*/*.coffee", "src/**/*/*.hbs"],
      tasks: ["coffee", "handlebars", "compass", "cssmin", "copy", "replace", "editmanifestforfirefox"],
      options: {
        spawn: false,
      }
    }
  }
}
