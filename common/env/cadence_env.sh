#!/bin/bash

# ============================================================
# Cadence tool environment for ASIC flow
# ============================================================

# License server
export LM_LICENSE_FILE=27000@mimic.ece.jhu.edu

# Cadence install root
export CADENCE_INSTALL_DIR=/cadence/installs

# Xcelium
export PATH=${CADENCE_INSTALL_DIR}/XCELIUMMAIN_24.03.005/tools.lnx86/bin:${PATH}

# Digital implementation tools.
# This path is based on the previous working ENVARS file.
export PATH=${CADENCE_INSTALL_DIR}/DDI-ISR1_23.11.000/bin:${PATH}
