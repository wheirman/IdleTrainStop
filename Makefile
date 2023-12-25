FILES=$(wildcard *.lua) info.json $(wildcard graphics/*) $(wildcard locale/*/*.cfg)
PATHS=$(patsubst %,IdleTrainStop/%,$(FILES))
VERSION=$(shell cat info.json | grep '"version":' | cut -d\" -f4)

zip:
	cd .. && zip -r IdleTrainStop_$(VERSION).zip $(PATHS)
