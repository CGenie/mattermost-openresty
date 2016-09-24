# Mattermost Openresty bridge

This is a bridge between [Mattermost](https://openresty.org/en/) and various other services,
scripted in Lua using the [Openresty](https://openresty.org/en/) platform.

## Installation

This is a Docker container with an up-to-date `docker-compose` file so basically you just need to
```
docker-compose up
```
and you're done.

## Bitbucket webhooks support

In Bitbucket, go to project Settings -> Integrations Services -> Add webhook. As the webhook URL enter
```
<openresty-host>/mattermost/bitbucket
```
Then go to Mattermost, add an Incoming hook and paste its URL
into `docker-compose.yaml` under the `BITBUCKET_MATTERMOST_URL` setting (this is where the notifications
about Bitbucket events will come). Start the containers and you're done!

## Sentry integration

In a [Sentry](https://sentry.io/welcome/) project settings, enable webhooks, then put this as the address:
```
<openresty-host>/sentry/mattermost
```
Again, create an Incoming webhook in Mattermost and save in `docker-compose.yaml` under the
`SENTRY_MATTERMOST_URL` variable.
