all: hooks

.PHONY: hooks

hooks:
	cd .git/hooks && ln -nsf ../../hooks/* ./
