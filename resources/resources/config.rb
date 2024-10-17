unified_mode true

# Cookbook:: rbcgroup
# Resource:: config

actions :add
default_action :add

attribute :check_cgroups, kind_of: [TrueClass, FalseClass], default: true
