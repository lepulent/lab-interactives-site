# See the README for installation instructions.

# Utilities
JS_COMPILER = ./node_modules/uglify-js/bin/uglifyjs
COFFEESCRIPT_COMPILER = ./node_modules/coffee-script/bin/coffee
MARKDOWN_COMPILER = bin/kramdown
# Turns out that just pointing Vows at a directory doesn't work, and its test matcher matches on
# the test's title, not its pathname. So we need to find everything in test/vows first.
VOWS = find test/vows -type f -name '*.js' -o -name '*.coffee' ! -name '.*' | xargs ./node_modules/.bin/vows --isolate --dot-matrix
MOCHA = find test/mocha -type f -name '*.js' -o -name '*.coffee' ! -name '.*' | xargs node_modules/.bin/mocha --reporter dot
EXAMPLES_LAB_DIR = ./examples/lab
SASS_COMPILER = bin/sass -I src --require ./src/helpers/sass/lab_fontface.rb
R_OPTIMIZER = ./node_modules/.bin/r.js
GENERATE_INTERACTIVE_INDEX = ruby src/helpers/process-interactives.rb

LAB_SRC_FILES := $(shell find src/lab -type f ! -name '.*' -print)
GRAPHER_SRC_FILES := $(shell find src/lab/grapher -type f ! -name '.*' -print)
IMPORT_EXPORT_SRC_FILES := $(shell find src/lab/import-export -type f ! -name '.*' -print)
ENERGY2D_SRC_FILES := $(shell find src/lab/energy2d -type f ! -name '.*' -print)
MD2D_SRC_FILES := $(shell find src/lab/md2d -type f ! -name '.*' -print)
SOLAR_SYSTEM_SRC_FILES := $(shell find src/lab/solar-system -type f ! -name '.*' -print)
SIGNAL_GENERATOR_SRC_FILES := $(shell find src/lab/signal-generator -type f ! -name '.*' -print)
SENSOR_SRC_FILES := $(shell find src/lab/sensor -type f ! -name '.*' -print)
COMMON_SRC_FILES := $(shell find src/lab/common -type f ! -name '.*' -print)
COMMON_SRC_FILES += src/lab/lab.version.js # files generated by script during build process,
COMMON_SRC_FILES += src/lab/lab.config.js  # so, cannot be listed using shell find.
FONT_FOLDERS := $(shell find vendor/fonts -mindepth 1 -maxdepth 1)

GLSL_TO_JS_CONVERTER := ./node-bin/glsl-to-js-converter
LAB_GLSL_FILES := $(shell find src/lab -name '*.glsl' -print)

