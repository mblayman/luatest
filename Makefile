.PHONY: deps html

lr = luarocks --tree .luarocks

build:
	$(lr) make

coverage:
	rm -f lcov.info
	lua -lluacov bin/luatest

html:
	rm -rf html
	genhtml -o html lcov.info
