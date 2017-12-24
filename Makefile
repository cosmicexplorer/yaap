LITCOFFEE_SRC_DIR := src
LITCOFFEE_SRC := $(wildcard $(LITCOFFEE_SRC_DIR)/*.litcoffee)
JS_OBJ := $(patsubst %.litcoffee,%.js,$(LITCOFFEE_SRC))

TEST_DIR := test
TEST_SRC := $(wildcard $(TEST_DIR)/*.coffee)
TEST_JS_OBJ := $(patsubst %.coffee,%.js,$(TEST_SRC))

NPM_DIR := node_modules
NPM_BIN_DIR := $(NPM_DIR)/.bin
COFFEE_CC := $(NPM_BIN_DIR)/coffee
MOCHA_RUN := $(NPM_BIN_DIR)/mocha
NPM_BINS := $(COFFEE_CC) $(MOCHA_RUN)

.PHONY: all clean test

all: $(JS_OBJ)

clean:
	rm -f $(TEST_JS_OBJ)
	rm -f $(JS_OBJ)
	rm -rf $(NPM_DIR)

test: all $(TEST_JS_OBJ) $(MOCHA_RUN)
	$(MOCHA_RUN)

%.js: %.coffee $(COFFEE_CC)
	$(COFFEE_CC) -bc --no-header $<

%.js: %.litcoffee $(COFFEE_CC)
	$(COFFEE_CC) -bc --no-header $<

$(NPM_BINS):
	npm install
