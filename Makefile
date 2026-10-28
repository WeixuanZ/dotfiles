# Thin shim. Tasks live in mise.toml. `make`, `make link`, and `make help`
# keep working, but mise is the task runner.
MISE ?= mise

.PHONY: default help
default:
	@command -v $(MISE) >/dev/null 2>&1 || { \
	  echo "mise is required. Install it with: curl https://mise.run | sh"; \
	  exit 1; \
	}
	@$(MISE) run link

help:
	@$(MISE) tasks

%:
	@command -v $(MISE) >/dev/null 2>&1 || { \
	  echo "mise is required. Install it with: curl https://mise.run | sh"; \
	  exit 1; \
	}
	@$(MISE) run $@
