# Table of Contents

   * [Mattermost Openresty bridge](#mattermost-openresty-bridge)
      * [Installation](#installation)
      * [Auth token](#auth-token)
      * [Bitbucket webhooks support](#bitbucket-webhooks-support)
         * [Multiple rooms for multiple Bitbucket configurations](#multiple-rooms-for-multiple-bitbucket-configurations)
      * [Bitbucket Pipelines support](#bitbucket-pipelines-support)
      * [Sentry integration](#sentry-integration)
      * [TeamCity integration](#teamcity-integration)

# Mattermost Openresty bridge

This is a bridge between [Mattermost](https://openresty.org/en/) and various other services,
scripted in Lua using the [Openresty](https://openresty.org/en/) platform.

## Installation

This is a Docker container with an up-to-date `docker-compose` file so basically you just need to
```
docker-compose up
```
and you're done.

If you want bots to send custom username to Mattermost, you need to check the
`Enable integrations to override usernames` setting in Mattermost System Console.

If you want to add custom config, best is to use the `docker-compose.override.yml` file
(see <https://docs.docker.com/compose/extends/> on how this works).

## Auth Token

It is possible to set the env variable `AUTH_TOKEN` to some string which will be checked
via the `/auth` endpoint. To pass the token in the URL, specify it in the querystring
under the `auth=` key:

```
https://<mattermost-openresty>/mattermost/bitbucket?auth=<auth-token>
```

(This is a primitive authentication method. However 3rd party webhooks like Bibucket don't
seem to provide even header tokens).

## Bitbucket webhooks support

In Bitbucket, go to project `Settings -> Webhooks -> Add webhook`. As the webhook URL enter
```
<openresty-host>/mattermost/bitbucket
```
Then go to Mattermost, add an Incoming hook and paste its URL
into `docker-compose.yml` under the `BITBUCKET_MATTERMOST_URL` setting (this is where the notifications
about Bitbucket events will come). Start the containers and you're done!

Username is `bitbucket` by default, change it via the `BITBUCKET_MATTERMOST_USER` env variable.

### Multiple rooms for multiple Bitbucket configurations

You can have multiple Bitbucket notifications being proxied to multiple rooms.
Just specify `BITBUCKET_MATTERMOST_URL_ROOM1` env variable and set the bitbucket
URL to `<openresty-host>/mattermost/bitbucket?room=room1` (uppercase env is handled automatically).

Same goes for `BITBUCKET_MATTERMOST_USER_USER1` being mapped to
`<openresty-host>/mattermost/bitbucket?user=user1`.

Don't forget to add your custom variables to the `nginx.conf` file!

If you don't want to provide multiple variables and alter the `nginx.conf` file, there is another
way to introduce multiple rooms. You can define a simple key-value mapping (in JSON format)
into the `BITBUCKET_MATTERMOST_URL` and `BITBUCKET_MATTERMOST_USER` variables.
Also, `"default"` key has the special property of returning the value whenever it
is not found in JSON.

For example:

```bash
BITBUCKET_MATTERMOST_URL='{"default": "<other-rooms>", "room1": "<room1-url>", "room2": "<room2-url>"}'
BITBUCKET_MATTERMOST_USER='{"room1": "<room1-user>", "room2": "<room2-user>"}'
```

The default user is `bitbucket` but there is no default URL so if room is undefined, nginx
will throw an exception.

## Bitbucket Pipelines support

We also support update notifications from Bitbucket Pipelines. To add the Webhook, go to
your repository settings on Bitbucket, select `Webhooks -> Add Webhook` and then make sure
to pick `Choose from a full list of triggers -> Build status updated`.

Environment variables are `PIPELINES_MATTERMOST_URL` and `PIPELINES_MATTERMOST_USER` and
they behave in exactly the same way as variables for the Bitbucket integration.

## Sentry integration

In a [Sentry](https://sentry.io/welcome/) project settings, enable webhooks, then put this as the address:
```
<openresty-host>/sentry/mattermost
```
Again, create an Incoming webhook in Mattermost and save in `docker-compose.yml` under the
`SENTRY_MATTERMOST_URL` variable.

Username is `sentry` by default, change it via the `SENTRY_MATTERMOST_USER` env variable.

Same logic applies for the `SENTRY_MATTERMOST_URL` and `SENTRY_MATTERMOST_USER` variables
for multi-room configuration as above.


## TeamCity integration

You need the [teamcity-webhooks plugin](https://github.com/evgeny-goldin/teamcity-webhooks).

Create an Incoming hook in Mattermost, save it in `docker-compose.yml` under the
`TEAMCITY_MATTERMOST_URL` variable.

Now, to set up TeamCity this is what I did: I created a dummy project, inside it a simple build
configuration with the following script contents:

```bash
#!/bin/bash

echo "%teamcity.build.triggeredBy%"

curl "<mattermost-openresty-server-url>" -XPOST -d '{"triggeredBy": "%teamcity.build.triggeredBy%"}'
```

For build Triggers, I add all build configurations that I want to watch. Unfortunately, our dummy
build will only get the variable `teamcity.build.triggeredBy` which has the form:
```
Finish Build Trigger; <project-name> :: <build-configuration>, build #8
```

So on our side, we parse that variable, and fetch all required data from the
[TeamCity REST API](https://confluence.jetbrains.com/display/TCD10/REST+API). That's why
you also need to specify the following variables:

* `TEAMCITY_SERVER_URL` -- the URL of the TeamCity server. It probably could sent via the above
  `curl` command but this way we get to add more fancy configuraitons (the syntax is also the
  key-value JSON format described above).
* `TEAMCITY_SERVER_AUTH` -- this is the base64-encoded `<username>:<password>` string for the
  TeamCity user who has read access to the projects, build configurations and build number data.
