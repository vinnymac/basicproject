require("es6-promise").polyfill()

_          = require "underscore"
autoprefix = require "autoprefixer"
cssnano    = require "cssnano"
gulp       = require "gulp"
concat     = require "gulp-concat"
gutil      = require "gulp-util"
gwebpack   = require "gulp-webpack"
imagemin   = require "gulp-imagemin"
livereload = require "gulp-livereload"
newer      = require "gulp-newer"
postcss    = require "gulp-postcss"
rename     = require "gulp-rename"
sass       = require "gulp-sass"
uglify     = require "gulp-uglify"

named      = require "vinyl-named"
webpack    = require "webpack"


if gutil.env.production then process.env.NODE_ENV = "production"


paths =
    # I/O paths
    sassIncludePaths : [
        "./node_modules/bootstrap-sass/assets/stylesheets/"
    ]
    sassInput   : [
        "./app/styles/app.sass"
    ]
    cssOutput   : "./dist/css/"

    fontInput   : "./node_modules/bootstrap-sass/assets/fonts/**/*.*"
    fontOutput  : "./dist/fonts/"

    imageInput  : [
        "./app/img/**/*.*"
    ]
    imageOutput : "./dist/img/"

    appInput    : [
        "./app/scripts/app.coffee"
    ]
    jsInput    :
        "global-deps.js" : [
            "./node_modules/raven-js/dist/raven.js"
        ]
    jsOutputDir : "./dist/js/"

    # Watch paths
    images : [
        "./app/img/**/*.*"
    ]
    scripts : [
        "./app/scripts/**/*.coffee"
    ]
    styles : [
        "./app/styles/**/*.sass"
        "./app/styles/**/*.scss"
        "./node_modules/bootstrap-sass/assets/stylesheets/**/*.scss"
    ]


webpackConfig =
    target: "web"
    watch: true
    debug: !gutil.env.production
    plugins: [
        new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/)
    ]
    resolve:
        extensions: ["", ".js", ".cjsx", ".coffee"]
        moduleDirectories: ["node_modules"]
    module:
        loaders: [
            {
                test    : /\.coffee$/
                loaders : ["coffee", "cjsx"]
            }
            {
                test    : /\.json$/
                loaders : ["json"]
            }
        ]
        postLoaders: [
            {
                test   : /\.js$/
                loader : "transform?envify"
            }
        ]


gulp.task "fonts", ->
    gulp.src paths.fontInput
        .pipe newer paths.fontOutput
        .pipe gulp.dest paths.fontOutput
        .pipe livereload()


gulp.task "images", ->
    gulp.src paths.imageInput
        .pipe newer paths.imageOutput
        .pipe imagemin()
        .pipe gulp.dest paths.imageOutput
        .pipe livereload()


gulp.task "scripts", ->
    for output, inputs of paths.jsInput
        gulp.src inputs
            .pipe concat output
            .pipe uglify()
            .pipe gulp.dest paths.jsOutputDir

    if gutil.env.production
        webpackConfig = _({}).extend(webpackConfig, { watch: false })

    gulp.src paths.appInput
        .pipe named()
        .pipe gwebpack webpackConfig
        .pipe if gutil.env.production then uglify() else gutil.noop()
        .pipe gulp.dest paths.jsOutputDir
        .pipe livereload()


gulp.task "styles", ->
    sassOptions =
        errLogToConsole : true
        includePaths    : paths.sassIncludePaths
        indentedSyntax  : true
        sourceComments  : "normal"

    postCssOptions = [
        autoprefix(browsers: [
            "last 3 versions"
            "> 1%"
            "ie 8"
        ])
        cssnano()
    ]

    gulp.src paths.sassInput
        .pipe sass sassOptions
        .pipe concat "app.css"
        .on "error", (e) -> gutil.log "Autoprefixing Error: ", e.message, e
        .pipe if gutil.env.production then postcss(postCssOptions) else gutil.noop()
        .pipe gulp.dest paths.cssOutput
        .pipe livereload()


gulp.task "watch", ->
    if not gutil.env.production
        gulp.watch paths.images, ["images"]
        gulp.watch paths.styles, ["styles"]

        livereload.listen()
        gulp.watch("./templates/**/*.html").on "change", livereload.changed


gulp.task "default", ["watch", "fonts", "images", "scripts", "styles"]
