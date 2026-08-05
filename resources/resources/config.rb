# Cookbook:: rbcgroup
# Resource:: config

unified_mode true

actions :add
default_action :add

property :check_cgroups, [true, false], default: true
