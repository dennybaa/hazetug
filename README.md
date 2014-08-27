# Hazetug

Cloud provisioner and bootstrapper for DigitalOcean and Linode.
Hazetug uses [fog cloud library](http://fog.io) to be able to easily append other cloud computes and *tugs* (bootstraps) hosts using:

* Knife bootstrap.

## Options

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
        <td>Location in the cloud compute, namely data center.</td>
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
        <td>User used to during provisioning and for connecting via ssh.</td>
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

### Knife tug bootstrap options

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

## Installation

Add this line to your application's Gemfile:

    gem 'hazetug'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hazetug

## Usage

### Configuration file

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

### Tasks

Hazetug bootstrap task file is yaml file as well, it consists of two sections **global** and **bootstrap**. Global section sets default variables used by hazetug, each bootstraped host from bootstrap list sets variables specific to it thus redefining global defaults. Let's have a look at a sample task file:

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

From the example above we can see various variables used by hazetug they are common for all bootstrapped nodes, that's why it's reasonable to locate them in the global. However each variable has three layer hierarchy more details look into the [Variables Priority](README.md#variables-priority) section.

### Variables priority

Hazetug uses 3-level priority for flexible variable choosing. Priority in the ascending order is the following: variable from the global section -> variable set via command option -> variable in the bootstrap list entity.
All variables are merged using this 3-level priority.


### Command Line and Invocation

### Bootstrap using knife

Help for linode compute is given bellow:

```
NAME
    knife - Bootstraps server using Knife

SYNOPSIS
    hazetug.rb [global options] linode bootstrap knife [command options] task.yaml

COMMAND OPTIONS
    -v, --variables=arg   - Set variable or comma-seperated list of variables (var1_1=hello) (default: none)
    -n, --number=arg      - Set number of created nodes, value from yaml is honored (default: 1)
    -c, --concurrency=arg - Set concurrency value, i.e. number of hosts bootstraped simultaneously (default: 1)
    -b, --bootstrap=arg   - Set path to knife bootstrap.erb file (default: bootstrap.erb)
```

All variables are passed to the bootstrap template and are available using the hazetug hash like - `hazetug[:variable_name]`. Amongst variables described here in the options sections, hazetug also passes useful variables such as ***compute_name***, ***public_ip_address***, ***private_ip_address*** if those are available.

#### Examples

* Provisioning and bootstrapping 5 nodes, each 3 of them will be processed simultaneously:
  
  `hazetug digitalocean bootstrap knife -n 5 -c 3 -b api.erb api-task.yaml`
  
* Redefining validation_key and chef_version:
  
  `hazetug digitalocean bootstrap knife -v validation_key=/tmp/validation.pem,chef_version=11.12.4 api.erb api-task.yaml`

## Contributing

1. Fork it ( http://github.com/<my-github-username>/hazetug/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
