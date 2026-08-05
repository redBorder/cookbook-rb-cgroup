# Cookbook:: rbcgroup
# Provider:: config

action :add do
  # Main systemd root slice
  systemd_unit 'redborder.slice' do
    content('Slice' => { 'Description' => 'redBorder Core Slice' })
    action [:create, :enable]
  end

  memory_services = node['redborder']['memory_services'] || {}
  systemdservices_map = node['redborder']['systemdservices'] || {}
  active_units = []

  memory_services.each do |srv_key, data|
    mem_kb = data['memory'].to_i
    next if mem_kb <= 0 # 0 value is valid for memoryHigh meaning the memory high is not defined. Is not a reason to stop the service creation if we want to start adding other attributes

    # Start Memory overriding:
    # Map service keys to actual systemd unit names (e.g., chef-server -> opscode-erchef)
    units = Array(systemdservices_map[srv_key] || srv_key) # Good
    units.each do |unit_name|
      active_units << unit_name

      directory "/etc/systemd/system/#{unit_name}.service.d" do # Directory creation per service (as cgroups config mandates)
        mode '0755'
        recursive true
      end

      systemd_unit "#{unit_name}.service.d/10-cgroups.conf" do # Basic file creation per service (as cgroups config mandates)
        # We are only defining MemoryHigh and Max, where we can define more an can already be in data. I think we should map even if we are not using yet.
        # The architecture of memory_services, forces use to only manage memory. So cpu is exiled for here.
        # I seems we are doing a mapping that should already exists in the node attributes, so the node should use the keys defined by us, not creating an extra map.
        # Idk if this affects to something else, but at least we should allow every cgroup/memory attribute with the same.
        # Latter in the attributes, be can redirect to cgroupsv2 documentation what is each attribute
        content( 
          'Service' => {
            'Slice' => "redborder-#{unit_name.delete('-')}.slice",  # This is ok
            'MemoryHigh' => "#{data['memory'].to_i}K",
            'MemoryMax' => (data['max_limit'].to_i > 0) ? "#{data['max_limit']}K" : nil,
          }.compact
        )
        action :create
        verify false
        triggers_reload true # Single daemon-reload
      end
    end
  end

  # Prune obsolete drop-ins for inactive services at converge time
  ruby_block 'prune_obsolete_cgroup_overrides' do
    block do
      Dir.glob('/etc/systemd/system/*.service.d/10-cgroups.conf').each do |path|
        unit_name = ::File.basename(::File.dirname(path)).chomp('.service.d') # Cool way to retrieve the *
        next if active_units.include?(unit_name)

        Chef::Log.info("rbcgroup: Pruning obsolete drop-in override for '#{unit_name}'")
        ::File.delete(path) if ::File.exist?(path)
        system('systemctl daemon-reload') # Is necessary to restart on each service? And why not using notifies run instead? 
      end
    end
    action :run
  end
end
