.PHONY: build app run clean

build:
	swift build

app:
	./scripts/build-app.sh release

run: app
	open build/Statify.app

clean:
	swift package clean
	rm -rf build
