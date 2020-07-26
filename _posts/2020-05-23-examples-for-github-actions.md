---
layout: post
title: Examples for GitHub Actions
date: 2020-05-23 12:59
author: Raimund Rittnauer
description: Examples for GitHub Actions with Docker container and JavaScript actions
categories: tech
comments: true
tags:
  - docker
  - github
---

You can choose to write your GitHub actions using either Docker or JavaScript.
The _action.yml_ file describes your action and is called _metadata file_ and uses the [metadata syntax for GitHub Actions](https://help.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions){:target="\_blank"}.

> Docker and JavaScript actions require a metadata file. The metadata filename must be either action.yml or action.yaml. The data in the metadata file defines the inputs, outputs and main entrypoint for your action ([about YAML syntax for GitHub Actions](https://help.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions#about-yaml-syntax-for-github-actions){:target="\_blank"}).

## Deploy with scp (Docker Action)

This action uses a Docker container to copy files with scp.

The _Dockerfile_ executes _entrypoint.sh_ and this script executes _sshpass_ with the values of the input fields which are declared in the _action.yml_ metadata file.

Set the values for _runs:_ in your _action.yml_ to specify which Dockerfile to use

```yml
runs:
  using: "docker"
  image: "Dockerfile"
```

_Dockerfile_

```Dockerfile
FROM alpine:3.11.6
RUN apk add --update openssh sshpass
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
```

To access the value of an input field inside your _entrypoint.sh_ you have to add the prefix _\$INPUT\__ and use uppercase letters.

_entrypoint.sh_

```bash
#!/bin/sh -l
export SSHPASS=$INPUT_PASSWORD
sshpass -e scp -r -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $INPUT_SOURCE $INPUT_USERNAME@$INPUT_HOSTNAME:$INPUT_TARGET
```

This is a private action, because of this we have to use the path to the location of the action in this repository

{% raw %}
```yaml
uses: ./.github/actions/deploy-with-scp-docker
with:
  hostname: ${{ secrets.HOSTNAME }}
  username: ${{ secrets.USERNAME }}
  password: ${{ secrets.PASSWORD }}
  source: "."
  target: ${{ secrets.TARGET }}
```
{% endraw %}

For more information checkout the [documentation about creating a Docker container action](https://help.github.com/en/actions/creating-actions/creating-a-docker-container-action){:target="\_blank"} and the [documentation about Dockerfile support](https://help.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions){:target="\_blank"}.

## Deploy with sftp (JavaScript Action)

This action uses Node.js to copy files with sftp.

The _index.js_ uses the [ssh2-sftp-client](https://www.npmjs.com/package/ssh2-sftp-client){:target="_blank"} package with the input fields which are declared in the \_action.yml_ metadata file to upload files with sftp.

Set the values for _runs:_ in your _action.yml_ to specify which JavaScript file to execute. We use the _deploy-with-sftp-javascript/dist/index.js_ file because the _deploy-with-sftp-javascript/index.js_ file got compiled using [@zeit/ncc](https://github.com/zeit/ncc){:target="\_blank"}.

> As an alternative to checking in your node_modules directory you can use a tool called zeit/ncc to compile your code and modules into one file used for distribution ([commit, tag and push your action to GitHub documentation](https://help.github.com/en/actions/creating-actions/creating-a-javascript-action#commit-tag-and-push-your-action-to-github){:target="\_blank"}).

```yml
runs:
  using: "node12"
  main: "dist/index.js"
```

To access the value of an input field inside your _index.js_ you have to use the [@actions/core](https://www.npmjs.com/package/@actions/core){:target="\_blank"} package.

_index.js_

```js
const core = require("@actions/core");
const SftpClient = require("ssh2-sftp-client");

async function main() {
  const client = new SftpClient();
  const source = core.getInput("source");
  const target = core.getInput("target");
  const sftpConfig = {
    host: core.getInput("hostname"),
    username: core.getInput("username"),
    password: core.getInput("password"),
  };

  try {
    await client.connect(sftpConfig);
    client.on("upload", (info) => {
      console.log(`Uploaded ${info.source}`);
    });
    return await client.uploadDir(source, target);
  } finally {
    client.end();
  }
}

main()
  .then((msg) => {
    console.log(msg);
  })
  .catch((err) => {
    core.setFailed(err.message);
  });
```

This is a private action, because of this we have to use the path to the location of the action in this repository.
You can set secrets in the settings page of your repository.

{% raw %}
```yaml
uses: ./.github/actions/deploy-with-sftp-javascript
with:
  hostname: ${{ secrets.HOSTNAME }}
  username: ${{ secrets.USERNAME }}
  password: ${{ secrets.PASSWORD }}
  source: "."
  target: ${{ secrets.TARGET }}
```
{% endraw %}

For more information checkout the [documentation about creating a JavaScript container action](https://help.github.com/en/actions/creating-actions/creating-a-javascript-action){:target="\_blank"} and the [GitHub Actions Toolkit](https://github.com/actions/toolkit){:target="\_blank"} is a really great collections of useful packages for developing GitHub JavaScript actions.

## Usage in GitHub workflow

{% raw %}
```yml
name: CI

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v2

      - name: Deploy with sftp JavaScript
        uses: ./.github/actions/deploy-with-sftp-javascript
        with:
          hostname: ${{ secrets.HOSTNAME }}
          username: ${{ secrets.USERNAME }}
          password: ${{ secrets.PASSWORD }}
          source: "./files-to-upload"
          target: "./html/javascript-action"

      - name: Deploy with scp Docker
        uses: ./.github/actions/deploy-with-scp-docker
        with:
          hostname: ${{ secrets.HOSTNAME }}
          username: ${{ secrets.USERNAME }}
          password: ${{ secrets.PASSWORD }}
          source: "./files-to-upload"
          target: "./html/docker-action"
```
{% endraw %}

The source code is available on [GitHub](https://github.com/raaaimund/github-actions-example){:target="\_blank"}.
