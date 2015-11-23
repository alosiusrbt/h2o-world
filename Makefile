build: node_modules
	#node_modules/.bin/coffee tools/fetch-hexadata-tweets.coffee src/_generated/_tweets.html
	node_modules/.bin/coffee tools/fuse.coffee src build

run: node_modules
	node_modules/.bin/coffee tools/server.coffee build

# After 'make run' you can do this to get to the web site.
browser_on_mac:
	open http://localhost:8080

clean:
	rm -rf build

node_modules: package.json
	npm install

test:
	s3cmd sync --dry-run --delete-removed --acl-public --exclude-from s3.exclude build/ s3://h2oworld.h2o.ai/

push:
	s3cmd sync --delete-removed --acl-public --exclude-from s3.exclude build/ s3://h2oworld.h2o.ai/

.PHONY: build run clean test push tweets
