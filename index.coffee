module.exports = ->
  # snuff out the standard motd
  @then @execute 'test -f /etc/motd && sudo rm /etc/motd; exit 0'
  # hack to block auto-rebuild
  @then @execute 'mkdir -p /etc/motd', sudo: true

  @default openssh: server:
    PrintMotd: 'no'
    PrintLastLog: 'no'

  @then @execute "sed -i 's/^session    optional   pam_motd\.so/#session    optional   pam_motd.so/' /etc/pam.d/login", sudo: true

  #update crontab adding script to populate /tmp/pub_ip if it doesn't exist, and do it now anyway
  @then @execute "wget -qO- http://ipecho.net/plain > /tmp/pub_ip && chmod 644 /tmp/pub_ip", ignore_errors: true
  @then @execute "crontab -l 2>&1 | sed \"s/^no crontab.*//g\" | sed \"s/.*ipecho.*//g\" | printf  \"$(cat -)\n0 22 * * 0 \twget -qO- http://ipecho.net/plain > /tmp/pub_ip\n\" | crontab -"

  # build the new dynamic motd
  @then @template [__dirname, 'templates', 'default', 'motd'],
    to: '/usr/local/bin/dynmotd'
    owner: 'root'
    group: 'root'
    mode: '0755'
    sudo: true

  @then @execute 'touch /etc/motd-maint', sudo: true

  if @server.motd?.banner
    @then @upload @server.motd.banner,
      to: '/usr/local/etc/dynmotd-art.txt'
      owner: 'root'
      group: 'root'
      mode: '0644'
      sudo: true
  else
    @then @execute 'touch /usr/local/etc/dynmotd-art.txt', sudo: true

  # all bash shell users will see it
  line = "/usr/local/bin/dynmotd"
  @then @execute "grep -q '#{line}' /etc/profile", test: ({code}) => if code isnt 0
    @then @execute "echo '#{line}' | sudo tee -a /etc/profile"

  # enable color prompts
  line2 = 'export color_prompt=yes'
  @then @execute "grep -q '#{line2}' /etc/profile", test: ({code}) => if code isnt 0
    @then @execute "echo '#{line2}' | sudo tee -a /etc/profile"
