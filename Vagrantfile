ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  #config.vm.synced_folder "/home/cs/data/VM/k8s/dirs/files", "/mnt",create: true,owner: "root", group: "root",mount_options:["dmode=775","fmode=644"]
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1
          ##修改为具有 50% 的主机 CPU 执行上限
    v.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
  end

  ##是否使用公私钥来登录,默认true
  config.ssh.insert_key = false
  config.ssh.private_key_path = [ 
    '~/.ssh/id_rsa', 
    '~/.vagrant.d/insecure_private_key' 
    ] 
    config.vm.provision 'file', 
    source: '~/.ssh/id_rsa.pub', 
    destination: '~/.ssh/authorized_keys' 


  # 激活hostmanager插件
  config.hostmanager.enabled = true

  # 在宿主机上的hosts文件中添加虚拟机的主机名解析信息
  config.hostmanager.manage_host = true

  # 在各自虚拟机中添加各虚拟机的主机名解析信息
  config.hostmanager.manage_guest = true

  #不忽略私有网络的地址
  config.hostmanager.ignore_private_ip = false

  (1..3).each do |i|
    config.vm.define "master#{i}" do |node|
            node.vm.hostname = "master0#{i}"
            node.vm.network "private_network", ip: "192.168.56.10#{i}", hostname: true
    end  
  
  end
  (1..3).each do |i|
      config.vm.define "node#{3+i}" do |node|
            node.vm.hostname = "node0#{3+i}"
            node.vm.network "private_network", ip: "192.168.56.10#{3+i}", hostname: true
                  ##默认最小40GB,Disk cannot be decreased in size. 8192 MB requested but disk is already 40960 MB.
            ##node.disksize.size = "48GB"
        end  
   end
    
     config.vm.provision "shell", path: "k8s.sh"
 
end