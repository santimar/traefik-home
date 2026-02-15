[![ghcr.io release](https://img.shields.io/github/v/release/santimar/traefik-home?label=latest%20version&style=for-the-badge)](https://github.com/santimar/traefik-home/pkgs/container/traefik-home/versions)

# Traefik Home
![preview](/doc/preview.jpg)

This tool will create a homepage for quickly accessing services which are hosted via the [Traefik reverse proxy](https://traefik.io/traefik/). This repo is for those using V2 and V3 of Traefik (for those using V1, please look [here](https://github.com/lobre/traefik-home))

Domains are automatically retrieved reading traefik labels and only http(s) routers are supported.

> [!IMPORTANT]  
> This tool makes some assumptions about your Traefik's setup and the way things are configured. Namely, it assumes that the _http_ endpoint is named `web`, while the _https_ endpoint is named `websecure`, in the [static configuration](https://doc.traefik.io/traefik/getting-started/configuration-overview/#the-static-configuration) of Traefik. It is important that this be the case or otherwise, you will end up with an [empty page](../../issues/69).  
> Assuming that you are using a _configuration file_ (as opposed to ENV variables or CLI options) for your static configuration, the endpoint part of the config might look something like this:
> ```yaml
> entryPoints:
> web:
>   address: ":80"
>   http:
>     redirections:
>       entryPoint:
>         to: https
>         scheme: https
>         permanent: true
> websecure:
>   address: ":443"
> ```
> As seen above, the names chosen for the endpoints are `web` and `websecure`, respectively, which is expected by this tool.

## Why this tool

Traefik is a reverse proxy that reads label on the docker compose file and automatically set up itself, so that you can access a service on a container with the specified hostname.
Even though Traefik provides a dashboard that allow you to see services that are proxied, you still have to remember (or save somewhere) all the hostnames in order to access your services.
This tool creates a Home page where all hostnames all listed, for easy access.

It uses [docker-gen](https://github.com/jwilder/docker-gen) to monitor docker configuration changes and render a web page that will be served using `nginx`
This way changes are immediately reflected whenever something gets updated.

## Usage

For a quick preview you can just run the image with the following docker run command:

```
docker run --name traefik-home \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    --label traefik.enable=true \
    --label traefik.http.routers.traefik-home.rule="Host(`home.example.com`)" \
    --label traefik.http.services.traefik-home.loadbalancer.server.port="80" \
    ghcr.io/santimar/traefik-home:latest
```

Wait for the service to be online, then go to `home.example.com` and enjoy the view.

For long runs however, the docker-compose file is a better approach.

## Docker compose
```yaml
version: '3'

services:
  traefik-home:
    image: ghcr.io/santimar/traefik-home:latest  # or use a specific tag version
    container_name: traefik-home
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    labels:
      - traefik.enable="true"
      - traefik.http.routers.traefik-home.rule="Host(`home.example.com`)"
      - traefik.http.services.traefik-home.loadbalancer.server.port="80"

  other-service:
    image: ...
    labels:
      # see below for more info about exposed containers configuration
      - traefik-home.icon: "https://url/of/an/icon.png"
      - traefik-home.alias: "Alias"
    
```

## Labels to configure Home

The `traefik-home` container can be configured using the following optional labels.

| Label                             | Description                                                                                   | Default   |
|-----------------------------------|-----------------------------------------------------------------------------------------------|-----------|
| traefik-home.show-footer          | Whether to show footer on the home page                                                       | true      |
| traefik-home.show-status-dot      | Whether to show green/red status dot near the container name                                  | true      |
| traefik-home.sort-by              | Container list sort order. Supported values are "default" (container creation date) or "name" | "default" |
| traefik-home.open-link-in-new-tab | Whether to open services link in a new tab                                                    | false     |

## Labels to configure containers

Home will use the following `traefik` labels to generate the HTML page.

| Label                                        | Description                                                      |
|----------------------------------------------|------------------------------------------------------------------|
| traefik.http.routers.\<service\>.rule        | Domain and path used by Home to generate the link to the service |
| traefik.http.routers.\<service\>.entrypoints | Only `web` or `websecure` entrypoints are shown                  |
| traefik.enable                               | Only explicitly enabled container are shown on the homepage      |

<details>
<summary>note about setting multiple domains and/or paths on the same rule</summary>

---
Traefik allows you to set multiple domains and path on the same rule like 
```
Host(`example.org`) && PathPrefix(`/path`) || Host(`domain.com`) && Path(`/path`)
```
However Traefik-Home will only use the first `Host` and `Path/PathPrefix` found within the rule.

In this example, the app will be available at `example.org/path`, ignoring the other domain.

Also, keep in mind that using a rule like 
```
Host(`example.org`) || Host(`domain.com`) && PathPrefix(`/path`)
```
will create a link to `example.org/path`.

In a situation like this, you just have to rewrite the rule like 
```
Host(`example.org`) && PathPrefix(`/`) || Host(`domain.com`) && PathPrefix(`/path`)
```
or like 
```
Host(`domain.com`) && PathPrefix(`/path`) || Host(`example.org`)
```
---
</details>

On each exposed container, the following optional labels can be added to provide a personalized configuration.

| Label                                   | Description                                                                                                                               |
|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| traefik-home.hide="true"                | Do not show this container in the home page                                                                                               |
| traefik-home.icon="https://url/of/icon" | URL of an image that will be used as icon for the container. If this label is not used, a icon with the container's initials will be used |
| traefik-home.alias="alias"              | If used, the alias will be shown instead of the container name                                                                            |

<details>
<summary>serving self-hosted icons</summary>

`traefik-home.icon` must be an URL, but since `traefik-home` runs on `nginx`, we can take advandage of it and serve self-hosted icons as well.

You will need to mount icon file(s) to `/usr/share/nginx/html/icons/` folder on `traefik-home` container like:

```yaml
traefik-home:
   image: ghcr.io/santimar/traefik-home:latest
   volumes:
       - /var/run/docker.sock:/var/run/docker.sock:ro
       - "/path/to/your/icon.svg:/usr/share/nginx/html/icons/my-icon.svg:ro"
   labels:
       - "traefik.enable=true"
       - "traefik.http.routers.traefik-home.rule=Host(`dashboard.localhost`)"
 ```

And then reference it in other container labels like so:
```yaml
   - "traefik-home.icon=http://dashboard.localhost/icons/my-icon.svg"
```
</details>

## Update

When a new release is available, just:
```
docker pull ghcr.io/santimar/traefik-home:latest
```

and then 

```
docker-compose up -d traefik-home 
```
