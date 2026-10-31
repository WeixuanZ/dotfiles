# Thin shim: tasks live in mise.toml. `make <task>` runs `mise run <task>`.
MISE ?= mise

.PHONY: default help
default: link

help:
	@$(MISE) tasks

%:
	@command -v $(MISE) >/dev/null 2>&1 || { echo "mise is required: curl https://mise.run | sh"; exit 1; }
	@$(MISE) run $@
