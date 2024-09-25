# Cookbook:: rbcgroup
#
# Provider:: config
#
require 'English'
action :add do
  begin
    execute 'load_cgroups' do
      command '/usr/lib/redborder/bin/rb_configure_cgroups.sh'
      action :nothing
    end

    dnf_package 'redborder-cgroups' do
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

    # Executed on chef-client
    ruby_block 'Checkupdate_cgroups' do
      # Check if active memservices have cgroups assigned and fix all if any
      block do
        # Run the check script and capture the exit status
        system('/usr/lib/redborder/scripts/rb_check_cgroups.rb')
        exit_status = $CHILD_STATUS.exitstatus

        # Check if the exit status is 1; if true, run the configuration script
        if exit_status == 1
          system('/usr/lib/redborder/bin/rb_configure_cgroups.sh')
        end
      end
    end

    Chef::Log.info('cookbook redborder-cgroup has been processed.')
  rescue => e
    Chef::Log.error(e.message)
  end
end
