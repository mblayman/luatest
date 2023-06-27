.PHONY: deps html

lr = luarocks --tree .luarocks

deps:
	$(lr) make

html:
	rm -rf html
	genhtml -o html lcov.info
