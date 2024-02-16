# Cookbook:: rbcgroup
#
# Provider:: config
#
action :add do
  begin
    execute 'load_cgroups' do
      command '/usr/lib/redborder/bin/rb_configure_cgroups.sh'
      action :nothing
    end

    dnf_package "redborder-cgroups" do
      action :upgrade
    end

    template '/etc/cgroup.conf' do
      source 'cgroup.conf.erb'
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'rbcgroup'
      mode '600'
      retries 2
      notifies :run, 'execute[load_cgroups]', :delayed
    end

    Chef::Log.info('cookbook redborder-cgroup has been processed.')
  rescue => e
    Chef::Log.error(e.message)
  end
end
