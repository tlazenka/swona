.PHONY: test
test:
	swift test
	
.PHONY: format
format:
	mint run nicklockwood/SwiftFormat@0.46.2 . 

.PHONY: test-docker
test-docker:
	docker-compose run --rm tests

.PHONY: format-docker
format-docker:
	docker-compose run --rm format
