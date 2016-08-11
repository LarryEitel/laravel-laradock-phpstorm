# laravel-laradock-phpstorm
Wiring up [Laravel](https://laravel.com/), [LaraDock](https://github.com/LaraDock/laradock) [Laravel+Docker] and [PHPStorm](https://www.jetbrains.com/phpstorm/) to play nice together complete with remote xdebug'ing as icing on top!

- [Intro](#Intro)
- [Installation](#Installation)
    - [Windows](#InstallWindows) 
    - [Docker](#InstallDocker) 
    - [Laravel](#InstallLaravel) 
    - [LaraDock](#InstallLaraDock) 
        - [Custom php-fpm](#InstallPHP-FPM) 
        - [Docker Images](#InstallDockerImages) 
            - [Push Images to Docker Hub](#InstallDockerImagesToTheHub) 
        - [Clean House](#InstallCleanHouse) 
        - [LaraDock Dial Tone](#InstallLaraDockDialTone) 
        - [SSH into php-fpm](#InstallLaraDockSSH) 
            - [KiTTY](#InstallKiTTY) 
    - [PHPStorm](#InstallPHPStorm)
        - [Configs](#InstallPHPStormConfigs)
- [Usage](#Usage)
    - [Laravel](#UsageLaravel) 
        - [Run ExampleTest](#UsagePHPStormRunExampleTest) 
        - [Debug ExampleTest](#UsagePHPStormDebugExampleTest) 
        - [Debug Web Site](#UsagePHPStormDebugSite) 

<a name="Intro"></a>
## Intro
Goal is to put together a sample Laravel project running on very slightly extended version LaraDock that can run in a development environment complete with remote debugging. 

I am running with Docker Native Windows.



<a name="Installation"></a>
## Installation
This project assumes experience and familiarity with Laravel, Laradock and PHPStorm before proceeding. 
The purpose of this project is to focus on how to get these three projects to work together in a PHPStorm development workflow.


<a name="InstallWindows"></a>
### Windows
#### [Hosts File Editor](http://hostsfileeditor.codeplex.com/)
- Hosts File Editor makes it easy to change your hosts file as well as archive multiple versions for easy retrieval.
    - Set `llpLaravel` to your docker host IP.

<a name="InstallDocker"></a>
### Docker


<a name="InstallLaravel"></a>
### Laravel

Install Laravel somewhere. See from perspective of [LaraDock Installation](https://github.com/LaraDock/laradock#Installation).

- Example with [Laravel Installer](https://laravel.com/docs/5.2#installing-laravel)
`laravel new laravel-laradock-phpstorm`

#### Create a GIT repo
- [Create a new repository](https://github.com/new)
```
cd laravel new laravel-laradock-phpstorm
git init
git add .
git  commit -m "first commit"
git remote add origin git@github.com:LarryEitel/laravel-laradock-phpstorm.git
git push -u origin master
```

<a name="InstallLaraDock"></a>
### Laradock
Since we will using LaraDock as a submodule,
```
# /c/_dk/laravel-laradock-phpstorm
git submodule add https://github.com/LaraDock/laradock.git

# We will retain laradock submodule to pull updates to compare/revise our 
# refactored version.
mkdir llp # short for laravel-laradock-phpstorm
cp -R laradock/* llp
cd llp
```


<a name="InstallPHP-FPM"></a>
### php-fpm
Here's a catalog of files in `laravel-laradock-phpstorm/llp/php-fpm`:
```
.dotfiles
    .bashrc # set a couple variables for git-town
.gitignore
Dockerfile-56
Dockerfile-70
Dockerfile-add-ssh-supervisor
Dockerfile-lwe
id_rsa_vm
id_rsa_vm.pub
laravel.ini
laravel.pool.conf
set_dockerhost_ip.sh*
supervisord.conf
xdebug.ini
```

- Create keys for use with Docker/vm and copy them into this directory. Note the `_vm` in their name. These will be .gitignore'd. At the moment, I found no way to copy them to the container by direct reference on a Windows Host. 
    - `id_rsa_vm`
    - `id_rsa_vm.pub`


<a name="InstallDockerImages"></a>
#### Custom Docker Images
Why create custom images? Speed! Convenient tweek'age of final image which can be conveniently rebuilt without having to rebuild entire image every time.

##### laradock-php-fpm-70
- snapshot of stock `laradock-php-fpm-70` and tag it
```
cd laravel-laradock-phpstorm/llp/php-fpm
```

Let's set a variable to reflect current `LaraDock` version:
`LARADOCK_VERSION=v4.0.4`

```
docker build --no-cache \
    -t larryeitel/laradock-php-fpm-70:latest \
    -t larryeitel/laradock-php-fpm-70:$LARADOCK_VERSION \
    -f Dockerfile-70 .

# Run:
docker images | awk '{print $1,$2,$3}' | grep laradock-php-fpm-70

# you should see:
larryeitel/laradock-php-fpm-70      latest              <hash>        14 seconds ago      522.3 MB
larryeitel/laradock-php-fpm-70      <LARADOCK_VERSION>  <hash>        14 seconds ago      522.3 MB


```

##### php-fpm/Dockerfile-70-ssh-supervisor
- Let's build an image that extends from `larryeitel/laradock-php-fpm-70` that will contain `ssh` and `supervisor`.
Please review [Dockerfile-70-ssh-supervisor](./llp/php-fpm/Dockerfile-70-ssh-supervisor) to see what is being added to this container.
    - For example, I am adding: 
        ```
        man \
        telnet \
        php-pear \
        git wget supervisor openssh-server \
        vim 
        ```
        Feel free to remove `man`, `telnet`, `php-pear` and `vim`.
    
```
cd laravel-laradock-phpstorm/llp/php-fpm

docker build --no-cache \
    -t larryeitel/llp-php-fpm-70-ssh-supervisor:latest \
    -t larryeitel/llp-php-fpm-70-ssh-supervisor:$LARADOCK_VERSION \
    -f Dockerfile-70-ssh-supervisor .

# Run:
docker images | awk '{print $1,$2,$3}' | grep llp-php-fpm-70-ssh-supervisor

# you should see:
larryeitel/llp-php-fpm-70-ssh-supervisor latest             <hash>
larryeitel/llp-php-fpm-70-ssh-supervisor <LARADOCK_VERSION> <hash>
```



##### php-fpm/Dockerfile-70-llp
This is where important configurations are made to accommodate PHPStorm. 

- If you rebuild the above images as in the case of a version bump for LaraDock, you probably want to refresh the php-fpm container too.
```
cd laravel-laradock-phpstorm/llp

docker-compose build --no-cache php-fpm
```

- If your containers are currently running, let's give it a restart.
`docker-compose up -d mysql nginx`


##### llp/docker-compose.yml
- Need to set your docker host IP for php-fpm container.
```
php-fpm:
    build:
        context: ./php-fpm
        args:
            - INSTALL_MONGO=false
            - INSTALL_XDEBUG=true

        # Changed to point to refactored Dockerfile
        dockerfile: Dockerfile-70-llp
    volumes_from:
        - volumes_source
    expose:
        - "9000"
    links:
        - workspace

    # added to expose ssh port
    ports:
        - "22:22"

    extra_hosts:
        # insert your docker host IP
        # this will be appended to php-fpm container /etc/hosts
        - "dockerhost:10.0.75.1"

    # PHPStorm needs this
    environment:
        - PHP_IDE_CONFIG="serverName=llpLaravel"
```

<a name="InstallDockerImagesToTheHub"></a>
#### Push Images to Docker Hub
Steps I take to push these images to the hub:
- docker login -u larryeitel -p
- docker push larryeitel/laradock-php-fpm-70:$LARADOCK_VERSION
- docker push larryeitel/laradock-php-fpm-70:latest
- docker push larryeitel/llp-php-fpm-70-ssh-supervisor:$LARADOCK_VERSION
- docker push larryeitel/llp-php-fpm-70-ssh-supervisor:latest


<a name="InstallCleanHouse"></a>
### Need to clean house first?
Make sure you are starting with a clean state. For example, do you have other LaraDock containers and images?
Here are a few things I use to clean things up.

- Delete all containers using `grep laradock` on the names, see: [Remove all containners based on docker image name](https://linuxconfig.org/remove-all-containners-based-on-docker-image-name). 
`docker ps -a | awk '{ print $1,$2 }' | grep laradock | awk '{print $1}' | xargs -I {} docker rm {}`

- Delete all images containing `laradock`.
`docker images | awk '{print $1,$2,$3}' | grep laradock | awk '{print $3}' | xargs -I {} docker rmi {}`
**Note:** Some may fail with: 
`Error response from daemon: conflict: unable to delete 3f38eaed93df (cannot be forced) - image has dependent child images`

- I added this to my `.bashrc` to remove orphaned images.
    ```
    dclean() {
        processes=`docker ps -q -f status=exited`
        if [ -n "$processes" ]; thend
          docker rm $processes
        fi
    
        images=`docker images -q -f dangling=true`
        if [ -n "$images" ]; then
          docker rmi $images
        fi
    }
    ```

<a name="InstallLaraDockDialTone"></a>
#### Let's get a dial-tone with Laravel

```
# barebones at this point
docker-compose up -d nginx mysql

# run 
docker-compose ps

# Should see:
llp_mysql_1            docker-entrypoint.sh mysqld      Up       0.0.0.0:3306->3306/tcp
llp_nginx_1            nginx                            Up       0.0.0.0:443->443/tcp, 0.0.0.0:80->80/tcp
llp_php-fpm_1          /usr/bin/supervisord -c /e ...   Up       0.0.0.0:22->22/tcp, 9000/tcp
llp_volumes_data_1     true                             Exit 0
llp_volumes_source_1   true                             Exit 0
llp_workspace_1        /sbin/my_init                    Up


```

- If you have run LaraDock on other projects, you MAY encounter this issue: [Plugin 'InnoDB' registration as a STORAGE ENGINE failed.](https://github.com/LaraDock/laradock/issues/202)

<a name="InstallLaraDockSSH"></a>
#### Let's shell into php-fpm
`ssh -i  php-fpm/id_rsa_vm root@docker`

<a name="InstallKiTTY"></a>
**Cha Ching!!!!**
##### KiTTY
[Kitty](http://www.9bis.net/kitty/) KiTTY is a fork from version 0.67 of PuTTY.

- Here are some settings that are working for me:
    - ![Session](screenshots/KiTTY/Session.png)
    - ![Terminal](screenshots/KiTTY/Terminal.png)
    - ![Window](screenshots/KiTTY/Window.png)
    - ![WindowAppearance](screenshots/KiTTY/WindowAppearance.png)
    - ![Connection](screenshots/KiTTY/Connection.png)
    - ![ConnectionData](screenshots/KiTTY/ConnectionData.png)
    - ![ConnectionSSH](screenshots/KiTTY/ConnectionSSH.png)
    - ![ConnectionSSHAuth](screenshots/KiTTY/ConnectionSSHAuth.png)


<a name="InstallPHPStorm"></a>
### PHPStorm
- File/New Project
![New Project Dialog Box](screenshots/PHPStorm/NewProjectDialogBox.png)
`dockerhost` was added to `etc/hosts` and points to `Docker Host IP`.


    - ![Create From Existing Sources](screenshots/PHPStorm/NewProjectCreateFromExistingSources.png)
Yes

<a name="InstallPHPStormConfigs"></a>
#### Configs
- Here are some settings that work:
    - `Settings/BuildDeploymentConnectionMappings`
        - ![Settings/BuildDeploymentConnectionMappings](screenshots/PHPStorm/Settings/BuildDeploymentConnectionMappings.png)
    
    - `Settings/DeploymentConnection`
        - ![Settings/DeploymentConnection](screenshots/PHPStorm/Settings/DeploymentConnection.png)
    
    - `Settings/LangsPHPInterpreters`
        - ![Settings/LangsPHPInterpreters](screenshots/PHPStorm/Settings/LangsPHPInterpreters.png)
    
    - `Settings/LangsPHPPHPUnit`
        - ![Settings/LangsPHPPHPUnit](screenshots/PHPStorm/Settings/LangsPHPPHPUnit.png)
    
    - `Settings/EditRunConfigurations`
        - ![Settings/EditRunConfigurations](screenshots/PHPStorm/Settings/EditRunConfigurations.png)
    
    - `Settings/LangsPHPServers`
        - ![Settings/LangsPHPServers](screenshots/PHPStorm/Settings/LangsPHPServers.png)
    
    - `RemoteHost`
        - ![RemoteHost](screenshots/PHPStorm/RemoteHost.png)


<a name="Usage"></a>
## Usage

<a name="UsagePHPStorm"></a>
## PHPStorm
<a name="UsagePHPStormRunExampleTest"></a>
### Run ExampleTest
- right-click on `tests/ExampleTest.php`
    - Select: `Run 'ExampleTest.php'` or `Ctrl+Shift+F10`.
    - Should pass!! You just ran a remote test via SSH!

<a name="UsagePHPStormDebugExampleTest"></a>
### Debug ExampleTest
- Open to edit: `tests/ExampleTest.php`
- Add a BreakPoint on line 16: `$this->visit('/')`
- right-click on `tests/ExampleTest.php`
    - Select: `Debug 'ExampleTest.php'`.
    - Should have stopped at the BreakPoint!! You are now debugging locally against a remote Laravel project via SSH!


<a name="UsagePHPStormDebugSite"></a>
### Debug WebSite
- Start Remote Debugging
    - ![DebugRemoteOn](screenshots/PHPStorm/DebugRemoteOn.png) 
- Open to edit: `bootstrap/app.php`
- Add a BreakPoint on line 14: `$app = new Illuminate\Foundation\Application(`
- Reload [Laravel Site](http://llplaravel/)
    - Should have stopped at the BreakPoint!! You are now debugging locally against a remote Laravel project via SSH!
