# JupyterNotebooks-Template

> NOTE: UPDATE THIS LINK WITH YOUR_ACCOUNT/YOUR_REPO
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/YOUR_ACCOUNT/YOUR_REPO/master?urlpath=lab)

This repo holds .NET Interactive notebooks.

## Tools included in the Dockerfile

* `Juypter Lab`
* `.NET Interactive`
* `PowerShell`
  * `Microsoft.PowerShell.UnixCompleters` module
* `kubectl`

It also sets the Jupyter Lab theme to Dark Mode :)

### Extensibility

* The `profile.ps1` will be your `$profile` in the container.
* Install more things in the Dockerfile if you so choose.
* Add more notebooks to the `notebooks` folder.

## Running with MyBinder

Click on the badge at the top of the README.

## Running with Docker locally

1. clone the repo
2. `cd /path/to/JupyterNotebooks`
3. `docker build . -t 'jupyter-notebooks'`
4. `docker run -p 8888:8888 -v ${PWD}:/data/JupyterNotebooks/ jupyter-notebooks:latest start.sh jupyter lab`
5. Navigate in your browser to the URL in your terminal (it looks like this: `http://127.0.0.1:8888/?token=23bad32792cb5415b9566ce42ac23739a6f8a105d931f564`)

At this point, you should be in Jupyter Lab. It's running within a container. You can modify any of the files in the UI and the changes will be reflected to your host OS so that you can commit changes to your own git repo or something like that.
