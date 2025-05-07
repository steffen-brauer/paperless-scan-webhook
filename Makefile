SHELL := /bin/bash
APP_NAME=pgnx-scan-webhook
APP_DIR=$(CURDIR)
PYTHON_BIN=/usr/bin/python3
SERVICE_FILE=/etc/systemd/system/${APP_NAME}.service
VENV_DIR=${APP_DIR}/venv
LOG_FILE=/var/log/${APP_NAME}.log
LOGROTATE_CONF=/etc/logrotate.d/${APP_NAME}

.PHONY: install venv dependencies service logrotate enable start

install: venv dependencies service logrotate enable start

	echo "   ^|^e Installation complete! The service is running."
	echo "   ^~         ^o  Logs are located at: $(LOG_FILE)"
	echo "   ^~         ^o  Log rotation is set to daily, with a 7-day retention."
	echo "   ^~         ^o  To check status: sudo systemctl status $(APP_NAME)"
	echo "   ^~         ^o  To view logs: sudo journalctl -u $(APP_NAME) --follow"

venv:
	@echo "   ^~         ^o  Creating virtual environment..."
	$(PYTHON_BIN) -m venv $(VENV_DIR)

dependencies:
	@echo "   ^~         ^o  Installing dependencies..."
	@source $(VENV_DIR)/bin/activate && pip install --upgrade pip
	@if [ -f "$(APP_DIR)/requirements.txt" ]; then \
		source $(VENV_DIR)/bin/activate && pip install -r $(APP_DIR)/requirements.txt; \
	else \
		echo "   ^}^l requirements.txt not found! Exiting..."; \
		exit 1; \
	fi

service:
	@echo "   ^~         ^o  Creating systemd service file..."
	@echo "[Unit]" | sudo tee $(SERVICE_FILE) > /dev/null
	@echo "Description=Gunicorn instance to serve Flask app" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "After=network.target" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "[Service]" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "User=paperless" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "Group=paperless" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "WorkingDirectory=$(APP_DIR)/src" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "Environment=\"PATH=$(VENV_DIR)/bin\"" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "ExecStart=$(VENV_DIR)/bin/gunicorn -w $(shell nproc) -b 0.0.0.0:5050 app:app --access-logfi>
	@echo "Restart=always" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "RestartSec=5" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "[Install]" | sudo tee -a $(SERVICE_FILE) > /dev/null
	@echo "WantedBy=multi-user.target" | sudo tee -a $(SERVICE_FILE) > /dev/null

logrotate:
	@echo "   ^~         ^o  Setting up log rotation..."
	@echo "/var/log/$(APP_NAME).log {" | sudo tee $(LOGROTATE_CONF) > /dev/null
	@echo "    daily" | sudo tee -a $(LOGROTATE_CONF) > /dev/null
	@echo "    missingok" | sudo tee -a $(LOGROTATE_CONF) > /dev/null
	@echo "    rotate 7" | sudo tee -a $(LOGROTATE_CONF) > /dev/null
	@echo "    compress" | sudo tee -a $(LOGROTATE_CONF) > /dev/null
	@echo "    delaycompress" | sudo tee -a $(LOGROTATE_CONF) > /dev/null
	@echo "    notifempty" | sudo tee -a $(LOGROTATE_CONF) > /dev/null
	@echo "    create 640 paperless paperless" | sudo tee -a $(LOGROTATE_CONF) > /dev/null
	@echo "}" | sudo tee -a $(LOGROTATE_CONF) > /dev/null

enable:
	@echo "   ^~         ^o  Enabling service..."
	sudo systemctl daemon-reload
	sudo systemctl enable $(APP_NAME)

start:
	@echo "   ^~         ^o  Starting service..."
	sudo systemctl start $(APP_NAME)

stop:
	@echo "   ^~         ^o  Stopping service..."
	sudo systemctl stop $(APP_NAME)

status:
	sudo systemctl status $(APP_NAME)

journal:
	sudo journalctl -u flaskapp.service -f