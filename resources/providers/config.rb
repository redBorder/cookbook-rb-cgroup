# Cookbook:: rbcgroup
# Provider:: config

action :add do
  systemd_unit 'redborder.slice' do
    content(
      'Slice' => {
        'Description' => 'redBorder Core Slice',
      }
    )
    action [:create, :enable]
  end

  memory_services = node['redborder']['memory_services'] || {}
  systemdservices_map = node['redborder']['systemdservices'] || {}
  active_units = []

  memory_services.each do |srv_key, data|
    mem_kb = data['memory'].to_i
    next if mem_kb <= 0

    # Map service keys to actual systemd unit names (e.g., chef-server -> opscode-erchef)
    units = Array(systemdservices_map[srv_key] || srv_key)

    units.each do |unit_name|
      active_units << unit_name

      directory "/etc/systemd/system/#{unit_name}.service.d" do
        mode '0755'
        recursive true
      end

      service unit_name do
        action :nothing
      end

      systemd_unit "#{unit_name}.service.d/10-cgroups.conf" do
        content(
          'Service' => {
            'Slice' => "redborder-#{unit_name.delete('-')}.slice",
            'MemoryHigh' => "#{mem_kb}K",
            'MemoryMax' => (data['max_limit'].to_i > 0) ? "#{data['max_limit']}K" : nil,
          }.compact
        )
        action :create
        verify false
        triggers_reload true
      end
    end
  end

  # Remove obsolete drop-ins for inactive services
  Dir.glob('/etc/systemd/system/*.service.d/10-cgroups.conf').each do |path|
    unit_name = ::File.basename(::File.dirname(path)).chomp('.service.d')
    next if active_units.include?(unit_name)

    systemd_unit "#{unit_name}.service.d/10-cgroups.conf" do
      action :delete
      verify false
      triggers_reload true
    end
  end
end
