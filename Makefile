# Copyright (c) 2021 Koen Vervloesem
# SPDX-License-Identifier: MIT

PROJECT_NAME=remarkable-calendar-creator

check: ## Check code
	@echo "Checking code..."
	bashate $(PROJECT_NAME).sh
	shellcheck $(PROJECT_NAME).sh
	yamllint .

help: ## Show this help message
	@echo "Supported targets:\n"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1:\3/p' \
	| column -t -s ':'

install: ## Install remarkable-calendar-creator on your reMarkable
	@echo "Installing $(PROJECT_NAME)..."
	install -D -m 755 $(PROJECT_NAME).sh /opt/bin/$(PROJECT_NAME)
	install -D -m 644 -t /opt/etc/$(PROJECT_NAME) $(PROJECT_NAME).env calendar
	install -D -m 644 /usr/share/remarkable/suspended.png /opt/etc/$(PROJECT_NAME)/suspended.png.backup
	install -D -m 644 -t /etc/systemd/system systemd/*
	systemctl daemon-reload
	systemctl start $(PROJECT_NAME).service
	systemctl enable $(PROJECT_NAME).timer

uninstall: ## Uninstall remarkable-calendar-creator on your reMarkable
	@echo "Uninstalling $(PROJECT_NAME)..."
	rm /opt/bin/$(PROJECT_NAME)
	install -D -m 644 /opt/etc/$(PROJECT_NAME)/suspended.png.backup /usr/share/remarkable/suspended.png
	systemctl disable --now remarkable-calendar-creator.timer
	rm /etc/systemd/system/remarkable-calendar-creator.*
	systemctl daemon-reload

.DEFAULT_GOAL := help
.PHONY: \
	check \
    help \
    install \
    uninstall
