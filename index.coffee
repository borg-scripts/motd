module.exports = ->
  # snuff out the standard motd
  @then @execute "test -f /etc/motd && sudo rm /etc/motd; exit 0"
  # hack to block auto-rebuild
  @then @execute "mkdir -p /etc/motd", sudo: true

  @default openssh: server:
    PrintMotd: 'no'
    PrintLastLog: 'no'

  @then @execute "sed -i 's/^session    optional   pam_motd\.so/#session    optional   pam_motd.so/' /etc/pam.d/login", sudo: true

  # build the new dynamic motd
  @then @template [__dirname, 'templates', 'default', "motd"],
    to: "/usr/local/bin/dynmotd"
    sudo: true
    owner: "root"
    group: "root"
    mode: "0755"

  @then @execute "touch /etc/motd-maint", sudo: true

  @then @template "/usr/local/etc/dynmotd-art.txt",
    content: @server.motd.banner
    owner: 'root'
    group: 'root'
    mode: '0644'
    sudo: true

  # all bash shell users will see it
  line = "/usr/local/bin/dynmotd"
  @then @execute "grep -q '#{line}' /etc/profile", test: ({code}) =>
    @then @execute "echo '#{line}' | sudo tee -a /etc/profile"

  # enable color prompts
  line2 = "export color_prompt=yes"
  @then @execute "grep -q '#{line2}' /etc/profile", test: ({code}) =>
    @then @execute "echo '#{line2}' | sudo tee -a /etc/profile"
