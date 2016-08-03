# laravel-laradock-phpstorm
Wiring up [Laravel](https://laravel.com/), [LaraDock](https://github.com/LaraDock/laradock) [Laravel+Docker] and [PHPStorm](https://www.jetbrains.com/phpstorm/) to play nice together complete with remote xdebug'ing as icing on top!

## NOTE: This project is incomplete and not ready for use.

<a name="Installation"></a>
## Installation
This project assumes experience and familiarity with Laravel, Laradock and PHPStorm before proceeding. 
The purpose of this project is to focus on how to get these three projects to work together in a PHPStorm development workflow.


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

#### Let's make some changes
##### php-fpm
Here's a catalog of files in `laravel-laradock-phpstorm/llp/php-fpm`:
```
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

###### Create/cache some images
###### laradock-php-fpm-70
- snapshot of stock `laradock-php-fpm-70` and tag it
```
cd laravel-laradock-phpstorm/llp/php-fpm
# Note the following with by default install extensions: xDebug and mongodb
# may choose to override
docker build -t larryeitel/laradock-php-fpm-70:latest \
    -t  larryeitel/laradock-php-fpm-70:v01 \
    -f Dockerfile-70 .

# Run:
docker images | awk '{print $1,$2,$3}' | grep laradock-php-fpm-70

# you should see:
larryeitel/laradock-php-fpm-70      latest              c4a5168e3802        14 seconds ago      522.3 MB
larryeitel/laradock-php-fpm-70      v01                 c4a5168e3802        14 seconds ago      522.3 MB


```

###### php-fpm/Dockerfile-70-ssh-supervisor
- Let's build an image that extends from `larryeitel/laradock-php-fpm-70` that will contain `ssh` and `supervisor`.
Please review [Dockerfile-70-ssh-supervisor](./llp/php-fpm/Dockerfile-70-ssh-supervisor) to see what is being added to this container.
    - For example, I am adding: 
        ```
        php-pear \
        git wget supervisor openssh-server \
        vim 
        ```
        Feel free to remove `php-pear` and `vim`.
    
```
cd laravel-laradock-phpstorm/llp/php-fpm

docker build -t larryeitel/llp-php-fpm-70-ssh-supervisor:latest -t \
    larryeitel/llp-php-fpm-70-ssh-supervisor:v01 \
    -f Dockerfile-70-ssh-supervisor .

# Run:
docker images | awk '{print $1,$2,$3}' | grep llp-php-fpm-70-ssh-supervisor

# you should see:
larryeitel/llp-php-fpm-70-ssh-supervisor latest b0485336a322
larryeitel/llp-php-fpm-70-ssh-supervisor v01 b0485336a322
```

###### php-fpm/Dockerfile-70-llp
This is where important configurations are made to accommodate PHPStorm. 


#### Need to clean house first?
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

#### Let's shell into php-fpm
`ssh -i  php-fpm/id_rsa_vm root@docker`

**Cha Ching!!!!**



### laravel-laradock-phpstorm - LLP
- File/New Project
![New Project Dialog Box](screenshots/PHPStorm/NewProjectDialogBox.png)
`dockerhost` was added to `etc/hosts` and points to `Docker Host IP`.


    - ![Create From Existing Sources](screenshots/PHPStorm/NewProjectCreateFromExistingSources.png)
Yes


