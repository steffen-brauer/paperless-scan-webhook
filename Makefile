APP_NAME=pgnx-scan-webhook
APP_DIR=$(CURDIR)/src
PYTHON_BIN=/usr/bin/python3
SERVICE_FILE=/etc/systemd/system/${APP_NAME}.service
VENV_DIR=${APP_DIR}/venv
LOG_FILE=/var/log/${APP_NAME}.log
LOGROTATE_CONF=/etc/logrotate.d/${APP_NAME}

.PHONY: install venv dependencies service logrotate enable start

install: venv dependencies service logrotate enable start

echo "✅ Installation complete! The service is running."
echo "➡️  Logs are located at: $(LOG_FILE)"
echo "➡️  Log rotation is set to daily, with a 7-day retention."
echo "➡️  To check status: sudo systemctl status $(APP_NAME)"
echo "➡️  To view logs: sudo journalctl -u $(APP_NAME) --follow"

venv:
	@echo "➡️  Creating virtual environment..."
	$(PYTHON_BIN) -m venv $(VENV_DIR)


dependencies:
	@echo "➡️  Installing dependencies..."
	@source $(VENV_DIR)/bin/activate && pip install --upgrade pip
	@if [ -f "$(APP_DIR)/requirements.txt" ]; then \
	    source $(VENV_DIR)/bin/activate && pip install -r $(APP_DIR)/requirements.txt; \
	else \
	    echo "❌ requirements.txt not found! Exiting..."; \
	    exit 1; \
	fi

service:
	@echo "➡️  Creating systemd service file..."
	sudo bash -c "cat > $(SERVICE_FILE)" << EOL
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=paperless
Group=paperless
WorkingDirectory=$(APP_DIR)
Environment="PATH=$(VENV_DIR)/bin"
ExecStart=$(VENV_DIR)/bin/gunicorn -w 4 -b 0.0.0.0:8000 app:app --access-logfile $(LOG_FILE)
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

logrotate:
	@echo "➡️  Setting up log rotation..."
	sudo bash -c "cat > $(LOGROTATE_CONF)" << EOL
$(LOG_FILE) {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 paperless paperless
    postrotate
        sudo systemctl reload $(APP_NAME) > /dev/null 2>&1 || true
    endscript
}
EOL
	sudo chmod 644 $(LOGROTATE_CONF)

enable:
	@echo "➡️  Enabling service..."
	sudo systemctl daemon-reload
	sudo systemctl enable $(APP_NAME)

start:
	@echo "➡️  Starting service..."
	sudo systemctl start $(APP_NAME)
