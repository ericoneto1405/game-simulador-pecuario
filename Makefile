SHELL := /bin/zsh

GODOT ?= ./.tools/Godot.app/Contents/MacOS/Godot
PORT ?= 8080
WEB_DIR := builds/web
PID_FILE := /tmp/game-simulador-pecuario-web.pid
SERVER_LOG := /tmp/game-simulador-pecuario-web.log
TEST_LOG := /tmp/game-simulador-pecuario-test.log
EXPORT_LOG := /tmp/game-simulador-pecuario-export.log

.PHONY: help import test test-server web check serve stop free-port restart status

help:
	@echo "Comandos disponíveis:"
	@echo "  make import   Importa os recursos visuais do Godot"
	@echo "  make test     Executa os testes automáticos"
	@echo "  make test-server Valida o servidor de horário"
	@echo "  make web      Gera a versão Web"
	@echo "  make check    Executa os testes e gera a versão Web"
	@echo "  make serve    Gera e inicia o servidor em http://localhost:$(PORT)"
	@echo "  make free-port Encerra o processo que estiver usando a porta $(PORT)"
	@echo "  make restart  Reinicia o servidor Web"
	@echo "  make stop     Encerra o servidor Web"
	@echo "  make status   Mostra o estado do servidor"

import:
	@$(GODOT) --headless --log-file "$(EXPORT_LOG)" --path . --import

test: import
	@$(GODOT) --headless --log-file "$(TEST_LOG)" --path . --script res://tests/smoke_test.gd

test-server:
	@python3 -m unittest discover -s tests -p 'test_time_server.py'

web: import
	@$(GODOT) --headless --log-file "$(EXPORT_LOG)" --path . --export-release Web "$(WEB_DIR)/index.html"
	@echo "Versão Web gerada em $(WEB_DIR)."

check: test test-server web

serve: web
	@if [ -f "$(PID_FILE)" ] && kill -0 "$$(cat "$(PID_FILE)")" 2>/dev/null; then \
		echo "Servidor já está ativo em http://localhost:$(PORT)"; \
	elif lsof -nP -iTCP:$(PORT) -sTCP:LISTEN >/dev/null 2>&1; then \
		echo "A porta $(PORT) já está sendo usada por outro processo."; \
		echo "Encerre o servidor anterior ou execute: make serve PORT=8081"; \
		exit 1; \
	else \
		nohup python3 tools/time_server.py --port "$(PORT)" --directory "$(WEB_DIR)" >"$(SERVER_LOG)" 2>&1 & \
		server_pid=$$!; \
		echo $$server_pid >"$(PID_FILE)"; \
		echo "Servidor iniciado em http://localhost:$(PORT)"; \
	fi

stop:
	@if [ -f "$(PID_FILE)" ]; then \
		server_pid="$$(cat "$(PID_FILE)")"; \
		if kill -0 "$$server_pid" 2>/dev/null; then \
			kill "$$server_pid"; \
			echo "Servidor encerrado."; \
		else \
			echo "O servidor registrado já estava encerrado."; \
		fi; \
		rm -f "$(PID_FILE)"; \
	else \
		echo "Nenhum servidor iniciado pelo Makefile está ativo."; \
	fi

free-port:
	@port_pids="$$(lsof -tiTCP:$(PORT) -sTCP:LISTEN 2>/dev/null)"; \
	if [ -n "$$port_pids" ]; then \
		echo "Encerrando processo da porta $(PORT): $$port_pids"; \
		kill $$port_pids 2>/dev/null || true; \
		attempt=0; \
		while lsof -tiTCP:$(PORT) -sTCP:LISTEN >/dev/null 2>&1 && [ "$$attempt" -lt 10 ]; do \
			sleep 0.1; \
			attempt=$$((attempt + 1)); \
		done; \
		remaining_pids="$$(lsof -tiTCP:$(PORT) -sTCP:LISTEN 2>/dev/null)"; \
		if [ -n "$$remaining_pids" ]; then \
			echo "Forçando encerramento: $$remaining_pids"; \
			kill -KILL $$remaining_pids; \
		fi; \
	else \
		echo "A porta $(PORT) já está livre."; \
	fi

restart:
	@$(MAKE) --no-print-directory stop
	@$(MAKE) --no-print-directory free-port PORT=$(PORT)
	@$(MAKE) --no-print-directory serve PORT=$(PORT)

status:
	@if [ -f "$(PID_FILE)" ] && kill -0 "$$(cat "$(PID_FILE)")" 2>/dev/null; then \
		echo "Servidor ativo em http://localhost:$(PORT)"; \
	else \
		echo "Servidor inativo."; \
	fi
