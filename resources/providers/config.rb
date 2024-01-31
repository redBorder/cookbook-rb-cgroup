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

    #Only executed if template has been modified
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

    #Executed on chef-client
    ruby_block 'Checkupdate_cgroups' do
      #Check if active memservices have cgroups assigned and fix all if any
      block do
        are_cgroups_assigned = `/usr/lib/redborder/scripts/rb_check_cgroups.rb`.strip
        unless are_cgroups_assigned
          `/usr/lib/redborder/bin/rb_configure_cgroups.sh`
        end
      end
    end
    
    Chef::Log.info('cookbook redborder-cgroup has been processed.')
  rescue => e
    Chef::Log.error(e.message)
  end
end
