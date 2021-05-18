# Copyright (c) 2021 Koen Vervloesem
# SPDX-License-Identifier: MIT

CREATOR_NAME=remarkable-calendar-creator
DOWNLOADER_NAME=remarkable-calendar-downloader
ICAL2PCAL=ical2pcal

check: ## Check code
	@echo "Checking code..."
	bashate remarkable-calendar-*.sh
	shellcheck remarkable-calendar-*.sh
	yamllint .

help: ## Show this help message
	@echo "Supported targets:\n"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1:\3/p' \
	| column -t -s ':'

install: ## Install remarkable-calendar-creator on your reMarkable
	@echo "Installing $(CREATOR_NAME)..."
	install -D -m 755 $(CREATOR_NAME).sh /opt/bin/$(CREATOR_NAME)
	install -D -m 755 $(DOWNLOADER_NAME).sh /opt/bin/$(DOWNLOADER_NAME)
	install -D -m 755 $(ICAL2PCAL).sh /opt/bin/$(ICAL2PCAL)
	install -D -m 644 -t /opt/etc/$(CREATOR_NAME) $(CREATOR_NAME).env.example calendar
	if [[ ! -f /opt/etc/$(CREATOR_NAME)/suspended.png.backup ]]; then \
		install -D -m 644 /usr/share/remarkable/suspended.png /opt/etc/$(CREATOR_NAME)/suspended.png.backup; \
	fi
	install -D -m 644 -t /etc/systemd/system systemd/*
	systemctl daemon-reload
	systemctl start $(CREATOR_NAME).service
	systemctl enable $(CREATOR_NAME).timer

uninstall: ## Uninstall remarkable-calendar-creator on your reMarkable
	@echo "Uninstalling $(CREATOR_NAME)..."
	rm /opt/bin/$(CREATOR_NAME) /opt/bin/$(DOWNLOADER_NAME) /opt/bin/$(ICAL2PCAL)
	install -D -m 644 /opt/etc/$(CREATOR_NAME)/suspended.png.backup /usr/share/remarkable/suspended.png
	systemctl disable --now remarkable-calendar-creator.timer
	rm /etc/systemd/system/remarkable-calendar-creator.*
	systemctl daemon-reload

.DEFAULT_GOAL := help
.PHONY: \
	check \
    help \
    install \
    uninstall
