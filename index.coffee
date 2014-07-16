module.exports = ->
  # snuff out the standard motd
  @then @execute, "test -f /etc/motd && sudo rm /etc/motd; exit 0"
  # hack to block auto-rebuild
  @then @execute, "mkdir -p /etc/motd", sudo: true

  @default openssh: server: print_motd: 'no'
  @default openssh: server: print_last_log: 'no'

  @then @execute, "sed -i 's/^session    optional   pam_motd\.so/#session    optional   pam_motd.so/' /etc/pam.d/login", sudo: true

  # build the new dynamic motd
  @then @template, [__dirname, 'templates', 'default', "motd"],
    to: "/usr/local/bin/dynmotd"
    sudo: true
    owner: "root"
    group: "root"
    mode: "0755"

  @then @execute, "touch /etc/motd-maint", sudo: true

  # all bash shell users will see it
  line = "/usr/local/bin/dynmotd"
  @unless "grep -q '#{line}' /etc/profile", =>
    @then @execute, "echo '#{line}' | sudo tee -a /etc/profile"

  # enable color prompts
  line2 = "export color_prompt=yes"
  @unless "grep -q '#{line2}' /etc/profile", =>
    @then @execute, "echo '#{line2}' | sudo tee -a /etc/profile"
