.PHONY: deps

deps:
	luarocks --tree .luarocks install argparse
	luarocks --tree .luarocks install inspect
