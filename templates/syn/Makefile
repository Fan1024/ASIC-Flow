.RECIPEPREFIX := >
.ONESHELL:
SHELL := /bin/bash
.SHELLFLAGS := -lc

ENV_SCRIPT := $(ASIC_FLOW_HOME)/common/env/cadence_env.sh

# ------------------------------------------------------------
# Shared shell fragments
# ------------------------------------------------------------
define check_environment
if [[ -z "$(ASIC_FLOW_HOME)" ]]; then
  echo "ERROR: ASIC_FLOW_HOME is not set."
  exit 1
fi
if [[ ! -f "$(ENV_SCRIPT)" ]]; then
  echo "ERROR: Cadence environment script does not exist: $(ENV_SCRIPT)"
  exit 1
fi
endef

define make_run_dir
mkdir -p runs
run_name="$(RUN)"
if [[ -z "$$run_name" ]]; then
  last=$$(find runs -maxdepth 1 -type d -name 'run_*' 2>/dev/null \
    | sed 's#.*/run_##' \
    | sort -n \
    | tail -1)
  if [[ -z "$$last" ]]; then
    last=0
  fi
  next=$$((10#$$last + 1))
  run_name=$$(printf "run_%03d" $$next)
fi
run_dir="runs/$$run_name"
if [[ -e "$$run_dir" ]]; then
  echo "ERROR: $$run_dir already exists."
  echo "Use another RUN name or delete it manually."
  exit 1
fi
mkdir -p "$$run_dir/logs"
rm -f latest
ln -s "$$run_dir" latest
endef

# ------------------------------------------------------------
# User targets
# ------------------------------------------------------------
help:
>@echo "Targets:"
>@echo "  make check           Read HDL, elaborate, and check constraints"
>@echo "  make syn             Run batch synthesis"
>@echo "  make syn_gui         Load the design in the Genus GUI"
>@echo "  make gui             Open an empty Genus GUI"
>@echo "  make list            List synthesis runs"
>@echo "  make prune [RUN=...] Remove intermediate database files"
>@echo "  make clean           Remove all generated runs"
>@echo "  make show-config     Show flow environment paths"

show-config:
>@echo "ASIC_FLOW_HOME = $(ASIC_FLOW_HOME)"
>@echo "ENV_SCRIPT     = $(ENV_SCRIPT)"

check:
>set -e -o pipefail
>$(check_environment)
>$(make_run_dir)
>echo "INFO: Checking HDL and elaboration in $$run_dir"
>source "$(ENV_SCRIPT)"
>cd "$$run_dir"
>which genus
>genus -f ../../scripts/run_genus_check.tcl \
>  | tee logs/genus_check_console.log
>echo "INFO: HDL check saved to ../../$$run_dir"
>echo "INFO: latest -> $$run_dir"

syn:
>set -e -o pipefail
>$(check_environment)
>$(make_run_dir)
>echo "INFO: Running synthesis in $$run_dir"
>source "$(ENV_SCRIPT)"
>cd "$$run_dir"
>which genus
>genus -f ../../scripts/run_genus.tcl \
>  | tee logs/genus_console.log
>echo "INFO: Synthesis run saved to ../../$$run_dir"
>echo "INFO: latest -> $$run_dir"

syn_gui:
>set -e -o pipefail
>$(check_environment)
>$(make_run_dir)
>echo "INFO: Opening Genus GUI in $$run_dir"
>source "$(ENV_SCRIPT)"
>cd "$$run_dir"
>which genus
>genus -gui -f ../../scripts/run_genus_gui.tcl \
>  | tee logs/genus_gui_console.log

gui:
>set -e -o pipefail
>$(check_environment)
>$(make_run_dir)
>echo "INFO: Opening empty Genus GUI in $$run_dir"
>source "$(ENV_SCRIPT)"
>cd "$$run_dir"
>which genus
>genus -gui | tee logs/genus_gui_console.log

list:
>find runs -maxdepth 1 -mindepth 1 -type d -name 'run_*' \
>  | sort || true
>if [[ -L latest ]]; then
>  echo "latest -> $$(readlink latest)"
>fi

prune:
>set -e
>run_dir="runs/$(RUN)"
>if [[ -z "$(RUN)" ]]; then
>  if [[ -L latest ]]; then
>    run_dir=$$(readlink latest)
>  else
>    echo "ERROR: No RUN specified and no latest symlink found."
>    echo "Usage: make prune RUN=run_001"
>    exit 1
>  fi
>fi
>if [[ ! -d "$$run_dir" ]]; then
>  echo "ERROR: $$run_dir does not exist."
>  exit 1
>fi
>rm -rf "$$run_dir/dbs" "$$run_dir/work"
>rm -f "$$run_dir/genus.cmd" "$$run_dir/genus.log" \
>  "$$run_dir"/*.cmd "$$run_dir"/*.log
>echo "INFO: Pruned intermediate files in $$run_dir"
>echo "INFO: Kept logs/, reports/, outputs/, results/, and fv/"

clean:
>rm -rf runs latest
>rm -rf logs reports outputs results dbs work fv
>rm -f genus.log genus.cmd *.log *.cmd
>echo "INFO: Removed all generated synthesis runs and top-level temporary files"

.PHONY: help show-config check syn syn_gui gui list prune clean
