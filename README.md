# Hazetug

Cloud provisioner and bootstraper which simplifies node creation and configuration deployment. Hazetug uses simple YAML task file which describes the configuration to setup.

Provisioning is handled by *haze* core which is based on [fog cloud library](http://fog.io). A plenty of different cloud computes available in fog (*AWS*, *Rackspace*, *BareMetalCloud* and many more) helps to extend hazetug with the new *"hazes"* quite simple.

Bootstrapping is done by *" tugs"*, hazetug supports only a few tugs for just Chef now.

## Supported cloud computes

- Linode
- DigitalOcean

## Supported bootstrap methods

- **knife** - chef knife bootstrap method.
- **solo**  - same as *knife* bootstrap, but it also uses [berkshelf](http://berkshelf.com) to package and upload cookbooks to a provisioned node, thus makes it possible usage of *chef-solo*.

## Task file options

### Cloud Computes specific options

<table>
    <tr>
        <td><b>Option</b></td>
        <td><b>Description</b></td>
    </tr>
    <tr>
        <td><b><i>name</i></b></td>
        <td>Name of a host to provision. Random names are possible using %rand(x)% macro.</td>
    </tr>
    <tr>
        <td><b><i>location</i></b></td>
        <td>Location in a cloud compute, namely data center.</td>
    </tr>
    <tr>
        <td><b><i>flavor</i></b></td>
        <td>Flavor of a provisioned host. Flavors are recognized by memory, use: 512mb, 4gb, etc to choose the proper one.</td>
    </tr>
    <tr>
        <td><b><i>image</i></b></td>
        <td>Distribution or image which is used for provisioning. Examples: ubuntu-12.04-x32, arch-linux-2014.14. If OS architecture is not specified then x64 is assumed.</td>
    </tr>
</table>

### SSH Specific

<table>
    <tr>
        <td><b>Option</b></td>
        <td><b>Description</b></td>
        <td><b>Default value</b></td>
    </tr>
    <tr>
        <td><b><i>ssh_user</i></b></td>
        <td>User used during provisioning and bootstrapping for connecting via ssh.</td>
        <td><i>root</i><td>
    </tr>
    <tr>
        <td><b><i>ssh_password</i></b></td>
        <td>Password for a provisioned node. Evaluated randomly for some computes.</td>
        <td></td>
    </tr>
    <tr>
        <td><b><i>ssh_port</i></b></td>
        <td>Port used for ssh connection.</td>
        <td><i>22</i><td>
    </tr>
    <tr>
        <td><b><i>host_key_verify</i></b></td>
        <td>Verifies host key, set to true to enable verification.</td>
        <td><i>false</i><td>
    </tr>
</table>

## Knife tug

<table>
    <tr>
        <td><b>Option</b></td>
        <td><b>Description</b></td>
        <td><b>Default value</b></td>
    </tr>
    <tr>
        <td><b><i>chef_validation_key</i></b></td>
        <td>Validation key used to authenticate new nodes in the Chef Server.</td>
        <td><i>validation.pem</i><td>
    </tr>
    <tr>
        <td><b><i>chef_environment</i></b></td>
        <td>Chef Environment used during bootstrap</td>
        <td></td>
    </tr>
    <tr>
        <td><b><i>chef_server_url</i></b></td>
        <td>URL of the Chef Serer.</td>
        <td></td>
    </tr>
</table>

## Solo tug

<table>
    <tr>
        <td><b>Option</b></td>
        <td><b>Description</b></td>
        <td><b>Default value</b></td>
    </tr>
    <tr>
        <td><b><i>chef_environment</i></b></td>
        <td>Chef Environment used during bootstrap</td>
        <td></td>
    </tr>
    <tr>
        <td><b><i>attributes</i></b></td>
        <td>Hash of attributes prepared for chef-solo run. (It's merged with the run_list).</td>
        <td><i>{}</i><td>
    </tr>
    <tr>
        <td><b><i>berksfile</i></b></td>
        <td>Path to Berksfile.</td>
        <td><i>./Berksfile</i></td>
    </tr>
</table>

## Configuration

### Variables priority

Hazetug uses 3-level priority for flexible variable choosing. Priority in the ascending order is the following: variable from the global section -> variable set via command option -> variable in the bootstrap list entity.
All variables are merged using this 3-level priority.

### Tug bootstrap templates

*Knife* and *solo* tugs use ruby ERB bootstrap template file which is basically a shell script performing initial bootstrap phase. Namely performing OS update and system package installation, bootstrapping ruby and chef.


## Installation

Add this line to your application's Gemfile:

    gem 'hazetug'
    # use master until version grater than 1.23.0 is released
    gem 'fog', git: 'https://github.com/fog/fog.git'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hazetug

## Usage

### 1. Create ~/.hazetug configuration file

Create *~/.hazetug* configuration file, with the content like:

```yaml
default:
  linode_api_key: YOUR_LINODE_API_KEY
  linode_ssh_keys:
    - ~/.ssh/linode.pem (Change with your path, it also might be missing)
  digitalocean_api_key: DIGITALOCEAN_API_KEY
  digitalocean_client_id: DIGITALOCEAN_CLIENT_ID
  digitalocean_ssh_keys:
    - ~/.ssh/digitalocean.pem (Change with your path)
```

### 2. Define task

Hazetug YAML task file consists of two sections **global** and **bootstrap**. Global section sets default variables used by hazetug and bootstrap section is basically a list of nodes to be provisioned and to be bootstrapped.
Each bootstrap entity includes *haze specification* (name, location, flavor  and image) as well as it defines node specific variables.

Let's have a look at a sample task file:

```
chef_server_url: 'https://mychefserver.uri'
chef_environment: staging
chef_version: 11.14.6
ruby_version: ruby-2.1.2
ssh_password: my-password-on-api-nodes
bootstrap:
  - name: api-testbox-%rand(6)%
    number:   2
    location: london
    flavor:   2gb
    image:    ubuntu-14.04-x64
    run_list: ["role[api]"]
```

This simple configuration is supposed to bring 6 nodes in the Cloud and bootstrap the with *knife* tug.

Also it's worth mentioning the variables priority look into the [Variables Priority](README.md#variables-priority) section.

### 3. Create bootstrap template file

Use one of the bootstrap templates provided in the *examples* directory or create yours.

### 4. Run hazetug

`bundle exec hazetug digitalocean bootstrap knife -b bootstrap.erb task.yaml`

## Command line and invocation

### Tug with chef-client and chef-solo (knife bootstrap)

Let's first have a look at command line help, issue the following command: `hazetug help digitalocean bootstrap knife`, and this will show you:

```
NAME
    bootstrap - Provisions and bootstraps server

SYNOPSIS
    hazetug [global options] digitalocean bootstrap [command options] knife <task.yaml>
    hazetug [global options] digitalocean bootstrap [command options] solo <task.yaml>

COMMAND OPTIONS
    -v, --variables=arg   - Set variable or comma-seperated list of variables (var1_1=hello) (default: none)
    -n, --number=arg      - Set number of created nodes, value from yaml is honored (default: 1)
    -c, --concurrency=arg - Set concurrency value, i.e. number of hosts bootstraped simultaneously (default: 1)
    -b, --bootstrap=arg   - Set path to knife bootstrap.erb file (default: bootstrap.erb)

COMMANDS
    knife - Bootstraps server using Knife in client mode
    solo  - Bootstraps server using Knife in solo mode
```

Concurrency and number are used to control hazetug provision and bootstrap flow. When we create 20 identical nodes we might want to process say it 4 nodes simultaneously, so we will use `-n 20 -c 4` on the command line. 

Variables are useful to define some parameter for hazetug, providing a variable on command line will redefine the corresponding variable in global section. So it's useful to specify something like: `-v chef_version=11.16.0.rc.0,ruby_version=2.1.2`.

#### Variables available in bootstrap template

Variables are merged and passed by tug into bootstrap template, use *hasetug[:variable]* to look up a value. For a example to get *chef_version* or *node location* it will be easy as this:

```
<%= hazetug[:chef_version] %>
<%= hazetug[:location] %>
```

While all the variables you've specified on command line and inside YAML task file are being merged and are available there are other dynamic values which might be useful as well:

- compute_name
- public_ip_address
- private_ip_address
- ssh_password


#### knife and solo tugs difference

They both use knife bootstrap, but *knife* is supposed to run chef-client while *solo* to run chef-solo. Also they use a little bit different options look at the [Task file options](README.md#task-file-options) section.
For more information on the bootstrap process have a look into *examples* directory.

More details about *solo* tug should be also given here. An important difference that *solo* tug is assisted by berkshelf to create and upload cookbooks package that makes possible **chef-solo** invocation. In the *examples* there's the line starting chef-solo:
`chef-solo -j /etc/chef/first-boot.json -r <%= hazetug[:cookbooks_file] %>`

Another note is about *run_list* and *attributes*, just mention that *run_list* is merged into *attributes* and available as `hazetug[:attributes_json]` inside the bootstrap template.

#### Invocation examples

* Provisioning and bootstrapping 5 nodes, each 3 of them will be processed simultaneously:
  
  `bundle exec hazetug digitalocean bootstrap knife -n 5 -c 3 -b api.erb api-task.yaml`
  
* Redefining validation_key and chef_version:
  
  `bundle hazetug digitalocean bootstrap knife -v validation_key=/tmp/validation.pem,chef_version=11.12.4 api.erb api-task.yaml`

## Contributing

1. Fork it ( http://github.com/dennybaa/hazetug/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
