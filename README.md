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

## Bitbucket webhooks support

In Bitbucket, go to project Settings -> Integrations Services -> Add webhook. As the webhook URL enter
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

## Sentry integration

In a [Sentry](https://sentry.io/welcome/) project settings, enable webhooks, then put this as the address:
```
<openresty-host>/sentry/mattermost
```
Again, create an Incoming webhook in Mattermost and save in `docker-compose.yml` under the
`SENTRY_MATTERMOST_URL` variable.

Username is `sentry` by default, change it via the `SENTRY_MATTERMOST_USER` env variable.