COUCHDB_RUNNING := $(findstring couch,$(shell curl http://localhost:5984 2> /dev/null))

# targets

INTERACTIVE_FILES := $(shell find src/models src/interactives -name '*.json' -exec echo {} \; | sed s'/src\/\(.*\)/public\/\1/' )
vpath %.json src

HAML_FILES := $(shell find src -name '*.haml' -exec echo {} \; | sed s'/src\/\(.*\)\.haml/public\/\1/' )
vpath %.haml src

SASS_TOP_LEVEL_FILES := $(shell find src -name '*.sass' -maxdepth 1 -exec echo {} \; | sed s'/src\/\(.*\)\.sass/public\/\1.css/' )
vpath %.sass src

SASS_EXAMPLE_FILES := $(shell find src/examples -name '*.sass' -exec echo {} \; | sed s'/src\/\(.*\)\.sass/public\/\1.css/' )
vpath %.sass src/examples

SASS_DOC_FILES := $(shell find src/doc -name '*.sass' -exec echo {} \; | sed s'/src\/\(.*\)\.sass/public\/\1.css/' )
DOC_FILES := $(SASS_DOC_FILES)
vpath %.sass src/doc

DOC_FILES += $(shell find src/doc -name '*.html' -print | sed s'/src\/\(.*\)\.html/public\/\1.html/')
vpath %.html src/doc

DOC_FILES += $(shell find src/doc -name '*.css' -print | sed s'/src\/\(.*\)\.css/public\/\1.css/')
vpath %.css src/doc

SCSS_EXAMPLE_FILES := $(shell find src -type d -name 'sass' -prune -o -name '*.scss' -exec echo {} \; | grep -v bourbon | sed s'/src\/\(.*\)\.scss/public\/\1.css/' )
vpath %.scss src

COFFEESCRIPT_EXAMPLE_FILES := $(shell find src/examples -name '*.coffee' -exec echo {} \; | sed s'/src\/\(.*\)\.coffee/public\/\1.js/' )
vpath %.coffee src

MARKDOWN_EXAMPLE_FILES := $(shell find src -type d -name 'sass' -prune -o -name '*.md'  -maxdepth 1 -exec echo {} \; | grep -v vendor | sed s'/src\/\(.*\)\.md/public\/\1.html/' )
vpath %.md src

LAB_JS_FILES = \
	public/lab/lab.grapher.js \
	public/lab/lab.energy2d.js \
	public/lab/lab.md2d.js \
	public/lab/lab.import-export.js \
	public/lab/lab.solar-system.js \
	public/lab/lab.js

.PHONY: all
all: \
	vendor/d3/d3.js \
	node_modules \
	bin \
	public
	$(MAKE) src

.PHONY: everything
everything:
	$(MAKE) clean
	$(MAKE) all
	$(MAKE) jnlp-all

.PHONY: src
src: \
	$(MARKDOWN_EXAMPLE_FILES) \
	$(LAB_JS_FILES) \
	$(LAB_JS_FILES:.js=.min.js) \
	$(HAML_FILES) \
	$(SASS_TOP_LEVEL_FILES) \
	$(SASS_EXAMPLE_FILES) \
	$(DOC_FILES) \
	$(SCSS_EXAMPLE_FILES) \
	$(COFFEESCRIPT_EXAMPLE_FILES) \
	$(INTERACTIVE_FILES) \
	public/interactives.html \
	public/embeddable.html \
	public/browser-check.html \
	public/interactives.json \
	public/index.css \
	public/grapher.css \
	public/interactives.css \
	public/embeddable.css \
	public/application.js

.PHONY: jnlp-all
jnlp-all: clean-jnlp \
	public/jnlp
	script/build-and-deploy-jars.rb --maven-update

clean:
	ruby script/check-development-dependencies.rb
	bundle install --binstubs
	mkdir -p public
	# public dir cleanup.
	bash -O extglob -c 'rm -rf public/!(.git|jnlp)'
	# Remove auto-generated files.
	rm -f src/lab/lab.config.js
	rm -f src/lab/lab.version.js
	# Node modules.
	rm -rf node_modules
	-$(MAKE) submodule-update || $(MAKE) submodule-update-tags
	rm -f vendor/jquery/dist/jquery*.js
	rm -f vendor/jquery-ui/dist/jquery-ui*.js

vendor/d3:
	submodule-update

.PHONY: submodule-update
symbolic-links:
	cd public/examples; if [ ! -L interactives ]; then ln -s ../ interactives; fi

.PHONY: submodule-update
submodule-update:
	git submodule update --init --recursive

.PHONY: submodule-update-tags
submodule-update-tags:
	git submodule sync
	git submodule foreach --recursive 'git fetch --tags'
	git submodule update --init --recursive

clean-jnlp:
	rm -rf public/jnlp

node_modules: node_modules/d3 \
	node_modules/jsdom \
	node_modules/arrays
	npm install

node_modules/d3:
	npm install vendor/d3

node_modules/jsdom:
	npm install test/vendor/jsdom

node_modules/arrays:
	npm install src/modules/arrays

bin:
	bundle install --binstubs

public: \
	copy-resources-to-public \
	public/lab \
	public/vendor \
	public/resources \
	public/examples \
	public/doc \
	public/experiments \
	public/imports \
	public/jnlp

.PHONY: copy-resources-to-public
copy-resources-to-public:
	# copy everything (including symbolic links) except files that are used to generate
  # resources from src/ to public/
	rsync -aq --exclude='helpers/' --exclude='layouts/' --exclude='modules/' --exclude='sass/' --exclude='vendor/' --filter '+ */' --exclude='*.haml' --exclude='*.sass' --exclude='*.scss' --exclude='*.yaml' --exclude='*.coffee' --exclude='*.rb' --exclude='*.md' src/ public/

public/examples:
	mkdir -p public/examples

public/doc: \
	public/doc/interactives \
	public/doc/models

public/doc/interactives:
	mkdir -p public/doc/interactives

public/doc/models:
	mkdir -p public/doc/models

.PHONY: public/experiments
public/experiments:
	mkdir -p public/experiments

.PHONY: public/jnlp
public/jnlp:
	mkdir -p public/jnlp

# MML->JSON conversion uses MD2D models for validation and default values handling
# so it depends on appropriate sources.
.PHONY: public/imports
public/imports: \
	$(MD2D_SRC_FILES) \
	$(COMMON_SRC_FILES)
	mkdir -p public/imports
	rsync -aq imports/ public/imports/
	$(MAKE) convert-mml
	rsync -aq --exclude 'converted/***' --filter '+ */'  --prune-empty-dirs --exclude '*.mml' --exclude '*.cml' --exclude '.*' --exclude '/*' public/imports/legacy-mw-content/ public/imports/legacy-mw-content/converted/

.PHONY: convert-mml
convert-mml:
	./node-bin/convert-mml-files
	./node-bin/create-mml-html-index
	./src/helpers/md2d/post-batch-processor.rb

.PHONY: convert-all-mml
convert-all-mml:
	./node-bin/convert-mml-files -a
	./node-bin/create-mml-html-index
	./src/helpers/md2d/post-batch-processor.rb

public/resources:
	cp -R ./src/resources ./public/

public/vendor: \
	public/vendor/d3 \
	public/vendor/d3-plugins \
	public/vendor/jquery/jquery.min.js \
	public/vendor/jquery-ui/jquery-ui.min.js \
	public/vendor/jquery-ui-touch-punch/jquery.ui.touch-punch.min.js \
	public/vendor/jquery-selectBoxIt \
	public/vendor/tinysort/jquery.tinysort.js \
	public/vendor/jquery-context-menu \
	public/vendor/science.js \
	public/vendor/modernizr \
	public/vendor/sizzle \
	public/vendor/hijs \
	public/vendor/mathjax \
	public/vendor/fonts \
	public/vendor/codemirror \
	public/vendor/dsp.js \
	public/vendor/requirejs \
	public/vendor/text \
	public/vendor/domReady \
	public/favicon.ico

public/vendor/dsp.js:
	mkdir -p public/vendor/dsp.js
	cp vendor/dsp.js/dsp.js public/vendor/dsp.js
	cp vendor/dsp.js/LICENSE public/vendor/dsp.js/LICENSE
	cp vendor/dsp.js/README public/vendor/dsp.js/README

public/vendor/d3: vendor/d3
	mkdir -p public/vendor/d3
	cp vendor/d3/d3*.js public/vendor/d3
	cp vendor/d3/LICENSE public/vendor/d3/LICENSE
	cp vendor/d3/README.md public/vendor/d3/README.md

public/vendor/d3-plugins:
	mkdir -p public/vendor/d3-plugins/cie
	cp vendor/d3-plugins/LICENSE public/vendor/d3-plugins/LICENSE
	cp vendor/d3-plugins/README.md public/vendor/d3-plugins/README.md
	cp vendor/d3-plugins/cie/*.js public/vendor/d3-plugins/cie
	cp vendor/d3-plugins/cie/README.md public/vendor/d3-plugins/cie/README.md

public/vendor/jquery-ui-touch-punch/jquery.ui.touch-punch.min.js: \
	public/vendor/jquery-ui-touch-punch
	cp vendor/jquery-ui-touch-punch/jquery.ui.touch-punch.min.js public/vendor/jquery-ui-touch-punch

public/vendor/jquery-ui-touch-punch:
	mkdir -p public/vendor/jquery-ui-touch-punch

public/vendor/jquery-selectBoxIt:
	mkdir -p public/vendor/jquery-selectBoxIt
	cp vendor/jquery-selectBoxIt/src/javascripts/jquery.selectBoxIt.min.js public/vendor/jquery-selectBoxIt/jquery.selectBoxIt.min.js
	cp vendor/jquery-selectBoxIt/src/stylesheets/jquery.selectBoxIt.css public/vendor/jquery-selectBoxIt/jquery.selectBoxIt.css

public/vendor/jquery-context-menu:
	mkdir -p public/vendor/jquery-context-menu
	cp vendor/jquery-context-menu/src/jquery.contextMenu.js public/vendor/jquery-context-menu
	cp vendor/jquery-context-menu/src/jquery.contextMenu.css public/vendor/jquery-context-menu

public/vendor/jquery/jquery.min.js: \
	vendor/jquery/dist/jquery.min.js \
	public/vendor/jquery
	cp vendor/jquery/dist/jquery*.js public/vendor/jquery
	cp vendor/jquery/MIT-LICENSE.txt public/vendor/jquery
	cp vendor/jquery/README.md public/vendor/jquery

public/vendor/jquery:
	mkdir -p public/vendor/jquery

public/vendor/jquery-ui/jquery-ui.min.js: \
	vendor/jquery-ui/dist/jquery-ui.min.js \
	public/vendor/jquery-ui
	cp -r vendor/jquery-ui/dist/* public/vendor/jquery-ui
	cp -r vendor/jquery-ui/themes/base/images public/vendor/jquery-ui
	cp vendor/jquery-ui/MIT-LICENSE.txt public/vendor/jquery-ui

public/vendor/jquery-ui:
	mkdir -p public/vendor/jquery-ui

public/vendor/tinysort:
	mkdir -p public/vendor/tinysort

public/vendor/tinysort/jquery.tinysort.js: \
	public/vendor/tinysort
	cp -r vendor/tinysort/src/* public/vendor/tinysort
	cp vendor/tinysort/README.md public/vendor/tinysort

public/vendor/science.js:
	mkdir -p public/vendor/science.js
	cp vendor/science.js/science*.js public/vendor/science.js
	cp vendor/science.js/LICENSE public/vendor/science.js
	cp vendor/science.js/README.md public/vendor/science.js

public/vendor/modernizr:
	mkdir -p public/vendor/modernizr
	cp vendor/modernizr/modernizr.js public/vendor/modernizr
	cp vendor/modernizr/readme.md public/vendor/modernizr

public/vendor/sizzle:
	mkdir -p public/vendor/sizzle
	cp vendor/sizzle/sizzle.js public/vendor/sizzle
	cp vendor/sizzle/LICENSE public/vendor/sizzle
	cp vendor/sizzle/README public/vendor/sizzle

public/vendor/hijs:
	mkdir -p public/vendor/hijs
	cp vendor/hijs/hijs.js public/vendor/hijs
	cp vendor/hijs/LICENSE public/vendor/hijs
	cp vendor/hijs/README.md public/vendor/hijs

public/vendor/mathjax:
	mkdir -p public/vendor/mathjax
	cp vendor/mathjax/MathJax.js public/vendor/mathjax
	cp vendor/mathjax/LICENSE public/vendor/mathjax
	cp vendor/mathjax/README.md public/vendor/mathjax
	cp -R vendor/mathjax/jax public/vendor/mathjax
	cp -R vendor/mathjax/extensions public/vendor/mathjax
	cp -R vendor/mathjax/images public/vendor/mathjax
	cp -R vendor/mathjax/fonts public/vendor/mathjax
	cp -R vendor/mathjax/config public/vendor/mathjax

public/vendor/fonts: $(FONT_FOLDERS)
	mkdir -p public/vendor/fonts
	cp -R vendor/fonts public/vendor/
	rm -rf public/vendor/fonts/Font-Awesome/.git

public/vendor/requirejs:
	mkdir -p public/vendor/requirejs
	cp vendor/requirejs/require.js public/vendor/requirejs
	cp vendor/requirejs/LICENSE public/vendor/requirejs
	cp vendor/requirejs/README.md public/vendor/requirejs

public/vendor/text:
	mkdir -p public/vendor/text
	cp vendor/text/text.js public/vendor/text
	cp vendor/text/LICENSE public/vendor/text
	cp vendor/text/README.md public/vendor/text

public/vendor/domReady:
	mkdir -p public/vendor/domReady
	cp vendor/domReady/domReady.js public/vendor/domReady
	cp vendor/domReady/LICENSE public/vendor/domReady
	cp vendor/domReady/README.md public/vendor/domReady

public/vendor/codemirror:
	mkdir -p public/vendor/codemirror
	cp vendor/codemirror/LICENSE public/vendor/codemirror
	cp vendor/codemirror/README.md public/vendor/codemirror
	cp -R vendor/codemirror/lib public/vendor/codemirror
	cp -R vendor/codemirror/addon public/vendor/codemirror
	cp -R vendor/codemirror/mode public/vendor/codemirror
	cp -R vendor/codemirror/theme public/vendor/codemirror
	cp -R vendor/codemirror/keymap public/vendor/codemirror
	# remove codemirror modules excluded by incompatible licensing
	rm -rf public/vendor/codemirror/mode/go
	rm -rf public/vendor/codemirror/mode/rst
	rm -rf public/vendor/codemirror/mode/verilog

public/favicon.ico:
	cp -f src/favicon.ico public/favicon.ico

vendor/jquery/dist/jquery.min.js: vendor/jquery
	cd vendor/jquery; npm install; \
	 npm install grunt-cli; \
	 ./node_modules/grunt-cli/bin/grunt

vendor/jquery:
	git submodule update --init --recursive

vendor/jquery-ui/dist/jquery-ui.min.js: vendor/jquery-ui
	cd vendor/jquery-ui; npm install; ./node_modules/grunt/bin/grunt build

vendor/jquery-ui:
	git submodule update --init --recursive

public/lab:
	mkdir -p public/lab

public/lab/lab.js: \
	public/lab/lab.grapher.js \
	public/lab/lab.md2d.js \
	public/lab/lab.solar-system.js \
	$(SIGNAL_GENERATOR_SRC_FILES) \
	$(SENSOR_SRC_FILES) \
	src/lab/lab.version.js \
	src/lab/lab.config.js
	$(R_OPTIMIZER) -o src/lab/lab.build.js

src/lab/lab.version.js: script/generate-js-version.rb
	./script/generate-js-version.rb

src/lab/lab.config.js: \
	script/generate-js-config.rb \
	config/config.yml
	./script/generate-js-config.rb

public/lab/lab.energy2d.js: \
	$(ENERGY2D_SRC_FILES) \
	$(COMMON_SRC_FILES)
	$(R_OPTIMIZER) -o src/lab/energy2d/energy2d.build.js

public/lab/lab.grapher.js: \
	$(GRAPHER_SRC_FILES) \
	$(COMMON_SRC_FILES)
	$(R_OPTIMIZER) -o src/lab/grapher/grapher.build.js

public/lab/lab.import-export.js: \
	$(IMPORT_EXPORT_SRC_FILES) \
	$(COMMON_SRC_FILES)
	$(R_OPTIMIZER) -o src/lab/import-export/import-export.build.js

public/lab/lab.solar-system.js: \
	$(SOLAR_SYSTEM_SRC_FILES) \
	$(COMMON_SRC_FILES)
	$(R_OPTIMIZER) -o src/lab/solar-system/solar-system.build.js

public/lab/lab.md2d.js: \
	$(MD2D_SRC_FILES) \
	$(COMMON_SRC_FILES)
	$(R_OPTIMIZER) -o src/lab/md2d/md2d.build.js

public/lab/lab.mw-helpers.js: src/mw-helpers/*.coffee
	cat $^ | $(COFFEESCRIPT_COMPILER) --stdio --print > $@
	@chmod ug+w $@

src/experiments/netlogo-visual/models/data-export-modular.nls: \
	src/experiments/netlogo-modules/data-export-modular.nls
	cp src/experiments/netlogo-modules/data-export-modular.nls src/experiments/netlogo-visual/models/data-export-modular.nls

src/experiments/netlogo-is-exporter/models/data-export-modular.nls: \
	src/experiments/netlogo-modules/data-export-modular.nls
	cp src/experiments/netlogo-modules/data-export-modular.nls src/experiments/netlogo-is-exporter/models/data-export-modular.nls

test: test/layout.html \
	vendor/d3 \
	public \
	$(LAB_JS_FILES) \
	$(JS_FILES:.js=.min.js)
	@echo
	@echo 'Mocha tests ...'
	@$(MOCHA)
	@echo 'Vows tests ...'
	@$(VOWS)
	@echo

.PHONY: test-src
test-src: test/layout.html \
	$(LAB_JS_FILES) \
	$(JS_FILES:.js=.min.js)
	@echo 'Running Mocha tests ...'
	@$(MOCHA)
	@echo 'Running Vows tests ...'
	@$(VOWS)

# run vows test WITHOUT trying to build Lab JS first. Run 'make; make test-mocha' to build & test.
.PHONY: test-vows
test-vows:
	@echo 'Running Vows tests ...'
	@$(VOWS)

# run mocha test WITHOUT trying to build Lab JS first. Run 'make; make test-mocha' to build & test.
.PHONY: test-mocha
test-mocha:
	@echo 'Running Mocha tests ...'
	@$(MOCHA)

.PHONY: debug-mocha
debug-mocha:
	@echo 'Running Mocha tests in debug mode...'
	@$(MOCHA) --debug-brk

%.min.js: %.js
	@rm -f $@
ifndef LAB_DEVELOPMENT
	$(JS_COMPILER) < $< > $@
	@chmod ug+w $@
else
endif

test/%.html: test/%.html.haml
	haml $< $@

public/%.html: src/%.html.haml
	haml -r ./script/setup.rb $< $@

public/%.html: src/%.html
	cp $< $@

public/%.css: src/%.css
	cp $< $@

public/index.css:
	$(SASS_COMPILER) src/index.sass public/index.css

public/application.js:
	cp src/application.js public/application.js

public/embeddable-author.css:
	$(SASS_COMPILER) src/embeddable.sass public/embeddable-author.css

public/embeddable.css:
	$(SASS_COMPILER) src/embeddable.sass public/embeddable.css

public/grapher.css: src/grapher.sass \
	src/sass/lab/_colors.sass \
	src/sass/lab/_grapher.sass
	$(SASS_COMPILER) src/grapher.sass public/grapher.css

public/examples/%.css: %.sass
	$(SASS_COMPILER) $< $@

public/doc/%.css: %.sass
	$(SASS_COMPILER) $< $@

public/lab/%.css: %.sass
	$(SASS_COMPILER) $< $@

lab/%.css: %.sass
	$(SASS_COMPILER) $< $@

public/%.css: %.scss
	$(SASS_COMPILER) $< $@

public/%.css: %.sass
	@echo $($<)
	$(SASS_COMPILER) $< $@

public/%.js: %.coffee
	@rm -f $@
	$(COFFEESCRIPT_COMPILER) --compile --print $< > $@

public/%.html: %.md
	@rm -f $@
	$(MARKDOWN_COMPILER) $< --toc-levels 2..6 --template src/layouts/$*.html.erb > $@

public/interactives/%.json: src/interactives/%.json
	@cp $< $@

public/models/%.json: src/models/%.json
	@cp $< $@

public/interactives.json: $(INTERACTIVE_FILES)
	$(GENERATE_INTERACTIVE_INDEX)

.PHONY: h
h:
	@echo $(HAML_FILES)

.PHONY: se
se:
	@echo $(SASS_EXAMPLE_FILES)

.PHONY: sce
sce:
	@echo $(SCSS_EXAMPLE_FILES)

.PHONY: sd
sd:
	@echo $(DOC_FILES)

.PHONY: s1
sl:
	@echo $(SASS_LIBRARY_FILES)

.PHONY: c
c:
	@echo $(COFFEESCRIPT_EXAMPLE_FILES)

.PHONY: cm
cm:
	@echo $(COMMON_SRC_FILES)

.PHONY: m
m:
	@echo $(MARKDOWN_EXAMPLE_FILES)

.PHONY: md2
md2:
	@echo $(MD2D_SRC_FILES)

solar-system:
	@echo $(SOLAR_SYSTEM_SRC_FILES)

.PHONY: signal-generator
signal-generator:
	@echo $(SIGNAL_GENERATOR_SRC_FILES)

.PHONY: sensor
sensor:
	@echo $(SENSOR_SRC_FILES)

.PHONY: gr
gr:
	@echo $(GRAPHER_SRC_FILES)

.PHONY: int
int:
	@echo $(INTERACTIVE_FILES)

.PHONY: cdb
cdb:
	@echo $(COUCHDB_RUNNING)

.PHONY: sources
sources:
	@echo $(LAB_SRC_FILES)

.PHONY: cdb-status
cdb-status:
ifeq ($(COUCHDB_RUNNING),couch)
	@echo "couchdb running"
else
	@echo "couchdb not running"
endif