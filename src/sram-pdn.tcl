source $::env(SCRIPTS_DIR)/openroad/common/pdn_cfg.tcl
define_pdn_grid -macro -instances {ram.bank0 ram.bank1} -name sram -starts_with POWER -halo {1.0 1.0}
add_pdn_connect -grid sram -layers {Metal4 Metal3}
