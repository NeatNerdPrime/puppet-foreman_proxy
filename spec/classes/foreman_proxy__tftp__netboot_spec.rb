require 'spec_helper'

describe 'foreman_proxy::tftp::netboot' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      let :params do
        {:root => '/tftproot'}
      end

      it { is_expected.to compile.with_all_deps }

      it 'should create grub2 boot symlink' do
        should contain_file("/tftproot/grub2/boot").
          with_ensure('link').with_target("../boot")
      end

      if facts[:os]['family'] == 'Debian'
        it { is_expected.to contain_class('foreman_proxy::tftp::netboot').with_grub_installation_type('debian') }
        it { should contain_package('grub-common').with_ensure('installed') }
        it { should contain_package('grub-efi-amd64-bin').with_ensure('installed') }

        it 'should generate efi image from grub2 modules for Debian' do
          should contain_exec('build-grub2-efi-image').with_unless("/bin/grep -q regexp '/tftproot/grub2/grubx64.efi'")
          should contain_file("/tftproot/grub2/grubx64.efi")
            .with_mode('0644')
            .with_owner('root')
            .that_requires('Exec[build-grub2-efi-image]')
        end
        it { should contain_file("/tftproot/grub2/shimx64.efi").with_ensure('link') }
        it { should contain_file("/tftproot/grub2/shim.efi").with_ensure('link') }
      elsif facts[:os]['family'] == 'RedHat'
        it { is_expected.to contain_class('foreman_proxy::tftp::netboot').with_grub_installation_type('redhat') }
        it { should contain_package('grub2-efi-x64').with_ensure('installed') }
        it { should contain_package('grub2-efi-x64-modules').with_ensure('installed') }
        it { should contain_package('grub2-tools').with_ensure('installed') }
        it { should contain_package('shim-x64').with_ensure('installed') }

        case facts[:operatingsystem]
        when /^(RedHat|Scientific|OracleLinux)$/
          it { should contain_file("/tftproot/grub2/grubx64.efi").with_source('/boot/efi/EFI/redhat/grubx64.efi') }
          it { should contain_file("/tftproot/grub2/shimx64.efi").with_source('/boot/efi/EFI/redhat/shimx64.efi').with_owner('root').with_mode('0644') }
        when 'Fedora'
          it { should contain_file("/tftproot/grub2/grubx64.efi").with_source('/boot/efi/EFI/fedora/grubx64.efi') }
          it { should contain_file("/tftproot/grub2/shimx64.efi").with_source('/boot/efi/EFI/fedora/shimx64.efi').with_owner('root').with_mode('0644') }
        when 'CentOS'
          it { should contain_file("/tftproot/grub2/grubx64.efi").with_source('/boot/efi/EFI/centos/grubx64.efi') }
          it { should contain_file("/tftproot/grub2/shimx64.efi").with_source('/boot/efi/EFI/centos/shimx64.efi').with_owner('root').with_mode('0644') }
        when 'AlmaLinux'
          it { should contain_file("/tftproot/grub2/grubx64.efi").with_source('/boot/efi/EFI/almalinux/grubx64.efi') }
          it { should contain_file("/tftproot/grub2/shimx64.efi").with_source('/boot/efi/EFI/almalinux/shimx64.efi').with_owner('root').with_mode('0644') }
        end
        it { should contain_file("/tftproot/grub2/shim.efi").with_ensure('link') }
      else
        it { is_expected.to contain_class('foreman_proxy::tftp::netboot').with_grub_installation_type('none') }
        # TODO: check if a warning is emited
      end
    end
  end
end
